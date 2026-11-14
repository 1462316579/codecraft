import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart' hide TextStyle;
import 'package:flutter/painting.dart' as painting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/iconfont.dart';

import '../../core/terminal/terminal.dart';
import '../../data/terminal/terminal_manager.dart';
import '../../data/terminal/terminal_settings.dart';
import '../../l10n/app_localizations.dart';
import 'terminal_settings_sheet.dart';
import 'widgets/extra_keys_row.dart';

/// ZeroTermux 风格的全屏终端页（基于 kyroon_pty）。
class TerminalPage extends ConsumerStatefulWidget {
  const TerminalPage({super.key});

  @override
  ConsumerState<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends ConsumerState<TerminalPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(terminalTabsProvider.notifier).prepare();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(terminalTabsProvider);
    final notifier = ref.read(terminalTabsProvider.notifier);
    final settings = ref.watch(terminalSettingsProvider);

    // 内置主题色（与TerminalThemePreset.builtin保持一致）
    const bgColor = Color(0xFF1E1E1E);
    const fgColor = Color(0xFFD4D4D4);
    const cursorColor = Color(0xFF00FF00);

    final active = state.active;
    final title = active?.title ?? l10n.terminalTitle;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      drawer: _SessionDrawer(
        state: state,
        onNewTab: () {
          Navigator.of(context).pop();
          notifier.newTab();
        },
        onActivate: (id) {
          Navigator.of(context).pop();
          notifier.activate(id);
        },
        onClose: (id) => notifier.closeTab(id),
        onSettings: () {
          Navigator.of(context).pop();
          showTerminalSettingsSheet(context, ref);
        },
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 顶部极简状态栏
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: bgColor,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Iconfont.menu, size: 20, color: fgColor),
                    tooltip: '会话列表',
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: fgColor,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Iconfont.plus, size: 20, color: fgColor),
                    tooltip: l10n.terminalNewTab,
                    onPressed: () => notifier.newTab(),
                  ),
                  IconButton(
                    icon: Icon(Iconfont.settings, size: 18, color: fgColor),
                    tooltip: l10n.terminalSettingsTitle,
                    onPressed: () => showTerminalSettingsSheet(context, ref),
                  ),
                ],
              ),
            ),
            // 终端视图
            Expanded(
              child: _buildTerminalBody(context, state, active, bgColor, fgColor, cursorColor, settings, notifier),
            ),
            // 底部附加按键行
            ExtraKeysRow(
              ctrl: state.ctrl,
              alt: state.alt,
              onEscape: () => notifier.write(String.fromCharCode(0x1b)),
              onTab: () => notifier.write(String.fromCharCode(0x09)),
              onToggleCtrl: notifier.toggleCtrl,
              onToggleAlt: notifier.toggleAlt,
              onArrow: (direction) => notifier.writeBytes(
                switch (direction) {
                  'left' => [0x1b, 0x5b, 0x44],
                  'up' => [0x1b, 0x5b, 0x41],
                  'down' => [0x1b, 0x5b, 0x42],
                  _ => [0x1b, 0x5b, 0x43],
                },
              ),
              onWrite: notifier.write,
              onWriteBytes: notifier.writeBytes,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalBody(
    BuildContext context,
    TerminalTabsState state,
    TerminalTab? active,
    Color bgColor,
    Color fgColor,
    Color cursorColor,
    TerminalSettings settings,
    TerminalTabsNotifier notifier,
  ) {
    if (state.preparing || state.creating) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: cursorColor),
            const SizedBox(height: 16),
            Text(
              state.stage ?? '正在启动终端…',
              style: painting.TextStyle(color: fgColor.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (state.error != null && active == null) {
      return _ErrorView(
        message: state.error!,
        onRetry: () => notifier.prepare(),
        foreground: fgColor,
        background: bgColor,
      );
    }

    if (active == null) {
      return _ErrorView(
        message: '暂无终端会话',
        onRetry: () => notifier.newTab(),
        foreground: fgColor,
        background: bgColor,
        retryLabel: '新建会话',
      );
    }

    return _TerminalViewBody(
      controller: active.controller,
      fontSize: settings.fontSize,
      fontFamily: settings.fontFamily.family,
      cursorStyle: settings.cursorStyle,
      bgColor: bgColor,
      fgColor: fgColor,
      cursorColor: cursorColor,
      notifier: notifier,
    );
  }
}

/// 终端视图主体
class _TerminalViewBody extends ConsumerStatefulWidget {
  final TerminalController controller;
  final double fontSize;
  final String fontFamily;
  final TerminalCursorStyle cursorStyle;
  final Color bgColor;
  final Color fgColor;
  final Color cursorColor;
  final TerminalTabsNotifier notifier;

  const _TerminalViewBody({
    required this.controller,
    required this.fontSize,
    required this.fontFamily,
    required this.cursorStyle,
    required this.bgColor,
    required this.fgColor,
    required this.cursorColor,
    required this.notifier,
  });

  @override
  ConsumerState<_TerminalViewBody> createState() => _TerminalViewBodyState();
}

class _TerminalViewBodyState extends ConsumerState<_TerminalViewBody> {
  @override
  void initState() {
    super.initState();
    widget.controller.onScreenUpdated = () {
      if (mounted) setState(() {});
    };
  }

  @override
  Widget build(BuildContext context) {
    return TerminalView(
      key: ValueKey(widget.controller),
      controller: widget.controller,
      fontConfig: TerminalFontConfig(
        fontSize: widget.fontSize,
        fontFamily: widget.fontFamily,
        height: 1.35,
      ),
      foreground: widget.fgColor,
      background: widget.bgColor,
      cursorColor: widget.cursorColor,
      selectionColor: widget.fgColor.withValues(alpha: 0.25),
      cursorStyle: switch (widget.cursorStyle) {
        TerminalCursorStyle.block => TerminalCursorRenderStyle.block,
        TerminalCursorStyle.underline => TerminalCursorRenderStyle.underline,
        TerminalCursorStyle.bar => TerminalCursorRenderStyle.bar,
      },
      autofocus: true,
      onUserInput: (bytes) {
        final tab = widget.notifier.state.active;
        if (tab == null) return;
        // 通过 shell 通道发送用户输入到终端进程
        tab.pty?.write(Uint8List.fromList(bytes));
      },
      onPtyOutput: (bytes) {
        widget.controller.feedOutput(bytes);
        setState(() {});
      },
      onScreenUpdated: () {
        setState(() {});
      },
      onTitleChanged: (title) {
        // 标题变更由外部处理
      },
    );
  }
}

/// 左侧会话抽屉
class _SessionDrawer extends StatelessWidget {
  final TerminalTabsState state;
  final VoidCallback onNewTab;
  final void Function(String id) onActivate;
  final void Function(String id) onClose;
  final VoidCallback onSettings;

  const _SessionDrawer({
    required this.state,
    required this.onNewTab,
    required this.onActivate,
    required this.onClose,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessions = state.tabs.where((t) => !t.mirror).toList();

    return Drawer(
      width: 300,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Text(
                    '终端会话',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Iconfont.plus, size: 20),
                    tooltip: '新建会话',
                    onPressed: onNewTab,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: sessions.isEmpty
                  ? Center(
                      child: Text(
                        '暂无会话',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final tab = sessions[index];
                        final isActive = tab.id == state.activeTabId;
                        return ListTile(
                          selected: isActive,
                          leading: Icon(
                            Iconfont.terminal,
                            size: 18,
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          title: Text(
                            tab.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            tab.running ? '运行中' : '已退出',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: tab.running
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Iconfont.x, size: 16),
                            tooltip: '关闭',
                            onPressed: () => onClose(tab.id),
                          ),
                          onTap: () => onActivate(tab.id),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Iconfont.settings, size: 20),
              title: const Text('终端设置'),
              onTap: onSettings,
            ),
            ListTile(
              leading: const Icon(Iconfont.x, size: 20),
              title: const Text('关闭终端'),
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// 启动失败视图
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Color foreground;
  final Color background;
  final String retryLabel;

  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.foreground,
    required this.background,
    this.retryLabel = '重试',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconfont.alertCircle, size: 48, color: foreground.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: painting.TextStyle(color: foreground.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: Text(retryLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
