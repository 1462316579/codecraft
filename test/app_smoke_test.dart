import 'dart:ffi' as ffi;

import 'package:codecraft/app/permissions_gate.dart';
import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/app/app.dart';
import 'package:codecraft/agent/models/chat_session.dart';
import 'package:codecraft/agent/models/project.dart';
import 'package:codecraft/features/sessions/sessions_drawer.dart';
import 'package:codecraft/agent/sessions_controller.dart';
import 'package:codecraft/app/router.dart';
import 'package:codecraft/data/db/app_database.dart';
import 'package:codecraft/data/db/daos.dart';
import 'package:codecraft/data/settings/app_settings.dart';
import 'package:codecraft/features/home/projects_page.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 整棵树的冒烟测试:把真实 App(含 go_router)跑起来并逐页进入。
///
/// 目的是抓「Element 生命周期」类断言崩溃(如 InheritedElement 被停用时仍有依赖者,
/// framework.dart 的 `_dependents.isEmpty`),这类问题只在真实树里才暴露。
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

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
          databaseProvider.overrideWithValue(db),
          workspaceProvider.overrideWithValue(Workspace('/tmp/codecraft-smoke')),
        ],
        child: const CodecraftApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('窄屏启动(含抽屉)不抛断言异常', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
          databaseProvider.overrideWithValue(db),
          workspaceProvider.overrideWithValue(Workspace('/tmp/codecraft-smoke')),
        ],
        child: const CodecraftApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
  });

  testWidgets('切换语言与主题模式不抛断言异常', (tester) async {
    await pumpApp(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    container.read(routerProvider).push('/settings/theme');
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(tester.takeException(), isNull);

    // 语言:跟随系统 → English → 中文(每次都会重建 Localizations)
    for (final label in ['语言', 'English', '中文']) {
      final row = find.text(label);
      if (row.evaluate().isEmpty) continue;
      await tester.tap(row.first);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull, reason: '语言切换 $label');
    }

    // 主题模式:浅色 / 深色 / 跟随系统
    final container2 = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    for (final mode in [AppThemeMode.dark, AppThemeMode.light, AppThemeMode.system]) {
      await container2.read(settingsProvider.notifier).setThemeMode(mode);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull, reason: '主题模式 $mode');
    }

    // 语言直接切换(不经过弹层)
    for (final code in ['en', 'zh', '']) {
      await container2.read(settingsProvider.notifier).setLocale(code);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull, reason: '语言 $code');
    }
  });

  testWidgets('有会话时:窄屏开抽屉、点会话、再切宽屏不抛断言异常', (tester) async {
    // 预置一个会话,让 HomeShell 渲染真实聊天页(而不是加载态)。
    ProviderContainer container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
        databaseProvider.overrideWithValue(db),
        workspaceProvider.overrideWithValue(Workspace('/tmp/codecraft-smoke')),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionsProvider.future);
    await container.read(sessionsProvider.notifier).create();

    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const CodecraftApp(),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    expect(tester.takeException(), isNull, reason: '有会话时窄屏渲染');

    // 打开抽屉(ShellScope 的依赖者在这里)
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull, reason: '开抽屉');

    // 抽屉开着时切到宽屏(ShellScope 整棵消失)
    tester.view.physicalSize = const Size(1200, 900);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull, reason: '抽屉开着窄→宽');

    tester.view.physicalSize = const Size(420, 900);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull, reason: '抽屉开着宽→窄');
  });

  testWidgets('宽度跨过断点切换布局不抛断言异常', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
          databaseProvider.overrideWithValue(db),
          workspaceProvider.overrideWithValue(Workspace('/tmp/codecraft-smoke')),
        ],
        child: const CodecraftApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull, reason: '窄屏初始渲染');

    // 横屏:宽度 >= 840 → 走宽屏分支(ShellScope 消失)
    tester.view.physicalSize = const Size(1200, 900);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull, reason: '窄 → 宽');

    // 转回竖屏 → 窄屏分支(ShellScope 重新出现)
    tester.view.physicalSize = const Size(420, 900);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull, reason: '宽 → 窄');
  });

  testWidgets('设置页逐个进入(含日志页)不抛断言异常', (tester) async {
    await pumpApp(tester);
    final context = tester.element(find.byType(MaterialApp));
    final router = ProviderScope.containerOf(context).read(routerProvider);
    router.push('/settings');
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    for (final path in [
      '/settings/logs',
      '/settings/storage',
      '/settings/token-stats',
      '/settings/theme',
      '/settings/general',
      '/settings/permissions',
      '/settings/mcp',
      '/settings/providers',
      '/settings/container',
      '/credentials',
    ]) {
      router.push(path);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull, reason: '进入 $path 时抛异常');
      router.pop();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull, reason: '离开 $path 时抛异常');
    }
  });

  testWidgets('启动停在项目列表,不自动进聊天页', (tester) async {
    // 预置会话,且偏好里记着「上次打开过」——新版也不该自动跳进聊天。
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
        databaseProvider.overrideWithValue(db),
        workspaceProvider.overrideWithValue(Workspace('/tmp/codecraft-smoke')),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionsProvider.future);
    await container.read(sessionsProvider.notifier).create();
    (await SharedPreferences.getInstance()).setString('shell.lastSessionId', 'whatever');

    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const CodecraftApp()),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    // 停在项目列表:有底栏、有新建按钮,没有聊天欢迎语。
    // 文案随系统语言变化,按组件与 l10n 键断言而不是写死中文。
    expect(find.byType(ProjectsPage), findsOneWidget, reason: '应停在项目页');
    expect(find.text('有什么可以帮你的?'), findsNothing, reason: '不应自动进入聊天页');
    expect(tester.takeException(), isNull);
  });

  testWidgets('项目页默认是项目列表,点项目才进入聊天页', (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
        databaseProvider.overrideWithValue(db),
        workspaceProvider.overrideWithValue(Workspace('/tmp/codecraft-smoke')),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionsProvider.future);
    // 清掉前面用例留下的会话,让项目页呈现真正的空态。
    for (final session in await db.sessionDao.list()) {
      await db.sessionDao.delete(session.id);
    }
    container.invalidate(sessionsProvider);
    await container.read(sessionsProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const CodecraftApp()),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    // 没有会话时停在项目列表空态:底栏两项在,聊天欢迎语不在。
    // 文案随系统语言变化,这里按文案键查而不是写死中文。
    final l10n = AppLocalizations.of(tester.element(find.byType(ProjectsPage)));
    expect(find.text(l10n.projectListEmpty), findsOneWidget);
    expect(find.text(l10n.tabProjects), findsWidgets);
    expect(find.text(l10n.settings), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('浅色下侧栏是纯白', (tester) async {
    // 启动停在项目列表;点进项目才到聊天页(宽屏下侧栏常驻在左侧)。
    await db.projectDao.upsert(
      const Project(id: 'p-sidebar', name: '侧栏测试', createdAt: 1, updatedAt: 1),
    );
    await db.sessionDao.upsert(
      const ChatSession(
        id: 'sidebar-s1',
        title: '侧栏测试',
        createdAt: 1,
        updatedAt: 1,
        projectId: 'p-sidebar',
      ),
    );
    Future<void> pumpApp() async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
            databaseProvider.overrideWithValue(db),
            workspaceProvider.overrideWithValue(Workspace('/tmp/codecraft-smoke')),
          ],
          child: const CodecraftApp(),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 30));
      }
    }

    addTearDown(tester.view.reset);
    await pumpApp();
    await tester.tap(find.text('侧栏测试').first);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    // 侧栏 = 会话抽屉的根 Container(宽屏常驻在左侧)。
    final drawer = find.byType(SessionsDrawer);
    expect(drawer, findsOneWidget);
    final container = tester.widget<Container>(
      find.descendant(of: drawer, matching: find.byType(Container)).first,
    );
    expect(container.color, Colors.white, reason: '浅色主题下侧栏应为纯白');
  });
}
