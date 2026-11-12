/// 终端单行缓冲区，移植自 Termux TerminalRow。
class TerminalRow {
  final int _columns;
  final List<int> _chars = [];
  final List<int> _styles = [];

  TerminalRow(this._columns, int defaultStyle) {
    _chars.addAll(List.filled(_columns, 0x20));
    _styles.addAll(List.filled(_columns, defaultStyle));
  }

  /// 获取指定列的字符码点。
  int getChar(int col) {
    if (col < 0 || col >= _columns) return 0;
    return _chars[col];
  }

  /// 获取指定列的样式。
  int getStyle(int col) {
    if (col < 0 || col >= _columns) return 0;
    return _styles[col];
  }

  /// 设置指定列的字符和样式。
  void setChar(int col, int codePoint, int style) {
    if (col < 0 || col >= _columns) return;
    _chars[col] = codePoint;
    _styles[col] = style;
  }

  /// 获取指定范围的文本。
  String getText(int start, int end) {
    start = start.clamp(0, _columns);
    end = end.clamp(0, _columns);
    if (start >= end) return '';
    final sb = StringBuffer();
    for (var i = start; i < end; i++) {
      sb.writeCharCode(_chars[i]);
    }
    return sb.toString();
  }

  /// 块设置：将 [startX, endX) 范围的字符设为 space，样式为 [style]。
  void blockSet(int startX, int endX, int codePoint, int style) {
    startX = startX.clamp(0, _columns);
    endX = endX.clamp(0, _columns);
    if (startX >= endX) return;
    for (var i = startX; i < endX; i++) {
      _chars[i] = codePoint;
      _styles[i] = style;
    }
  }

  /// 调整行长度到 [newColumns]。
  void resize(int newColumns) {
    while (_chars.length < newColumns) {
      _chars.add(0x20);
      _styles.add(0);
    }
    while (_chars.length > newColumns) {
      _chars.removeLast();
      _styles.removeLast();
    }
  }

  /// 复制另一行的区间 [startX, endX) 到 [destX]。
  void copyInterval(TerminalRow src, int startX, int endX, int destX) {
    final len = (endX - startX).clamp(0, _columns - destX);
    if (len <= 0) return;
    for (var i = 0; i < len; i++) {
      _chars[destX + i] = src._chars[startX + i];
      _styles[destX + i] = src._styles[startX + i];
    }
  }

  int get columns => _columns;
}
