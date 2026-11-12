import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:codecraft/app/permissions_gate.dart';
import 'package:codecraft/app/app.dart';
import 'package:codecraft/app/router.dart';
import 'package:codecraft/core/log/log_store.dart';
import 'package:codecraft/data/db/app_database.dart';
import 'package:codecraft/data/settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 日志页的导航冒烟:内容页是用 `MaterialPageRoute` 手动 push 的(go_router 之外的导航),
/// 这里覆盖「列表 → 内容页 → 返回」全流程,确认不会破坏 Element 树。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  open.overrideFor(OperatingSystem.linux, () => ffi.DynamicLibrary.open('libsqlite3.so.0'));
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late AppDatabase db;
  late Directory base;

  setUp(() async {
    // 跳过首次权限引导:本文件不验证它,弹窗会遮挡其它点击。
    SharedPreferences.setMockInitialValues({PermissionsGate.onboardedKey: true});
    db = await AppDatabase.open(inMemory: true);
    base = Directory.systemTemp.createTempSync('log-nav');
    final logs = Directory('${base.path}/logs')..createSync();
    File('${logs.path}/log-2026-10-25.txt').writeAsStringSync(
      '2026-10-25 10:00:00.000 INFO  App: 启动完成\n'
      '2026-10-25 10:00:01.000 ERROR Chat: 失败\n'
      '#0      main (package:x)\n',
    );
  });

  tearDown(() async {
    await db.close();
    if (base.existsSync()) base.deleteSync(recursive: true);
  });

  testWidgets('日志列表进入内容页再返回不抛异常', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
          databaseProvider.overrideWithValue(db),
          logBaseDirProvider.overrideWith((ref) async => base),
        ],
        child: const CodecraftApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    container.read(routerProvider).push('/settings/logs');
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(tester.takeException(), isNull, reason: '进入日志页');

    // 文件行 → 内容页
    expect(find.text('log-2026-10-25.txt'), findsOneWidget, reason: '列表里有该文件');
    await tester.tap(find.text('log-2026-10-25.txt'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(tester.takeException(), isNull, reason: '进入日志内容页');
    expect(find.text('log-2026-10-25.txt'), findsNWidgets(2),
        reason: '列表行 + 内容页标题');

    // 返回(两个路由的 AppBar 都在树里,pageBack 会因存在两个返回按钮而失败,
    // 这里直接弹掉栈顶路由)
    container.read(routerProvider).pop();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(tester.takeException(), isNull, reason: '从内容页返回');
  });
}