/// 终端文本样式（SGR 属性位掩码），移植自 Termux TextStyle。
///
/// 样式以 int 位掩码形式存储，包含颜色索引、粗体、下划线、反显等。
class TextStyle {
  static const int NORMAL = 0;

  // 属性位
  static const int BOLD = 1 << 0;
  static const int UNDERLINE = 1 << 1;
  static const int BLINK = 1 << 2;
  static const int REVERSE = 1 << 3;
  static const int CONCEAL = 1 << 4;
  static const int STRIKETHROUGH = 1 << 5;

  // 颜色索引位置
  static const int COLOR_INDEX_SHIFT = 8;
  static const int COLOR_INDEX_MASK = 0xFF << COLOR_INDEX_SHIFT;

  // 前景/背景真彩色标志
  static const int FOREGROUND_TRUE_COLOR = 1 << 24;
  static const int BACKGROUND_TRUE_COLOR = 1 << 25;
  static const int WIDE_CHAR_RIGHT = 1 << 26;

  static int getForegroundColorIndex(int style) =>
      (style & COLOR_INDEX_MASK) >> COLOR_INDEX_SHIFT;

  static int getBackgroundColorIndex(int style) =>
      (style & (COLOR_INDEX_MASK << 8)) >> (COLOR_INDEX_SHIFT + 8);

  static bool isBold(int style) => (style & BOLD) != 0;
  static bool isUnderline(int style) => (style & UNDERLINE) != 0;
  static bool isBlink(int style) => (style & BLINK) != 0;
  static bool isReverse(int style) => (style & REVERSE) != 0;
  static bool isConceal(int style) => (style & CONCEAL) != 0;
  static bool isStrikethrough(int style) => (style & STRIKETHROUGH) != 0;
  static bool isWideCharRight(int style) => (style & WIDE_CHAR_RIGHT) != 0;
  static bool isForegroundTrueColor(int style) =>
      (style & FOREGROUND_TRUE_COLOR) != 0;
  static bool isBackgroundTrueColor(int style) =>
      (style & BACKGROUND_TRUE_COLOR) != 0;

  static const int COLOR_INDEX_DEFAULT = 9;
  static const int COLOR_INDEX_BACKGROUND = 9;

  /// 应用 SGR 参数到样式。
  static int applySgr(int style, List<int> params, List<int>? subParams) {
    var i = 0;
    while (i < params.length) {
      final param = params[i];
      switch (param) {
        case 0: // 重置
          style = NORMAL;
        case 1: // 粗体
          style |= BOLD;
        case 2: // 模糊（简化处理为粗体）
          style |= BOLD;
        case 3: // 斜体（忽略）
          break;
        case 4: // 下划线
          style |= UNDERLINE;
        case 5: // 闪烁
          style |= BLINK;
        case 6: // 急闪（忽略）
          break;
        case 7: // 反显
          style |= REVERSE;
        case 8: // 隐藏
          style |= CONCEAL;
        case 9: // 删除线
          style |= STRIKETHROUGH;
        case 10: // 首选字体（忽略）
          break;
        case 21: // 双倍下划线（简化为下划线）
          style |= UNDERLINE;
        case 22: // 关闭粗体
          style &= ~BOLD;
        case 24: // 关闭下划线
          style &= ~UNDERLINE;
        case 25: // 关闭闪烁
          style &= ~BLINK;
        case 27: // 关闭反显
          style &= ~REVERSE;
        case 28: // 关闭隐藏
          style &= ~CONCEAL;
        case 29: // 关闭删除线
          style &= ~STRIKETHROUGH;
        case 30:
        case 31:
        case 32:
        case 33:
        case 34:
        case 35:
        case 36:
        case 37: // 前景色 0-7
          style = (style & ~COLOR_INDEX_MASK) |
              ((param - 30) << COLOR_INDEX_SHIFT);
          style &= ~FOREGROUND_TRUE_COLOR;
        case 38: // 前景色扩展
          if (subParams != null && subParams.isNotEmpty) {
            // 简化：只处理 5;n 256色
            if (subParams.length >= 2 && subParams[0] == 5) {
              final color = subParams[1];
              style = (style & ~COLOR_INDEX_MASK) |
                  (color << COLOR_INDEX_SHIFT);
              style &= ~FOREGROUND_TRUE_COLOR;
            }
          }
        case 39: // 默认前景色
          style = (style & ~COLOR_INDEX_MASK) |
              (COLOR_INDEX_DEFAULT << COLOR_INDEX_SHIFT);
          style &= ~FOREGROUND_TRUE_COLOR;
        case 40:
        case 41:
        case 42:
        case 43:
        case 44:
        case 45:
        case 46:
        case 47: // 背景色 0-7
          style = (style & ~(COLOR_INDEX_MASK << 8)) |
              ((param - 40) << (COLOR_INDEX_SHIFT + 8));
          style &= ~BACKGROUND_TRUE_COLOR;
        case 48: // 背景色扩展
          if (subParams != null && subParams.isNotEmpty) {
            if (subParams.length >= 2 && subParams[0] == 5) {
              final color = subParams[1];
              style = (style & ~(COLOR_INDEX_MASK << 8)) |
                  (color << (COLOR_INDEX_SHIFT + 8));
              style &= ~BACKGROUND_TRUE_COLOR;
            }
          }
        case 49: // 默认背景色
          style = (style & ~(COLOR_INDEX_MASK << 8)) |
              (COLOR_INDEX_BACKGROUND << (COLOR_INDEX_SHIFT + 8));
          style &= ~BACKGROUND_TRUE_COLOR;
        case 90:
        case 91:
        case 92:
        case 93:
        case 94:
        case 95:
        case 96:
        case 97: // 前景亮色 0-7
          style = (style & ~COLOR_INDEX_MASK) |
              ((param - 90 + 8) << COLOR_INDEX_SHIFT);
          style &= ~FOREGROUND_TRUE_COLOR;
        case 100:
        case 101:
        case 102:
        case 103:
        case 104:
        case 105:
        case 106:
        case 107: // 背景亮色 0-7
          style = (style & ~(COLOR_INDEX_MASK << 8)) |
              ((param - 100 + 8) << (COLOR_INDEX_SHIFT + 8));
          style &= ~BACKGROUND_TRUE_COLOR;
      }
      i++;
    }
    return style;
  }

  /// 设置宽字符右半部标记。
  static int setWideCharRight(int style, bool right) {
    if (right) {
      style |= WIDE_CHAR_RIGHT;
    } else {
      style &= ~WIDE_CHAR_RIGHT;
    }
    return style;
  }

  /// 解码前景色索引。
  static int decodeForeColor(int style) => getForegroundColorIndex(style);

  /// 解码背景色索引。
  static int decodeBackColor(int style) => getBackgroundColorIndex(style);
}
