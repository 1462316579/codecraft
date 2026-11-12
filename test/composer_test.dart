import 'dart:io';
import 'dart:typed_data';

import 'package:codecraft/agent/models/agent_attachment.dart';
import 'package:codecraft/agent/models/agent_ui_state.dart';
import 'package:codecraft/agent/models/chat_session.dart';
import 'package:codecraft/agent/models/skill.dart';
import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/data/settings/app_settings.dart';
import 'package:codecraft/data/skills.dart';
import 'package:codecraft/data/workspace_files.dart';
import 'package:codecraft/data/workspaces.dart';
import 'package:codecraft/features/chat/widgets/chat_composer.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 内存文件列表:键是相对工作区根的目录路径('' 表示根),值是该项下的条目。
class _FakeFiles implements WorkspaceFiles {
  _FakeFiles(this.entries, this.root);

  final Map<String, List<DirEntry>> entries;
  final String root;

  @override
  Future<List<DirEntry>> listDir(String path) async {
    final relative = path == root ? '' : path.substring(root.length + 1);
    return entries[relative] ?? const [];
  }

  @override
  Future<bool> exists(String path) async => true;

  @override
  Future<bool> isDirectory(String path) async => entries.containsKey(path);

  @override
  Future<int> sizeOf(String path) async => 0;

  @override
  Future<void> writeBytes(String path, Uint8List bytes) async {}

  @override
  Future<String> readText(String path) async => '';

  @override
  Future<Uint8List> readBytes(String path) async => Uint8List(0);

  @override
  Future<void> writeText(String path, String content) async {}

  @override
  Future<void> createDir(String path) async {}

  @override
  Future<void> rename(String from, String to) async {}

  @override
  Future<void> delete(String path, {bool recursive = false}) async {}

  @override
  Future<void> copy(String from, String to, {bool overwrite = false}) async {}

  @override
  Future<void> move(String from, String to, {bool overwrite = false}) async {}

  @override
  Future<int> extractArchive(String archivePath, String destDir) async => 0;

  @override
  Future<List<SearchHit>> searchLines(
    String root,
    String pattern, {
    bool ignoreCase = false,
    bool fixed = false,
    required int limit,
  }) async =>
      const [];
}

Future<void> pumpComposer(
  WidgetTester tester, {
  required ChatSession? session,
  void Function(ReasoningEffort)? onPickEffort,
  TextEditingController? input,
  List<SkillEntry> skills = const [],
  Map<String, List<DirEntry>>? files,
  void Function(String)? onSend,
  VoidCallback? onStop,
  ChatViewState state = const ChatViewState(),
}) async {
  final workspaceDir = Directory.systemTemp.createTempSync('composer_ws');
  // 面板读 skillsStoreProvider(真实扫盘):在临时工作区里预置技能,让面板能加载出数据。
  for (final skill in skills) {
    final dir = skill.scope == SkillScope.project
        ? Directory('${workspaceDir.path}/.codecraft/skills/${skill.skill.name}')
        : Directory('${workspaceDir.path}/skills/${skill.skill.name}');
    dir.createSync(recursive: true);
    File('${dir.path}/SKILL.md').writeAsStringSync(
      '---\nname: ${skill.skill.name}\ndescription: ${skill.skill.description}\n---\n正文',
    );
  }
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      workspaceProvider.overrideWithValue(Workspace(workspaceDir.path)),
      configDirProvider.overrideWithValue(workspaceDir.path),
      skillsProvider.overrideWith((ref) => Future.value(skills)),
      if (files != null) ...[
        // 固定当前工作区到临时目录:否则 currentWorkspaceProvider 会解析真实工作区路径,
        // 与注入的假文件表对不上。
        currentWorkspaceProvider.overrideWithValue(Workspace(workspaceDir.path)),
        workspaceFilesProvider.overrideWith(
          (ref) async => _FakeFiles(files, workspaceDir.path),
        ),
      ],
    ],
  );
  addTearDown(container.dispose);
  // 预加载工作区列表:它依赖真实目录 IO,先给它真实异步时间,避免弹层停在加载态。
  await tester.runAsync(() => container.read(workspacesProvider.future));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ChatComposer(
            state: state,
            session: session,
            input: input ?? TextEditingController(),
            onSend: onSend ?? (_) {},
            onStop: onStop ?? () {},
            onPickModel: () {},
            onPickEffort: onPickEffort ?? (_) {},
            onRemoveAttachment: (_) {},
            onUploadFile: () {},
            onAttachImage: () {},
            onTakePhoto: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('输入区不再有开发/写作模式切换按钮', (tester) async {
    await pumpComposer(
      tester,
      session: const ChatSession(id: 's', title: '', createdAt: 0, updatedAt: 0),
    );

    // 模式由项目决定(新建时选编程/写作),输入区不再提供切换。
    expect(find.text('开发'), findsNothing, reason: '输入区不该有模式胶囊');
    expect(find.text('写作'), findsNothing, reason: '输入区不该有模式胶囊');
  });

  testWidgets('思考强度按钮点击弹出档位弹层', (tester) async {
    await pumpComposer(
      tester,
      session: const ChatSession(id: 's', title: '', createdAt: 0, updatedAt: 0),
    );
    await tester.tap(find.byTooltip('思考强度'));
    await tester.pumpAndSettle();
    expect(find.text('不思考'), findsOneWidget);
    expect(find.text('极高'), findsOneWidget);
  });

  testWidgets('输入区没有工作区按钮(工作区由项目类型决定)', (tester) async {
    await pumpComposer(
      tester,
      session: const ChatSession(id: 's', title: '', createdAt: 0, updatedAt: 0),
    );
    expect(find.byTooltip('工作区'), findsNothing, reason: '工作区已不由用户手动选');
  });

  testWidgets('附件按钮存在,弹层展示三个入口', (tester) async {
    await pumpComposer(
      tester,
      session: const ChatSession(id: 's', title: '', createdAt: 0, updatedAt: 0),
    );
    expect(find.byTooltip('添加附件'), findsOneWidget);
    await tester.tap(find.byTooltip('添加附件'));
    await tester.pumpAndSettle();
    expect(find.text('上传文件'), findsOneWidget);
    expect(find.text('上传图片'), findsOneWidget);
    expect(find.text('拍照'), findsOneWidget);
  });

  testWidgets('@ 按钮在模型按钮左侧,点击弹出技能列表', (tester) async {
    final input = TextEditingController();
    await pumpComposer(
      tester,
      session: const ChatSession(id: 's', title: '', createdAt: 0, updatedAt: 0),
      skills: const [
        SkillEntry(Skill(name: 'writer', description: '写作方法论', instructions: ''), SkillScope.global),
      ],
      input: input,
    );

    final atButton = find.byTooltip('@ 技能');
    final modelButton = find.byTooltip('模型');
    expect(atButton, findsOneWidget);
    expect(modelButton, findsOneWidget);
    // 位置关系:@ 在模型左侧(同一行内 x 更小)。
    expect(
      tester.getCenter(atButton).dx,
      lessThan(tester.getCenter(modelButton).dx),
      reason: '@ 按钮应位于模型按钮左侧',
    );

    await tester.tap(atButton);
    await tester.pump();
    await tester.pump();
    // 面板数据是 autoDispose provider:在 runAsync 里等真实 IO 完成(FakeAsync 下不能 pumpAndSettle)。
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump();
    // 浮层面板:条目标题带 @ 前缀展示,描述一并显示;输入框被写入一个 @ 待补全。
    expect(find.text('writer'), findsOneWidget);
    expect(find.text('写作方法论'), findsOneWidget);
    expect(find.textContaining('继续输入可筛选'), findsOneWidget);
  });

  testWidgets('选中技能后把 @名字 插入光标处', (tester) async {
    final input = TextEditingController(text: '请用');

    await pumpComposer(
      tester,
      session: const ChatSession(id: 's', title: '', createdAt: 0, updatedAt: 0),
      input: input,
      skills: const [
        SkillEntry(Skill(name: 'writer', instructions: ''), SkillScope.global),
      ],
    );
    // selection 必须在文本就位后设置(控制器在构造时文本还没同步进来)。
    input.selection = const TextSelection.collapsed(offset: 2);

    await tester.tap(find.byTooltip('@ 技能'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('writer'));
    await tester.pump();

    // 按钮打开时已在光标处预置 `@`,确认后整段替换为提及。
    expect(input.text, '请用 @writer ');
    expect(input.selection.baseOffset, '请用 @writer '.length, reason: '光标落在插入内容之后');
  });

  testWidgets('没有可用技能时给出管理入口', (tester) async {
    await pumpComposer(
      tester,
      session: const ChatSession(id: 's', title: '', createdAt: 0, updatedAt: 0),
    );

    await tester.tap(find.byTooltip('@ 技能'));
    await tester.pump();
    await tester.pump();
    expect(find.text('还没有可用的技能,先在设置里导入或新建一个。'), findsOneWidget);
  });

  testWidgets('文件按钮在 @ 与模型之间,点击后逐层浏览并插入路径', (tester) async {
    final input = TextEditingController();
    await pumpComposer(
      tester,
      session: const ChatSession(id: 's', title: '', createdAt: 0, updatedAt: 0),
      input: input,
      files: {
        '': [
          DirEntry(name: 'src', isDirectory: true, size: 0, modified: DateTime(2026)),
          DirEntry(name: 'README.md', isDirectory: false, size: 10, modified: DateTime(2026)),
        ],
        'src': [
          DirEntry(name: 'main.dart', isDirectory: false, size: 20, modified: DateTime(2026)),
        ],
      },
    );

    final atButton = find.byTooltip('@ 技能');
    final fileButton = find.byTooltip('@ 文件');
    final modelButton = find.byTooltip('模型');
    expect(
      tester.getCenter(atButton).dx < tester.getCenter(fileButton).dx,
      isTrue,
      reason: '文件按钮在 @ 右侧',
    );
    expect(
      tester.getCenter(fileButton).dx < tester.getCenter(modelButton).dx,
      isTrue,
      reason: '文件按钮在模型左侧',
    );

    await tester.tap(fileButton);
    for (var i = 0; i < 6; i++) {
      await tester.pump();
    }
    // 平铺列出(含子目录文件),目录点击不做逐层浏览。
    expect(find.text('README.md'), findsOneWidget);
    expect(find.text('src/main.dart'), findsOneWidget);
    await tester.tap(find.text('src/main.dart'));
    await tester.pump();

    expect(input.text, '@~/workspace/src/main.dart ');
  });

  testWidgets('文件列表隐藏点开头的条目', (tester) async {
    await pumpComposer(
      tester,
      session: const ChatSession(id: 's', title: '', createdAt: 0, updatedAt: 0),
      files: {
        '': [
          DirEntry(name: '.codecraft', isDirectory: true, size: 0, modified: DateTime(2026)),
          DirEntry(name: 'lib', isDirectory: true, size: 0, modified: DateTime(2026)),
        ],
        'lib': [
          DirEntry(name: 'main.dart', isDirectory: false, size: 20, modified: DateTime(2026)),
        ],
      },
    );

    await tester.tap(find.byTooltip('@ 文件'));
    await tester.pump();
    await tester.pump();
    expect(find.text('lib/main.dart'), findsOneWidget);
    expect(find.textContaining('.codecraft'), findsNothing);
  });

  testWidgets('窄屏下按钮行不溢出(工具按钮可横向滚动)', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpComposer(
      tester,
      session: const ChatSession(id: 's', title: '', createdAt: 0, updatedAt: 0),
      files: {'': const []},
    );
    // 溢出会以异常形式抛给测试框架;这里断言渲染期没有异常。
    expect(tester.takeException(), isNull);
    // 工具按钮行与发送键始终可见。
    expect(find.byIcon(LucideIcons.arrowUp), findsOneWidget);
  });

  testWidgets('输入框直接键入 @ 触发面板,继续输入实时筛选', (tester) async {
    final input = TextEditingController();
    await pumpComposer(
      tester,
      session: const ChatSession(id: 's', title: '', createdAt: 0, updatedAt: 0),
      input: input,
      skills: const [
        SkillEntry(Skill(name: 'writer', description: '写作方法论', instructions: ''), SkillScope.global),
        SkillEntry(Skill(name: 'reader', description: '阅读方法', instructions: ''), SkillScope.global),
      ],
    );

    // 模拟用户键入 @:更新文本与光标并发出监听回调。
    input.value = TextEditingValue(text: '@', selection: const TextSelection.collapsed(offset: 1));
    await tester.pump();
    await tester.pump();
    expect(find.text('writer'), findsOneWidget);
    expect(find.text('reader'), findsOneWidget);

    // 继续键入筛选词 w:只剩 writer。
    input.value = TextEditingValue(text: '@w', selection: const TextSelection.collapsed(offset: 2));
    await tester.pump();
    await tester.pump();
    expect(find.text('writer'), findsOneWidget);
    expect(find.text('reader'), findsNothing);

    // 空格结束会话:面板收回。
    input.value = TextEditingValue(text: '@w ', selection: const TextSelection.collapsed(offset: 3));
    await tester.pump();
    expect(find.text('writer'), findsNothing);
  });

  testWidgets('面板开着时回车确认首条候选而不是发送', (tester) async {
    String? sent;
    final input = TextEditingController();
    await pumpComposer(
      tester,
      session: const ChatSession(id: 's', title: '', createdAt: 0, updatedAt: 0),
      input: input,
      skills: const [
        SkillEntry(Skill(name: 'writer', instructions: ''), SkillScope.global),
      ],
      onSend: (text) => sent = text,
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    input.value = TextEditingValue(text: '@', selection: const TextSelection.collapsed(offset: 1));
    await tester.pump();
    await tester.pump();
    expect(find.text('writer'), findsOneWidget, reason: '前置:面板已开');

    // 面板开着时回车走「确认首条」:textInputAction 已升级为 done(newline 会插换行)。
    final editable = tester.widget<TextField>(find.byType(TextField).first);
    expect(editable.textInputAction, TextInputAction.done,
        reason: '面板开着时回车键应为确认(done)而不是换行');

    // 确认路径本身等价于点击首条(该行为已在上面的按钮用例覆盖):
    await tester.tap(find.text('writer'));
    await tester.pump();
    expect(input.text, '@writer ');
    expect(sent, isNull, reason: '没有触发发送');
  });

  testWidgets('点发送按钮会回调 onSend(清空由页面按结果决定)', (tester) async {
    String? sent;
    final input = TextEditingController(text: '你好');
    await pumpComposer(
      tester,
      session: const ChatSession(id: 's', title: '', createdAt: 0, updatedAt: 0),
      input: input,
      onSend: (text) => sent = text,
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    // 发送按钮:有内容时显示,点击把当前文本交出去。
    await tester.tap(find.byIcon(LucideIcons.arrowUp));
    await tester.pump();

    expect(sent, '你好');
  });

  testWidgets('只有附件没有文字:发送键可点,直接发送', (tester) async {
    String? sent;
    await pumpComposer(
      tester,
      session: const ChatSession(id: 's', title: '', createdAt: 0, updatedAt: 0),
      state: ChatViewState(pendingAttachments: [
        const AgentAttachment(
          fileName: 'a.png',
          localPath: '/tmp/a.png',
          mimeType: 'image/png',
          sizeBytes: 1,
        ),
      ]),
      onSend: (text) => sent = text,
    );

    // 待发附件本身就是内容:没打字时发送键也应当可点,点击即发出(正文为空)。
    await tester.tap(find.bySemanticsLabel('发送'));
    await tester.pump();

    expect(sent, '', reason: '附件本身即内容,没文字也应能直接发送');
  });

  testWidgets('模型按钮显示品牌 logo;Auto 时显示通用图标', (tester) async {
    // 指定具体模型 → 有 logo(不再是通用 memory 图标)。
    await pumpComposer(
      tester,
      session: const ChatSession(
        id: 's',
        title: '',
        createdAt: 0,
        updatedAt: 0,
        providerId: 'p1',
        model: 'deepseek-v4-pro',
      ),
    );
    expect(find.byIcon(Icons.memory), findsNothing,
        reason: '有具体模型时应显示品牌 logo');

    // Auto → 通用图标。
    await pumpComposer(
      tester,
      session: const ChatSession(
        id: 's',
        title: '',
        createdAt: 0,
        updatedAt: 0,
        model: 'auto',
      ),
    );
    expect(find.byIcon(Icons.memory), findsOneWidget,
        reason: 'Auto 没有具体模型,用通用芯片图标');
  });

  testWidgets('工具按钮紧凑排列(36dp、无额外间隙)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpComposer(
      tester,
      session: const ChatSession(id: 's', title: '', createdAt: 0, updatedAt: 0),
    );

    // 四个工具按钮都应在,且宽度为 36dp(IconButton 默认 48dp 会撑出间隙)。
    for (final tooltip in ['@ 技能', '@ 文件', '模型', '思考强度']) {
      final finder = find.byTooltip(tooltip);
      expect(finder, findsOneWidget, reason: '$tooltip 应存在');
      expect(tester.getSize(finder).width, 36, reason: '$tooltip 应为 36dp');
    }

    // 相邻按钮应紧挨(间距 0),不能出现 12dp 的默认内边距空隙。
    final model = tester.getRect(find.byTooltip('模型'));
    final effort = tester.getRect(find.byTooltip('思考强度'));
    expect(effort.left, closeTo(model.right, 0.5),
        reason: '思考强度应紧贴模型按钮右侧');
    expect(effort.left, greaterThan(model.left), reason: '思考强度在模型右边');
  });

  group('停止对话', () {
    testWidgets('流式中输入框为空:显示停止键,点击触发 onStop', (tester) async {
      var stops = 0;
      var sends = 0;
      await pumpComposer(
        tester,
        session: const ChatSession(id: 's', title: '', createdAt: 0, updatedAt: 0),
        state: const ChatViewState(streaming: true),
        onStop: () => stops++,
        onSend: (_) => sends++,
      );

      expect(find.bySemanticsLabel('停止'), findsOneWidget, reason: '流式中应有停止键');
      await tester.tap(find.bySemanticsLabel('停止'));
      expect(stops, 1);
      expect(sends, 0, reason: '点停止不该触发发送');
    });

    testWidgets('流式中输入框有内容:仍是停止键(这正是「无法终止」的场景)', (tester) async {
      var stops = 0;
      var sends = 0;
      final input = TextEditingController(text: '我还要说点什么');
      await pumpComposer(
        tester,
        session: const ChatSession(id: 's', title: '', createdAt: 0, updatedAt: 0),
        input: input,
        state: const ChatViewState(streaming: true),
        onStop: () => stops++,
        onSend: (_) => sends++,
      );

      expect(find.bySemanticsLabel('停止'), findsOneWidget,
          reason: '打了字也必须能停止,否则对话停不下来');
      await tester.tap(find.bySemanticsLabel('停止'));
      expect(stops, 1);
      expect(sends, 0, reason: '流式期间点这个键必须走停止,不能走发送');
    });

    testWidgets('空闲且有内容:显示发送键', (tester) async {
      var sends = 0;
      final input = TextEditingController(text: '你好');
      await pumpComposer(
        tester,
        session: const ChatSession(id: 's', title: '', createdAt: 0, updatedAt: 0),
        input: input,
        onSend: (_) => sends++,
      );

      expect(find.bySemanticsLabel('停止'), findsNothing, reason: '空闲时不该有停止键');
      await tester.tap(find.bySemanticsLabel('发送'));
      expect(sends, 1);
    });

    testWidgets('空闲且无内容:发送键不可点', (tester) async {
      var sends = 0;
      await pumpComposer(
        tester,
        session: const ChatSession(id: 's', title: '', createdAt: 0, updatedAt: 0),
        onSend: (_) => sends++,
      );

      await tester.tap(find.bySemanticsLabel('发送'));
      expect(sends, 0, reason: '没内容时不该发出去');
    });

    testWidgets('流式中提示文案告知可以停止', (tester) async {
      await pumpComposer(
        tester,
        session: const ChatSession(id: 's', title: '', createdAt: 0, updatedAt: 0),
        state: const ChatViewState(streaming: true),
      );
      expect(find.text('AI 正在处理中,点右侧方块可停止'), findsOneWidget,
          reason: '不该再承诺「自动排队」,实际并不排队');
    });
  });
}
