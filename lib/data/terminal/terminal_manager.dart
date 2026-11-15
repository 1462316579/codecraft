import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kyroon_pty/kyroon_pty.dart';

import '../../core/terminal/terminal.dart';

/// 一个终端会话标签。
class TerminalTab {
  final String id;
  String title;
  final TerminalController controller;
  final bool mirror;

  Pty? _pty;
  StreamSubscription<Uint8List>? _subscription;
  bool running = false;

  TerminalTab({
    required this.id,
    required this.title,
    required this.controller,
    this.mirror = false,
    Pty? pty,
  }) {
    if (pty != null) attach(pty);
  }

  Pty? get pty => _pty;

  /// 绑定（或替换）PTY，并把输出接入终端控制器。
  void attach(Pty pty) {
    _subscription?.cancel();
    _pty = pty;
    running = true;
    _subscription = pty.output.listen(
      controller.feed,
      onError: (Object _) {},
    );
  }

  void write(List<int> bytes) {
    _pty?.write(Uint8List.fromList(bytes));
  }

  void writeText(String text) {
    write(utf8.encode(text));
  }

  void resize(int columns, int rows) {
    // kyroon_pty 的签名是 resize(rows, cols)
    _pty?.resize(rows, columns);
    controller.resize(columns, rows);
  }

  void dispose() {
    _subscription?.cancel();
    _pty?.kill();
    _pty = null;
    running = false;
  }
}

/// 终端标签状态。
class TerminalTabsState {
  final List<TerminalTab> tabs;
  final String? activeTabId;
  final bool preparing;
  final bool creating;
  final String? error;
  final String? stage;
  final bool ctrl;
  final bool alt;

  const TerminalTabsState({
    this.tabs = const [],
    this.activeTabId,
    this.preparing = false,
    this.creating = false,
    this.error,
    this.stage,
    this.ctrl = false,
    this.alt = false,
  });

  TerminalTab? get active =>
      tabs.where((tab) => tab.id == activeTabId).firstOrNull;

  TerminalTabsState copyWith({
    List<TerminalTab>? tabs,
    String? Function()? activeTabId,
    bool? preparing,
    bool? creating,
    String? Function()? error,
    String? Function()? stage,
    bool? ctrl,
    bool? alt,
  }) {
    return TerminalTabsState(
      tabs: tabs ?? this.tabs,
      activeTabId: activeTabId == null ? this.activeTabId : activeTabId(),
      preparing: preparing ?? this.preparing,
      creating: creating ?? this.creating,
      error: error == null ? this.error : error(),
      stage: stage == null ? this.stage : stage(),
      ctrl: ctrl ?? this.ctrl,
      alt: alt ?? this.alt,
    );
  }
}

final terminalTabsProvider =
    NotifierProvider<TerminalTabsNotifier, TerminalTabsState>(
  TerminalTabsNotifier.new,
);

/// 终端标签管理器。
class TerminalTabsNotifier extends Notifier<TerminalTabsState> {
  int _seq = 0;

  @override
  TerminalTabsState build() => const TerminalTabsState();

  /// 首次进入终端页：没有会话就自动开一个。
  Future<void> prepare() async {
    if (state.tabs.any((tab) => !tab.mirror) || state.preparing) return;
    state = state.copyWith(
      preparing: true,
      error: () => null,
      stage: () => '正在准备终端…',
    );
    try {
      await newTab();
      state = state.copyWith(preparing: false, creating: false, stage: () => null);
    } catch (e) {
      state = state.copyWith(
        preparing: false,
        creating: false,
        stage: () => null,
        error: () => _describeError(e),
      );
    }
  }

  Future<void> newTab() async {
    if (state.creating) return;
    state = state.copyWith(creating: true, error: () => null);

    try {
      final shell = await TermuxBootstrap.ensure(
        onStage: (stage) => state = state.copyWith(stage: () => stage),
      );
      state = state.copyWith(stage: () => '正在启动 bash…');
      await _openTab(shell);
    } catch (e) {
      state = state.copyWith(
        creating: false,
        stage: () => null,
        error: () => _describeError(e),
      );
      rethrow;
    }
  }

  Future<void> _openTab(String shell) async {
    final controller = TerminalController(
      columns: 80,
      rows: 24,
      onTitle: (title) => _updateTitle(title),
      onClipboard: (text) => Clipboard.setData(ClipboardData(text: text)),
      onBell: () {},
    );

    final preflight = TermuxBootstrap.lastPreflight;
    // 自检失败就别再 exec bash（只会得到一个秒退的空白终端），
    // 直接用系统 shell，并把失败原因写在屏幕上。
    final useTermux = preflight == null || preflight.ok;
    final launchPath = useTermux ? shell : '/system/bin/sh';

    final pty = Pty.start(
      launchPath,
      arguments: useTermux ? const ['-l'] : const [],
      rows: 24,
      columns: 80,
      environment:
          useTermux ? TermuxBootstrap.environment : TermuxBootstrap.systemEnvironment,
      workingDirectory: TermuxBootstrap.home,
    );

    controller.onResponse = (data) {
      pty.write(Uint8List.fromList(utf8.encode(data)));
    };

    final id = '${++_seq}';
    final tab = TerminalTab(
      id: id,
      title: launchPath.split('/').last,
      controller: controller,
      pty: pty,
    );

    controller.writeString('CodeCraft Terminal · $launchPath\r\n');
    if (!useTermux) {
      controller.writeString('\x1b[33m[Termux 环境自检未通过]\x1b[0m\r\n');
      controller.writeString('${preflight.detail}\r\n');
      controller.writeString(
        '\x1b[2m已改用系统 /system/bin/sh。修正环境后重开标签即可恢复 Termux。\x1b[0m\r\n\r\n',
      );
    }

    final startedAt = DateTime.now();
    var fallbackTried = !useTermux;

    pty.exitCode.then((code) async {
      tab.running = false;
      final elapsed = DateTime.now().difference(startedAt);
      // 立刻退出（1.5s 内）或非零退出都视为启动失败：
      // 前者覆盖 /etc/profile 里直接 exit 的情况，后者覆盖 exec/动态链接失败。
      final quickFailure = elapsed < const Duration(milliseconds: 1500) || code != 0;

      if (!fallbackTried && quickFailure && !tab.mirror) {
        fallbackTried = true;
        final detail = await TermuxBootstrap.preflight(force: true);
        controller.writeString(
          '\r\n\x1b[31m[启动失败] $shell 退出码 $code（${elapsed.inMilliseconds}ms）\x1b[0m\r\n',
        );
        if (detail.detail.isNotEmpty) {
          controller.writeString('\x1b[33m${detail.detail}\x1b[0m\r\n');
        }
        controller.writeString('\x1b[2m改用系统 /system/bin/sh 继续。\x1b[0m\r\n\r\n');
        try {
          final fallback = Pty.start(
            '/system/bin/sh',
            rows: 24,
            columns: 80,
            environment: TermuxBootstrap.systemEnvironment,
            workingDirectory: TermuxBootstrap.home,
          );
          tab.attach(fallback);
          tab.title = 'sh (fallback)';
          state = state.copyWith();
          fallback.exitCode.then((shCode) {
            tab.running = false;
            controller.writeString('\r\n[会话已退出，退出码: $shCode]\r\n');
            state = state.copyWith();
          });
          return;
        } catch (e) {
          controller.writeString('\x1b[31m系统 shell 也无法启动: $e\x1b[0m\r\n');
        }
      }

      controller.writeString('\r\n\x1b[2m[会话已退出，退出码: $code]\x1b[0m\r\n');
      state = state.copyWith();
    });

    state = state.copyWith(
      tabs: [...state.tabs, tab],
      activeTabId: () => id,
      creating: false,
      stage: () => null,
      error: () => null,
    );
  }

  void _updateTitle(String title) {
    final active = state.active;
    if (active == null || active.mirror) return;
    if (active.title == title || title.isEmpty) return;
    active.title = title;
    state = state.copyWith();
  }

  void activate(String id) {
    if (state.activeTabId == id) return;
    state = state.copyWith(activeTabId: () => id);
  }

  void closeTab(String id) {
    final closing = state.tabs.where((tab) => tab.id == id).firstOrNull;
    closing?.dispose();
    final tabs = [...state.tabs]..removeWhere((tab) => tab.id == id);
    state = state.copyWith(
      tabs: tabs,
      activeTabId: () =>
          state.activeTabId == id ? (tabs.isEmpty ? null : tabs.last.id) : state.activeTabId,
    );
  }

  void write(String data) {
    final tab = state.active;
    if (tab == null || tab.mirror) return;
    tab.writeText(data);
  }

  void writeBytes(List<int> bytes) {
    final tab = state.active;
    if (tab == null || tab.mirror) return;
    tab.write(bytes);
  }

  void resizeActive(int columns, int rows) {
    final tab = state.active;
    if (tab == null) return;
    tab.resize(columns, rows);
  }

  void toggleCtrl() => state = state.copyWith(ctrl: !state.ctrl);
  void toggleAlt() => state = state.copyWith(alt: !state.alt);
  void clearModifiers() {
    if (!state.ctrl && !state.alt) return;
    state = state.copyWith(ctrl: false, alt: false);
  }

  String _describeError(Object e) {
    if (e is PlatformException) {
      return '${e.code}: ${e.message ?? ''}';
    }
    return e.toString();
  }

  // ------------------------------------------------------------ AI 镜像标签

  /// AI 命令镜像标签的固定 id
  static const String agentTabId = 'agent-mirror';

  TerminalTab _agentTab(String title) {
    final existing = state.tabs.where((tab) => tab.id == agentTabId).firstOrNull;
    if (existing != null) return existing;

    final tab = TerminalTab(
      id: agentTabId,
      title: title,
      controller: TerminalController(columns: 80, rows: 30, scrollback: 2000),
      mirror: true,
    );
    state = state.copyWith(tabs: [...state.tabs, tab]);
    return tab;
  }

  void mirrorCommand(String title, String command) {
    final tab = _agentTab(title);
    tab.controller.writeString('\x1b[2m\$ \x1b[0m$command\r\n');
  }

  void mirrorOutput(String output, {int? exitCode}) {
    final tab = state.tabs.where((item) => item.id == agentTabId).firstOrNull;
    if (tab == null) return;
    if (output.isNotEmpty) {
      tab.controller.writeString(output.endsWith('\n') ? output : '$output\r\n');
    }
    if (exitCode != null && exitCode != 0) {
      tab.controller.writeString('\x1b[31m[exit $exitCode]\x1b[0m\r\n');
    }
  }
}

/// 预检结果：用来判断 Termux 环境是否可以真正 exec。
class TerminalPreflightResult {
  final bool ok;
  final int? exitCode;
  final String output;
  final String detail;

  const TerminalPreflightResult({
    required this.ok,
    this.exitCode,
    this.output = '',
    this.detail = '',
  });

  String get summary {
    if (ok) return '';
    return '预检失败：$detail';
  }
}

/// Termux 运行环境：负责安装 bootstrap、构造环境变量、启动前自检。
class TermuxBootstrap {
  TermuxBootstrap._();

  static const MethodChannel _channel =
      MethodChannel('ids.codecraft.app/native_paths');

  static String? _prefix;
  static String? _home;
  static String? _bash;
  static bool _ready = false;

  static TerminalPreflightResult? lastPreflight;

  static String? get prefix => _prefix;
  static String? get home => _home;
  static String? get bashPath => _bash;

  static Map<String, String> get environment {
    final prefix = _prefix ?? '/data/data/ids.codecraft.app/files/usr';
    final home = _home ?? '/data/data/ids.codecraft.app/files/home';
    return {
      'PREFIX': prefix,
      'HOME': home,
      'TMPDIR': '$prefix/tmp',
      'SHELL': '$prefix/bin/bash',
      'TERM': 'xterm-256color',
      'COLORTERM': 'truecolor',
      'LANG': 'en_US.UTF-8',
      'LC_ALL': 'en_US.UTF-8',
      'PATH': '$prefix/bin:$prefix/bin/applets:/system/bin:/system/xbin',
      'LD_LIBRARY_PATH': '$prefix/lib',
      'TERMUX_PACKAGE_MANAGER': 'apt',
      'TERMUX_PACKAGE_ARCH': 'aarch64',
      'TERMUX_APP_PID': '$pid',
    };
  }

  /// 系统 shell 的最小环境（Termux 不可用时的兜底）。
  static Map<String, String> get systemEnvironment => {
        'TERM': 'xterm-256color',
        'PATH': '/system/bin:/system/xbin:/sbin',
        'HOME': _home ?? '/',
        'TMPDIR': '/data/local/tmp',
      };

  /// 确保 bootstrap 已安装，返回 bash 的绝对路径。
  static Future<String> ensure({void Function(String stage)? onStage}) async {
    if (_ready && _bash != null) return _bash!;

    final filesDir = await _channel.invokeMethod<String>('filesDir');
    if (filesDir == null || filesDir.isEmpty) {
      throw StateError('无法获取应用私有目录');
    }
    _prefix = '$filesDir/usr';
    _home = '$filesDir/home';
    _bash = '$_prefix/bin/bash';

    await Directory(_home!).create(recursive: true);
    await Directory('$_prefix/tmp').create(recursive: true);

    var status = await _status();
    if (status['installed'] != true) {
      onStage?.call('正在安装 Termux 环境（约 100MB，仅首次）…');
      _triggerInstall();
      var finished = false;
      for (var i = 0; i < 1200; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        status = await _status();
        final stage = status['stage'] as String?;
        if (stage != null && stage.isNotEmpty) onStage?.call(stage);
        final error = status['error'] as String?;
        if (error != null && error.isNotEmpty) {
          throw StateError('环境安装失败：$error');
        }
        if (status['installed'] == true) {
          finished = true;
          break;
        }
        if (status['installing'] != true && i > 4) break;
      }
      if (!finished) {
        throw StateError('Termux 环境安装未完成（可能中断），请重试');
      }
    }

    if (!File(_bash!).existsSync()) {
      throw StateError('未找到 $_bash，请重新安装环境');
    }

    onStage?.call('正在自检运行环境…');
    lastPreflight = await preflight();
    _ready = true;
    return _bash!;
  }

  /// 在真实进程里跑一次 bash，验证动态链接与 exec 权限。
  static Future<TerminalPreflightResult> preflight({bool force = false}) async {
    if (!force && lastPreflight != null) return lastPreflight!;
    try {
      final raw =
          await _channel.invokeMethod<Map<Object?, Object?>>('terminalPreflight');
      if (raw == null) {
        return const TerminalPreflightResult(ok: true);
      }
      final result = TerminalPreflightResult(
        ok: raw['ok'] == true,
        exitCode: (raw['exitCode'] as num?)?.toInt(),
        output: (raw['output'] as String?) ?? '',
        detail: (raw['detail'] as String?) ?? '',
      );
      lastPreflight = result;
      return result;
    } on MissingPluginException {
      // 旧版 APK 没有这个通道方法，跳过自检
      return const TerminalPreflightResult(ok: true);
    } catch (e) {
      return TerminalPreflightResult(ok: false, detail: e.toString());
    }
  }

  static Future<Map<Object?, Object?>> _status() async {
    try {
      final raw =
          await _channel.invokeMethod<Map<Object?, Object?>>('bootstrapStatus');
      return raw ?? const {};
    } on MissingPluginException {
      return {'installed': true};
    }
  }

  static void _triggerInstall() {
    unawaited(
      _channel.invokeMethod<bool>('ensureBootstrap').catchError((Object _) => false),
    );
  }
}
