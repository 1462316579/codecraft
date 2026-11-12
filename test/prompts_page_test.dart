import 'dart:ffi' as ffi;

import 'package:codecraft/app/app.dart';
import 'package:codecraft/app/permissions_gate.dart';
import 'package:codecraft/app/router.dart';
import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/data/db/app_database.dart';
import 'package:codecraft/data/db/daos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';

/// 提示词设置页:三款内置场景提示词与内置编号片段正常渲染,
/// 首次进入自动弹出使用说明公告,关闭后记为已读、帮助按钮可重看。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  open.overrideFor(OperatingSystem.linux, () => ffi.DynamicLibrary.open('libsqlite3.so.0'));
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late AppDatabase db;

  setUp(() async {
    // 跳过首次权限引导:本文件不验证它,弹窗会遮挡其它点击。
    SharedPreferences.setMockInitialValues({PermissionsGate.onboardedKey: true});
    db = await AppDatabase.open(inMemory: true);
  });

  tearDown(() async => db.close());

  testWidgets('提示词页加载内置片段与三款场景提示词,首次进入弹使用说明', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          workspaceProvider.overrideWithValue(Workspace('/tmp/codecraft-prompts-test')),
        ],
        child: const CodecraftApp(),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    // 深链直达提示词页(与设置页入口同一路由)。
    final router = ProviderScope.containerOf(
      tester.element(find.byType(CodecraftApp)),
      listen: false,
    ).read(routerProvider);
    router.push('/settings/prompts');
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    // 三款内置场景提示词:标题与摘要取自 assets,与界面语言无关。
    expect(find.textContaining('编程项目场景'), findsOneWidget);
    expect(find.textContaining('写作项目场景'), findsOneWidget);
    expect(find.textContaining('应用逆向项目场景'), findsOneWidget);
    // 内置编号片段(进程级缓存合并进列表)。
    expect(find.text('00 · identity'), findsOneWidget);
    expect(find.text('99 · runtime-context'), findsOneWidget);

    // 首次进入自动弹出使用说明(测试环境默认英文)。
    expect(find.text('How it works'), findsOneWidget);
    // 关闭弹窗即记为已读。
    await tester.tap(find.text('Got it'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    expect(find.text('How it works'), findsNothing);
    expect(prefs.getString('prompts.announcementShownHash'), isNotEmpty);

    // 已读后重新进入不再自动弹,帮助按钮仍可手动打开。
    router.pop();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    router.push('/settings/prompts');
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    expect(find.text('How it works'), findsNothing);
    await tester.tap(find.byTooltip('Help'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    expect(find.text('How it works'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    expect(tester.takeException(), isNull);
  });
}
