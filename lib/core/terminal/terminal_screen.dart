import 'terminal_row.dart';
import 'terminal_style.dart';

/// 终端屏幕模型。
///
/// 设计要点（与旧实现相比刻意保持简单，避免索引环绕带来的错位）：
/// - 主缓冲区用一个线性 List 保存「滚动历史 + 可见区」，可见区始终是末尾 `rows` 行；
///   满屏滚动时把它挪进历史，因此不需要环形索引换算。
/// - 备用缓冲区（vim、less 等全屏程序）独立保存，没有历史。
/// - 光标坐标 `cursorY` 只相对可见区，超出范围由滚动处理。
class TerminalScreen {
  int _columns;
  int _rows;
  final int scrollbackLimit;

  final List<TerminalRow> _main = [];
  final List<TerminalRow> _alt = [];
  bool _altActive = false;

  int _cx = 0;
  int _cy = 0;

  int _savedCx = 0;
  int _savedCy = 0;

  int _scrollTop = 0;
  int _scrollBottom = 0;

  bool _autoWrap = true;
  bool _originMode = false;
  bool _insertMode = false;
  bool _cursorVisible = true;
  bool _blinkCursor = false;
  bool _appCursorKeys = false;
  bool _bracketedPaste = false;

  /// 打印到最后一列后，光标停在原地等待下一次换行（延迟换行）。
  bool _pendingWrap = false;

  /// 内容版本号：每次修改 +1，供渲染层判断是否需要重绘。
  int version = 0;

  TerminalScreen({
    int columns = 80,
    int rows = 24,
    this.scrollbackLimit = 5000,
  })  : _columns = columns,
        _rows = rows {
    _scrollBottom = rows - 1;
    _resetBuffers();
  }

  int get columns => _columns;
  int get rows => _rows;

  int get cursorX => _cx;
  int get cursorY => _cy;

  bool get autoWrap => _autoWrap;
  set autoWrap(bool value) => _autoWrap = value;

  bool get originMode => _originMode;
  set originMode(bool value) => _originMode = value;

  bool get insertMode => _insertMode;
  set insertMode(bool value) => _insertMode = value;

  bool get cursorVisible => _cursorVisible;
  set cursorVisible(bool value) => _cursorVisible = value;

  bool get blinkCursor => _blinkCursor;
  set blinkCursor(bool value) => _blinkCursor = value;

  bool get appCursorKeys => _appCursorKeys;
  set appCursorKeys(bool value) => _appCursorKeys = value;

  bool get bracketedPaste => _bracketedPaste;
  set bracketedPaste(bool value) => _bracketedPaste = value;

  bool get altActive => _altActive;

  int get scrollTop => _scrollTop;
  int get scrollBottom => _scrollBottom;

  /// 可向上滚动的历史行数。
  int get scrollbackLength => _altActive ? 0 : _main.length - _rows;

  void _resetBuffers() {
    _main.clear();
    for (var i = 0; i < _rows; i++) {
      _main.add(TerminalRow(_columns));
    }
    _alt.clear();
    _altActive = false;
    _cx = 0;
    _cy = 0;
    _scrollTop = 0;
    _scrollBottom = _rows - 1;
    _pendingWrap = false;
  }

  /// 取可见区第 [viewRow] 行；负数表示向上翻历史。
  TerminalRow? rowAt(int viewRow) {
    final list = _altActive ? _alt : _main;
    final index = list.length - _rows + viewRow;
    if (index < 0 || index >= list.length) return null;
    return list[index];
  }

  TerminalRow? get _currentRow => rowAt(_cy);

  /// 本地回显（非 PTY）时直接写一行文本。
  void writeLocal(String text) {
    for (final rune in text.runes) {
      if (rune == 0x0A) {
        lineFeed();
      } else if (rune == 0x0D) {
        carriageReturn();
      } else {
        putChar(rune, 1, kDefaultColor, kDefaultColor, 0);
      }
    }
  }

  void putChar(int codePoint, int width, int fg, int bg, int attrs) {
    if (width <= 0) {
      // 组合字符：附加到前一格（简化：覆盖为组合字符本身，保证可见）
      final row = _currentRow;
      if (row != null && _cx > 0) {
        row.setCell(_cx - 1, codePoint, fg, bg, attrs);
        version++;
      }
      return;
    }

    if (_pendingWrap) {
      _cx = 0;
      _indexDown();
      _pendingWrap = false;
    }

    if (_cx + width > _columns) {
      _cx = 0;
      _indexDown();
    }

    final row = _currentRow;
    if (row == null) return;

    if (_insertMode && width == 1) {
      row.insertCells(_cx, 1, fg, bg);
    }

    row.setCell(_cx, codePoint, fg, bg, attrs);
    if (width == 2) {
      // 宽字符第二格：标记为尾部，渲染时跳过
      if (_cx + 1 < _columns) {
        row.setCell(_cx + 1, 0x20, fg, bg, attrs | CellAttr.wideTail);
      }
    }

    if (_cx + width >= _columns) {
      _cx = _columns - 1;
      _pendingWrap = true;
    } else {
      _cx += width;
    }
    version++;
  }

  void carriageReturn() {
    _cx = 0;
    _pendingWrap = false;
    version++;
  }

  void lineFeed() {
    _pendingWrap = false;
    _indexDown();
  }

  void backspace() {
    if (_cx > 0) {
      _cx--;
      _pendingWrap = false;
      version++;
    }
  }

  void tab() {
    final next = ((_cx ~/ 8) + 1) * 8;
    _cx = next < _columns ? next : _columns - 1;
    _pendingWrap = false;
    version++;
  }

  void backTab() {
    final prev = ((_cx - 1) ~/ 8) * 8;
    _cx = prev > 0 ? prev : 0;
    _pendingWrap = false;
    version++;
  }

  /// 光标下移一行；到底部则滚动。
  void _indexDown() {
    if (_cy == _scrollBottom) {
      scrollUp(1);
    } else if (_cy < _rows - 1) {
      _cy++;
    }
    version++;
  }

  bool scrollUp(int count) {
    if (count <= 0) return false;
    final top = _scrollTop;
    final bottom = _scrollBottom;
    final regionHeight = bottom - top + 1;

    if (_altActive) {
      for (var i = 0; i < count; i++) {
        if (top < _alt.length) _alt.removeAt(top);
        _alt.insert(bottom.clamp(0, _alt.length), TerminalRow(_columns));
      }
      version++;
      return true;
    }

    if (top == 0 && bottom == _rows - 1) {
      // 整屏滚动：可见区 = 列表末尾 rows 行，因此直接追加新行即可，
      // 原来的顶行自然落入历史（不要 removeAt，否则历史永远为空）。
      for (var i = 0; i < count; i++) {
        _main.add(TerminalRow(_columns));
      }
      while (_main.length > _rows + scrollbackLimit) {
        _main.removeAt(0);
      }
      version++;
      return true;
    }

    final span = count > regionHeight ? regionHeight : count;
    final visibleStart = _main.length - _rows;
    for (var i = 0; i < span; i++) {
      _main.removeAt(visibleStart + top);
      _main.insert(visibleStart + bottom, TerminalRow(_columns));
    }
    version++;
    return true;
  }

  bool scrollDown(int count) {
    if (count <= 0) return false;
    final top = _scrollTop;
    final bottom = _scrollBottom;
    final regionHeight = bottom - top + 1;
    final span = count > regionHeight ? regionHeight : count;

    if (_altActive) {
      for (var i = 0; i < span; i++) {
        _alt.removeAt(bottom.clamp(0, _alt.length - 1));
        _alt.insert(top.clamp(0, _alt.length), TerminalRow(_columns));
      }
      version++;
      return true;
    }

    final visibleStart = _main.length - _rows;
    for (var i = 0; i < span; i++) {
      _main.removeAt(visibleStart + bottom);
      _main.insert(visibleStart + top, TerminalRow(_columns));
    }
    version++;
    return true;
  }

  void moveCursorTo(int row, int col) {
    final top = _originMode ? _scrollTop : 0;
    final bottom = _originMode ? _scrollBottom : _rows - 1;
    _cy = (top + row).clamp(0, bottom);
    _cx = col.clamp(0, _columns - 1);
    _pendingWrap = false;
    version++;
  }

  void moveCursorUp(int count) {
    final limit = _originMode ? _scrollTop : 0;
    _cy = (_cy - count).clamp(limit, _rows - 1);
    _pendingWrap = false;
    version++;
  }

  void moveCursorDown(int count) {
    final limit = _originMode ? _scrollBottom : _rows - 1;
    _cy = (_cy + count).clamp(0, limit);
    _pendingWrap = false;
    version++;
  }

  void moveCursorForward(int count) {
    _cx = (_cx + count).clamp(0, _columns - 1);
    _pendingWrap = false;
    version++;
  }

  void moveCursorBack(int count) {
    _cx = (_cx - count).clamp(0, _columns - 1);
    _pendingWrap = false;
    version++;
  }

  void moveCursorToColumn(int col) {
    _cx = (col - 1).clamp(0, _columns - 1);
    _pendingWrap = false;
    version++;
  }

  void setScrollRegion(int top, int bottom) {
    var t = top.clamp(0, _rows - 1);
    var b = bottom.clamp(0, _rows - 1);
    if (b <= t) {
      t = 0;
      b = _rows - 1;
    }
    _scrollTop = t;
    _scrollBottom = b;
    moveCursorTo(0, 0);
  }

  /// 擦除显示区域。[mode] 0=光标到末尾 1=开头到光标 2=全部 3=全部并清历史。
  void eraseInDisplay(int mode) {
    switch (mode) {
      case 0:
        _eraseRowRange(_cx, _columns);
        for (var y = _cy + 1; y < _rows; y++) {
          rowAt(y)?.clear(0, _columns);
        }
        break;
      case 1:
        _eraseRowRange(0, _cx + 1);
        for (var y = 0; y < _cy; y++) {
          rowAt(y)?.clear(0, _columns);
        }
        break;
      case 2:
        for (var y = 0; y < _rows; y++) {
          rowAt(y)?.clear(0, _columns);
        }
        break;
      case 3:
        for (var y = 0; y < _rows; y++) {
          rowAt(y)?.clear(0, _columns);
        }
        if (!_altActive) {
          // 清空滚动历史
          while (_main.length > _rows) {
            _main.removeAt(0);
          }
        }
        break;
    }
    version++;
  }

  /// 擦除整行/行首/行尾。
  void eraseInLine(int mode) {
    switch (mode) {
      case 0:
        _eraseRowRange(_cx, _columns);
        break;
      case 1:
        _eraseRowRange(0, _cx + 1);
        break;
      case 2:
        _eraseRowRange(0, _columns);
        break;
    }
    version++;
  }

  void _eraseRowRange(int from, int to) {
    _currentRow?.clear(from, to);
  }

  void insertLines(int count) {
    var n = count <= 0 ? 1 : count;
    if (_cy < _scrollTop || _cy > _scrollBottom) return;
    final regionHeight = _scrollBottom - _cy + 1;
    if (n > regionHeight) n = regionHeight;
    final list = _altActive ? _alt : _main;
    final visibleStart = list.length - _rows;
    for (var i = 0; i < n; i++) {
      list.removeAt(visibleStart + _scrollBottom);
      list.insert(visibleStart + _cy, TerminalRow(_columns));
    }
    version++;
  }

  void deleteLines(int count) {
    var n = count <= 0 ? 1 : count;
    if (_cy < _scrollTop || _cy > _scrollBottom) return;
    final regionHeight = _scrollBottom - _cy + 1;
    if (n > regionHeight) n = regionHeight;
    final list = _altActive ? _alt : _main;
    final visibleStart = list.length - _rows;
    for (var i = 0; i < n; i++) {
      list.removeAt(visibleStart + _cy);
      list.insert(visibleStart + _scrollBottom, TerminalRow(_columns));
    }
    version++;
  }

  void insertChars(int count) {
    final row = _currentRow;
    if (row == null) return;
    row.insertCells(_cx, count <= 0 ? 1 : count, kDefaultColor, kDefaultColor);
    version++;
  }

  void deleteChars(int count) {
    final row = _currentRow;
    if (row == null) return;
    row.deleteCells(_cx, count <= 0 ? 1 : count, kDefaultColor, kDefaultColor);
    version++;
  }

  void eraseChars(int count) {
    final row = _currentRow;
    if (row == null) return;
    final n = count <= 0 ? 1 : count;
    row.clear(_cx, (_cx + n).clamp(0, _columns));
    version++;
  }

  void saveCursor() {
    _savedCx = _cx;
    _savedCy = _cy;
  }

  void restoreCursor() {
    _cx = _savedCx.clamp(0, _columns - 1);
    _cy = _savedCy.clamp(0, _rows - 1);
    _pendingWrap = false;
    version++;
  }

  void enterAltScreen({bool clear = true}) {
    if (!_altActive) {
      _savedCx = _cx;
      _savedCy = _cy;
      _altActive = true;
      _alt
        ..clear()
        ..addAll(List.generate(_rows, (_) => TerminalRow(_columns)));
    }
    if (clear) {
      for (final row in _alt) {
        row.clear(0, _columns);
      }
    }
    _cx = 0;
    _cy = 0;
    _pendingWrap = false;
    version++;
  }

  void exitAltScreen({bool restoreCursor = true}) {
    if (!_altActive) return;
    _altActive = false;
    _alt.clear();
    if (restoreCursor) {
      _cx = _savedCx.clamp(0, _columns - 1);
      _cy = _savedCy.clamp(0, _rows - 1);
    }
    _pendingWrap = false;
    version++;
  }

  void reset() {
    _autoWrap = true;
    _originMode = false;
    _insertMode = false;
    _cursorVisible = true;
    _blinkCursor = false;
    _appCursorKeys = false;
    _bracketedPaste = false;
    _resetBuffers();
    version++;
  }

  /// 改变尺寸：可见区必须始终包含光标所在行。
  ///
  /// 不能简单保留缓冲区末尾 `rows` 行：终端刚打开时光标在第 0 行，
  /// 尺寸收缩（软键盘弹出等）会把光标行推进历史，随后 shell 在新位置
  /// 重绘提示符，等尺寸恢复时提示符就停在屏幕中间，表现为「光标和提示符错位」。
  void resize(int columns, int rows) {
    if (columns == _columns && rows == _rows) return;

    final oldRows = _rows;
    final visibleStart = _main.length - oldRows;
    final cursorIndex = visibleStart + _cy;

    _columns = columns;
    _rows = rows;
    _scrollTop = 0;
    _scrollBottom = rows - 1;

    if (rows < oldRows) {
      if (_cy < rows) {
        // 光标仍在新的可见区内：丢弃视口下方的行（本来就看不见）。
        final keep = visibleStart + rows;
        if (_main.length > keep) _main.removeRange(keep, _main.length);
      } else {
        // 光标落在新视口之外：保留光标行及其上方内容，丢弃其下方内容，
        // 光标停在新的最后一行。
        final keep = cursorIndex + 1;
        if (_main.length > keep) _main.removeRange(keep, _main.length);
        _cy = rows - 1;
      }
    }

    for (final row in _main) {
      row.resize(columns);
    }
    while (_main.length < visibleStart + rows) {
      _main.add(TerminalRow(columns));
    }
    while (_main.length > rows + scrollbackLimit) {
      _main.removeAt(0);
    }

    for (final row in _alt) {
      row.resize(columns);
    }
    while (_alt.length < rows) {
      _alt.add(TerminalRow(columns));
    }
    while (_alt.length > rows) {
      _alt.removeLast();
    }

    _cx = _cx.clamp(0, columns - 1);
    _cy = _cy.clamp(0, rows - 1);
    _pendingWrap = false;
    version++;
  }
}
