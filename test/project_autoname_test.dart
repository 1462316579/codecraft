import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:codecraft/agent/models/chat_session.dart';
import 'package:codecraft/agent/models/project.dart';
import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/app/app.dart';
import 'package:codecraft/app/permissions_gate.dart';
import 'package:codecraft/data/db/app_database.dart';
import 'package:codecraft/data/db/daos.dart';
import 'package:codecraft/data/novel_project.dart';
import 'package:codecraft/data/settings/app_settings.dart';
import 'package:codecraft/features/home/projects_page.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 新建编程项目按类型自动命名;新建写作(小说)项目走新建小说向导,
/// 填书名后建项目并在写作工作区下生成小说目录结构。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  open.overrideFor(OperatingSystem.linux, () => ffi.DynamicLibrary.open('libsqlite3.so.0'));
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late AppDatabase db;

  setUp(() async {
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
          workspaceProvider.overrideWithValue(Workspace('/tmp/codecraft-autoname')),
        ],
        child: const CodecraftApp(),
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
  }

  /// 点右上角加号 → 在弹出菜单里选一种项目类型。
  Future<void> createProject(WidgetTester tester, String kindLabel) async {
    final l10n = AppLocalizations.of(tester.element(find.byType(ProjectsPage)));
    await tester.tap(find.byTooltip(l10n.projectNew));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    await tester.tap(find.text(kindLabel).last);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
  }

  testWidgets('新建编程项目不弹输入框,自动命名', (tester) async {
    await pumpApp(tester);
    final l10n = AppLocalizations.of(tester.element(find.byType(ProjectsPage)));

    await createProject(tester, l10n.projectKindCoding);

    expect(find.byType(AlertDialog), findsNothing, reason: '不该再要求输入项目名');
    final projects = await db.projectDao.list();
    expect(projects, hasLength(1));
    expect(projects.single.name, '${l10n.projectKindCoding} 1');
    expect(projects.single.kind, ProjectKind.coding);
  });

  testWidgets('写作项目走新建小说向导:书名即项目名,并生成小说目录结构', (tester) async {
    // 把「主存储根」指到临时目录,验证脚手架真的落在 AI小说/<书名>/ 下。
    final storage = Directory.systemTemp.createTempSync('novel-create');
    addTearDown(() {
      if (storage.existsSync()) storage.deleteSync(recursive: true);
    });
    const channel = MethodChannel('com.codecraft.flutter/external_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'primaryRoot') return storage.path;
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await pumpApp(tester);
    final l10n = AppLocalizations.of(tester.element(find.byType(ProjectsPage)));

    await createProject(tester, l10n.projectKindWriting);

    // 弹出新建小说向导,而不是自动命名。
    expect(find.text(l10n.novelNew), findsOneWidget, reason: '写作项目应弹出新建小说向导');
    expect(find.text('写作 1'), findsNothing, reason: '不再自动命名「写作 1」');

    await tester.enterText(find.byType(TextField).first, '星辰变');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.novelCreate));
    // 创建流程里有真实目录 IO 与数据库写入:await 续体跑在 FakeAsync 里要靠 pump 推进,
    // 真实 IO 完成要靠 runAsync 里的真实延时让事件循环转动——两者交替直到项目落库
    // (file_tree_tab_test 的 settle 同款约定;回调必须含真实 Future.delayed,
    // 否则同步 sqlite 不会让 real event loop 转动,目录 IO 永远完不成)。
    for (var i = 0; i < 200; i++) {
      final created = await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return db.projectDao.list();
      });
      if ((created ?? const []).isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 10));
    }
    await tester.pumpAndSettle();


    final projects = await db.projectDao.list();
    expect(projects, hasLength(1));
    expect(projects.single.name, '星辰变');
    expect(projects.single.kind, ProjectKind.writing);
    expect(projects.single.mode, AgentMode.write);

    // 目录结构:AI小说/<书名>/{角色关联,小说资料/五个空文件,小说章节}
    final novelDir = Directory('${storage.path}/AI小说/星辰变');
    expect(Directory('${novelDir.path}/角色关联').existsSync(), isTrue);
    expect(Directory('${novelDir.path}/小说章节').existsSync(), isTrue);
    for (final file in NovelScaffold.materialFiles) {
      final target = File('${novelDir.path}/小说资料/$file');
      expect(target.existsSync(), isTrue, reason: '$file 应为空文件');
      expect(target.readAsStringSync(), isEmpty);
    }
  });

  testWidgets('同类型重名时序号递增', (tester) async {
    await pumpApp(tester);
    final l10n = AppLocalizations.of(tester.element(find.byType(ProjectsPage)));
    final base = l10n.projectKindCoding;

    await createProject(tester, base);
    // 新建后进入聊天页(独立路由),返回项目列表再建第二个。
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    await createProject(tester, base);

    final names = [for (final p in await db.projectDao.list()) p.name];
    expect(names, containsAll(['$base 1', '$base 2']), reason: '同名时序号递增,避免两条同名项目');
  });
}
