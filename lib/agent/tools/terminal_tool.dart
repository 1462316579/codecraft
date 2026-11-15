import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../data/terminal/terminal_manager.dart';
import 'tool.dart';

/// 操作应用内置终端（PRoot 容器里的交互式 shell）。
///
/// 与终端页面共用 [terminalTabsProvider]：AI 新建的会话、输入的命令和读取到的
/// 画面就是用户眼前那个终端，而不是另一个隐藏进程。
class TerminalTool extends AgentTool {
  TerminalTool(this._ref);

  final Ref _ref;

  TerminalTabsState get _state => _ref.read(terminalTabsProvider);

  static const List<String> actions = [
    'list',
    'open',
    'show',
    'read',
    'write',
    'key',
    'close',
  ];

  static const Set<String> readOnlyActions = {'list', 'read'};

  /// 常见按键对应的终端转义序列。
  static const Map<String, String> keySequences = {
    'Enter': '\r',
    'Return': '\r',
    'Tab': '\t',
    'Escape': '\x1b',
    'Esc': '\x1b',
    'Space': ' ',
    'Backspace': '\x7f',
    'Delete': '\x1b[3~',
    'ArrowUp': '\x1b[A',
    'Up': '\x1b[A',
    'ArrowDown': '\x1b[B',
    'Down': '\x1b[B',
    'ArrowRight': '\x1b[C',
    'Right': '\x1b[C',
    'ArrowLeft': '\x1b[D',
    'Left': '\x1b[D',
    'Home': '\x1b[H',
    'End': '\x1b[F',
    'PageUp': '\x1b[5~',
    'PageDown': '\x1b[6~',
    'CtrlA': '\x01',
    'CtrlC': '\x03',
    'CtrlD': '\x04',
    'CtrlE': '\x05',
    'CtrlK': '\x0b',
    'CtrlL': '\x0c',
    'CtrlU': '\x15',
    'CtrlZ': '\x1a',
  };

  @override
  String get name => 'Terminal';

  @override
  String get description =>
      '操作应用内置终端（PRoot 容器里的交互式 shell）：新建/查看会话、向 PTY 输入命令或按键、'
      '读取终端屏幕内容、关闭会话。一次性命令优先用 Bash；需要运行 top/vim/ssh 等交互式程序、'
      '或查看终端当前画面时用本工具。open/show 会把界面切到终端页；write 默认在末尾补回车。';

  @override
  ToolPermissionPolicy get permissionPolicy => ToolPermissionPolicy.ask;

  @override
  Set<ToolCapability> get capabilities => const {ToolCapability.executeCommands};

  @override
  PermissionRequestText permissionRequest(
      Map<String, dynamic> args, String argsPreview) {
    final action = (args['action'] as String?)?.trim() ?? '';
    final detail = switch (action) {
      'write' => (args['text'] as String?) ?? '',
      'key' => (args['key'] as String?) ?? '',
      _ => '',
    };
    return PermissionRequestText(
      title: '内置终端',
      summary: 'AI 请求执行 terminal.$action${detail.isEmpty ? '' : ' $detail'}',
      details: argsPreview,
    );
  }

  @override
  Map<String, ToolParameter> get parameters => const {
        'action': ToolParameter(
          name: 'action',
          type: ParameterType.string,
          description: '操作类型：list=列出现有会话；open=新建会话并切到终端页；'
              'show=切到终端页（没有会话时自动新建）；read=读取屏幕文本；'
              'write=向终端输入文本；key=发送特殊按键；close=关闭会话',
          enumValues: actions,
        ),
        'tabId': ToolParameter(
          name: 'tabId',
          type: ParameterType.string,
          description: '目标终端会话 id（缺省为当前会话）',
          required: false,
        ),
        'text': ToolParameter(
          name: 'text',
          type: ParameterType.string,
          description: 'write：要输入的内容（shell 命令或交互式程序的输入）',
          required: false,
        ),
        'newline': ToolParameter(
          name: 'newline',
          type: ParameterType.boolean,
          description: 'write：是否在末尾补回车，默认 true',
          required: false,
        ),
        'wait': ToolParameter(
          name: 'wait',
          type: ParameterType.integer,
          description: 'write/key：写入后等待多少毫秒再读取屏幕，默认 800，最大 15000',
          required: false,
        ),
        'key': ToolParameter(
          name: 'key',
          type: ParameterType.string,
          description: 'key：按键名，支持 Enter/Tab/Escape/Backspace/ArrowUp/ArrowDown/'
              'ArrowLeft/ArrowRight/Home/End/PageUp/PageDown/CtrlC/CtrlD/CtrlL 等',
          required: false,
        ),
        'lines': ToolParameter(
          name: 'lines',
          type: ParameterType.integer,
          description: 'read：读取最近多少行（含滚动历史），默认 60',
          required: false,
        ),
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args, {String? sessionId}) async {
    final notifier = _ref.read(terminalTabsProvider.notifier);
    final action = (args['action'] as String?)?.trim() ?? '';
    final tabId = args['tabId'] as String?;

    switch (action) {
      case 'list':
        final state = _state;
        final lines = state.tabs
            .map((tab) => '- ${tab.id}${tab.id == state.activeTabId ? ' (当前)' : ''} '
                '${tab.mirror ? '[AI 命令记录]' : (tab.running ? '[运行中]' : '[已退出]')} ${tab.title}')
            .join('\n');
        return ToolSuccess(lines.isEmpty ? '(没有终端会话，可先用 action=open 新建)' : lines);

      case 'open':
        final before = _state.tabs.map((tab) => tab.id).toSet();
        await notifier.newTab();
        final error = _state.error;
        if (error != null) {
          return ToolError(error, code: 'TERMINAL_UNAVAILABLE');
        }
        final created = _state.tabs
            .where((tab) => !tab.mirror && !before.contains(tab.id))
            .firstOrNull;
        if (created == null) {
          return const ToolError('终端会话创建失败，请重试', code: 'TERMINAL_CREATE_FAILED');
        }
        if (!created.running) {
          return const ToolError(
            '终端会话已创建但容器未能启动，请到 设置 → 容器与镜像 检查 PRoot 运行环境。',
            code: 'TERMINAL_NOT_RUNNING',
          );
        }
        _showPage();
        return ToolSuccess({
          'tabId': created.id,
          'title': created.title,
          'message': '已新建终端会话并切换到终端页',
        });

      case 'show':
        var tab = notifier.interactiveTab(tabId);
        if (tab == null) {
          await notifier.newTab();
          final error = _state.error;
          if (error != null) return ToolError(error, code: 'TERMINAL_UNAVAILABLE');
          tab = notifier.interactiveTab();
        }
        if (tab == null) {
          return const ToolError('没有可用的终端会话', code: 'TERMINAL_MISSING');
        }
        _showPage();
        return ToolSuccess('已切换到终端会话 ${tab.id}');

      case 'read':
        final tab = notifier.interactiveTab(tabId);
        if (tab == null) {
          return ToolError(
            tabId == null || tabId.isEmpty
                ? '没有可读取的终端会话，请先用 action=open 新建'
                : '终端会话不存在或不是可交互会话：$tabId',
            code: 'TERMINAL_MISSING',
          );
        }
        final raw = args['lines'];
        final lines = switch (raw) {
          final num value => value.toInt(),
          final String value => int.tryParse(value) ?? 60,
          _ => 60,
        };
        final text = notifier.readScreen(tabId: tab.id, lines: lines);
        return ToolSuccess(text.isEmpty ? '(终端没有输出)' : text);

      case 'write':
        final text = args['text'] as String?;
        if (text == null || text.isEmpty) {
          return const ToolError('write 需要 text 参数');
        }
        final newline = (args['newline'] as bool?) ?? true;
        // PTY 用回车作为换行,统一把 \n / \r\n 归一化,避免命令不执行。
        final normalized =
            text.replaceAll('\r\n', '\n').replaceAll('\n', '\r');
        final payload =
            newline && !normalized.endsWith('\r') ? '$normalized\r' : normalized;
        if (!notifier.writeTo(payload, tabId: tabId)) {
          return const ToolError(
            '终端会话不存在或已退出，请先用 action=open 新建会话',
            code: 'TERMINAL_MISSING',
          );
        }
        await _settle(args);
        return ToolSuccess(_snapshot(notifier, tabId));

      case 'key':
        final key = args['key'] as String?;
        if (key == null || key.isEmpty) {
          return const ToolError('key 需要 key 参数');
        }
        final sequence = keySequences[key] ?? (key.length == 1 ? key : null);
        if (sequence == null) {
          return ToolError(
            '不支持的按键：$key（可用：${keySequences.keys.join('/')}）',
            code: 'UNSUPPORTED_KEY',
          );
        }
        if (!notifier.writeTo(sequence, tabId: tabId)) {
          return const ToolError(
            '终端会话不存在或已退出，请先用 action=open 新建会话',
            code: 'TERMINAL_MISSING',
          );
        }
        await _settle(args);
        return ToolSuccess(_snapshot(notifier, tabId));

      case 'close':
        final state = _state;
        final target = tabId ??
            notifier.interactiveTab()?.id ??
            state.activeTabId;
        if (target == null || target.isEmpty) {
          return const ToolError('没有可关闭的终端会话');
        }
        notifier.closeTab(target);
        return ToolSuccess('已关闭终端会话 $target');

      default:
        return ToolError('未知 action：$action');
    }
  }

  /// 写入后等一小段时间，让 shell 有机会输出，再把屏幕回给模型。
  Future<void> _settle(Map<String, dynamic> args) async {
    final raw = args['wait'];
    final ms = switch (raw) {
      final num value => value.toInt(),
      final String value => int.tryParse(value) ?? 800,
      _ => 800,
    };
    await Future<void>.delayed(Duration(milliseconds: ms.clamp(0, 15000)));
  }

  String _snapshot(TerminalTabsNotifier notifier, String? tabId) {
    final text = notifier.readScreen(tabId: tabId, lines: 30);
    return text.isEmpty ? '(终端暂无输出)' : text;
  }

  /// 把界面切到终端页，让用户看到 AI 正在操作的会话。
  void _showPage() {
    final router = _ref.read(routerProvider);
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (path == '/terminal') return;
    unawaited(router.push('/terminal'));
  }
}

/// 工具在会话里的注册入口。
final terminalToolProvider = Provider<TerminalTool>((ref) => TerminalTool(ref));
