import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kyroon_pty/kyroon_pty.dart';

import 'bounded_output.dart';
import 'command_engine.dart';

/// 基于 kyroon_pty 的自研终端命令执行后端。
///
/// 不依赖 Termux，直接在宿主环境（容器内或本地）通过 PTY 启动 shell，
/// 适用于“终端不使用 Termux，使用自研终端”的场景。
class PtyCommandEngine implements CommandEngine {
  PtyCommandEngine({
    this.shell = 'bash',
    this.workdir,
  });

  /// 默认 shell 可执行文件。
  final String shell;

  /// 工作目录，为 null 时使用进程默认目录。
  final String? workdir;

  static const Duration defaultTimeout = Duration(seconds: 120);
  static const Duration maxTimeout = Duration(seconds: 1800);

  bool _ready = false;

  @override
  Future<bool> isReady() async => _ready;

  @override
  Future<String?> notReadyHint() async => null;

  /// 标记容器/环境已就绪（由容器安装流程在安装完成后调用）。
  void setReady() => _ready = true;

  @override
  Future<CommandResult> runCommandSync(
    String command, {
    String? workdir,
    Duration timeout = defaultTimeout,
  }) async {
    final clamped = _clamp(timeout);
    final pty = Pty.start(shell);

    final output = BoundedOutput();
    final completer = Completer<int>();

    final subscription = pty.output.listen(
      (data) {
        final text = String.fromCharCodes(data);
        output.append(text);
      },
      onDone: () => completer.complete(0),
      onError: (e) => completer.completeError(e),
    );

    var timedOut = false;
    final timer = Timer(clamped, () {
      timedOut = true;
      pty.kill();
      completer.complete(-1);
    });

    try {
      pty.write(Uint8List.fromList(utf8.encode(command)));
      pty.write(Uint8List.fromList(utf8.encode('\n')));
      await completer.future.timeout(clamped, onTimeout: () {
        timedOut = true;
        pty.kill();
        return -1;
      });
    } catch (e) {
      timedOut = true;
      pty.kill();
      return CommandResult(output: '无法执行命令: $e', exitCode: -1);
    } finally {
      timer.cancel();
      await subscription.cancel();
      pty.kill();
    }

    return CommandResult(
      output: output.build(),
      exitCode: timedOut ? -1 : await completer.future,
      timedOut: timedOut,
      truncated: output.truncated,
    );
  }

  @override
  Stream<Object> runCommandStream(
    String command, {
    String? workdir,
    Duration timeout = defaultTimeout,
  }) async* {
    final clamped = _clamp(timeout);
    final pty = Pty.start(shell);

    final controller = StreamController<Object>();
    var timedOut = false;
    final timer = Timer(clamped, () {
      timedOut = true;
      pty.close(killProcess: true);
    });

    pty.output.listen(
      (data) {
        final text = String.fromCharCodes(data);
        for (final line in const LineSplitter().convert(text)) {
          if (line.isNotEmpty) {
            controller.add(CommandLineEvent(line));
          }
        }
      },
      onDone: () => controller.close(),
      onError: (e) {
        controller.add(CommandLineEvent('错误: $e'));
        controller.close();
      },
    );

    try {
      pty.write(Uint8List.fromList(utf8.encode(command)));
      pty.write(Uint8List.fromList(utf8.encode('\n')));
    } catch (e) {
      controller.add(CommandLineEvent('无法执行命令: $e'));
      controller.close();
    }

    await for (final event in controller.stream) {
      yield event;
    }

    timer.cancel();
    pty.kill();

    yield CommandExitEvent(timedOut ? -1 : 0, timedOut: timedOut);
  }

  @override
  Future<TerminalProcess> openTerminal({
    String? command,
    int cols = 80,
    int rows = 24,
    String? workdir,
  }) async {
    final pty = Pty.start(shell);

    final outputController = StreamController<List<int>>();
    final exitCompleter = Completer<int>();

    final subscription = pty.output.listen(
      (data) {
        if (!outputController.isClosed) {
          outputController.add(data);
        }
      },
      onDone: () {
        exitCompleter.complete(0);
        if (!outputController.isClosed) outputController.close();
      },
      onError: (e) {
        exitCompleter.completeError(e);
        if (!outputController.isClosed) outputController.close();
      },
    );

    if (command != null && command.isNotEmpty) {
      pty.write(Uint8List.fromList(utf8.encode(command)));
      pty.write(Uint8List.fromList(utf8.encode('\n')));
    }

    return _PtyTerminalProcess(
      pty: pty,
      output: outputController.stream,
      exitCode: exitCompleter.future,
      onWrite: (bytes) => pty.write(Uint8List.fromList(bytes)),
      onResize: (c, r) {
        // kyroon_pty 目前不支持动态 resize，保留接口兼容
      },
      onKill: () {
        subscription.cancel();
        pty.close(killProcess: true);
        if (!outputController.isClosed) outputController.close();
      },
    );
  }

  Duration _clamp(Duration timeout) {
    if (timeout < const Duration(seconds: 1)) return const Duration(seconds: 1);
    if (timeout > maxTimeout) return timeout;
    return timeout;
  }
}

class _PtyTerminalProcess implements TerminalProcess {
  _PtyTerminalProcess({
    required Pty pty,
    required this.output,
    required this.exitCode,
    required void Function(List<int> bytes) onWrite,
    required void Function(int cols, int rows) onResize,
    required void Function() onKill,
  }) : _pty = pty,
        _onWrite = onWrite,
        _onResize = onResize,
        _onKill = onKill;

  final Pty _pty;
  final Stream<List<int>> output;
  final Future<int> exitCode;
  final void Function(List<int> bytes) _onWrite;
  final void Function(int cols, int rows) _onResize;
  final void Function() _onKill;

  @override
  void write(List<int> bytes) => _onWrite(bytes);

  @override
  void resize(int cols, int rows) => _onResize(cols, rows);

  @override
  void kill() => _onKill();
}

final ptyEngineProvider = FutureProvider<PtyCommandEngine>((ref) async {
  return PtyCommandEngine();
});
