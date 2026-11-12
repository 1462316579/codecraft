import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/data/container/command_engine.dart';
import 'package:codecraft/data/git/container_git.dart';
import 'package:codecraft/data/git/git_runner.dart';
import 'package:codecraft/data/settings/app_settings.dart';
import 'package:codecraft/features/git/git_page.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 按命令特征返回不同 git 输出的假引擎,让整页在真实控制器驱动下渲染。
class _ScriptedEngine implements CommandEngine {
  @override
  Future<CommandResult> runCommandSync(
    String command, {
    String? workdir,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    if (command.contains('MERGE_HEAD')) {
      return const CommandResult(output: '', exitCode: 1);
    }
    if (command.contains('rev-parse')) {
      return const CommandResult(output: 'true', exitCode: 0);
    }
    if (command.contains('status')) {
      return const CommandResult(
        output: '## feature/foo...origin/feature/foo [ahead 2, behind 1]\n'
            ' M src/Main.kt\n'
            'A  src/New.kt\n'
            '?? untracked/\n'
            '?? loose.txt',
        exitCode: 0,
      );
    }
    if (command.contains('for-each-ref')) {
      return const CommandResult(
        output: 'feature/foo\u001fh1\u001f*\u001frefs/heads/feature/foo\u001forigin/feature/foo\u001f[ahead 2, behind 1]\n'
            'main\u001fh2\u001f\u001frefs/heads/main\u001f\u001f\n'
            'origin/main\u001fh2\u001f\u001frefs/remotes/origin/main\u001f\u001f\n'
            'v1.0\u001fh2\u001f\u001frefs/tags/v1.0\u001f\u001f',
        exitCode: 0,
      );
    }
    if (command.contains('remote')) {
      return const CommandResult(output: 'origin\n', exitCode: 0);
    }
    if (command.contains('config')) {
      return const CommandResult(output: 'Alice\n', exitCode: 0);
    }
    if (command.contains('log')) {
      return const CommandResult(
        output: 'h1\u001fh1short\u001fAlice\u001f2 days ago\u001ffeat: 第一条\u001f\u001f\n'
            'h2\u001fh2short\u001fBob\u001f3 days ago\u001ffix: 第二条\u001fh1\u001f正文',
        exitCode: 0,
      );
    }
    return const CommandResult(output: '', exitCode: 0);
  }

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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpGitPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          workspaceProvider.overrideWithValue(Workspace('/workspace')),
          containerGitProvider.overrideWithValue(
            ContainerGit(GitRunner(() async => _ScriptedEngine())),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const GitPage(),
        ),
      ),
    );
    // 控制器在 initState 里异步刷新,多泵几帧让状态落定。
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('仓库态渲染顶栏、概览与三格统计', (tester) async {
    await pumpGitPage(tester);

    expect(find.text('Git'), findsOneWidget);
    expect(find.text('工作区有改动'), findsOneWidget);
    expect(find.text('feature/foo'), findsWidgets);
    expect(find.text('已暂存'), findsOneWidget);
    expect(find.text('已修改'), findsOneWidget);
    expect(find.text('未跟踪'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('状态页列出已暂存/已修改/未跟踪三组', (tester) async {
    await pumpGitPage(tester);

    // 行内按「文件名 + 目录」两行显示,不是完整路径。
    expect(find.text('Main.kt'), findsOneWidget);
    expect(find.text('New.kt'), findsOneWidget);
    expect(find.text('loose.txt'), findsOneWidget);
    expect(find.text('untracked/'), findsOneWidget);
    expect(find.text('已暂存 (1)'), findsOneWidget);
    expect(find.text('已修改 (1)'), findsOneWidget);
    expect(find.text('未跟踪 (2)'), findsOneWidget);
  });

  testWidgets('底部悬浮标签栏在三页之间切换', (tester) async {
    await pumpGitPage(tester);

    expect(find.text('状态'), findsOneWidget);
    expect(find.text('分支'), findsOneWidget);
    expect(find.text('提交'), findsOneWidget);

    await tester.tap(find.text('分支'));
    await tester.pumpAndSettle();
    expect(find.text('HEAD'), findsOneWidget);
    expect(find.text('当前分支'), findsOneWidget);

    await tester.tap(find.text('提交'));
    await tester.pumpAndSettle();
    // PageView 三页常驻,切页后当前页内容应在视口内。
    expect(find.text('提交记录 (2)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('提交页显示泳道、短哈希与引用胶囊', (tester) async {
    await pumpGitPage(tester);

    await tester.tap(find.text('提交'));
    await tester.pumpAndSettle();

    expect(find.text('feat: 第一条'), findsOneWidget);
    expect(find.text('h1short'), findsOneWidget);
    expect(find.text('Alice'), findsWidgets);
    expect(find.text('没有更多了'), findsOneWidget);
  });
}