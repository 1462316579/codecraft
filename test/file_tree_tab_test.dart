import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:codecraft/agent/models/chat_session.dart';
import 'package:codecraft/agent/models/project.dart';
import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/app/current_project.dart';
import 'package:codecraft/app/shell.dart';
import 'package:codecraft/core/theme/app_theme.dart';
import 'package:codecraft/data/settings/app_settings.dart';
import 'package:codecraft/data/editor_target.dart';
import 'package:codecraft/data/workbench.dart';
import 'package:codecraft/data/workspaces.dart';
import 'package:codecraft/features/sessions/file_tree_tab.dart';
import 'package:codecraft/features/sessions/file_type_icon.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 侧边栏「文件」Tab:真实临时目录 + 真实 IO(用 runAsync 推进事件循环)。
void main() {
  late Directory root;
  late Directory current;

  setUp(() {
    root = Directory.systemTemp.createTempSync('file-tree');
    // workspacesProvider 在 <sandbox>/projects/default 下建工作区。
    current = Directory('${root.path}/projects/default')..createSync(recursive: true);
    Directory('${current.path}/lib').createSync();
    File('${current.path}/README.md').writeAsStringSync('# hello');
    File('${current.path}/lib/main.dart').writeAsStringSync('void main() {}');
    File('${current.path}/app.log').writeAsStringSync('log');
    File('${current.path}/.gitignore').writeAsStringSync('*.log\n');
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  /// post-frame 里发起的真实目录 IO 必须在 runAsync 中推进,否则 FakeAsync 下永不完成。
  Future<void> settle(WidgetTester tester) async {
    // listDir 内部是 `await for` 流 + 逐个 stat(),需要多轮「推进事件循环 + 重建帧」
    // 才能让嵌套的目录读取全部落地(FakeAsync 下这些 Future 不会自己完成)。
    // 文件多一个就多一轮 stat await(加上 .gitignore 读取),轮数给足。
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
  }

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    List<Override> extraOverrides = const [],
  }) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
        workspaceProvider.overrideWithValue(Workspace(root.path)),
        ...extraOverrides,
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(workspacesProvider.future));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // 树很高时 ListView 懒加载会截断后面的行:给足高度让全部条目都在视口内。
          home: const Scaffold(
            body: SizedBox(width: 400, height: 1200, child: FileTreeTab()),
          ),
        ),
      ),
    );
    await settle(tester);
    return container;
  }

  group('写作项目的工作区', () {
    testWidgets('树根是 AI小说 目录,不是沙盒里的 default', (tester) async {
      // 写作项目的工作区在外部存储根下;这里把「主存储根」指到临时目录,
      // 就能在不碰真机路径的前提下验证目录与显示名。
      final storage = Directory.systemTemp.createTempSync('ext-storage');
      addTearDown(() {
        if (storage.existsSync()) storage.deleteSync(recursive: true);
      });
      final novel = Directory('${storage.path}/AI小说')..createSync(recursive: true);
      File('${novel.path}/第一章.md').writeAsStringSync('正文');

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

      await pump(
        tester,
        extraOverrides: [currentAgentModeProvider.overrideWithValue(AgentMode.write)],
      );

      expect(find.text('AI小说'), findsOneWidget, reason: '写作项目的树根应是 AI小说');
      expect(find.text('default'), findsNothing, reason: '写作项目不该落到沙盒目录');

      await tester.tap(find.text('AI小说'));
      await settle(tester);
      expect(find.text('第一章.md'), findsOneWidget, reason: '应列出 AI小说 里的文件');
    });
  });

  group('新建文件', () {
    testWidgets('写作项目里新建文件不崩溃,文件真的建出来', (tester) async {
      // 回归:早先输入框的控制器在 showDialog 返回后立刻释放,此时弹窗还在
      // 退场、输入框仍在拆除,会抛「A TextEditingController was used after
      // being disposed」,并连带把 `_dependents.isEmpty` 断言带崩(整屏报错)。
      final storage = Directory.systemTemp.createTempSync('ext-storage');
      addTearDown(() {
        if (storage.existsSync()) storage.deleteSync(recursive: true);
      });
      final novel = Directory('${storage.path}/AI小说')..createSync(recursive: true);

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

      await pump(
        tester,
        extraOverrides: [currentAgentModeProvider.overrideWithValue(AgentMode.write)],
      );
      await tester.tap(find.text('AI小说'));
      await settle(tester);

      await tester.longPress(find.text('AI小说'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('新建文件'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField).first, '第一章');
      await tester.pump();
      await tester.tap(find.text('创建'));
      await settle(tester);

      expect(tester.takeException(), isNull, reason: '不该抛 disposed controller 或 _dependents 断言');
      expect(File('${novel.path}/第一章').existsSync(), isTrue);
      // 弹窗还在退场动画里,它的输入框也会匹配到这段文字,所以只断言存在。
      expect(find.text('第一章'), findsWidgets, reason: '新建的文件应出现在树里');
    });

    testWidgets('名字带路径分隔符时不予提交', (tester) async {
      await pump(tester);
      await tester.tap(find.text('default'));
      await settle(tester);

      await tester.longPress(find.text('default'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('新建文件'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField).first, 'a/b');
      await tester.pump();
      await tester.tap(find.text('创建'));
      await settle(tester);

      // 弹窗应当仍在(没被提交),且没有写到上级目录。
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(File('${current.path}/a/b').existsSync(), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('取消新建时不创建文件', (tester) async {
      await pump(tester);
      await tester.tap(find.text('default'));
      await settle(tester);

      await tester.longPress(find.text('default'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('新建文件'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField).first, '不该存在');
      await tester.pump();
      await tester.tap(find.text('取消'));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(File('${current.path}/不该存在').existsSync(), isFalse);
    });
  });

  group('文件类型图标', () {
    test('按扩展名区分代码/脚本/文本/图片/压缩包/数据库', () {
      expect(fileTypeIconFor('main.dart'), LucideIcons.code);
      expect(fileTypeIconFor('run.sh'), LucideIcons.terminal);
      expect(fileTypeIconFor('README.md'), LucideIcons.fileText);
      expect(fileTypeIconFor('logo.png'), LucideIcons.image);
      expect(fileTypeIconFor('pkg.zip'), LucideIcons.package);
      expect(fileTypeIconFor('app.db'), LucideIcons.database);
      expect(fileTypeIconFor('unknown.xyz'), LucideIcons.file);
    });

    test('无后缀特殊文件名', () {
      expect(fileTypeIconFor('Dockerfile'), LucideIcons.terminal);
      expect(fileTypeIconFor('.gitignore'), LucideIcons.fileText);
      expect(fileTypeIconFor('.env'), LucideIcons.fileText);
      expect(fileTypeIconFor('.env.local'), LucideIcons.fileText);
    });
  });

  group('双根节点', () {
    testWidgets('只渲染一个工作区根,默认不展开', (tester) async {
      await pump(tester);
      // 根显示名取工作区名(测试里是 default)。根节点始终展开(远程目标首屏可见子文件)。
      expect(find.text('default'), findsOneWidget);
      expect(find.text('lib'), findsOneWidget, reason: '根节点现在始终展开');
      expect(find.text('内置 Ubuntu'), findsNothing, reason: '不再有容器根节点');
      expect(tester.takeException(), isNull);
    });

    testWidgets('展开工作区根后显示子项,点目录再展开', (tester) async {
      await pump(tester);
      await tester.tap(find.text('default'));
      await settle(tester);
      expect(find.text('lib'), findsOneWidget);
      expect(find.text('README.md'), findsOneWidget);

      await tester.tap(find.text('lib'));
      await settle(tester);
      expect(find.text('main.dart'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('折叠父目录时连同已展开的子目录一起收掉', (tester) async {
      await pump(tester);
      await tester.tap(find.text('default'));
      await settle(tester);
      await tester.tap(find.text('lib'));
      await settle(tester);
      expect(find.text('main.dart'), findsOneWidget);

      // 根节点固定展开(不提供折叠),折叠行为用「折叠 lib 后子树收起」验证。
      await tester.tap(find.text('lib'));
      await settle(tester);
      expect(find.text('main.dart'), findsNothing, reason: '折叠 lib 应把子树收掉');
      await tester.tap(find.text('lib'));
      await settle(tester);
      expect(find.text('main.dart'), findsOneWidget);
    });
  });

  group('压缩包解压', () {
    /// 用 archive 包在临时目录里现场构造 zip(不依赖系统 zip 命令)。
    Uint8List buildZip(Map<String, List<int>> files) {
      final encoder = ZipEncoder();
      final archive = Archive();
      files.forEach((name, bytes) {
        archive.addFile(ArchiveFile.bytes(name, bytes));
      });
      return encoder.encodeBytes(archive);
    }

    testWidgets('长按 zip 出现解压菜单,解压后出现同名目录', (tester) async {
      File('${current.path}/bundle.zip').writeAsBytesSync(buildZip({
        'a.txt': utf8.encode('hello'),
        'inner/b.txt': utf8.encode('world'),
      }));

      await pump(tester);
      expect(find.text('bundle.zip'), findsOneWidget);

      await tester.longPress(find.text('bundle.zip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('解压'), findsOneWidget, reason: 'zip 应出现「解压」菜单项');

      await tester.tap(find.text('解压'));
      await settle(tester);

      expect(find.text('bundle'), findsOneWidget, reason: '解压后应出现同名目录');
      expect(Directory('${current.path}/bundle').existsSync(), isTrue);
      expect(File('${current.path}/bundle/a.txt').readAsStringSync(), 'hello');
      expect(File('${current.path}/bundle/inner/b.txt').readAsStringSync(), 'world');
      expect(tester.takeException(), isNull);
    });

    testWidgets('目标已存在时先确认覆盖,取消则不动旧目录', (tester) async {
      File('${current.path}/data.zip').writeAsBytesSync(buildZip({
        'new.txt': utf8.encode('new'),
      }));
      // 预先放一个同名目录,里面有个旧文件。
      Directory('${current.path}/data').createSync();
      File('${current.path}/data/old.txt').writeAsStringSync('old');

      await pump(tester);
      await tester.longPress(find.text('data.zip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('解压'));
      // 存在性探测是真 IO,得先推进;确认框弹出动需要额外 pump 动画帧。
      await settle(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 弹出覆盖确认,点取消。
      expect(find.text('目标文件夹已存在'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await settle(tester);
      expect(File('${current.path}/data/old.txt').existsSync(), isTrue,
          reason: '取消覆盖时旧目录应保持不变');
      expect(File('${current.path}/data/new.txt').existsSync(), isFalse);
    });

    testWidgets('不支持的格式(7z)不显示解压菜单', (tester) async {
      File('${current.path}/thing.7z').writeAsBytesSync([1, 2, 3]);

      await pump(tester);
      await tester.longPress(find.text('thing.7z'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('解压'), findsNothing, reason: '7z 不在支持列表,不该有解压入口');
    });
  });

  group('忽略态与点文件', () {
    testWidgets('.gitignore 命中的文件用橙色弱化', (tester) async {
      await pump(tester);
      await tester.tap(find.text('default'));
      await settle(tester);

      final text = tester.widget<Text>(find.text('app.log'));
      expect(text.style?.color, const Color(0xFFD97706));
    });

    testWidgets('点开头文件弱化,但仍显示', (tester) async {
      await pump(tester);
      await tester.tap(find.text('default'));
      await settle(tester);

      final text = tester.widget<Text>(find.text('.gitignore'));
      final color = text.style?.color;
      expect(color, isNotNull);
      expect(color!.a, lessThan(1.0), reason: '点开头文件用半透明弱化');
    });
  });

  group('文件操作', () {
    testWidgets('点文件把目标交给编辑器并开右栏,不再只读预览', (tester) async {
      // 宽屏走右栏分支:不涉及路由跳转,能在没有 GoRouter 的测试树里验证。
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final container = await pump(tester);
      await tester.tap(find.text('default'));
      await settle(tester);
      await tester.tap(find.text('README.md'));
      await settle(tester);

      expect(
        container.read(editorTargetProvider)?.path,
        '${current.path}/README.md',
        reason: '点文件应该把路径交给编辑器',
      );
      expect(
        container.read(workbenchProvider).kind,
        WorkbenchPaneKind.editor,
        reason: '宽屏应该开工作台右栏',
      );
      expect(find.text('hello'), findsNothing, reason: '不再弹出只读预览');
      expect(tester.takeException(), isNull);
    });

    testWidgets('复制后在另一目录粘贴,出现副本', (tester) async {
      await pump(tester);
      await tester.tap(find.text('default'));
      await settle(tester);

      // 复制 README.md
      await tester.longPress(find.text('README.md'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('复制'));
      await settle(tester);

      // 粘到 lib 目录
      await tester.longPress(find.text('lib'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('粘贴到此处'));
      await settle(tester);

      expect(File('${current.path}/lib/README.md').existsSync(), isTrue);
      expect(File('${current.path}/README.md').existsSync(), isTrue,
          reason: '复制不应删除源');
    });

    testWidgets('剪切后粘贴,源消失', (tester) async {
      await pump(tester);
      await tester.tap(find.text('default'));
      await settle(tester);

      await tester.longPress(find.text('README.md'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('剪切'));
      await settle(tester);

      await tester.longPress(find.text('lib'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('粘贴到此处'));
      await settle(tester);

      expect(File('${current.path}/lib/README.md').existsSync(), isTrue);
      expect(File('${current.path}/README.md').existsSync(), isFalse,
          reason: '剪切后源应被移走');
    });
  });

  group('应用逆向项目', () {
    testWidgets('文件面板展示 APK 内的文件:先提示解压,解压后列出条目', (tester) async {
      const channel = MethodChannel('com.codecraft.flutter/apk_files');
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method != 'extract') return null;
        final dir = Directory(call.arguments['destDir'] as String)..createSync(recursive: true);
        Directory('${dir.path}/res').createSync();
        File('${dir.path}/AndroidManifest.xml').writeAsStringSync('<manifest/>');
        File('${dir.path}/res/layout.xml').writeAsStringSync('<x/>');
        return 2;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      final project = Project(
        id: 'p1',
        name: '栗子漫画',
        createdAt: 0,
        updatedAt: 0,
        kind: ProjectKind.reverse,
        appApkPath: '/data/app/~~hash/com.hbsclj.uth-1/base.apk',
      );
      await pump(tester, extraOverrides: [currentProjectProvider.overrideWithValue(project)]);

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
      expect(find.text(l10n.apkExtractHint), findsOneWidget, reason: '首次浏览先提示解压');
      expect(find.text('AndroidManifest.xml'), findsNothing);
      expect(find.text('default'), findsNothing, reason: '逆向项目不显示工作区目录');

      await tester.tap(find.text(l10n.apkExtractAction));
      await settle(tester);

      expect(find.text('APK'), findsOneWidget, reason: '树根显示为 APK');
      await tester.tap(find.text('APK'));
      await settle(tester);
      expect(find.text('AndroidManifest.xml'), findsOneWidget, reason: '应列出 APK 内的文件');
      expect(find.text('res'), findsOneWidget);
    });

    testWidgets('拿不到安装包路径时给出提示,不退化成工作区', (tester) async {
      final project = Project(
        id: 'p2',
        name: '无路径应用',
        createdAt: 0,
        updatedAt: 0,
        kind: ProjectKind.reverse,
      );
      await pump(tester, extraOverrides: [currentProjectProvider.overrideWithValue(project)]);

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
      expect(find.text(l10n.apkPathUnavailable), findsOneWidget);
      expect(find.text('default'), findsNothing);
    });
  });
}
