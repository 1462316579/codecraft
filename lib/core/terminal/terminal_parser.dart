import 'terminal_screen.dart';
import 'terminal_style.dart';
import 'wc_width.dart';

enum _State {
  ground,
  escape,
  escapeIntermediate,
  csiEntry,
  csiParam,
  csiIntermediate,
  csiIgnore,
  oscString,
  dcsString,
  charset,
}

/// VT100 / xterm 转义序列解析器。
///
/// 只负责把字节流翻译成对 [TerminalScreen] 的操作，以及少量需要回写到
/// PTY 的应答（设备属性、光标位置查询）。状态机跨数据块保留。
class TerminalParser {
  TerminalParser(
    this.screen, {
    this.onResponse,
    this.onTitle,
    this.onBell,
    this.onClipboard,
  });

  final TerminalScreen screen;

  /// 需要写回 PTY 的应答，例如 `ESC [ ? 6 n` 的位置报告。
  final void Function(String data)? onResponse;

  /// OSC 0 / OSC 2 设置的窗口标题。
  final void Function(String title)? onTitle;

  final void Function()? onBell;

  /// OSC 52：文本写入系统剪贴板。
  final void Function(String text)? onClipboard;

  _State _state = _State.ground;

  final List<int> _params = [];
  int _currentParam = -1;
  int _intermediate = 0;
  int _privateMarker = 0;
  final StringBuffer _osc = StringBuffer();
  final StringBuffer _dcs = StringBuffer();

  // 当前绘制的样式
  int fg = kDefaultColor;
  int bg = kDefaultColor;
  int attrs = 0;

  void reset() {
    _state = _State.ground;
    _params.clear();
    _currentParam = -1;
    _intermediate = 0;
    _privateMarker = 0;
    _osc.clear();
    _dcs.clear();
    fg = kDefaultColor;
    bg = kDefaultColor;
    attrs = 0;
    screen.reset();
  }

  void write(String data) {
    for (final rune in data.runes) {
      _handle(rune);
    }
  }

  void _handle(int c) {
    switch (_state) {
      case _State.ground:
        _ground(c);
        break;
      case _State.escape:
        _escape(c);
        break;
      case _State.escapeIntermediate:
        // ESC ( ) * + # 后面的一个字符直接丢弃
        _state = _State.ground;
        break;
      case _State.csiEntry:
      case _State.csiParam:
      case _State.csiIntermediate:
        _csi(c);
        break;
      case _State.csiIgnore:
        if (c >= 0x40 && c <= 0x7E) _state = _State.ground;
        break;
      case _State.oscString:
        if (c == 0x07) {
          _dispatchOsc();
          _state = _State.ground;
        } else if (c == 0x1B) {
          _dispatchOsc();
          _state = _State.escape;
        } else if (c >= 0x20 || c == 0x09) {
          if (_osc.length < 8192) _osc.writeCharCode(c);
        }
        break;
      case _State.dcsString:
        if (c == 0x07) {
          _state = _State.ground;
        } else if (c == 0x1B) {
          _state = _State.escape;
        }
        break;
      case _State.charset:
        _state = _State.ground;
        break;
    }
  }

  void _ground(int c) {
    if (c == 0x1B) {
      _params.clear();
      _currentParam = -1;
      _intermediate = 0;
      _privateMarker = 0;
      _state = _State.escape;
      return;
    }
    if (c < 0x20) {
      switch (c) {
        case 0x07:
          onBell?.call();
          break;
        case 0x08:
          screen.backspace();
          break;
        case 0x09:
          screen.tab();
          break;
        case 0x0A:
        case 0x0B:
        case 0x0C:
          screen.lineFeed();
          break;
        case 0x0D:
          screen.carriageReturn();
          break;
        case 0x0E: // SO
        case 0x0F: // SI
          break;
      }
      return;
    }
    if (c == 0x7F) return;

    final width = WcWidth.wcwidth(c);
    if (width < 0) return;
    screen.putChar(c, width, fg, bg, attrs);
  }

  void _escape(int c) {
    _state = _State.ground;
    switch (c) {
      case 0x5B: // [
        _params.clear();
        _currentParam = -1;
        _intermediate = 0;
        _privateMarker = 0;
        _state = _State.csiEntry;
        break;
      case 0x5D: // ]
        _osc.clear();
        _state = _State.oscString;
        break;
      case 0x50: // P (DCS)
        _dcs.clear();
        _state = _State.dcsString;
        break;
      case 0x28: // (
      case 0x29: // )
      case 0x2A: // *
      case 0x2B: // +
      case 0x23: // #
        _state = _State.charset;
        break;
      case 0x37: // 7 保存光标
        screen.saveCursor();
        break;
      case 0x38: // 8 恢复光标
        screen.restoreCursor();
        break;
      case 0x44: // D 索引（下移一行）
        screen.lineFeed();
        break;
      case 0x45: // E 下一行
        screen.carriageReturn();
        screen.lineFeed();
        break;
      case 0x4D: // M 反向索引（上移一行）
        if (screen.cursorY == screen.scrollTop) {
          screen.scrollDown(1);
        } else {
          screen.moveCursorUp(1);
        }
        break;
      case 0x48: // H 设置制表位（按 8 列固定制表位，忽略）
        break;
      case 0x63: // c 完全重置
        reset();
        break;
      case 0x3D: // = 应用键盘
      case 0x3E: // > 数字键盘
        break;
      case 0x5C: // \ ST
        break;
      default:
        break;
    }
  }

  void _csi(int c) {
    if (c >= 0x30 && c <= 0x39) {
      if (_currentParam < 0) _currentParam = 0;
      _currentParam = _currentParam * 10 + (c - 0x30);
      _state = _State.csiParam;
      return;
    }
    if (c == 0x3B || c == 0x3A) {
      // ; 或 :（子参数按普通参数处理）
      _params.add(_currentParam < 0 ? 0 : _currentParam);
      _currentParam = -1;
      _state = _State.csiParam;
      return;
    }
    if (c >= 0x3C && c <= 0x3F && _params.isEmpty && _currentParam < 0) {
      _privateMarker = c;
      _state = _State.csiParam;
      return;
    }
    if (c >= 0x20 && c <= 0x2F) {
      _intermediate = c;
      _state = _State.csiIntermediate;
      return;
    }
    if (c >= 0x40 && c <= 0x7E) {
      if (_currentParam >= 0) {
        _params.add(_currentParam);
        _currentParam = -1;
      }
      _dispatchCsi(c);
      _state = _State.ground;
      return;
    }
    if (c < 0x20) {
      // C0 控制字符在 CSI 中立即执行
      _ground(c);
      return;
    }
    _state = _State.csiIgnore;
  }

  int _p(int index, [int fallback = 1]) {
    if (index >= _params.length) return fallback;
    final value = _params[index];
    return value == 0 ? fallback : value;
  }

  int _pZero(int index) {
    if (index >= _params.length) return 0;
    return _params[index];
  }

  void _dispatchCsi(int finalByte) {
    final private = _privateMarker;
    final isPrivate = private == 0x3F; // ?

    if (_intermediate != 0) {
      // 带中间字节的序列（如 DECSCUSR 的 " q"）这里不处理
      return;
    }

    switch (finalByte) {
      case 0x40: // @ 插入字符
        screen.insertChars(_p(0));
        break;
      case 0x41: // A 上
        screen.moveCursorUp(_p(0));
        break;
      case 0x42: // B 下
        screen.moveCursorDown(_p(0));
        break;
      case 0x43: // C 右
        screen.moveCursorForward(_p(0));
        break;
      case 0x44: // D 左
        screen.moveCursorBack(_p(0));
        break;
      case 0x45: // E 下 n 行（列归零）
        screen.moveCursorDown(_p(0));
        screen.moveCursorToColumn(1);
        break;
      case 0x46: // F 上 n 行（列归零）
        screen.moveCursorUp(_p(0));
        screen.moveCursorToColumn(1);
        break;
      case 0x47: // G 定位列
      case 0x60: // ` 定位列
        screen.moveCursorToColumn(_p(0));
        break;
      case 0x48: // H 定位行列
      case 0x66: // f 同上
        screen.moveCursorTo(_p(0) - 1, _p(1) - 1);
        break;
      case 0x49: // I 前进 n 个制表位
        for (var i = 0; i < _p(0); i++) {
          screen.tab();
        }
        break;
      case 0x4A: // J 擦除显示
        screen.eraseInDisplay(_pZero(0));
        break;
      case 0x4B: // K 擦除行
        screen.eraseInLine(_pZero(0));
        break;
      case 0x4C: // L 插入行
        screen.insertLines(_p(0));
        break;
      case 0x4D: // M 删除行
        screen.deleteLines(_p(0));
        break;
      case 0x50: // P 删除字符
        screen.deleteChars(_p(0));
        break;
      case 0x53: // S 上滚
        screen.scrollUp(_p(0));
        break;
      case 0x54: // T 下滚
        screen.scrollDown(_p(0));
        break;
      case 0x58: // X 擦除字符
        screen.eraseChars(_p(0));
        break;
      case 0x5A: // Z 反向制表
        for (var i = 0; i < _p(0); i++) {
          screen.backTab();
        }
        break;
      case 0x62: // b 重复上一字符（简化：忽略参数，重复最后一格）
        break;
      case 0x63: // c 设备属性
        if (!isPrivate) {
          onResponse?.call('\x1b[?1;2c');
        }
        break;
      case 0x64: // d 定位行
        screen.moveCursorTo(_p(0) - 1, screen.cursorX);
        break;
      case 0x65: // e 下移 n 行
        screen.moveCursorDown(_p(0));
        break;
      case 0x67: // g 清除制表位（固定制表位，忽略）
        break;
      case 0x68: // h 设置模式
        _setModes(isPrivate: isPrivate, enable: true);
        break;
      case 0x6C: // l 重置模式
        _setModes(isPrivate: isPrivate, enable: false);
        break;
      case 0x6D: // m SGR
        _applySgr();
        break;
      case 0x6E: // n 设备状态查询
        _deviceStatus();
        break;
      case 0x72: // r 设置滚动区域
        if (!isPrivate) {
          screen.setScrollRegion(_p(0) - 1, _p(1, screen.rows) - 1);
        }
        break;
      case 0x73: // s 保存光标
        screen.saveCursor();
        break;
      case 0x75: // u 恢复光标
        screen.restoreCursor();
        break;
      case 0x74: // t 窗口操作（忽略）
      case 0x71: // q（光标样式，忽略）
        break;
      default:
        break;
    }
  }

  void _setModes({required bool isPrivate, required bool enable}) {
    if (!isPrivate) {
      for (final mode in _params) {
        if (mode == 4) screen.insertMode = enable;
      }
      return;
    }
    for (final mode in _params) {
      switch (mode) {
        case 1:
          screen.appCursorKeys = enable;
          break;
        case 6:
          screen.originMode = enable;
          break;
        case 7:
          screen.autoWrap = enable;
          break;
        case 12:
          screen.blinkCursor = enable;
          break;
        case 25:
          screen.cursorVisible = enable;
          break;
        case 47:
        case 1047:
          if (enable) {
            screen.enterAltScreen();
          } else {
            screen.exitAltScreen(restoreCursor: false);
          }
          break;
        case 1048:
          if (enable) {
            screen.saveCursor();
          } else {
            screen.restoreCursor();
          }
          break;
        case 1049:
          if (enable) {
            screen.enterAltScreen();
          } else {
            screen.exitAltScreen();
          }
          break;
        case 2004:
          screen.bracketedPaste = enable;
          break;
        default:
          break;
      }
    }
  }

  void _deviceStatus() {
    final request = _params.isEmpty ? 0 : _params[0];
    switch (request) {
      case 5:
        onResponse?.call('\x1b[0n');
        break;
      case 6:
        final row = screen.cursorY + 1;
        final col = screen.cursorX + 1;
        onResponse?.call('\x1b[$row;${col}R');
        break;
    }
  }

  void _applySgr() {
    if (_params.isEmpty) {
      fg = kDefaultColor;
      bg = kDefaultColor;
      attrs = 0;
      return;
    }
    var i = 0;
    while (i < _params.length) {
      final p = _params[i];
      switch (p) {
        case 0:
          fg = kDefaultColor;
          bg = kDefaultColor;
          attrs = 0;
          break;
        case 1:
          attrs |= CellAttr.bold;
          break;
        case 2:
          attrs |= CellAttr.faint;
          break;
        case 3:
          attrs |= CellAttr.italic;
          break;
        case 4:
          attrs |= CellAttr.underline;
          break;
        case 5:
        case 6:
          attrs |= CellAttr.blink;
          break;
        case 7:
          attrs |= CellAttr.reverse;
          break;
        case 8:
          attrs |= CellAttr.hidden;
          break;
        case 9:
          attrs |= CellAttr.strike;
          break;
        case 21:
        case 22:
          attrs &= ~(CellAttr.bold | CellAttr.faint);
          break;
        case 23:
          attrs &= ~CellAttr.italic;
          break;
        case 24:
          attrs &= ~CellAttr.underline;
          break;
        case 25:
          attrs &= ~CellAttr.blink;
          break;
        case 27:
          attrs &= ~CellAttr.reverse;
          break;
        case 28:
          attrs &= ~CellAttr.hidden;
          break;
        case 29:
          attrs &= ~CellAttr.strike;
          break;
        case 38:
          i = _extendedColor(i, isForeground: true);
          continue;
        case 48:
          i = _extendedColor(i, isForeground: false);
          continue;
        case 39:
          fg = kDefaultColor;
          break;
        case 49:
          bg = kDefaultColor;
          break;
        default:
          if (p >= 30 && p <= 37) {
            fg = TerminalPalette.ansi16[p - 30];
          } else if (p >= 40 && p <= 47) {
            bg = TerminalPalette.ansi16[p - 40];
          } else if (p >= 90 && p <= 97) {
            fg = TerminalPalette.ansi16[p - 90 + 8];
          } else if (p >= 100 && p <= 107) {
            bg = TerminalPalette.ansi16[p - 100 + 8];
          }
          break;
      }
      i++;
    }
  }

  /// 解析 38 / 48 扩展颜色，返回下一个待处理参数下标。
  int _extendedColor(int index, {required bool isForeground}) {
    final next = index + 1;
    if (next >= _params.length) return index + 1;
    final mode = _params[next];
    if (mode == 5 && next + 1 < _params.length) {
      final color = TerminalPalette.color256(_params[next + 1]);
      if (isForeground) {
        fg = color;
      } else {
        bg = color;
      }
      return next + 2;
    }
    if (mode == 2 && next + 3 < _params.length) {
      final r = _params[next + 1].clamp(0, 255);
      final g = _params[next + 2].clamp(0, 255);
      final b = _params[next + 3].clamp(0, 255);
      final color = (r << 16) | (g << 8) | b;
      if (isForeground) {
        fg = color;
      } else {
        bg = color;
      }
      return next + 4;
    }
    return index + 1;
  }

  void _dispatchOsc() {
    final data = _osc.toString();
    _osc.clear();
    if (data.isEmpty) return;

    final separator = data.indexOf(';');
    if (separator <= 0) return;
    final command = data.substring(0, separator);
    final payload = data.substring(separator + 1);

    switch (command) {
      case '0':
      case '2':
        if (payload.isNotEmpty) onTitle?.call(payload);
        break;
      case '52':
        // OSC 52 ; c ; base64
        final parts = payload.split(';');
        if (parts.length >= 2) {
          _decodeClipboard(parts[1]);
        }
        break;
      default:
        break;
    }
  }

  void _decodeClipboard(String base64Text) {
    if (base64Text.isEmpty || base64Text == '?') return;
    try {
      final bytes = _base64Decode(base64Text);
      onClipboard?.call(String.fromCharCodes(bytes));
    } catch (_) {
      // 非法 base64 直接忽略
    }
  }

  List<int> _base64Decode(String text) {
    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final output = <int>[];
    var buffer = 0;
    var bits = 0;
    for (final rune in text.codeUnits) {
      if (rune == 0x3D) break; // '='
      final value = alphabet.indexOf(String.fromCharCode(rune));
      if (value < 0) continue;
      buffer = (buffer << 6) | value;
      bits += 6;
      if (bits >= 8) {
        bits -= 8;
        output.add((buffer >> bits) & 0xFF);
      }
    }
    return output;
  }
}
