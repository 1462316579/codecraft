import 'dart:ffi' as ffi;

import 'package:codecraft/app/permissions_gate.dart';
import 'package:codecraft/agent/models/chat_session.dart';
import 'package:codecraft/agent/models/project.dart';
import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/app/app.dart';
import 'package:codecraft/data/db/app_database.dart';
import 'package:codecraft/data/db/daos.dart';
import 'package:codecraft/data/settings/app_settings.dart';
import 'package:codecraft/features/chat/widgets/chat_header.dart';
import 'package:codecraft/features/home/projects_page.dart';
import 'package:codecraft/features/sessions/sessions_drawer.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../core/icons/iconfont.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 项目与会话分层后的行为:项目决定模式与工具集,会话只是项目内的对话。
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

  /// 播下一个项目及其首条会话(新结构:项目与会话是两层)。
  Future<void> seedProject(
    String projectId,
    String name, {
    AgentMode mode = AgentMode.build,
    ProjectKind kind = ProjectKind.coding,
    String? sessionId,
  }) async {
    await db.projectDao.upsert(
      Project(
        id: projectId,
        name: name,
        createdAt: 1,
        updatedAt: 5,
        mode: mode,
        kind: kind,
      ),
    );
    await db.sessionDao.upsert(
      ChatSession(
        id: sessionId ?? '$projectId-s1',
        title: name,
        createdAt: 1,
        updatedAt: 5,
        mode: mode,
        projectId: projectId,
      ),
    );
  }

  /// 启动应用并点进指定项目(项目列表 → 点项目行)。
  Future<void> openProject(WidgetTester tester, String name) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
          workspaceProvider.overrideWithValue(Workspace('/tmp/codecraft-mode-test')),
        ],
        child: const CodecraftApp(),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    await tester.tap(find.text(name).first);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
  }

  /// 确保侧栏可见(宽屏常驻;窄屏从抽屉拉开)。
  Future<void> openDrawer(WidgetTester tester) async {
    final drawer = find.byType(SessionsDrawer);
    if (drawer.evaluate().isEmpty) {
      await tester.tap(find.byIcon(Icons.menu).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Finder headerIcon(IconData icon) => find.descendant(
        of: find.byType(ChatHeader),
        matching: find.byIcon(icon),
      );

  testWidgets('编程项目:顶栏有 Git 与终端入口', (tester) async {
    await seedProject('p-code-1', '编程项目');
    await openProject(tester, '编程项目');

    expect(find.byType(ChatHeader), findsOneWidget);
    expect(headerIcon(Iconfont.gitBranch), findsOneWidget, reason: '编程项目应有 Git 入口');
    expect(headerIcon(Iconfont.terminal), findsOneWidget, reason: '编程项目应有终端入口');
  });

  testWidgets('写作项目:顶栏没有 Git 与终端入口', (tester) async {
    await seedProject('p-write-1', '写作项目', mode: AgentMode.write);
    await openProject(tester, '写作项目');

    expect(find.byType(ChatHeader), findsOneWidget);
    expect(headerIcon(Iconfont.gitBranch), findsNothing, reason: '写作项目不该有 Git 入口');
    expect(headerIcon(Iconfont.terminal), findsNothing, reason: '写作项目不该有终端入口');
  });

  testWidgets('逆向项目:顶栏没有 Git(终端保留)', (tester) async {
    await seedProject('p-rev-1', '逆向项目', kind: ProjectKind.reverse);
    await openProject(tester, '逆向项目');

    expect(find.byType(ChatHeader), findsOneWidget);
    expect(headerIcon(Iconfont.gitBranch), findsNothing, reason: '逆向项目不该有 Git 入口');
    expect(headerIcon(Iconfont.terminal), findsOneWidget, reason: '终端仍可用于看 APK 内容');
  });

  testWidgets('逆向项目:侧栏没有浏览器与 Codespaces', (tester) async {
    await seedProject('p-rev-2', '逆向项目', kind: ProjectKind.reverse);
    await openProject(tester, '逆向项目');
    await openDrawer(tester);

    final l10n = AppLocalizations.of(tester.element(find.byType(SessionsDrawer)));
    final drawer = find.byType(SessionsDrawer);
    expect(
      find.descendant(of: drawer, matching: find.text(l10n.browserTitle)),
      findsNothing,
      reason: '逆向项目不需要浏览器',
    );
    expect(
      find.descendant(of: drawer, matching: find.text(l10n.codespacesTitle)),
      findsNothing,
      reason: '逆向项目不需要 Codespaces',
    );
  });

  testWidgets('侧栏只列当前项目的会话,其它项目的会话不出现', (tester) async {
    await seedProject('p-code-3', '代码项目');
    await seedProject('p-write-3', '写作项目', mode: AgentMode.write);
    // 额外给代码项目加一条会话,验证它们同属一个项目。
    await db.sessionDao.upsert(
      const ChatSession(
        id: 'p-code-3-s2',
        title: '代码项目的第二条会话',
        createdAt: 2,
        updatedAt: 6,
        projectId: 'p-code-3',
      ),
    );

    await openProject(tester, '代码项目');
    await openDrawer(tester);

    final drawer = find.byType(SessionsDrawer);
    expect(
      find.descendant(of: drawer, matching: find.text('代码项目的第二条会话')),
      findsWidgets,
      reason: '同项目下的会话都应出现在侧栏',
    );
    expect(
      find.descendant(of: drawer, matching: find.text('写作项目')),
      findsNothing,
      reason: '别的项目的会话不该出现在本项目的侧栏',
    );
  });

  testWidgets('聊天页加号只建会话,不建项目', (tester) async {
    await seedProject('p-write-4', '写作项目', mode: AgentMode.write);
    await openProject(tester, '写作项目');
    final projectsBefore = await db.projectDao.list();

    await tester.tap(
      find.descendant(of: find.byType(ChatHeader), matching: find.byIcon(Icons.add)),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    // 项目数量不变——加号不产生项目。
    expect(await db.projectDao.list(), hasLength(projectsBefore.length));

    final sessions = await db.sessionDao.list();
    expect(sessions, hasLength(2), reason: '应新开一个会话');
    final created = sessions.firstWhere((s) => s.id != 'p-write-4-s1');
    expect(created.projectId, 'p-write-4', reason: '新会话应归属当前项目');
    expect(created.mode, AgentMode.write, reason: '新会话沿用项目的写作模式');
  });

  testWidgets('项目页加号新建的是项目,且带走一条初始会话', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
          workspaceProvider.overrideWithValue(Workspace('/tmp/codecraft-mode-test')),
        ],
        child: const CodecraftApp(),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    await tester.tap(find.byIcon(Icons.plus).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // 文案随系统语言变化,按 l10n 键定位而不是写死中文。
    final l10n = AppLocalizations.of(tester.element(find.byType(ProjectsPage)));
    await tester.tap(find.text(l10n.projectKindCoding).first);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    final projects = await db.projectDao.list();
    expect(projects, hasLength(1), reason: '项目页加号建项目');
    expect(projects.first.name, '${l10n.projectKindCoding} 1', reason: '编程项目按类型自动命名');
    final sessions = await db.sessionDao.list();
    expect(sessions, hasLength(1), reason: '新项目带一条初始会话');
    expect(sessions.first.projectId, projects.first.id);
  });

  testWidgets('写作项目的侧栏没有浏览器与 Codespaces', (tester) async {
    await seedProject('p-write-5', '写作项目', mode: AgentMode.write);
    await openProject(tester, '写作项目');
    await openDrawer(tester);

    final drawer = find.byType(SessionsDrawer);
    expect(
      find.descendant(of: drawer, matching: find.byIcon(Icons.public)),
      findsNothing,
      reason: '写作项目的侧栏不该有浏览器入口',
    );
    expect(
      find.descendant(of: drawer, matching: find.byIcon(Iconfont.cloud)),
      findsNothing,
      reason: '写作项目的侧栏不该有 Codespaces 入口',
    );
  });

  testWidgets('编程项目的侧栏保留浏览器与 Codespaces', (tester) async {
    await seedProject('p-code-5', '代码项目');
    await openProject(tester, '代码项目');
    await openDrawer(tester);

    final drawer = find.byType(SessionsDrawer);
    expect(
      find.descendant(of: drawer, matching: find.byIcon(Icons.public)),
      findsWidgets,
      reason: '编程项目的侧栏应保留浏览器入口',
    );
    expect(
      find.descendant(of: drawer, matching: find.byIcon(Iconfont.cloud)),
      findsWidgets,
      reason: '编程项目的侧栏应保留 Codespaces 入口',
    );
  });
}