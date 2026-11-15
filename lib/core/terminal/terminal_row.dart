import 'dart:typed_data';

import 'terminal_style.dart';

/// 终端的一行：字符码点 + 前景色 + 背景色 + 属性。
///
/// 用四个平行的 Int32List 存储，宽字符占两格（右半格打 [CellAttr.wideTail] 标记）。
class TerminalRow {
  int columns;

  Int32List _chars;
  Int32List _fg;
  Int32List _bg;
  Int32List _attrs;

  TerminalRow(this.columns)
      : _chars = Int32List(columns),
        _fg = Int32List(columns),
        _bg = Int32List(columns),
        _attrs = Int32List(columns) {
    clear(0, columns);
  }

  int getChar(int col) => (col < 0 || col >= columns) ? 0x20 : _chars[col];
  int getFg(int col) => (col < 0 || col >= columns) ? kDefaultColor : _fg[col];
  int getBg(int col) => (col < 0 || col >= columns) ? kDefaultColor : _bg[col];
  int getAttrs(int col) => (col < 0 || col >= columns) ? 0 : _attrs[col];

  void setCell(
    int col,
    int codePoint,
    int fg,
    int bg,
    int attrs,
  ) {
    if (col < 0 || col >= columns) return;
    _chars[col] = codePoint;
    _fg[col] = fg;
    _bg[col] = bg;
    _attrs[col] = attrs;
  }

  /// 用空白覆盖 [from, to) 区间（末尾不含）。
  void clear(int from, int to, {int fg = kDefaultColor, int bg = kDefaultColor}) {
    final start = from.clamp(0, columns);
    final end = to.clamp(0, columns);
    if (start >= end) return;
    _chars.fillRange(start, end, 0x20);
    _fg.fillRange(start, end, fg);
    _bg.fillRange(start, end, bg);
    _attrs.fillRange(start, end, 0);
  }

  /// 从 [src] 复制 [from, to) 到本行的 [dest] 起始位置。
  void copyRange(TerminalRow src, int from, int to, int dest) {
    final count = (to - from).clamp(0, columns - dest);
    if (count <= 0) return;
    for (var i = 0; i < count; i++) {
      final s = from + i;
      if (s < 0 || s >= src.columns) continue;
      _chars[dest + i] = src._chars[s];
      _fg[dest + i] = src._fg[s];
      _bg[dest + i] = src._bg[s];
      _attrs[dest + i] = src._attrs[s];
    }
  }

  /// 在 [at] 处插入 [count] 个空白格，右侧内容右移。
  void insertCells(int at, int count, int fg, int bg) {
    if (at < 0 || at >= columns || count <= 0) return;
    final moveCount = columns - at - count;
    for (var i = columns - 1; i >= at + count; i--) {
      _chars[i] = _chars[i - count];
      _fg[i] = _fg[i - count];
      _bg[i] = _bg[i - count];
      _attrs[i] = _attrs[i - count];
    }
    if (moveCount < 0) {
      // count 超出剩余宽度：整段清空
      clear(at, columns, fg: fg, bg: bg);
      return;
    }
    clear(at, at + count, fg: fg, bg: bg);
  }

  /// 删除 [at] 起的 [count] 个字符，右侧内容左移。
  void deleteCells(int at, int count, int fg, int bg) {
    if (at < 0 || at >= columns || count <= 0) return;
    for (var i = at; i < columns; i++) {
      final src = i + count;
      if (src < columns) {
        _chars[i] = _chars[src];
        _fg[i] = _fg[src];
        _bg[i] = _bg[src];
        _attrs[i] = _attrs[src];
      } else {
        _chars[i] = 0x20;
        _fg[i] = fg;
        _bg[i] = bg;
        _attrs[i] = 0;
      }
    }
  }

  /// 行尾是否有可见内容（用于读取文本）。
  int get textEnd {
    var end = columns;
    while (end > 0 && _chars[end - 1] == 0x20 && _attrs[end - 1] == 0) {
      end--;
    }
    return end;
  }

  String getText([int start = 0, int? end]) {
    final to = (end ?? columns).clamp(0, columns);
    final from = start.clamp(0, columns);
    if (from >= to) return '';
    final sb = StringBuffer();
    for (var i = from; i < to; i++) {
      if (CellAttr.has(_attrs[i], CellAttr.wideTail)) continue;
      sb.writeCharCode(_chars[i]);
    }
    return sb.toString().trimRight();
  }

  /// 宽度变化：保留左侧内容，右侧补空格。
  void resize(int newColumns) {
    if (newColumns == columns) return;
    final chars = Int32List(newColumns);
    final fg = Int32List(newColumns);
    final bg = Int32List(newColumns);
    final attrs = Int32List(newColumns);
    chars.fillRange(0, newColumns, 0x20);
    fg.fillRange(0, newColumns, kDefaultColor);
    bg.fillRange(0, newColumns, kDefaultColor);
    final count = newColumns < columns ? newColumns : columns;
    for (var i = 0; i < count; i++) {
      chars[i] = _chars[i];
      fg[i] = _fg[i];
      bg[i] = _bg[i];
      attrs[i] = _attrs[i];
    }
    _chars = chars;
    _fg = fg;
    _bg = bg;
    _attrs = attrs;
    columns = newColumns;
  }
}
