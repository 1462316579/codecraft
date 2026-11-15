/// 终端视图 Flutter 组件，移植自 Termux TerminalView。
///
/// 负责：
/// - 键盘输入（RawKeyboardListener）
/// - 与 TerminalController 连接，将 PTY 输出渲染到屏幕
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide TextStyle;
import 'package:flutter/services.dart';

import 'terminal.dart';

/// 终端视图：用户交互的主界面
class TerminalView extends StatefulWidget {
  final TerminalController controller;
  final TerminalFontConfig fontConfig;
  final Color foreground;
  final Color background;
  final Color cursorColor;
  final Color selectionColor;
  final TerminalCursorRenderStyle cursorStyle;
  final bool autofocus;

  final void Function(List<int> bytes)? onUserInput;
  final void Function(List<int> bytes)? onPtyOutput;
  final VoidCallback? onScreenUpdated;
  final ValueChanged<String>? onTitleChanged;
  final VoidCallback? onCopyToClipboard;
  final VoidCallback? onPasteFromClipboard;

  const TerminalView({
    super.key,
    required this.controller,
    required this.fontConfig,
    required this.foreground,
    required this.background,
    required this.cursorColor,
    required this.selectionColor,
    this.cursorStyle = TerminalCursorRenderStyle.block,
    this.autofocus = true,
    this.onUserInput,
    this.onPtyOutput,
    this.onScreenUpdated,
    this.onTitleChanged,
    this.onCopyToClipboard,
    this.onPasteFromClipboard,
  });

  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView> {
  late FocusNode _focusNode;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    widget.controller.onScreenUpdated = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final buffer = controller.buffer;

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKey: _onKeyEvent,
      child: GestureDetector(
        onTapDown: (_) => _focusNode.requestFocus(),
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: TerminalRenderer(
              buffer: buffer,
              fontConfig: widget.fontConfig,
              foreground: widget.foreground,
              background: widget.background,
              cursorColor: widget.cursorColor,
              selectionColor: widget.selectionColor,
              cursorRenderStyle: widget.cursorStyle,
              cursorVisible: true,
              cursorEnabled: true,
              scrollOffset: _scrollOffset,
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _onKeyEvent(FocusNode node, RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return KeyEventResult.ignored;

    final logicalKey = event.logicalKey;
    final isCtrl = event.isControlPressed;
    final isAlt = event.isAltPressed;
    final isShift = event.isShiftPressed;

    void sendToPty(List<int> bytes) {
      widget.onUserInput?.call(bytes);
    }

    // Ctrl+C
    if (isCtrl && logicalKey == LogicalKeyboardKey.keyC) {
      sendToPty([0x03]);
      return KeyEventResult.handled;
    }
    // Ctrl+D
    if (isCtrl && logicalKey == LogicalKeyboardKey.keyD) {
      sendToPty([0x04]);
      return KeyEventResult.handled;
    }
    // Ctrl+Z
    if (isCtrl && logicalKey == LogicalKeyboardKey.keyZ) {
      sendToPty([0x1A]);
      return KeyEventResult.handled;
    }
    // Ctrl+L
    if (isCtrl && logicalKey == LogicalKeyboardKey.keyL) {
      sendToPty([0x0C]);
      return KeyEventResult.handled;
    }
    // Tab
    if (logicalKey == LogicalKeyboardKey.tab) {
      sendToPty(isShift ? [0x1B, 0x5B, 0x5A] : [0x09]);
      return KeyEventResult.handled;
    }
    // ESC
    if (logicalKey == LogicalKeyboardKey.escape) {
      sendToPty([0x1B]);
      return KeyEventResult.handled;
    }
    // Enter
    if (logicalKey == LogicalKeyboardKey.enter ||
        logicalKey == LogicalKeyboardKey.numpadEnter) {
      sendToPty([0x0D]);
      return KeyEventResult.handled;
    }
    // Backspace
    if (logicalKey == LogicalKeyboardKey.backspace) {
      sendToPty([0x08]);
      return KeyEventResult.handled;
    }
    // Delete
    if (logicalKey == LogicalKeyboardKey.delete) {
      sendToPty([0x1B, 0x5B, 0x33, 0x7E]);
      return KeyEventResult.handled;
    }
    // Home / End
    if (logicalKey == LogicalKeyboardKey.home) {
      sendToPty([0x1B, 0x5B, 0x48]);
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.end) {
      sendToPty([0x1B, 0x5B, 0x46]);
      return KeyEventResult.handled;
    }
    // PageUp / PageDown
    if (logicalKey == LogicalKeyboardKey.pageUp) {
      sendToPty([0x1B, 0x5B, 0x35, 0x7E]);
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.pageDown) {
      sendToPty([0x1B, 0x5B, 0x36, 0x7E]);
      return KeyEventResult.handled;
    }
    // Insert
    if (logicalKey == LogicalKeyboardKey.insert) {
      sendToPty([0x1B, 0x5B, 0x32, 0x7E]);
      return KeyEventResult.handled;
    }
    // F1-F12
    for (var i = 1; i <= 12; i++) {
      final keyName = 'keyF$i';
      final key = LogicalKeyboardKey.byDebugName(keyName);
      if (logicalKey == key) {
        sendToPty([0x1B, 0x5B, 0x31, 0x30 + (i ~/ 10), 0x30 + (i % 10), 0x7E]);
        return KeyEventResult.handled;
      }
    }
    // Ctrl+Shift+C: 复制到剪贴板
    if (isCtrl && isShift && logicalKey == LogicalKeyboardKey.keyC) {
      widget.onCopyToClipboard?.call();
      return KeyEventResult.handled;
    }
    // Ctrl+Shift+V: 从剪贴板粘贴
    if (isCtrl && isShift && logicalKey == LogicalKeyboardKey.keyV) {
      widget.onPasteFromClipboard?.call();
      return KeyEventResult.handled;
    }
    // 方向键
    if (logicalKey == LogicalKeyboardKey.arrowLeft) {
      sendToPty([0x1B, 0x5B, 0x44]);
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.arrowRight) {
      sendToPty([0x1B, 0x5B, 0x43]);
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.arrowUp) {
      sendToPty([0x1B, 0x5B, 0x41]);
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.arrowDown) {
      sendToPty([0x1B, 0x5B, 0x42]);
      return KeyEventResult.handled;
    }
    // 字符输入
    if (event.character != null && event.character!.isNotEmpty) {
      final char = event.character!;
      final codeUnits = utf8.encode(char);

      if (isCtrl && !isAlt && codeUnits.length == 1) {
        final byte = codeUnits[0];
        if (byte >= 0x61 && byte <= 0x7A) {
          sendToPty([byte - 0x60]);
        } else if (byte >= 0x41 && byte <= 0x5A) {
          sendToPty([byte - 0x40]);
        } else if (byte == 0x20) {
          sendToPty([0x00]);
        } else {
          sendToPty(codeUnits);
        }
      } else {
        if (isAlt) {
          sendToPty([0x1B]);
        }
        sendToPty(codeUnits);
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
