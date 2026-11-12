import 'dart:convert';
import 'dart:io';

import 'package:codecraft/data/codespaces_engine.dart';
import 'package:codecraft/data/container/command_engine.dart';
import 'package:codecraft/data/execution_target.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 记录调用参数的假 transport:模拟本地容器这一层。
class _RecordingEngine extends CommandEngine {
  _RecordingEngine({
    this.ready = true,
    this.ghInstalled = true,
    this.result = const CommandResult(output: 'ok', exitCode: 0),
    this.interceptProbes = true,
  });

  bool ready;
  bool ghInstalled;
  CommandResult result;

  /// 是否拦截探测链命令(warmUp/CODESPACE_REPO_ROOT)返回预制结果;
  /// 关掉后探测命令也走通用 [result],用于模拟探测失败。
  bool interceptProbes;

  /// openTerminal 收到的 command 实参(用于断言转发形态)。
  String? terminalCommand;

  final List<String> commands = [];

  @override
  Future<bool> isReady() async => ready;

  @override
  Future<String?> notReadyHint() async => ready ? null : '容器尚未初始化';

  @override
  Future<CommandResult> runCommandSync(
    String command, {
    String? workdir,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    assert(workdir == null || workdir.isNotEmpty);
    commands.add(command);
    // 新版 isReady/hasGh 会同时探测 gh 与 ghHelper 可执行。
    if (command.contains('command -v gh') || command.contains('test -x')) {
      return CommandResult(output: ghInstalled ? '/usr/bin/gh\n' : '', exitCode: ghInstalled ? 0 : 1);
    }
    // 探测链模拟:warmUp 标记 + CODESPACE_REPO_ROOT,让 remoteRoot 解析出稳定根。
    if (interceptProbes) {
      if (command.contains('echo __codecraft_ok__')) {
        return const CommandResult(output: '__codecraft_ok__', exitCode: 0);
      }
      if (command.contains('CODESPACE_REPO_ROOT')) {
        return const CommandResult(output: '/workspaces/repo', exitCode: 0);
      }
    }
    return result;
  }

  @override
  Future<TerminalProcess> openTerminal({
    String? command,
    int cols = 80,
    int rows = 24,
    String? workdir,
  }) async {
    terminalCommand = command;
    return _NoopTerminal();
  }

  @override
  Stream<Object> runCommandStream(
    String command, {
    String? workdir,
    Duration timeout = const Duration(seconds: 120),
  }) =>
      const Stream.empty();
}

class _NoopTerminal implements TerminalProcess {
  @override
  Stream<List<int>> get output => const Stream.empty();

  @override
  Future<int> get exitCode => Future.value(0);

  @override
  void write(List<int> bytes) {}

  @override
  void resize(int cols, int rows) {}

  @override
  void kill() {}
}

/// 从转发命令里把 base64 载荷解出来,验证「远端真正执行的是原始命令」。
///
/// 不能直接找 `printf '%s' '<载荷>'`:整段内层脚本会被再包一层单引号,
/// 内部引号按 POSIX 规则转义成 `'\''`。base64 字符集不含引号/反斜杠,
/// 所以按「最长的 base64 串」定位是稳妥的;载荷可能被单引号或双引号包裹
/// (remoteCommand 用 "...",_remoteArgv 内层同样),两种都认。
String _decodePayload(String forwarded) {
  // 载荷可能被单引号或双引号包裹(remoteCommand 用 "...",_remoteArgv 内层同),
  // 两种都认,取最长的 base64 串。
  final sq = RegExp(r"'([A-Za-z0-9+/=]{4,})'").allMatches(forwarded);
  final dq = RegExp(r'"([A-Za-z0-9+/=]{4,})"').allMatches(forwarded);
  final base64Matches = [...sq, ...dq];
  expect(base64Matches, isNotEmpty, reason: '转发命令里应含 base64 载荷:$forwarded');
  final longest = base64Matches.reduce(
    (a, b) => (a.group(1)!.length >= b.group(1)!.length) ? a : b,
  );
  return utf8.decode(base64Decode(longest.group(1)!));
}

void main() {
  group('CodespacesEngine 命令转发', () {
    test('命令经 gh codespace ssh 转发,且远端执行的是原命令', () async {
      final transport = _RecordingEngine(result: const CommandResult(output: 'hi', exitCode: 0));
      final engine = CodespacesEngine(transport: transport, codespace: 'fluffy-parakeet-abc');

      final result = await engine.runCommandSync('ls -la "我的 目录"');

      expect(result.output, 'hi');
      final forwarded = transport.commands.single;
      // 经 ghHelper 包装(令牌注入),但转发主体仍是 codespace ssh。
      expect(forwarded, contains("codespace ssh -c 'fluffy-parakeet-abc' -- sh -c"));
      expect(_decodePayload(forwarded), 'ls -la "我的 目录"');
    });

    test('本地容器视角的 workdir 不透传给远端', () async {
      final transport = _RecordingEngine();
      await CodespacesEngine(transport: transport, codespace: 'cs')
          .runCommandSync('pwd', workdir: '/root/workspace');
      // workdir 会作为本地进程 cwd 传给 transport;转发命令本身不含该路径。
      // (探测链会额外发若干命令,它们同样不应泄漏本地路径。)
      expect(
        transport.commands.every((c) => !c.contains('/root/workspace')),
        isTrue,
        reason: transport.commands.join('\n'),
      );
    });

    test('Codespace 名带引号时不会破坏本地 shell 命令', () async {
      final transport = _RecordingEngine();
      await CodespacesEngine(transport: transport, codespace: "a'b")
          .runCommandSync('true');
      expect(transport.commands.single, contains(r"'a'\''b'"));
    });
  });

  group('完整转发链路(真实 sh + 假 gh 桩)', () {
    String fakePath(Directory dir) =>
        '${dir.path}:${Platform.environment['PATH'] ?? ''}';

    /// 假 gh:跳过 `codespace ssh -c NAME --`,其余参数在本机原样执行,
    /// 以此模拟「本地 sh → gh argv → 远端 sh」这条链,专测引号是否被破坏。
    Directory makeFakeGh() {
      final dir = Directory.systemTemp.createTempSync('fake-gh');
      addTearDown(() => dir.deleteSync(recursive: true));
      final gh = File('${dir.path}/gh')
        ..writeAsStringSync('#!/bin/sh\n'
            'while [ \$# -gt 0 ] && [ "\$1" != "--" ]; do shift; done\n'
            '[ "\$1" = "--" ] && shift\n'
            'exec "\$@"\n');
      Process.runSync('chmod', ['755', gh.path]);
      return dir;
    }

    test('带引号、变量与中文的命令在整条链路上保持不变', () async {
      final dir = makeFakeGh();
      final engine = CodespacesEngine(transport: _RecordingEngine(), codespace: 'cs', ghHelper: 'gh');
      final command = engine.remoteCommand(
        r'''printf '%s\n' "a'b" "中文 空格" "$((1+2))"''',
      );
      final result = await Process.run(
        'sh',
        ['-c', command],
        environment: {'PATH': fakePath(dir)},
      );
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(result.stdout.toString().trim().split('\n'), ["a'b", '中文 空格', '3']);
    });

    test('多行脚本也能完整送达远端', () async {
      final dir = makeFakeGh();
      final engine = CodespacesEngine(transport: _RecordingEngine(), codespace: 'cs', ghHelper: 'gh');
      final command = engine.remoteCommand('echo one\necho "two 2"');
      final result = await Process.run(
        'sh',
        ['-c', command],
        environment: {'PATH': fakePath(dir)},
      );
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(result.stdout.toString().trim().split('\n'), ['one', 'two 2']);
    });
  });

  group('CodespacesEngine 就绪判定与提示', () {
    test('warmUp 输出混入 banner/MOTD 杂质时不算连接失败', () async {
      // 旧版要求 trim 后严格等于 '1':gh 输出任何杂质都会误报「连接超时」。
      final transport = _RecordingEngine(
        result: const CommandResult(
          output: 'Welcome to Ubuntu 22.04\n__codecraft_ok__\n * Documentation: https://help.ubuntu.com',
          exitCode: 0,
        ),
      );
      final engine = CodespacesEngine(transport: transport, codespace: 'cs');
      // 不抛「连接 Codespace 超时」即为通过;根目录解析交给后续探测。
      await expectLater(engine.remoteRoot(), completion('/workspaces/repo'));
    });

    test('warmUp 失败时错误信息带诊断原文而非笼统超时', () async {
      final transport = _RecordingEngine(
        result: const CommandResult(output: 'gh: codespace not found', exitCode: 1),
        interceptProbes: false,
      );
      final engine = CodespacesEngine(transport: transport, codespace: 'nope');
      await expectLater(
        engine.remoteRoot(),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('codespace not found'),
        )),
      );
    });

    test('容器未就绪时 isReady 为假,并沿用容器的提示', () async {
      final transport = _RecordingEngine(ready: false);
      final engine = CodespacesEngine(transport: transport, codespace: 'cs');
      expect(await engine.isReady(), isFalse);
      expect(await engine.notReadyHint(), '容器尚未初始化');
    });

    test('容器就绪但缺 gh 时 isReady 为假,提示引导去环境安装', () async {
      final transport = _RecordingEngine(ghInstalled: false);
      final engine = CodespacesEngine(transport: transport, codespace: 'cs');
      expect(await engine.isReady(), isFalse);
      expect(await engine.notReadyHint(), CodespacesEngine.ghMissingHint);
    });

    test('容器与 gh 都就绪时 isReady 为真、无提示', () async {
      final engine = CodespacesEngine(transport: _RecordingEngine(), codespace: 'cs');
      expect(await engine.isReady(), isTrue);
      expect(await engine.notReadyHint(), isNull);
    });

    test('gh 不存在导致的失败输出被换成引导文案', () async {
      final transport = _RecordingEngine(
        result: const CommandResult(output: 'sh: gh: command not found', exitCode: 127),
      );
      final result = await CodespacesEngine(transport: transport, codespace: 'cs')
          .runCommandSync('ls');
      expect(result.output, CodespacesEngine.ghMissingHint);
      expect(result.exitCode, 127);
    });

    test('与 gh 无关的失败原样保留,便于诊断', () async {
      final transport = _RecordingEngine(
        result: const CommandResult(output: 'ls: cannot access x', exitCode: 2),
      );
      final result = await CodespacesEngine(transport: transport, codespace: 'cs')
          .runCommandSync('ls x');
      expect(result.output, 'ls: cannot access x');
    });
  });

  group('CodespacesEngine 终端会话', () {
    test('无命令时开远端交互 shell', () async {
      final transport = _RecordingEngine();
      await CodespacesEngine(transport: transport, codespace: 'cs-1').openTerminal();
      // 远端根探测会先走一轮;最终终端命令仍是 gh 转发的交互 shell。
      expect(transport.terminalCommand, contains("codespace ssh -c 'cs-1'"));
      expect(transport.terminalCommand, contains(r'exec $SHELL -i'));
    });

    test('带命令时命令同样经 base64 转到远端', () async {
      final transport = _RecordingEngine();
      await CodespacesEngine(transport: transport, codespace: 'cs-1')
          .openTerminal(command: r'echo $HOME');
      final command = transport.terminalCommand!;
      expect(command, contains("codespace ssh -c 'cs-1' -- "));
      expect(_decodePayload(command), r'echo $HOME');
    });
  });

  group('CodespacesEngine 流式执行', () {
    test('按行发出输出后给出退出事件', () async {
      final transport = _RecordingEngine(
        result: const CommandResult(output: 'a\nb\n', exitCode: 3),
      );
      final events = await CodespacesEngine(transport: transport, codespace: 'cs')
          .runCommandStream('x')
          .toList();
      expect(events.whereType<CommandLineEvent>().map((e) => e.text), ['a', 'b']);
      final exit = events.whereType<CommandExitEvent>().single;
      expect(exit.exitCode, 3);
    });
  });

  group('执行目标', () {
    test('默认本地,可切到 Codespace 再切回', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(executionTargetProvider.notifier);

      expect(container.read(executionTargetProvider), isA<LocalExecutionTarget>());
      expect(container.read(executionTargetProvider).isRemote, isFalse);

      notifier.useCodespace('cs-1', repository: 'octocat/Hello-World');
      final codespace = container.read(executionTargetProvider);
      expect(codespace, isA<CodespaceExecutionTarget>());
      expect(codespace.isRemote, isTrue);
      expect(codespace.label, 'octocat/Hello-World');

      notifier.useLocal();
      expect(container.read(executionTargetProvider), isA<LocalExecutionTarget>());
    });

    test('同一 Codespace 的目标相等,不同 Codespace 不等(切换监听据此判变更)', () {
      expect(
        const CodespaceExecutionTarget(name: 'cs', repository: 'a/b'),
        const CodespaceExecutionTarget(name: 'cs', repository: 'a/b'),
      );
      expect(
        const CodespaceExecutionTarget(name: 'cs') ==
            const CodespaceExecutionTarget(name: 'other'),
        isFalse,
      );
      expect(const LocalExecutionTarget(), const LocalExecutionTarget());
      expect(const LocalExecutionTarget() == const CodespaceExecutionTarget(name: 'cs'), isFalse);
    });
  });
}