import 'dart:ffi';

import 'package:codecraft/core/ui/settings_group.dart';
import 'package:codecraft/data/db/app_database.dart';
import 'package:codecraft/data/db/daos.dart';
import 'package:codecraft/data/settings/app_settings.dart';
import 'package:codecraft/data/db/llm_call_records.dart';
import 'package:codecraft/features/settings/token_stats_page.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';
import 'package:codecraft/data/model_catalog.dart';

/// Token 统计页布局回归:各区块必须落在 SettingsGroup 里(对齐上游 SettingsGroup 包裹),
/// 空数据时三个分组各显示一个占位,页面不能停在加载态。
void main() {
  late AppDatabase db;

  setUpAll(() {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  setUp(() async {
    db = await AppDatabase.open(inMemory: true);
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() => db.close());

  Future<void> pumpPage(WidgetTester tester) async {
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(preferences),
        // 资产加载在 FakeAsync 下永不完成(会挂住 pumpAndSettle);这里给空目录,
        // 费用相关的行为由 model_catalog_test 覆盖。
        modelCatalogProvider.overrideWith((ref) async => ModelCatalog.empty),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TokenStatsPage(),
        ),
      ),
    );
    // 等 load() 完成(DAO 查询是异步的)。
    await tester.pumpAndSettle();
  }

  testWidgets('空数据:不转圈,三个分组各有「暂无数据」占位且都在分组内', (tester) async {
    await pumpPage(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Token 统计'), findsOneWidget);

    // 三个分组标题都在(调用记录在下方,需滚动才可见)。
    expect(find.text('供应商统计'), findsOneWidget);
    expect(find.text('模型统计'), findsOneWidget);

    // 滚到底部,确保三个分组的占位都进入布局(ListView 惰性构建)。
    await tester.scrollUntilVisible(find.text('调用记录'), 300);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('调用记录'), findsOneWidget);

    // 每个「暂无数据」都必须被 SettingsGroup 包裹(上游空态占位在 SettingsGroup 内)。
    final placeholders = find.text('暂无数据');
    expect(placeholders, findsNWidgets(3));
    for (var index = 0; index < 3; index++) {
      expect(
        find.ancestor(
          of: placeholders.at(index),
          matching: find.byType(SettingsGroup),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('空数据:汇总卡显示 - 与 0.00 美元(对齐上游)', (tester) async {
    await pumpPage(tester);

    expect(find.text('总消耗'), findsOneWidget);
    expect(find.text('请求次数'), findsOneWidget);
    expect(find.text('费用'), findsOneWidget);
    expect(find.text('缓存命中率'), findsOneWidget);
    expect(find.text('-'), findsNWidgets(3));
    expect(find.text('\$0.00'), findsOneWidget);
  });

  testWidgets('有数据:供应商/模型/调用记录都渲染在分组内,趋势单点时不渲染', (tester) async {
    await db.llmCallDao.insert(LlmCallRecord(
      providerId: 'p1',
      model: 'm1',
      inputTokens: 1000,
      outputTokens: 200,
      cachedInputTokens: 400,
      status: 'success',
      ttfbMillis: 300,
      durationMillis: 1500,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    await pumpPage(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('供应商统计'), findsOneWidget);
    expect(find.text('模型统计'), findsOneWidget);
    // 只有一个数据点,趋势块按上游不渲染。
    expect(find.text('消耗趋势'), findsNothing);
    // 渠道名缺失时回退显示 id。
    expect(find.text('p1'), findsWidgets);
    expect(find.text('m1'), findsWidgets);

    await tester.scrollUntilVisible(find.text('调用记录'), 200);
    expect(find.text('调用记录'), findsOneWidget);
    expect(find.byType(SettingsGroup), findsWidgets);
  });
}