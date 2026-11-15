import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kyroon_pty/kyroon_pty.dart';

import '../../core/terminal/terminal.dart';
import '../container/container_launcher.dart';

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
    state = state.copyWith(
      creating: true,
      error: () => null,
      stage: () => '正在准备容器…',
    );

    try {
      final spec = await ContainerLauncher.build(
        onStage: (stage) => state = state.copyWith(stage: () => stage),
      );
      state = state.copyWith(stage: () => '正在启动 ${spec.containerName}…');
      _openTab(spec);
    } on ContainerMissingException catch (e) {
      state = state.copyWith(
        creating: false,
        stage: () => null,
        error: () => e.message,
      );
    } catch (e) {
      state = state.copyWith(
        creating: false,
        stage: () => null,
        error: () => _describeError(e),
      );
    }
  }

  /// 在 PRoot 容器里开一个交互式登录 shell。
  void _openTab(ContainerLaunchSpec spec) {
    final controller = TerminalController(
      columns: 80,
      rows: 24,
      onTitle: (title) => _updateTitle(title),
      onClipboard: (text) => Clipboard.setData(ClipboardData(text: text)),
      onBell: () {},
    );

    final id = '${++_seq}';
    final tab = TerminalTab(
      id: id,
      title: spec.containerName,
      controller: controller,
    );

    try {
      final pty = Pty.start(
        spec.executable,
        arguments: spec.loginArguments,
        rows: 24,
        columns: 80,
        environment: spec.environment,
        workingDirectory: spec.workingDirectory,
      );

      controller.onResponse = (data) {
        pty.write(Uint8List.fromList(utf8.encode(data)));
      };
      tab.attach(pty);

      pty.exitCode.then((code) {
        tab.running = false;
        controller.writeString('\r\n\x1b[2m[容器已退出，退出码: $code]\x1b[0m\r\n');
        state = state.copyWith();
      });
    } catch (e) {
      tab.running = false;
      controller.writeString('\x1b[31m无法启动容器：$e\x1b[0m\r\n');
      controller.writeString(
        '\x1b[2m请到 设置 → 容器与镜像 检查 PRoot 运行环境。\x1b[0m\r\n',
      );
    }

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

  /// 取一个可交互（非 AI 镜像）标签：优先当前标签，否则第一个可交互标签。
  TerminalTab? interactiveTab([String? tabId]) {
    if (tabId != null && tabId.isNotEmpty) {
      final tab = state.tabs.where((item) => item.id == tabId).firstOrNull;
      return (tab == null || tab.mirror) ? null : tab;
    }
    final active = state.active;
    if (active != null && !active.mirror) return active;
    return state.tabs.where((item) => !item.mirror).firstOrNull;
  }

  /// 读取终端屏幕文本（含最近的滚动历史），供 AI 查看交互式程序输出。
  String readScreen({String? tabId, int lines = 60}) {
    final tab = interactiveTab(tabId);
    if (tab == null) return '';
    final screen = tab.controller.screen;
    final available = screen.scrollbackLength + screen.rows;
    final count = lines <= 0 ? screen.rows : lines.clamp(1, available);
    final rows = <String>[];
    for (var index = screen.rows - count; index < screen.rows; index++) {
      final row = screen.rowAt(index);
      if (row != null) rows.add(row.getText());
    }
    return rows.join('\n').trimRight();
  }

  /// 向标签的 PTY 写入文本（AI 操作交互式终端）。
  bool writeTo(String data, {String? tabId}) {
    final tab = interactiveTab(tabId);
    if (tab == null || !tab.running) return false;
    tab.writeText(data);
    return true;
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
