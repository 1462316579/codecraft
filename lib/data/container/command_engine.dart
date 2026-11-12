import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'bounded_output.dart';

/// 命令输出的一行(stdout/stderr 合并后的行)。
class CommandLineEvent {
  const CommandLineEvent(this.text);

  final String text;
}

/// 命令结束事件(退出码;超时被杀时为 -1 且 [timedOut] 为 true)。
class CommandExitEvent {
  const CommandExitEvent(this.exitCode, {this.timedOut = false});

  final int exitCode;
  final bool timedOut;
}

/// 一次非流式命令执行的结果。
class CommandResult {
  const CommandResult({
    required this.output,
    required this.exitCode,
    this.timedOut = false,
    this.truncated = false,
  });

  final String output;
  final int exitCode;
  final bool timedOut;

  /// 输出是否因过大被限幅(仅保留开头与结尾)。
  final bool truncated;

  bool get ok => exitCode == 0 && !timedOut;
}

/// 终端长驻会话:容器内交互式进程的字节流 + 输入通道。
abstract interface class TerminalProcess {
  /// 合并后的 stdout/stderr 字节流(PTY 输出含 ANSI 序列)。
  Stream<List<int>> get output;

  void write(List<int> bytes);

  Future<int> get exitCode;

  /// 变更窗口大小;不支持的实现可以空转(容器内 `script` 方案无法重排)。
  void resize(int cols, int rows);

  void kill();
}

/// 以 dart:io 进程实现的终端会话。
class IoTerminalProcess implements TerminalProcess {
  IoTerminalProcess({required Process process, required this.output}) : _process = process;

  final Process _process;

  @override
  final Stream<List<int>> output;

  @override
  void write(List<int> bytes) => _process.stdin.add(bytes);

  @override
  Future<int> get exitCode => _process.exitCode;

  @override
  void resize(int cols, int rows) {}

  @override
  void kill() => _process.kill(ProcessSignal.sigkill);
}

/// 命令执行后端(对齐上游 CommandEngine):本地 PRoot 容器(未来可扩展远程 SSH)。
abstract class CommandEngine {
  /// 容器是否已就绪(可执行命令)。
  Future<bool> isReady();

  /// 未就绪时给模型的提示(引导去容器页面初始化)。
  Future<String?> notReadyHint();

  /// 同步执行一次性命令,返回聚合输出(限幅后)。
  Future<CommandResult> runCommandSync(
    String command, {
    String? workdir,
    Duration timeout = const Duration(seconds: 120),
  });

  /// 打开一个交互式终端会话(容器内 PTY),供终端页使用。
  /// [command] 为空时用容器默认 shell 的交互模式。
  Future<TerminalProcess> openTerminal({
    String? command,
    int cols = 80,
    int rows = 24,
    String? workdir,
  });

  /// 流式执行:逐行输出 + 结束时的事件。
  Stream<Object> runCommandStream(
    String command, {
    String? workdir,
    Duration timeout = const Duration(seconds: 120),
  });
}



/// 把「行流」累积进 [BoundedOutput] 的工具方法(stdout/stderr 共用)。
Future<void> drainToBounded(Stream<List<int>> stream, BoundedOutput output) async {
  await for (final line in stream.transform(utf8.decoder).transform(const LineSplitter())) {
    output.append(line);
    output.append('\n');
  }
}

/// 启动子进程的函数签名(测试可注入假实现)。
typedef ProcessStarter = Future<Process> Function(
  String executable,
  List<String> arguments, {
  Map<String, String>? environment,
  String? workingDirectory,
  bool? runInShell,
});

Future<Process> defaultProcessStarter(
  String executable,
  List<String> arguments, {
  Map<String, String>? environment,
  String? workingDirectory,
  bool? runInShell,
}) =>
    Process.start(
      executable,
      arguments,
      environment: environment,
      workingDirectory: workingDirectory,
      runInShell: runInShell ?? false,
    );