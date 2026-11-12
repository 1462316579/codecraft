import 'package:codecraft/agent/models/git_models.dart';
import 'package:codecraft/data/container/command_engine.dart';
import 'package:codecraft/data/git/container_git.dart';
import 'package:codecraft/data/git/git_runner.dart';
import 'package:codecraft/core/theme/git_colors.dart';
import 'package:codecraft/features/git/git_branches_tab.dart';
import 'package:codecraft/features/git/widgets/git_common.dart';
import 'package:codecraft/features/git/widgets/git_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('分支树', () {
    GitBranch branch(String name, {bool current = false, bool remote = false}) =>
        GitBranch(name: name, current: current, remote: remote);

    test('按 / 切分构建层级树,同层按段名字典序', () {
      final tree = buildBranchTree([
        branch('feature/login'),
        branch('main', current: true),
        branch('feature/ui/button'),
        branch('develop'),
      ]);
      expect(tree.map((node) => node.segment), ['develop', 'feature', 'main']);
      final feature = tree.firstWhere((node) => node.segment == 'feature');
      expect(feature.branch, isNull, reason: '中间段是虚拟文件夹');
      expect(feature.children.map((node) => node.segment), ['login', 'ui']);
      final ui = feature.children.firstWhere((node) => node.segment == 'ui');
      expect(ui.children.single.segment, 'button');
      expect(ui.children.single.branch!.name, 'feature/ui/button');
      expect(ui.children.single.fullPath, 'feature/ui/button');
      expect(ui.fullPath, 'feature/ui');
    });

    test('叶子节点承载原始分支(含 current 标记)', () {
      final tree = buildBranchTree([branch('main', current: true)]);
      expect(tree.single.branch!.current, isTrue);
      expect(tree.single.fullPath, 'main');
    });

    test('空列表返回空树', () {
      expect(buildBranchTree(const []), isEmpty);
    });
  });

  group('仓库选择显示名', () {
    test('工作区根只显示工作区名', () {
      expect(
        RepoPickerSheet.displayPath('/data/projects/default', '/data/projects/default'),
        'default',
      );
    });

    test('子目录显示为「工作区名/子目录」', () {
      expect(
        RepoPickerSheet.displayPath('/data/projects/default/git1', '/data/projects/default'),
        'default/git1',
      );
    });

    test('工作区路径带尾斜杠也能正确拼接', () {
      expect(
        RepoPickerSheet.displayPath('/data/projects/default/git1', '/data/projects/default/'),
        'default/git1',
      );
    });
  });

  group('状态码配色(对齐上游 GitStatusColors)', () {
    test('按首字符映射新增/修改/删除/重命名/未跟踪/冲突/类型变更', () {
      expect(GitStatusColors.background('A'), const Color(0xFF16A34A));
      expect(GitStatusColors.background('M'), const Color(0xFFD97706));
      expect(GitStatusColors.background('D'), const Color(0xFFDC2626));
      expect(GitStatusColors.background('R'), const Color(0xFF2563EB));
      expect(GitStatusColors.background('C'), const Color(0xFF2563EB));
      expect(GitStatusColors.background('?'), const Color(0xFF94A3B8));
      expect(GitStatusColors.background('U'), const Color(0xFF9333EA));
      expect(GitStatusColors.background('T'), const Color(0xFF0891B2));
      expect(GitStatusColors.background('X'), const Color(0xFF64748B));
      expect(GitStatusColors.background(''), const Color(0xFF64748B));
    });

    test('前景色按背景亮度自适应(阈值 0.45,对齐上游 luminance())', () {
      // 浅灰背景(相对亮度约 0.65)用深色字,保证对比度。
      expect(GitStatusColors.foreground(const Color(0xFFCBD5E1)), const Color(0xFF0F172A));
      // 未跟踪灰与新增绿亮度都低于阈值,用白字。
      expect(GitStatusColors.foreground(const Color(0xFF94A3B8)), Colors.white);
      expect(GitStatusColors.foreground(const Color(0xFF16A34A)), Colors.white);
    });
  });

  group('状态码徽标', () {
    testWidgets('只显示前两个字符', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Center(child: StatusChip(code: 'MM'))),
      ));
      expect(find.text('MM'), findsOneWidget);
    });

    testWidgets('未跟踪显示 ??', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Center(child: StatusChip(code: '??'))),
      ));
      expect(find.text('??'), findsOneWidget);
    });
  });

  group('命令层(假引擎)', () {
    test('isRepository 依据 rev-parse 退出码判定', () async {
      final engine = _FakeEngine(exitCode: 0, output: 'true');
      final git = ContainerGit(GitRunner(() async => engine));
      expect(await git.isRepository('/repo'), isTrue);

      final failing = ContainerGit(GitRunner(() async => _FakeEngine(exitCode: 128)));
      expect(await failing.isRepository('/repo'), isFalse);
    });

    test('hasRemote 依据 remote 输出是否为空判定', () async {
      final withRemote = ContainerGit(
        GitRunner(() async => _FakeEngine(output: 'origin\n')),
      );
      expect(await withRemote.hasRemote('/repo'), isTrue);

      final withoutRemote = ContainerGit(GitRunner(() async => _FakeEngine(output: '  \n')));
      expect(await withoutRemote.hasRemote('/repo'), isFalse);
    });
  });
}

class _FakeEngine implements CommandEngine {
  _FakeEngine({this.output = '', this.exitCode = 0});

  final String output;
  final int exitCode;

  @override
  Future<CommandResult> runCommandSync(
    String command, {
    String? workdir,
    Duration timeout = const Duration(seconds: 120),
  }) async =>
      CommandResult(output: output, exitCode: exitCode);

  @override
  Future<bool> isReady() async => true;

  @override
  Future<String?> notReadyHint() async => null;

  @override
  Future<TerminalProcess> openTerminal({String? command, int cols = 80, int rows = 24, String? workdir}) =>
      throw UnimplementedError();

  @override
  Stream<Object> runCommandStream(
    String command, {
    String? workdir,
    Duration timeout = const Duration(seconds: 120),
  }) =>
      const Stream.empty();
}