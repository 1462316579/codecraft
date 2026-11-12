import 'dart:io';

import 'package:codecraft/agent/models/chat_session.dart';
import 'package:codecraft/agent/permissions/shell_parser.dart';
import 'package:codecraft/agent/permissions/tool_permission_engine.dart';
import 'package:codecraft/agent/tools/command_tools.dart';
import 'package:codecraft/data/container/command_engine.dart';
import 'package:codecraft/data/permissions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory configDir;
  late Directory workspace;
  late PermissionRulesRepository repository;
  late ToolPermissionEngine engine;
  late BashTool bash;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('shell_config');
    workspace = Directory.systemTemp.createTempSync('shell_ws');
    repository = PermissionRulesRepository(
      globalFile: File(p.join(configDir.path, 'permissions.json')),
      workspaceRoot: workspace.path,
    );
    engine = ToolPermissionEngine(repository);
    bash = BashTool(engine: () => Future<CommandEngine>.error('评测不执行命令'));
  });

  tearDown(() {
    configDir.deleteSync(recursive: true);
    workspace.deleteSync(recursive: true);
  });

  Future<PermissionEval> evaluateShell(
    String command, {
    AgentMode mode = AgentMode.build,
    ToolPermissionEngine? customEngine,
    bool elevate = false,
  }) =>
      (customEngine ?? engine).evaluate(
        tool: bash,
        toolName: bash.name,
        mode: mode,
        args: {
          'command': command,
          if (elevate) 'elevate': true,
        },
      );

  group('ShellCommandParser', () {
    test('引号内的分隔符不拆段,引号外拆段', () {
      final quoted = ShellCommandParser.analyze("echo 'a && b | c'");
      expect(quoted.segments, [
        ['echo', 'a && b | c'],
      ]);
      expect(quoted.analyzable, isTrue);

      final split = ShellCommandParser.analyze('ls -la && cat notes.txt | head -5');
      expect(split.segments, [
        ['ls', '-la'],
        ['cat', 'notes.txt'],
        ['head', '-5'],
      ]);
    });

    test('命令替换、子 shell、反引号与未闭合引号 → 不可静态判定', () {
      expect(ShellCommandParser.analyze('echo \$(date)').analyzable, isFalse);
      expect(ShellCommandParser.analyze('echo `date`').analyzable, isFalse);
      expect(ShellCommandParser.analyze('(cd a && ls)').analyzable, isFalse);
      expect(ShellCommandParser.analyze('echo "it\'s').analyzable, isFalse);
    });

    test('单引号内的反引号不触发不可判定,双引号内触发', () {
      expect(ShellCommandParser.analyze("echo 'code: `x`'").analyzable, isTrue);
      expect(ShellCommandParser.analyze('echo "code: `x`"').analyzable, isFalse);
    });

    test('输出重定向到绝对路径 → 不可判定;相对路径与输入重定向不触发', () {
      expect(ShellCommandParser.analyze('echo hi > /etc/passwd').analyzable, isFalse);
      expect(ShellCommandParser.analyze('echo hi >> out.txt').analyzable, isTrue);
      expect(ShellCommandParser.analyze('wc -l < notes.txt').analyzable, isTrue);
    });

    test('段首环境赋值被跳过,程序名取首个有效 token', () {
      final analysis = ShellCommandParser.analyze('FOO=1 BAR=2 git status');
      expect(analysis.segments, [
        ['FOO=1', 'BAR=2', 'git', 'status'],
      ]);
      expect(ShellCommandParser.effectiveTokens(analysis.segments.first), ['git', 'status']);
      expect(ShellCommandParser.programPrefix(analysis.segments.first), 'git');
    });

    test('记忆前缀:分发器带子命令、普通程序仅程序名、rm 带目标', () {
      expect(
        ShellCommandParser.rememberablePrefix(['git', 'pull', 'origin', 'main']),
        'git pull',
      );
      expect(ShellCommandParser.rememberablePrefix(['npm', 'run', 'build']), 'npm run');
      expect(
        ShellCommandParser.rememberablePrefix(['npm', '--version']),
        'npm',
        reason: '子命令紧跟 flag 时退化为程序名',
      );
      expect(ShellCommandParser.rememberablePrefix(['cat', 'a.txt']), 'cat');
      expect(ShellCommandParser.rememberablePrefix(['rm', 'tmp.txt']), 'rm tmp.txt');
      expect(
        ShellCommandParser.rememberablePrefix(['rm', '-rf', 'build']),
        isNull,
        reason: '递归删除不可记忆',
      );
      expect(ShellCommandParser.rememberablePrefix(['rm', '*.log']), isNull);
    });

    test('内置安全清单只放行只读命令', () {
      expect(BuiltInSafeCommands.isSafe(['ls', '-la']), isTrue);
      expect(BuiltInSafeCommands.isSafe(['git', 'status']), isTrue);
      expect(BuiltInSafeCommands.isSafe(['git', 'config', '--get', 'user.name']), isTrue);
      expect(BuiltInSafeCommands.isSafe(['git', 'push']), isFalse);
      expect(BuiltInSafeCommands.isSafe(['rm', '-rf', 'x']), isFalse);
      expect(BuiltInSafeCommands.isSafe(['node', 'script.js']), isFalse);
      expect(BuiltInSafeCommands.isSafe(['sed', '-i', 's/a/b/', 'f']), isFalse);
      expect(BuiltInSafeCommands.isSafe(['/usr/bin/ls']), isFalse,
          reason: '按字面首 token 匹配:绝对路径不会被规则命中(宁可多问)');
    });
  });

  group('Bash 工具判定(dev 模式)', () {
    test('内置安全命令 → 直接放行', () async {
      for (final command in ['ls -la', 'git status', 'cat README.md | head -20']) {
        final eval = await evaluateShell(command);
        expect(eval.verdict, PermissionVerdict.allow, reason: command);
      }
    });

    test('未命中白名单 → 询问并可记忆命令前缀', () async {
      final eval = await evaluateShell('git pull origin main && npm install');
      expect(eval.verdict, PermissionVerdict.ask);
      expect(eval.rememberablePatterns, containsAll(['git pull', 'npm install']));
    });

    test('混合命令中任一段不可放行即询问', () async {
      final eval = await evaluateShell('ls && ./scripts/build.sh');
      expect(eval.verdict, PermissionVerdict.ask);
      expect(eval.rememberablePatterns, contains('./scripts/build.sh'));
    });

    test('不可静态判定 → 询问且不可记忆', () async {
      final eval = await evaluateShell('echo \$(date)');
      expect(eval.verdict, PermissionVerdict.ask);
      expect(eval.rememberablePatterns, isEmpty);
      expect(eval.rememberDisabledReason, ToolPermissionEngine.shellUnrememberableReason);
    });

    test('已记忆的 ALLOW 前缀命中即放行', () async {
      await repository.add(
        PermissionScope.project,
        const PermissionRule(toolName: 'Bash', pattern: 'git pull'),
      );
      final eval = await evaluateShell('git pull --rebase origin main');
      expect(eval.verdict, PermissionVerdict.allow);
    });

    test('DENY 规则优先于内置安全清单', () async {
      await repository.add(
        PermissionScope.project,
        const PermissionRule(
          toolName: 'Bash',
          pattern: 'cat',
          decision: PermissionDecision.deny,
        ),
      );
      final eval = await evaluateShell('cat secrets.txt');
      expect(eval.verdict, PermissionVerdict.deny);
    });

    test('rm 递归/通配 → 询问但不可记忆', () async {
      final eval = await evaluateShell('rm -rf build');
      expect(eval.verdict, PermissionVerdict.ask);
      expect(eval.rememberablePatterns, isEmpty);
      expect(eval.rememberDisabledReason, ToolPermissionEngine.rmUnrememberableReason);
    });

    test('灾难性删除 → 拒绝,并提示提权重试', () async {
      for (final command in ['rm -rf /', 'rm -rf /etc', 'rm -rf ~', 'rm -rf *']) {
        final eval = await evaluateShell(command);
        expect(eval.verdict, PermissionVerdict.deny, reason: command);
        expect(eval.denyReason, contains('elevate'), reason: command);
      }
    });

    test('工作区内的删除属正常操作,走普通询问', () async {
      final eval = await evaluateShell('rm -rf /root/workspace/build');
      expect(eval.verdict, PermissionVerdict.ask);
    });

    test('携带 elevate 的灾难性删除 → 降级为一次性提权确认', () async {
      final eval = await evaluateShell('rm -rf /etc', elevate: true);
      expect(eval.verdict, PermissionVerdict.ask);
      expect(eval.askTitle, ToolPermissionEngine.elevateAskTitle);
      expect(eval.rememberablePatterns, isEmpty);
    });
  });
}
