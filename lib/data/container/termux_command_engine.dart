import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/services.dart' show MethodChannel, EventChannel;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bounded_output.dart';
import 'command_engine.dart';

/// 首次安装 bootstrap 的实时进度文案（供终端页在加载态展示）。
/// null 表示当前不在安装中。
final ValueNotifier<String?> bootstrapStageNotifier = ValueNotifier<String?>(null);

/// 基于 Termux 内置 shell 的命令执行后端：不再通过 PRoot 容器，
/// 而是直接在宿主 Termux 环境中启动进程执行命令。
class TermuxCommandEngine implements CommandEngine {
  TermuxCommandEngine({ProcessStarter? starter})
      : _starter = starter ?? defaultProcessStarter;

  static const Duration defaultTimeout = Duration(seconds: 120);
  static const Duration maxTimeout = Duration(seconds: 1800);

  final ProcessStarter _starter;

  @override
  Future<bool> isReady() async => true;

  @override
  Future<String?> notReadyHint() async => null;

  static const String _appFilesDir = '/data/user/0/ids.codecraft.app/files';
  static const String _homeDir = '$_appFilesDir/home';
  static const String _prefixDir = '$_appFilesDir/usr';

  /// ZeroTermux 风格的基础环境变量（映射到本应用沙箱路径）。
  static Map<String, String> _baseEnvironment() => {
        'HOME': _homeDir,
        'PREFIX': _prefixDir,
        'PATH': '$_prefixDir/bin:$_prefixDir/bin/applets:/system/bin:/system/xbin',
        'LD_LIBRARY_PATH': '$_prefixDir/lib',
        'TMPDIR': '$_prefixDir/tmp',
        'SHELL': '/system/bin/sh',
        'TERM': 'xterm-256color',
        'PS1': r'~ $ ',
        'LANG': 'en_US.UTF-8',
        'COLORTERM': 'truecolor',
        'USER': 'user',
        'LOGNAME': 'user',
        'TERMUX_VERSION': '0.118.0',
        'TERMUX_APP_PID': '${pid}',
      };

  static String _terminalInitScriptPty() => r'''
export HOME="${HOME:-/data/user/0/ids.codecraft.app/files/home}"
export PREFIX="${PREFIX:-/data/user/0/ids.codecraft.app/files/usr}"
export PATH="$PREFIX/bin:$PREFIX/bin/applets:/system/bin:/system/xbin:${PATH:-}"
export LD_LIBRARY_PATH="$PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PS1='~ $ '
mkdir -p "$HOME" "$PREFIX/bin" "$PREFIX/tmp" "$PREFIX/etc" 2>/dev/null || true
cd "$HOME" 2>/dev/null || cd /
if [ -f "$HOME/.profile" ]; then . "$HOME/.profile"; fi
if [ ! -f "$PREFIX/etc/motd_shown" ]; then
  printf '\033[1;32mWelcome to CodeCraft Terminal!\033[0m\r\n\r\n'
  printf ' \033[1;34m*\033[0m Home:   %s\r\n' "$HOME"
  printf ' \033[1;34m*\033[0m Prefix: %s\r\n\r\n' "$PREFIX"
  mkdir -p "$PREFIX/etc" 2>/dev/null && echo 1 > "$PREFIX/etc/motd_shown" 2>/dev/null || true
fi
if [ -x "$PREFIX/bin/bash" ]; then
  export SHELL="$PREFIX/bin/bash"
  exec "$PREFIX/bin/bash" -l
else
  export SHELL="/system/bin/sh"
  exec /system/bin/sh -i
fi
''';

  static String _terminalInitScriptNoTty() => r'''
export HOME="${HOME:-/data/user/0/ids.codecraft.app/files/home}"
export PREFIX="${PREFIX:-/data/user/0/ids.codecraft.app/files/usr}"
export PATH="$PREFIX/bin:$PREFIX/bin/applets:/system/bin:/system/xbin:${PATH:-}"
export PS1='~ $ '
mkdir -p "$HOME" "$PREFIX/bin" "$PREFIX/tmp" "$PREFIX/etc" 2>/dev/null || true
cd "$HOME" 2>/dev/null || cd /
if [ -f "$HOME/.profile" ]; then . "$HOME/.profile"; fi
if [ ! -f "$PREFIX/etc/motd_shown" ]; then
  printf '\033[1;32mWelcome to CodeCraft Terminal!\033[0m\r\n\r\n'
  printf ' \033[1;34m*\033[0m Shell:  /system/bin/sh\r\n'
  printf ' \033[1;34m*\033[0m Home:   %s\r\n' "$HOME"
  printf ' \033[1;34m*\033[0m Prefix: %s\r\n\r\n' "$PREFIX"
  printf 'Working with packages: \033[1mapt\033[0m (bootstrap required)\r\n\r\n'
  mkdir -p "$PREFIX/etc" 2>/dev/null && echo 1 > "$PREFIX/etc/motd_shown" 2>/dev/null || true
fi
# 添加换行符确保提示符在非 TTY 管道中被刷新显示
printf '%s\n' "$PS1"
exec /system/bin/sh -i
''';

  static List<String> _terminalArgv({required bool hasPty}) {
    if (_hasBootstrapLogin()) {
      return ['$_prefixDir/bin/login'];
    }
    if (hasPty) {
      final script = _terminalInitScriptPty();
      return ['/system/bin/sh', '-c', script];
    }
    // 非 PTY 路径也必须走交互式初始化脚本，设置 PS1 并进入交互式 sh，
    // 否则裸 /system/bin/sh 不会输出提示符，终端看起来是空白的。
    final script = _terminalInitScriptNoTty();
    return ['/system/bin/sh', '-c', script];
  }

  static bool _hasBootstrapLogin() {
    try {
      final installed = File('$_prefixDir/.bootstrapped').existsSync() &&
          File('$_prefixDir/bin/bash').existsSync();
      return installed && File('$_prefixDir/bin/login').existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<CommandResult> runCommandSync(
    String command, {
    String? workdir,
    Duration timeout = defaultTimeout,
  }) async {
    final clamped = _clamp(timeout);
    final shell = '/system/bin/sh';
    final args = ['-c', command];
    Process process;
    try {
      process = await _starter(
        shell,
        args,
        environment: _baseEnvironment(),
        workingDirectory: workdir,
      );
    } catch (error) {
      return CommandResult(output: '无法启动进程:$error', exitCode: -1);
    }

    var timedOut = false;
    final timer = Timer(clamped, () {
      timedOut = true;
      process.kill(ProcessSignal.sigkill);
    });
    final output = BoundedOutput();
    final drains = [
      drainToBounded(process.stdout, output).catchError((_) {}),
      drainToBounded(process.stderr, output).catchError((_) {}),
    ];
    final exitCode = await process.exitCode;
    timer.cancel();
    await Future.wait(drains);
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
    final shell = '/system/bin/sh';
    final args = ['-c', command];
    Process process;
    try {
      process = await _starter(
        shell,
        args,
        environment: _baseEnvironment(),
        workingDirectory: workdir,
      );
    } catch (error) {
      yield CommandLineEvent('无法启动进程:$error');
      yield const CommandExitEvent(-1);
      return;
    }

    final controller = StreamController<String>();
    final stdoutSub = process.stdout
        .transform(const SystemEncoding().decoder)
        .transform(const LineSplitter())
        .listen(controller.add);
    final stderrSub = process.stderr
        .transform(const SystemEncoding().decoder)
        .transform(const LineSplitter())
        .listen(controller.add);
    var timedOut = false;
    final timer = Timer(clamped, () {
      timedOut = true;
      process.kill(ProcessSignal.sigkill);
    });
    final done = Future.wait<void>([stdoutSub.asFuture(), stderrSub.asFuture()])
        .then((_) => controller.close(), onError: (_) => controller.close());
    await for (final line in controller.stream) {
      yield CommandLineEvent(line);
    }
    await done;
    timer.cancel();
    final exitCode = await process.exitCode;
    yield CommandExitEvent(timedOut ? -1 : exitCode, timedOut: timedOut);
  }

  @override
  Future<TerminalProcess> openTerminal({
    String? command,
    int cols = 80,
    int rows = 24,
    String? workdir,
  }) async {
    final effectiveWorkdir = workdir ?? _homeDir;
    if (Platform.isAndroid) {
      print('T_DIAG: openTerminal start');
      await _ensureBootstrap();

      Object? ptyError;
      Object? shellError;
      try {
        print('T_DIAG: attempting _openPtyTerminalViaChannel');
        return await _openPtyTerminalViaChannel(cols: cols, rows: rows, workdir: effectiveWorkdir);
      } catch (e) {
        ptyError = e;
      }
      try {
        print('T_DIAG: attempting _openShellTerminalViaChannel');
        return await _openShellTerminalViaChannel(cols: cols, rows: rows, workdir: effectiveWorkdir);
      } catch (e) {
        shellError = e;
      }
      try {
        print('T_DIAG: attempting _startProcessTerminal');
        return await _startProcessTerminal(workdir: effectiveWorkdir);
      } catch (e) {
        final details = [
          if (ptyError != null) 'pty: $ptyError',
          if (shellError != null) 'shell: $shellError',
          'io: $e',
        ].join('; ');
        throw Exception('无法启动终端: $details');
      }
    }
    return _startProcessTerminal(workdir: workdir);
  }

  static Future<void> _ensureBootstrap() async {
    print('T_DIAG: _ensureBootstrap start');
    const markerPath = '$_prefixDir/.bootstrapped';
    const bashPath = '$_prefixDir/bin/bash';
    bool installed() {
      try {
        return File(markerPath).existsSync() && File(bashPath).existsSync();
      } catch (_) {
        return false;
      }
    }

    if (installed()) {
      print('T_DIAG: bootstrap already installed');
      bootstrapStageNotifier.value = null;
      return;
    }

    const channel = MethodChannel('ids.codecraft.app/bootstrap');
    try {
      channel.invokeMethod<bool>('ensureInstall').then(
        (_) {},
        onError: (_) {},
      );
    } catch (_) {}

    final deadline = DateTime.now().add(const Duration(minutes: 10));
    var retriggerAt = DateTime.now().add(const Duration(seconds: 3));
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 500));

      Map<Object?, Object?>? st;
      try {
        st = await channel
            .invokeMethod<Map<Object?, Object?>>('status')
            .timeout(const Duration(seconds: 3), onTimeout: () => null);
      } catch (_) {
        st = null;
      }

      if (installed()) {
        print('T_DIAG: bootstrap install finished');
        bootstrapStageNotifier.value = null;
        return;
      }

      if (st != null) {
        final error = st['error'] as String?;
        final installing = st['installing'] == true;
        if (error != null && !installing) {
          bootstrapStageNotifier.value = null;
          throw Exception('Linux 环境安装失败：$error');
        }
        if (!installing && DateTime.now().isAfter(retriggerAt)) {
          retriggerAt = DateTime.now().add(const Duration(seconds: 5));
          try {
            channel.invokeMethod<bool>('ensureInstall').then(
              (_) {},
              onError: (_) {},
            );
          } catch (_) {}
        }
        final stage = st['stage'] as String?;
        final progress = st['progress'];
        final pct = progress is int && progress >= 0 ? ' $progress%' : '';
        if (stage != null && stage.isNotEmpty) {
          bootstrapStageNotifier.value = '正在安装 Linux 环境… $stage$pct';
        } else {
          bootstrapStageNotifier.value = '正在安装 Linux 环境…';
        }
      }
    }
    bootstrapStageNotifier.value = null;
    throw Exception('Linux 环境安装超时，请重试');
  }

  Future<TerminalProcess> _openShellTerminalViaChannel({
    required int cols,
    required int rows,
    String? workdir,
  }) async {
    final methodChannel = MethodChannel('ids.codecraft.app/shell');
    final eventChannel = EventChannel('ids.codecraft.app/shell/events');

    final env = _baseEnvironment();
    final outputController = StreamController<List<int>>();
    final exitCompleter = Completer<int>();
    StreamSubscription? subscription;
    int? sessionId;

    subscription = eventChannel.receiveBroadcastStream().listen((event) {
      print('T_DIAG: SHELL_RAW_EVENT: $event');
      final map = event as Map?;
      if (map == null) return;
      final eventId = map['id'];
      if (sessionId == null || eventId.toString() != sessionId.toString()) return;
      if (map.containsKey('data')) {
        var data = map['data'];
        if (data is List) {
          var bytes = List<int>.from(data);
          if (bytes.isNotEmpty && !outputController.isClosed) {
            outputController.add(bytes);
          }
        }
      }
      if (map.containsKey('exit')) {
        exitCompleter.complete(map['exit'] as int);
        if (!outputController.isClosed) {
          outputController.close();
        }
        subscription?.cancel();
      }
    });

    final argv = _terminalArgv(hasPty: false);
    try {
      sessionId = await methodChannel.invokeMethod<int>('open', {
        'argv': argv,
        'env': env.entries.map((e) => '${e.key}=${e.value}').toList(),
        'cwd': workdir,
      }).timeout(const Duration(seconds: 15));
    } catch (e) {
      await subscription.cancel();
      if (!outputController.isClosed) await outputController.close();
      rethrow;
    }
    if (sessionId == null || sessionId <= 0) {
      await subscription.cancel();
      if (!outputController.isClosed) await outputController.close();
      throw Exception('无法创建 Shell 会话');
    }

    return ShellChannelTerminalProcess(
      id: sessionId,
      output: outputController.stream,
      exitCode: exitCompleter.future,
      onWrite: (bytes) => methodChannel.invokeMethod('write', {'id': sessionId, 'data': bytes}),
      onKill: () {
        subscription?.cancel();
        methodChannel.invokeMethod('close', {'id': sessionId});
        if (!outputController.isClosed) outputController.close();
      },
    );
  }

  Future<TerminalProcess> _startProcessTerminal({String? workdir}) async {
    final argv = _terminalArgv(hasPty: false);
    final shell = argv.first;
    final args = argv.length > 1 ? argv.sublist(1) : <String>[];
    Process process;
    try {
      process = await _starter(
        shell,
        args,
        environment: _baseEnvironment(),
        workingDirectory: workdir,
      ).timeout(const Duration(seconds: 10));
    } catch (error) {
      throw Exception('无法启动终端:$error');
    }

    final output = StreamController<List<int>>();
    void onData(List<int> bytes) {
      if (!output.isClosed) output.add(bytes);
    }

    final stdoutSub = process.stdout.listen(onData);
    final stderrSub = process.stderr.listen(onData);
    process.exitCode.whenComplete(() async {
      await stdoutSub.cancel();
      await stderrSub.cancel();
      await output.close();
    });
    return IoTerminalProcess(process: process, output: output.stream);
  }

  Future<TerminalProcess> _openPtyTerminalViaChannel({
    required int cols,
    required int rows,
    String? workdir,
  }) async {
    final methodChannel = MethodChannel('ids.codecraft.app/pty');
    final eventChannel = EventChannel('ids.codecraft.app/pty/events');

    final available = await methodChannel
            .invokeMethod<bool>('available')
            .timeout(const Duration(seconds: 5), onTimeout: () => false) ??
        false;
    print('T_DIAG: PTY_AVAILABLE: $available');
    if (!available) {
      throw Exception('原生 PTY 不可用');
    }

    final env = _baseEnvironment();
    final outputController = StreamController<List<int>>();
    final exitCompleter = Completer<int>();
    StreamSubscription? subscription;
    int? sessionId;

    subscription = eventChannel.receiveBroadcastStream().listen((event) {
      print('T_DIAG: PTY_RAW_EVENT: $event');
      final map = event as Map?;
      if (map == null) return;
      final eventId = map['id'];
      if (sessionId == null || eventId.toString() != sessionId.toString()) return;
      if (map.containsKey('data')) {
        final data = map['data'];
        if (data is List && !outputController.isClosed) {
          outputController.add(List<int>.from(data));
        } else if (data is Uint8List && !outputController.isClosed) {
          outputController.add(data);
        }
      }
      if (map.containsKey('exit')) {
        exitCompleter.complete(map['exit'] as int);
        if (!outputController.isClosed) {
          outputController.close();
        }
        subscription?.cancel();
      }
    });

    final argv = _terminalArgv(hasPty: true);
    try {
      sessionId = await methodChannel.invokeMethod<int>('open', {
        'argv': argv,
        'env': env.entries.map((e) => '${e.key}=${e.value}').toList(),
        'cwd': workdir,
        'cols': cols,
        'rows': rows,
      }).timeout(const Duration(seconds: 15));
      print('T_DIAG: PTY_SESSION_ID: $sessionId');
    } catch (e) {
      await subscription.cancel();
      if (!outputController.isClosed) await outputController.close();
      rethrow;
    }
    if (sessionId == null || sessionId <= 0) {
      await subscription.cancel();
      if (!outputController.isClosed) await outputController.close();
      throw Exception('无法创建 PTY 会话');
    }

    return PtyChannelTerminalProcess(
      id: sessionId,
      output: outputController.stream,
      exitCode: exitCompleter.future,
      onWrite: (bytes) => methodChannel.invokeMethod('write', {'id': sessionId, 'data': bytes}),
      onResize: (c, r) => methodChannel.invokeMethod('resize', {'id': sessionId, 'cols': c, 'rows': r}),
      onKill: () {
        subscription?.cancel();
        methodChannel.invokeMethod('close', {'id': sessionId});
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

class PtyChannelTerminalProcess implements TerminalProcess {
  PtyChannelTerminalProcess({
    required this.id,
    required this.output,
    required this.exitCode,
    required void Function(List<int> bytes) onWrite,
    required void Function(int cols, int rows) onResize,
    required void Function() onKill,
  }) : _onWrite = onWrite,
        _onResize = onResize,
        _onKill = onKill;

  final int id;
  @override
  final Stream<List<int>> output;
  @override
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

class ShellChannelTerminalProcess implements TerminalProcess {
  ShellChannelTerminalProcess({
    required this.id,
    required this.output,
    required this.exitCode,
    required void Function(List<int> bytes) onWrite,
    required void Function() onKill,
  }) : _onWrite = onWrite,
        _onKill = onKill;

  final int id;
  @override
  final Stream<List<int>> output;
  @override
  final Future<int> exitCode;
  final void Function(List<int> bytes) _onWrite;
  final void Function() _onKill;

  @override
  void write(List<int> bytes) => _onWrite(bytes);

  @override
  void resize(int cols, int rows) {}

  @override
  void kill() => _onKill();
}

final termuxEngineProvider = FutureProvider<TermuxCommandEngine>((ref) async {
  return TermuxCommandEngine();
});
