import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'terminal_controller.dart';
import 'terminal_renderer.dart';
import 'terminal_row.dart';
import 'terminal_style.dart';

/// 终端视图：绘制 + 键盘/触摸输入 + 自动调整行列数。
class TerminalView extends StatefulWidget {
  final TerminalController controller;
  final TerminalFontConfig fontConfig;
  final Color foreground;
  final Color background;
  final Color cursorColor;
  final Color selectionColor;
  final TerminalCursorRenderStyle cursorStyle;
  final bool autofocus;

  /// 底部附加键的 CTRL/ALT 是否处于按下状态，作用于下一个输入。
  final bool ctrl;
  final bool alt;

  /// 发送用户输入（已经是终端要接收的字节序列对应的字符串）。
  final void Function(String data)? onInput;

  /// 行列数变化，调用方应同步 PTY 尺寸。
  final void Function(int columns, int rows)? onResize;

  /// CTRL/ALT 修饰键被消费后回调，用于复位按钮状态。
  final VoidCallback? onModifiersConsumed;

  /// 请求粘贴（Ctrl+Shift+V）。
  final VoidCallback? onPasteRequest;

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
    this.ctrl = false,
    this.alt = false,
    this.onInput,
    this.onResize,
    this.onModifiersConsumed,
    this.onPasteRequest,
  });

  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'terminal');
  final TextEditingController _textController = TextEditingController();

  Timer? _blinkTimer;
  bool _cursorOn = true;

  int _scrollOffset = 0;
  int _appliedColumns = 0;
  int _appliedRows = 0;

  int? _selAnchorRow;
  int? _selAnchorCol;
  int? _selRow;
  int? _selCol;
  bool _selecting = false;

  bool _syncingText = false;
  bool _resizeScheduled = false;
  int _wantColumns = 0;
  int _wantRows = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.onScreenUpdated = _onScreenUpdated;
    _textController.addListener(_onEditingChanged);
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!mounted) return;
      setState(() => _cursorOn = !_cursorOn);
    });
  }

  @override
  void didUpdateWidget(TerminalView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.onScreenUpdated = null;
      widget.controller.onScreenUpdated = _onScreenUpdated;
      _scrollOffset = 0;
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _textController.removeListener(_onEditingChanged);
    _textController.dispose();
    _focusNode.dispose();
    widget.controller.onScreenUpdated = null;
    super.dispose();
  }

  void _onScreenUpdated() {
    if (!mounted) return;
    setState(() {});
  }

  // ---------------------------------------------------------------- 输入

  void _sendRaw(String data) {
    if (data.isEmpty) return;
    widget.onInput?.call(data);
  }

  /// 应用 CTRL/ALT 按钮状态后发送文本。
  void _sendWithModifiers(String text) {
    var data = text;
    if (widget.ctrl && text.length == 1) {
      final code = text.codeUnitAt(0);
      if (code >= 0x61 && code <= 0x7A) {
        data = String.fromCharCode(code - 0x60);
      } else if (code >= 0x41 && code <= 0x5A) {
        data = String.fromCharCode(code - 0x40);
      } else if (code == 0x20) {
        data = String.fromCharCode(0);
      }
    } else if (widget.ctrl) {
      data = '\x1b$text';
    }
    if (widget.alt) {
      data = '\x1b$data';
    }
    if (widget.ctrl || widget.alt) {
      widget.onModifiersConsumed?.call();
    }
    _sendRaw(data);
  }

  void _onEditingChanged() {
    if (_syncingText) return;
    final value = _textController.value;
    // 输入法组词中先不发送
    if (value.composing.isValid) return;
    final text = value.text;
    if (text.isEmpty) return;

    _syncingText = true;
    _textController.value = TextEditingValue.empty;
    _syncingText = false;

    _sendWithModifiers(text);
    _scrollOffset = 0;
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    final key = event.logicalKey;
    final isCtrl = keyboard.isControlPressed;
    final isShift = keyboard.isShiftPressed;

    if (isCtrl && isShift && key == LogicalKeyboardKey.keyV) {
      widget.onPasteRequest?.call();
      return KeyEventResult.handled;
    }

    String? sequence;
    // 应用光标键模式（DECCKM，vim/less 会开启）：方向键用 SS3 前缀
    final appCursor = widget.controller.screen.appCursorKeys;
    final cursorPrefix = appCursor ? '\x1bO' : '\x1b[';
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      sequence = '\r';
    } else if (key == LogicalKeyboardKey.backspace) {
      sequence = '\x7f';
    } else if (key == LogicalKeyboardKey.tab) {
      sequence = isShift ? '\x1b[Z' : '\t';
    } else if (key == LogicalKeyboardKey.escape) {
      sequence = '\x1b';
    } else if (key == LogicalKeyboardKey.arrowUp) {
      sequence = '${cursorPrefix}A';
    } else if (key == LogicalKeyboardKey.arrowDown) {
      sequence = '${cursorPrefix}B';
    } else if (key == LogicalKeyboardKey.arrowRight) {
      sequence = '${cursorPrefix}C';
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      sequence = '${cursorPrefix}D';
    } else if (key == LogicalKeyboardKey.home) {
      sequence = '${cursorPrefix}H';
    } else if (key == LogicalKeyboardKey.end) {
      sequence = '${cursorPrefix}F';
    } else if (key == LogicalKeyboardKey.delete) {
      sequence = '\x1b[3~';
    } else if (key == LogicalKeyboardKey.insert) {
      sequence = '\x1b[2~';
    } else if (key == LogicalKeyboardKey.pageUp) {
      sequence = '\x1b[5~';
    } else if (key == LogicalKeyboardKey.pageDown) {
      sequence = '\x1b[6~';
    } else if (key == LogicalKeyboardKey.f1) {
      sequence = '\x1bOP';
    } else if (key == LogicalKeyboardKey.f2) {
      sequence = '\x1bOQ';
    } else if (key == LogicalKeyboardKey.f3) {
      sequence = '\x1bOR';
    } else if (key == LogicalKeyboardKey.f4) {
      sequence = '\x1bOS';
    } else if (key == LogicalKeyboardKey.f5) {
      sequence = '\x1b[15~';
    } else if (key == LogicalKeyboardKey.f6) {
      sequence = '\x1b[17~';
    } else if (key == LogicalKeyboardKey.f7) {
      sequence = '\x1b[18~';
    } else if (key == LogicalKeyboardKey.f8) {
      sequence = '\x1b[19~';
    } else if (key == LogicalKeyboardKey.f9) {
      sequence = '\x1b[20~';
    } else if (key == LogicalKeyboardKey.f10) {
      sequence = '\x1b[21~';
    } else if (key == LogicalKeyboardKey.f11) {
      sequence = '\x1b[23~';
    } else if (key == LogicalKeyboardKey.f12) {
      sequence = '\x1b[24~';
    } else if (isCtrl) {
      // Ctrl+字母 → 控制字符
      final label = key.keyLabel.toUpperCase();
      if (label.length == 1) {
        final code = label.codeUnitAt(0);
        if (code >= 0x40 && code <= 0x5F) {
          sequence = String.fromCharCode(code - 0x40);
        }
      }
    }

    if (sequence == null) return KeyEventResult.ignored;
    _sendRaw(sequence);
    _scrollOffset = 0;
    return KeyEventResult.handled;
  }

  // ---------------------------------------------------------------- 触摸

  Size _cellSize() => TerminalFontMetrics.cellSize(widget.fontConfig);

  ({int col, int row}) _cellAt(Offset local) {
    final cell = _cellSize();
    final screen = widget.controller.screen;
    final col = (local.dx / cell.width).floor().clamp(0, screen.columns - 1);
    final viewRow =
        (local.dy / cell.height).floor().clamp(0, screen.rows - 1) - _scrollOffset;
    return (col: col, row: viewRow);
  }

  void _startSelection(Offset local) {
    final cell = _cellAt(local);
    setState(() {
      _selecting = true;
      _selAnchorRow = cell.row;
      _selAnchorCol = cell.col;
      _selRow = cell.row;
      _selCol = cell.col;
      _focusNode.requestFocus();
    });
  }

  void _updateSelection(Offset local) {
    if (!_selecting) return;
    final cell = _cellAt(local);
    setState(() {
      _selRow = cell.row;
      _selCol = cell.col;
    });
  }

  TerminalSelection? get _selection {
    if (_selAnchorRow == null || _selRow == null) return null;
    var startRow = _selAnchorRow!;
    var startCol = _selAnchorCol!;
    var endRow = _selRow!;
    var endCol = _selCol!;
    if (endRow < startRow || (endRow == startRow && endCol < startCol)) {
      final row = startRow;
      final col = startCol;
      startRow = endRow;
      startCol = endCol;
      endRow = row;
      endCol = col;
    }
    return TerminalSelection(
      startRow: startRow,
      startCol: startCol,
      endRow: endRow,
      endCol: endCol,
    );
  }

  String _selectedText() {
    final sel = _selection;
    if (sel == null) return '';
    final screen = widget.controller.screen;
    final buffer = StringBuffer();
    for (var row = sel.startRow; row <= sel.endRow; row++) {
      final line = screen.rowAt(row);
      if (line == null) continue;
      final from = row == sel.startRow ? sel.startCol : 0;
      final to = row == sel.endRow ? sel.endCol + 1 : screen.columns;
      buffer.writeln(_sliceRow(line, from, to));
    }
    return buffer.toString().trimRight();
  }

  String _sliceRow(TerminalRow row, int from, int to) {
    final buffer = StringBuffer();
    for (var col = from; col < to && col < row.columns; col++) {
      if (CellAttr.has(row.getAttrs(col), CellAttr.wideTail)) continue;
      buffer.writeCharCode(row.getChar(col));
    }
    return buffer.toString().trimRight();
  }

  Future<void> _finishSelection() async {
    if (!_selecting) return;
    setState(() => _selecting = false);
    final text = _selectedText();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
  }

  void _clearSelection() {
    if (_selAnchorRow == null && _selRow == null) return;
    setState(() {
      _selAnchorRow = null;
      _selAnchorCol = null;
      _selRow = null;
      _selCol = null;
      _selecting = false;
    });
  }

  // ---------------------------------------------------------------- 布局

  void _scheduleResize(int columns, int rows) {
    _wantColumns = columns;
    _wantRows = rows;
    if (_resizeScheduled) return;
    _resizeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resizeScheduled = false;
      if (!mounted) return;
      final screen = widget.controller.screen;
      if (_wantColumns == _appliedColumns && _wantRows == _appliedRows) return;
      if (screen.columns == _wantColumns && screen.rows == _wantRows) {
        _appliedColumns = _wantColumns;
        _appliedRows = _wantRows;
        return;
      }
      _appliedColumns = _wantColumns;
      _appliedRows = _wantRows;
      widget.controller.resize(_wantColumns, _wantRows);
      widget.onResize?.call(_wantColumns, _wantRows);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = widget.controller.screen;
    final cell = _cellSize();

    return Focus(
      onKeyEvent: _onKeyEvent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          _focusNode.requestFocus();
          _clearSelection();
        },
        onLongPressStart: (details) => _startSelection(details.localPosition),
        onLongPressMoveUpdate: (details) => _updateSelection(details.localPosition),
        onLongPressEnd: (_) => _finishSelection(),
        onVerticalDragUpdate: (details) {
          final delta = -(details.primaryDelta ?? 0) / cell.height;
          final next = (_scrollOffset + delta).round();
          final clamped = next.clamp(0, screen.scrollbackLength);
          if (clamped != _scrollOffset) {
            setState(() => _scrollOffset = clamped);
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                (constraints.maxWidth / cell.width).floor().clamp(2, 400);
            final rows =
                (constraints.maxHeight / cell.height).floor().clamp(2, 400);
            _scheduleResize(columns, rows);
            if (_scrollOffset > screen.scrollbackLength) {
              _scrollOffset = screen.scrollbackLength;
            }

            return Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: TerminalRenderer(
                        screen: screen,
                        fontConfig: widget.fontConfig,
                        foreground: widget.foreground,
                        background: widget.background,
                        cursorColor: widget.cursorColor,
                        selectionColor: widget.selectionColor,
                        cursorRenderStyle: widget.cursorStyle,
                        cursorVisible: _cursorOn || !screen.blinkCursor,
                        cursorEnabled: screen.cursorVisible,
                        scrollOffset: _scrollOffset,
                        selection: _selection,
                      ),
                    ),
                  ),
                ),
                // 隐藏输入框：软键盘 / 中文输入法需要 TextInput 连接才能送字
                Positioned(
                  left: 0,
                  top: 0,
                  width: 1,
                  height: 1,
                  child: Opacity(
                    opacity: 0.01,
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      autofocus: widget.autofocus,
                      showCursor: false,
                      enableInteractiveSelection: false,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.none,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.transparent,
                        fontSize: 1,
                        height: 1,
                      ),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
