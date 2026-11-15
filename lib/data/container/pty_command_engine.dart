import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kyroon_pty/kyroon_pty.dart';

import 'bounded_output.dart';
import 'command_engine.dart';
import 'container_launcher.dart';

/// 基于 kyroon_pty 的自研终端命令执行后端。
///
/// AI 的命令与终端跑在同一个默认容器里（PRoot），因此两边环境完全一致；
/// 容器未安装时返回明确的引导文案，而不是静默失败。
class PtyCommandEngine implements CommandEngine {
  PtyCommandEngine({this.workdir});

  /// 工作目录，为 null 时使用容器默认目录（应用文档目录）。
  final String? workdir;

  static const Duration defaultTimeout = Duration(seconds: 120);
  static const Duration maxTimeout = Duration(seconds: 1800);

  ContainerLaunchSpec? _spec;
  Future<ContainerLaunchSpec>? _loading;

  /// 解析容器启动参数（只解析一次，之后复用）。
  Future<ContainerLaunchSpec> _resolve() {
    final cached = _spec;
    if (cached != null) return Future.value(cached);
    final pending = _loading;
    if (pending != null) return pending;

    final future = ContainerLauncher.build(workdir: workdir).then(
      (spec) {
        _spec = spec;
        _loading = null;
        return spec;
      },
      onError: (Object error) {
        _loading = null;
        throw error;
      },
    );
    _loading = future;
    return future;
  }

  @override
  Future<bool> isReady() async {
    try {
      await _resolve();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> notReadyHint() async {
    try {
      await _resolve();
      return null;
    } on ContainerMissingException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Future<CommandResult> runCommandSync(
    String command, {
    String? workdir,
    Duration timeout = defaultTimeout,
  }) async {
    final clamped = _clamp(timeout);

    final ContainerLaunchSpec spec;
    try {
      spec = await _resolve();
    } on ContainerMissingException catch (e) {
      return CommandResult(output: e.message, exitCode: -1);
    } catch (e) {
      return CommandResult(output: '无法启动容器: $e', exitCode: -1);
    }

    final pty = Pty.start(
      spec.executable,
      arguments: spec.commandArguments(command),
      environment: spec.environment,
      workingDirectory: workdir ?? spec.workingDirectory,
    );

    final output = BoundedOutput();
    var timedOut = false;

    final subscription = pty.output.listen(
      (data) {
        final text = String.fromCharCodes(data);
        output.append(text);
      },
    );

    final timer = Timer(clamped, () {
      timedOut = true;
      pty.kill();
    });

    int exitCode;
    try {
      exitCode = await pty.exitCode.timeout(clamped, onTimeout: () {
        timedOut = true;
        pty.kill();
        return -1;
      });
    } catch (e) {
      timedOut = true;
      pty.kill();
      return CommandResult(
        output: '无法执行命令: $e',
        exitCode: -1,
        timedOut: true,
        truncated: output.truncated,
      );
    } finally {
      timer.cancel();
      await subscription.cancel();
      pty.kill();
    }

    return CommandResult(
      output: output.build(),
      exitCode: timedOut ? -1 : exitCode,
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

    final ContainerLaunchSpec spec;
    try {
      spec = await _resolve();
    } on ContainerMissingException catch (e) {
      yield CommandLineEvent(e.message);
      yield const CommandExitEvent(-1);
      return;
    } catch (e) {
      yield CommandLineEvent('无法启动容器: $e');
      yield const CommandExitEvent(-1);
      return;
    }

    final pty = Pty.start(
      spec.executable,
      arguments: spec.commandArguments(command),
      environment: spec.environment,
      workingDirectory: workdir ?? spec.workingDirectory,
    );

    final controller = StreamController<Object>();
    var timedOut = false;
    final timer = Timer(clamped, () {
      timedOut = true;
      pty.kill();
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

    // -c 模式下无需写入，shell 已在启动时执行命令

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
    final spec = await _resolve();
    final pty = Pty.start(
      spec.executable,
      arguments: spec.loginArguments,
      environment: spec.environment,
      workingDirectory: workdir ?? spec.workingDirectory,
      rows: rows,
      columns: cols,
    );

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
        // kyroon_pty 当前版本不支持动态 resize，
        // 若需要调整终端大小，可在下次 openTerminal 时传入新的 cols/rows。
      },
      onKill: () {
        subscription.cancel();
        pty.kill();
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
