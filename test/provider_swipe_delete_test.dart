import 'dart:ffi' hide Size;

import 'package:codecraft/data/db/app_database.dart';
import 'package:codecraft/data/db/daos.dart';
import 'package:codecraft/data/providers/provider_config.dart';
import 'package:codecraft/data/settings/app_settings.dart';
import 'package:codecraft/features/settings/providers_page.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';

ProviderConfig provider({
  String id = 'p1',
  String name = 'Channel',
  String apiKey = '',
  bool multiKeyEnabled = false,
  List<ProviderKey> apiKeys = const [],
}) =>
    ProviderConfig(
      id: id,
      name: name,
      type: ProviderType.openai,
      apiKey: apiKey,
      multiKeyEnabled: multiKeyEnabled,
      apiKeys: apiKeys,
    );

void main() {
  group('firstUsableApiKey(拉取模型/测试连通性用的 Key)', () {
    test('单 Key 模式用 apiKey 字段', () {
      expect(provider(apiKey: 'sk-single').firstUsableApiKey, 'sk-single');
    });

    test('多 Key 模式从 apiKeys 取首个非空项,而不是空的 apiKey', () {
      final config = provider(
        multiKeyEnabled: true,
        apiKeys: const [
          ProviderKey('  '),
          ProviderKey('sk-multi-1'),
          ProviderKey('sk-multi-2'),
        ],
      );
      expect(config.apiKey, isEmpty, reason: '多 Key 模式下单 Key 字段是空的');
      expect(config.firstUsableApiKey, 'sk-multi-1');
    });

    test('多 Key 但列表为空时返回空串', () {
      expect(provider(multiKeyEnabled: true).firstUsableApiKey, isEmpty);
    });
  });

  group('AI 提供商列表:左划删除', () {
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
            home: const ProvidersPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('左划(右往左)只露出删除按钮,不自动删除', (tester) async {
      await db.providerDao.upsert(provider(name: '待删除渠道'));
      await pumpPage(tester);

      await tester.drag(find.text('待删除渠道'), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // 滑开后渠道仍在,且没弹任何对话框。
      expect(find.text('待删除渠道'), findsOneWidget);
      expect(find.text('确定删除该供应商?'), findsNothing);
      expect(find.text('删除'), findsWidgets);
      expect(await db.providerDao.list(), hasLength(1));
    });

    testWidgets('点删除按钮才弹确认,确认后移除', (tester) async {
      await db.providerDao.upsert(provider(name: '待删除渠道'));
      await pumpPage(tester);

      await tester.drag(find.text('待删除渠道'), const Offset(-400, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      expect(find.text('确定删除该供应商?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, '删除'));
      await tester.pumpAndSettle();

      expect(find.text('待删除渠道'), findsNothing);
      expect(await db.providerDao.list(), isEmpty);
    });

    testWidgets('取消确认时保留渠道', (tester) async {
      await db.providerDao.upsert(provider(name: '保留渠道'));
      await pumpPage(tester);

      await tester.drag(find.text('保留渠道'), const Offset(-400, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      expect(find.text('保留渠道'), findsOneWidget);
      expect(await db.providerDao.list(), hasLength(1));
    });
  });
}