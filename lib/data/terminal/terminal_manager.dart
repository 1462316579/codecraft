import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart' hide TextStyle;
import 'package:flutter/painting.dart' as painting;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kyroon_pty/kyroon_pty.dart';

import '../../../core/terminal/terminal.dart';

/// 终端标签
class TerminalTab {
  final String id;
  String title;
  final TerminalController controller;
  final Pty pty;
  bool running = false;
  final bool mirror;

  TerminalTab({
    required this.id,
    required this.title,
    required this.controller,
    required this.pty,
    this.mirror = false,
  });

  TerminalBuffer get buffer => controller.buffer;
  TerminalEmulator get emulator => controller.emulator;
}

/// 终端标签状态
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
  String? get activeTabIdOrNull => activeTabId;

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

/// 终端标签管理器
class TerminalTabsNotifier extends Notifier<TerminalTabsState> {
  int _seq = 0;

  @override
  TerminalTabsState build() {
    return const TerminalTabsState();
  }

  Future<void> prepare() async {
    if (state.tabs.any((t) => !t.mirror) || state.preparing) return;

    state = state.copyWith(
      preparing: true,
      error: () => null,
      stage: () => '正在准备终端…',
    );

    try {
      await newTab();
      state = state.copyWith(
        preparing: false,
        creating: false,
        stage: () => null,
      );
    } catch (e) {
      state = state.copyWith(
        preparing: false,
        creating: false,
        stage: () => null,
        error: () => e.toString(),
      );
    }
  }

  /// 打开新的终端标签（使用 kyroon_pty）
  Future<void> newTab() async {
    if (state.creating) return;
    state = state.copyWith(creating: true, error: () => null);

    try {
      await _openPtyTab();
    } catch (e) {
      state = state.copyWith(creating: false, error: () => e.toString());
      rethrow;
    }
  }

  /// 通过 kyroon_pty 打开终端会话
  Future<void> _openPtyTab() async {
    final shell = _resolveShellPath();
    final pty = Pty.start(
      shell,
      rows: 24,
      columns: 80,
      environment: {
        'TERM': 'xterm-256color',
        'PATH': [
          if (Platform.environment['PATH'] != null)
            Platform.environment['PATH']!,
          '/system/bin',
          '/system/xbin',
          '/vendor/bin',
          '/product/bin',
        ].join(':'),
      },
    );

    final id = ++_seq;
    final tabId = id.toString();

    final buffer = TerminalBuffer(columns: 80, rows: 24);
    final emulator = TerminalEmulator(buffer, _PtyOutput(
      tabId: tabId,
      onTitleChanged: (oldTitle, newTitle) {
        final tab = state.tabs.firstWhere(
          (t) => t.id == tabId,
          orElse: () => throw StateError('tab not found'),
        );
        if (tab != null && tab.title != newTitle && newTitle.isNotEmpty) {
          tab.title = newTitle;
          state = state.copyWith();
        }
      },
      copyCallback: (text) {
        Clipboard.setData(ClipboardData(text: text));
      },
      pasteCallback: () {
        Clipboard.getData(Clipboard.kTextPlain).then((clipboard) {
          if (clipboard != null && clipboard.text != null) {
            pty.write(Uint8List.fromList(utf8.encode(clipboard.text!)));
          }
        });
      },
      mouseCallback: (button, state, x, y) {
        // SGR-1006 mouse encoding: ESC [ < cb ; Cx ; Cy M (press) / m (release)
        final isPress = state == 1;
        final cb = _encodeMouseButton(button, state);
        final seq = String.fromCharCodes([
          0x1B, 0x5B, 0x3C, // ESC [ <
        ]) + '$cb ; $x ; ${isPress ? 'M' : 'm'}';
        pty.write(utf8.encode(seq));
      },
    ));
    final controller = TerminalController(
      emulator: emulator,
      buffer: buffer,
    );

    // 监听 PTY 输出
    pty.output.listen((data) {
      controller.feedOutput(data);
    }, onError: (_) {});

    final tab = TerminalTab(
      id: tabId,
      title: shell.split('/').last,
      controller: controller,
      pty: pty,
    );
    tab.running = true;

    // 进程退出时提示，避免终端停在空白界面无任何反馈
    pty.exitCode.then((code) {
      tab.running = false;
      controller.writeString(
        '\r\n\x1b[33m[进程已退出: $code]\x1b[0m\r\n',
      );
      state = state.copyWith();
    });

    state = state.copyWith(
      tabs: [...state.tabs, tab],
      activeTabId: () => tabId,
      creating: false,
      stage: () => null,
      error: () => null,
    );
  }

  void activate(String id) {
    if (state.activeTabId == id) return;
    state = state.copyWith(activeTabId: () => id);
  }

  void closeTab(String id) {
    final tabs = [...state.tabs]..removeWhere((t) => t.id == id);
    state = state.copyWith(
      tabs: tabs,
      activeTabId: () => state.activeTabId == id
          ? (tabs.isEmpty ? null : tabs.last.id)
          : state.activeTabId,
    );
  }

  void write(String data) {
    final tab = state.active;
    if (tab == null) return;
    tab.pty.write(Uint8List.fromList(utf8.encode(data)));
  }

  void writeBytes(List<int> bytes) {
    final tab = state.active;
    if (tab == null) return;
    tab.pty.write(Uint8List.fromList(bytes));
  }

  void toggleCtrl() => state = state.copyWith(ctrl: !state.ctrl);
  void toggleAlt() => state = state.copyWith(alt: !state.alt);

  /// AI 命令镜像标签的固定 id
  static const String agentTabId = 'agent-mirror';

  /// 取(必要时创建)AI 命令镜像标签
  TerminalTab _agentTab(String title) {
    final existing = state.tabs.where((tab) => tab.id == agentTabId).firstOrNull;
    if (existing != null) return existing;

    final buffer = TerminalBuffer(columns: 80, rows: 100, scrollbackRows: 5000);
    final emulator = TerminalEmulator(buffer, _MirrorOutput(tabId: 'agent'));
    final controller = TerminalController(
      emulator: emulator,
      buffer: buffer,
    );

    final tab = TerminalTab(
      id: agentTabId,
      title: title,
      controller: controller,
      pty: Pty.start(_resolveShellPath()),
      mirror: true,
    );
    state = state.copyWith(tabs: [...state.tabs, tab]);
    return tab;
  }

  /// 把 AI 执行的命令写进镜像标签
  void mirrorCommand(String title, String command) {
    final tab = _agentTab(title);
    tab.controller.writeString('\x1b[2m\$ \x1b[0m$command\r\n');
  }

  /// 追加命令输出到镜像标签
  void mirrorOutput(String output, {int? exitCode}) {
    final tab = state.tabs.where((item) => item.id == agentTabId).firstOrNull;
    if (tab == null) return;
    if (output.isNotEmpty) {
      tab.controller.writeString(output.endsWith('\n') ? output : output + '\r\n');
    }
    if (exitCode != null && exitCode != 0) {
      tab.controller.writeString('\x1b[31m[exit $exitCode]\x1b[0m\r\n');
    }
  }

  /// SGR-1006 鼠标编码：button 状态编码
  int _encodeMouseButton(int button, int state) {
    // button: 0=左,1=中,2=右；state: 0=释放,1=按下
    // SGR-1006: cb = button + (shift<<4) + (alt<<3) + (ctrl<<2)
    int cb = button;
    // 如果没有修饰键状态，直接返回 button
    return cb;
  }
}

/// 镜像标签的输出回调：不做任何处理
class _MirrorOutput implements TerminalOutput {
  final String tabId;
  _MirrorOutput({required this.tabId});

  @override
  void write(List<int> data, int offset, int count) {}

  @override
  void titleChanged(String oldTitle, String newTitle) {}

  @override
  void onCopyTextToClipboard(String text) {}

  @override
  void onPasteTextFromClipboard() {}

  @override
  void onBell() {}

  @override
  void onColorsChanged() {}

  @override
  void mouseEvent(int button, int state, int x, int y) {}
}

/// PTY 输出回调：将模拟器输出写回 PTY（kyroon_pty 不需要写回，因为用 Pty.write 直接写）
class _PtyOutput implements TerminalOutput {
  final String tabId;
  final void Function(String oldTitle, String newTitle)? onTitleChanged;
  final void Function(String text)? copyCallback;
  final VoidCallback? pasteCallback;
  final void Function(int button, int state, int x, int y)? mouseCallback;

  _PtyOutput({
    required this.tabId,
    this.onTitleChanged,
    this.copyCallback,
    this.pasteCallback,
    this.mouseCallback,
  });

  @override
  void write(List<int> data, int offset, int count) {}

  @override
  void titleChanged(String oldTitle, String newTitle) {
    onTitleChanged?.call(oldTitle, newTitle);
  }

  @override
  void onCopyTextToClipboard(String text) {
    copyCallback?.call(text);
  }

  @override
  void onPasteTextFromClipboard() {
    pasteCallback?.call();
  }

  @override
  void onBell() {}

  @override
  void onColorsChanged() {}

  @override
  void mouseEvent(int button, int state, int x, int y) {
    mouseCallback?.call(button, state, x, y);
  }
}

/// 解析可用的 shell 可执行文件。
///
/// Android 系统通常不自带 bash，直接 `Pty.start('bash')` 会 execvp 失败，
/// 子进程立即退出，终端只剩一片空白。这里按优先级探测常见路径，
/// 最终回退到系统一定存在的 /system/bin/sh。
String _resolveShellPath() {
  const candidates = <String>[
    '/data/data/ids.codecraft.app/files/usr/bin/bash',
    '/system/bin/bash',
    '/system/xbin/bash',
    '/vendor/bin/bash',
    '/product/bin/bash',
    '/bin/bash',
    '/usr/bin/bash',
  ];
  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }
  final pathEnv = Platform.environment['PATH'] ?? '';
  for (final name in const ['bash', 'sh']) {
    for (final dir in pathEnv.split(':')) {
      if (dir.isEmpty) continue;
      final candidate = '$dir/$name';
      if (File(candidate).existsSync()) return candidate;
    }
  }
  return '/system/bin/sh';
}

/// 终端标签提供器
final terminalTabsProvider =
    NotifierProvider<TerminalTabsNotifier, TerminalTabsState>(
  TerminalTabsNotifier.new,
);
