/// 终端仿真器：ANSI/VT 转义序列解析状态机，移植自 Termux TerminalEmulator。
///
import 'dart:async';

import 'text_style.dart';
import 'terminal_buffer.dart';
import 'terminal_output.dart';

/// 输入字节通过 [appendByte] 或 [append] 喂入，解析结果通过
/// [TerminalOutput] 回调通知宿主。
class TerminalEmulator {
  // 状态机状态
  static const int ESC_GROUND = 0;
  static const int ESC_ESCAPE = 1;
  static const int ESC_CSI_ENTRY = 2;
  static const int ESC_CSI_PARAM = 3;
  static const int ESC_CSI_INTERMEDIATE = 4;
  static const int ESC_OSC_STRING = 9;

  final TerminalBuffer _buffer;
  final TerminalOutput _output;

  int _escapeState = ESC_GROUND;
  int _paramCount = 0;
  final List<int> _params = List.filled(16, 0);
  int _utf8Expected = 0;
  int _utf8CodePoint = 0;
  String _title = '';
  int _oscLength = 0;
  final List<int> _oscBuffer = [];

  TerminalEmulator(this._buffer, this._output);

  void resize(int columns, int rows) {
    _buffer.resize(columns, rows);
    if (_onScreenUpdated != null) _onScreenUpdated!();
  }

  void reset() {
    _escapeState = ESC_GROUND;
    _paramCount = 0;
    _utf8Expected = 0;
    _oscBuffer.clear();
    _oscLength = 0;
    _buffer.reset();
  }

  List<int> drainOutput() => <int>[];

  TerminalBuffer get buffer => _buffer;
  String get title => _title;

  void Function()? _onScreenUpdated;
  set onScreenUpdated(void Function()? cb) {
    _onScreenUpdated = cb;
    _buffer.onScreenUpdated = cb;
  }

  void appendByte(int byte) {
    if (_escapeState == ESC_GROUND && byte >= 0x80) {
      if (byte >= 0xC0 && byte <= 0xDF) {
        _utf8Expected = 1;
        _utf8CodePoint = byte & 0x1F;
      } else if (byte >= 0xE0 && byte <= 0xEF) {
        _utf8Expected = 2;
        _utf8CodePoint = byte & 0x0F;
      } else if (byte >= 0xF0 && byte <= 0xF7) {
        _utf8Expected = 3;
        _utf8CodePoint = byte & 0x07;
      } else {
        _processCodePoint(0xFFFD);
      }
      return;
    }
    if (_utf8Expected > 0) {
      _continueUtf8(byte);
      return;
    }
    _processCodePoint(byte);
  }

  void append(List<int> bytes, [int offset = 0, int? count]) {
    final len = count ?? bytes.length;
    for (var i = offset; i < offset + len; i++) {
      appendByte(bytes[i]);
    }
  }

  void _continueUtf8(int byte) {
    if (byte < 0x80 || byte > 0xBF) {
      _utf8Expected = 0;
      _processCodePoint(0xFFFD);
      _processCodePoint(byte);
      return;
    }
    _utf8CodePoint = (_utf8CodePoint << 6) | (byte & 0x3F);
    _utf8Expected--;
    if (_utf8Expected == 0) {
      _processCodePoint(_utf8CodePoint);
    }
  }

  void _processCodePoint(int codePoint) {
    switch (_escapeState) {
      case ESC_GROUND:
        _doGround(codePoint);
        break;
      case ESC_ESCAPE:
        _doEscape(codePoint);
        break;
      case ESC_CSI_ENTRY:
        _doCsiEntry(codePoint);
        break;
      case ESC_CSI_PARAM:
        _doCsiParam(codePoint);
        break;
      case ESC_CSI_INTERMEDIATE:
        _doCsiIntermediate(codePoint);
        break;
      case ESC_OSC_STRING:
        _doOscString(codePoint);
        break;
    }
  }

  void _doGround(int b) {
    if (b < 0x20 || b == 0x7F) {
      switch (b) {
        case 0x07: // BEL
          _output.onBell();
          break;
        case 0x08: // BS
          _buffer.backspace();
          break;
        case 0x09: // HT
          _buffer.horizontalTab();
          break;
        case 0x0A: // LF
          _buffer.lineFeed();
          break;
        case 0x0C: // FF
          _buffer.formFeed();
          break;
        case 0x0D: // CR
          _buffer.carriageReturn();
          break;
        case 0x1B: // ESC
          _escapeState = ESC_ESCAPE;
          break;
      }
    } else {
      final style = _buffer.currentStyle;
      _buffer.writeChar(b, style);
    }
    if (_onScreenUpdated != null) _onScreenUpdated!();
  }

  void _doEscape(int b) {
    _escapeState = ESC_GROUND;
    switch (b) {
      case 0x3F: // DEC 私有模式前缀
        _escapeState = ESC_CSI_ENTRY;
        break;
      case 0x63: // RIS 重置
        reset();
        break;
      case 0x45: // NEL
        _buffer.carriageReturn();
        _buffer.lineFeed();
        break;
      case 0x44: // IND
        _buffer.lineFeed();
        break;
      case 0x48: // HTS
        _buffer.setTabStop(_buffer.cursorX);
        break;
      case 0x49: // OSC
        _escapeState = ESC_OSC_STRING;
        _oscBuffer.clear();
        _oscLength = 0;
        break;
    }
    if (_onScreenUpdated != null) _onScreenUpdated!();
  }

  void _doCsiEntry(int b) {
    _escapeState = ESC_GROUND;
    _paramCount = 0;
    for (var i = 0; i < _params.length; i++) _params[i] = 0;
    if (b >= 0x30 && b <= 0x3F) {
      _escapeState = ESC_CSI_PARAM;
      _params[0] = b == 0x3F ? 0 : (b - 0x30);
    } else if (b >= 0x20 && b <= 0x2F) {
      _escapeState = ESC_CSI_INTERMEDIATE;
    } else if (b >= 0x40 && b <= 0x7E) {
      _doCsiFinal(b, [0]);
    }
  }

  void _doCsiParam(int b) {
    if (b >= 0x30 && b <= 0x3F) {
      if (_paramCount < 15) {
        if (b == 0x3B) {
          _paramCount++;
          _params[_paramCount] = 0;
        } else {
          _params[_paramCount] =
              _params[_paramCount] * 10 + (b - 0x30);
          if (_params[_paramCount] > 9999) {
            _params[_paramCount] = 9999;
          }
        }
      }
    } else if (b >= 0x20 && b <= 0x2F) {
      _escapeState = ESC_CSI_INTERMEDIATE;
    } else if (b >= 0x40 && b <= 0x7E) {
      _escapeState = ESC_GROUND;
      _doCsiFinal(b, _params.sublist(0, _paramCount + 1));
    }
  }

  void _doCsiIntermediate(int b) {
    if (b >= 0x40 && b <= 0x7E) {
      _escapeState = ESC_GROUND;
      _doCsiFinal(b, _params.sublist(0, _paramCount + 1));
    }
  }

  int _getParam(List<int> params, int index, int defaultValue) {
    if (index < params.length) return params[index];
    return defaultValue;
  }

  void _doCsiFinal(int b, List<int> params) {
    final effective = params.isNotEmpty ? params : [0];
    final p0 = _getParam(effective, 0, 0);
    final p1 = effective.length > 1 ? _getParam(effective, 1, 0) : 0;

    switch (b) {
      case 0x41: // CUU 光标上移
        _buffer.moveCursor(0, -_getParam(effective, 0, 1));
        break;
      case 0x42: // CUD 光标下移
        _buffer.moveCursor(0, _getParam(effective, 0, 1));
        break;
      case 0x43: // CUF 光标右移
        _buffer.moveCursor(_getParam(effective, 0, 1), 0);
        break;
      case 0x44: // CUB 光标左移
        _buffer.moveCursor(-_getParam(effective, 0, 1), 0);
        break;
      case 0x47: // CHA
        _buffer.setCursorPosition(
            _getParam(effective, 0, 1) - 1, _buffer.cursorY);
        break;
      case 0x48: // CUP
        _buffer.setCursorPosition(
            _getParam(effective, 1, 1) - 1,
            _getParam(effective, 0, 1) - 1);
        break;
      case 0x4B: // EL
        _buffer.clearLine(p0);
        break;
      case 0x4D: // ED
        _buffer.clearScreen(p0);
        break;
      case 0x4E: // ED 别名
        _buffer.clearScreen(p0);
        break;
      case 0x6D: // SGR
        final style = TextStyle.applySgr(
            _buffer.currentStyle, effective, null);
        _buffer.setCurrentStyle(style);
        break;
      case 0x6E: // DSR
        if (p0 == 5) {
          // 终端状态
        } else if (p0 == 6) {
          // CPR 光标位置报告
          final response =
              '\u001b[${_buffer.cursorY + 1};${_buffer.cursorX + 1}R';
          _output.write(response.codeUnits, 0, response.length);
        }
        break;
      case 0x72: // DECSTBM
        _buffer.setScrollRegion(
            _getParam(effective, 0, 1) - 1,
            effective.length > 1
                ? _getParam(effective, 1, _buffer.rows) - 1
                : _buffer.rows - 1);
        break;
      case 0x3D: // DECSET
        _doDecset(effective, true);
        break;
      case 0x3E: // DECRST
        _doDecset(effective, false);
        break;
    }
    if (_onScreenUpdated != null) _onScreenUpdated!();
  }

  void _doDecset(List<int> params, bool isSet) {
    for (final p in params) {
      switch (p) {
        case 25: // DECTCEM 光标显示
          _buffer.setCursorVisible(isSet);
          break;
        case 1049: // 备屏幕切换
          if (isSet) {
            _buffer.switchToAltBuffer();
          } else {
            _buffer.switchToMainBuffer();
          }
          break;
      }
    }
  }

  void _doOscString(int b) {
    if (b == 0x07 || b == 0x1B) {
      _doOscFinal();
      _escapeState = ESC_GROUND;
      if (b == 0x1B) {
        // 等待 ST
      }
    } else if (_oscLength < 4096) {
      _oscBuffer.add(b);
      _oscLength++;
    }
  }

  void _doOscFinal() {
    if (_oscBuffer.isEmpty) return;
    final oscString = String.fromCharCodes(_oscBuffer);
    _oscBuffer.clear();
    _oscLength = 0;

    if (oscString.startsWith('0;') || oscString.startsWith('2;')) {
      final sepIdx = oscString.indexOf(';');
      final newTitle = sepIdx >= 0
          ? oscString.substring(sepIdx + 1)
          : oscString;
      final oldTitle = _title;
      _title = newTitle;
      _output.titleChanged(oldTitle, newTitle);
    }
  }
}
