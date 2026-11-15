import 'dart:async';

import 'terminal_row.dart';
import 'text_style.dart';
import 'wc_width.dart';

/// 终端缓冲区：屏幕行 + 滚动历史，移植自 Termux TerminalBuffer。
class TerminalBuffer {
  int columns;
  int rows;
  final int scrollbackRows;

  final List<TerminalRow?> _lines = [];
  int _totalRows = 0;

  TerminalRow? _screen;
  List<TerminalRow?> _altLines = [];
  int _altTotalRows = 0;

  int _topLine = 0;

  int _cursorX = 0;
  int _cursorY = 0;

  bool _cursorEnabled = true;
  bool _cursorVisible = true;

  int _scrollTop = 0;
  int _scrollBottom = -1;

  bool _originMode = false;
  bool _autoWrap = true;

  int _defaultStyle = 0;
  int _currentStyle = 0;

  final Set<int> _tabStops = {};

  void Function()? onScreenUpdated;

  TerminalBuffer({
    required this.columns,
    required this.rows,
    this.scrollbackRows = 2000,
  }) {
    _initTabStops();
    // 必须走 _resizeBuffer：只有它会初始化 _screen / _topLine / _totalRows，
    // 否则 getLine() 始终返回 null，写入的字符会被全部丢弃（终端一片空白）。
    _resizeBuffer(columns, rows);
  }

  void _initTabStops() {
    _tabStops.clear();
    for (var i = 0; i < columns; i += 8) {
      _tabStops.add(i);
    }
  }

  void resize(int newCols, int newRows) {
    columns = newCols;
    rows = newRows;
    _initTabStops();
    _resizeBuffer(newCols, newRows);
  }

  void _resizeBuffer(int newCols, int newRows) {
    _totalRows = newRows + scrollbackRows;
    _lines.clear();
    for (var i = 0; i < _totalRows; i++) {
      _lines.add(TerminalRow(newCols, 0));
    }
    _screen = _lines[scrollbackRows];
    _cursorX = 0;
    _cursorY = 0;
    _topLine = scrollbackRows;
    _altLines.clear();
    _altTotalRows = 0;
    _scrollTop = 0;
    _scrollBottom = newRows - 1;
  }

  void reset() {
    _resizeBuffer(columns, rows);
    _defaultStyle = 0;
    _currentStyle = 0;
    _cursorX = 0;
    _cursorY = 0;
    _originMode = false;
    _autoWrap = true;
    _tabStops.clear();
    _initTabStops();
    if (onScreenUpdated != null) onScreenUpdated!();
  }

  TerminalRow? getLine(int externalRow) {
    if (_screen == null) return null;
    final internalRow = externalToInternalRow(externalRow);
    if (internalRow < 0 || internalRow >= _lines.length) return null;
    return _lines[internalRow];
  }

  int externalToInternalRow(int externalRow) {
    var internalRow = _topLine + externalRow;
    while (internalRow < 0) internalRow += _totalRows;
    while (internalRow >= _totalRows) internalRow -= _totalRows;
    return internalRow % _totalRows;
  }

  int get cursorX => _cursorX;
  int get cursorY => _cursorY;

  void setCursorPosition(int x, int y) {
    _cursorX = x.clamp(0, columns - 1);
    _cursorY = y.clamp(0, rows - 1);
  }

  void moveCursor(int dx, int dy) {
    _cursorX = (_cursorX + dx).clamp(0, columns - 1);
    _cursorY = (_cursorY + dy).clamp(0, rows - 1);
  }

  TerminalRow? get currentRow => getLine(_cursorY);

  int get defaultStyle => _defaultStyle;
  void setDefaultStyle(int style) => _defaultStyle = style;
  int get currentStyle => _currentStyle;
  void setCurrentStyle(int style) => _currentStyle = style;

  void writeChar(int codePoint, int style) {
    final row = currentRow;
    if (row == null) return;

    final width = WcWidth.wcwidth(codePoint);

    if (width == 0) {
      if (_cursorX > 0) {
        row.setChar(_cursorX - 1, codePoint, style);
      }
      return;
    }

    if (_cursorX + width > columns) {
      if (_autoWrap) {
        _cursorX = 0;
        _cursorY++;
        if (_cursorY >= rows) {
          _scrollDown(1);
          _cursorY = rows - 1;
        }
      } else {
        row.setChar(columns - 1, codePoint, style);
        return;
      }
    }

    final targetRow = currentRow;
    if (targetRow == null) return;

    targetRow.setChar(_cursorX, codePoint, style);

    if (width == 2) {
      if (_cursorX + 1 < columns) {
        targetRow.setChar(
          _cursorX + 1,
          0x20,
          TextStyle.setWideCharRight(style, true),
        );
      }
    }

    _cursorX += width;
  }

  void lineFeed() {
    _cursorX = 0;
    _cursorY++;
    if (_cursorY >= rows) {
      _scrollDown(1);
      _cursorY = rows - 1;
    }
  }

  void carriageReturn() => _cursorX = 0;

  void backspace() {
    if (_cursorX > 0) {
      _cursorX--;
      final row = currentRow;
      if (row != null) {
        row.setChar(_cursorX, 0x20, 0);
      }
    }
  }

  void horizontalTab() {
    var nextTab = _cursorX + 1;
    while (nextTab < columns && !_tabStops.contains(nextTab)) {
      nextTab++;
    }
    if (nextTab < columns) {
      _cursorX = nextTab;
    } else {
      _cursorX = columns - 1;
    }
  }

  void verticalTab() => lineFeed();
  void formFeed() => lineFeed();

  void _scrollDown(int n) {
    final bottom = _scrollBottom >= 0 ? _scrollBottom : rows - 1;
    final top = _scrollTop;
    if (n <= 0) return;
    if (n > bottom - top + 1) n = bottom - top + 1;

    _topLine = (_topLine + n) % _totalRows;

    for (var i = 0; i < n; i++) {
      final visualRow = bottom - i;
      final internalRow = (_topLine + visualRow) % _totalRows;
      _lines[internalRow] = TerminalRow(columns, _defaultStyle);
    }

    if (onScreenUpdated != null) onScreenUpdated!();
  }

  void _scrollUp(int n) {
    final bottom = _scrollBottom >= 0 ? _scrollBottom : rows - 1;
    final top = _scrollTop;
    if (n <= 0) return;
    if (n > bottom - top + 1) n = bottom - top + 1;

    _topLine = (_topLine - n + _totalRows) % _totalRows;

    for (var i = 0; i < n; i++) {
      final visualRow = top + i;
      final internalRow = (_topLine + visualRow) % _totalRows;
      _lines[internalRow] = TerminalRow(columns, _defaultStyle);
    }

    if (onScreenUpdated != null) onScreenUpdated!();
  }

  void fillArea(int x1, int y1, int x2, int y2, int style) {
    for (var y = y1; y <= y2 && y < rows; y++) {
      final row = getLine(y);
      if (row != null) {
        row.blockSet(x1, x2, 0x20, style);
      }
    }
    if (onScreenUpdated != null) onScreenUpdated!();
  }

  void blockCopy(int sx, int sy, int w, int h, int dx, int dy) {
    for (var dy2 = 0; dy2 < h; dy2++) {
      final srcRow = getLine(sy + dy2);
      final dstRow = getLine(dy + dy2);
      if (srcRow != null && dstRow != null) {
        dstRow.copyInterval(srcRow, sx, sx + w, dx);
      }
    }
    if (onScreenUpdated != null) onScreenUpdated!();
  }

  void switchToAltBuffer() {
    if (_altLines.isEmpty) {
      _altTotalRows = rows + scrollbackRows;
      _altLines =
          List.generate(_altTotalRows, (_) => TerminalRow(columns, 0));
    }
    _screen = _altLines[scrollbackRows];
    _topLine = scrollbackRows;
    _cursorX = 0;
    _cursorY = 0;
    if (onScreenUpdated != null) onScreenUpdated!();
  }

  void switchToMainBuffer() {
    _screen = _lines[scrollbackRows];
    _topLine = scrollbackRows;
    if (onScreenUpdated != null) onScreenUpdated!();
  }

  void clearScreen(int mode) {
    final row = currentRow;
    if (row == null) return;
    switch (mode) {
      case 0:
        fillArea(_cursorX, _cursorY, columns - 1, rows - 1, _defaultStyle);
        break;
      case 1:
        fillArea(0, 0, _cursorX, _cursorY, _defaultStyle);
        break;
      case 2:
      case 3:
        fillArea(0, 0, columns - 1, rows - 1, _defaultStyle);
        break;
    }
  }

  void clearLine(int mode) {
    final row = currentRow;
    if (row == null) return;
    switch (mode) {
      case 0:
        row.blockSet(_cursorX, columns, 0x20, _defaultStyle);
        break;
      case 1:
        row.blockSet(0, _cursorX + 1, 0x20, _defaultStyle);
        break;
      case 2:
        row.blockSet(0, columns, 0x20, _defaultStyle);
        break;
    }
  }

  void setScrollRegion(int top, int bottom) {
    _scrollTop = top.clamp(0, rows - 1);
    _scrollBottom = bottom.clamp(_scrollTop, rows - 1);
    _cursorX = 0;
    _cursorY = 0;
  }

  int get scrollTop => _scrollTop;
  int get scrollBottom => _scrollBottom >= 0 ? _scrollBottom : rows - 1;

  bool get originMode => _originMode;
  void setOriginMode(bool enabled) => _originMode = enabled;

  bool get autoWrap => _autoWrap;
  void setAutoWrap(bool enabled) => _autoWrap = enabled;

  bool get cursorEnabled => _cursorEnabled;
  void setCursorEnabled(bool enabled) => _cursorEnabled = enabled;

  bool get cursorVisible => _cursorVisible;
  void setCursorVisible(bool visible) => _cursorVisible = visible;

  int get visibleRows => rows;
  int get visibleCols => columns;

  void setTabStop(int x) => _tabStops.add(x);
  void clearTabStop(int x) => _tabStops.remove(x);
  void clearAllTabStops() => _tabStops.clear();
  bool isTabStop(int x) => _tabStops.contains(x);
}
