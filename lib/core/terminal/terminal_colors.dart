import 'text_style.dart';

/// 终端颜色解析，移植自 Termux TerminalColors。
class TerminalColors {
  // ANSI 标准 16 色
  static const List<int> _ansiColors = [
    0x000000, // 0 黑
    0x800000, // 1 红
    0x008000, // 2 绿
    0x808000, // 3 黄
    0x000080, // 4 蓝
    0x800080, // 5 品红
    0x008080, // 6 青
    0xC0C0C0, // 7 白
    0x808080, // 8 亮黑
    0xFF0000, // 9 亮红
    0x00FF00, // 10 亮绿
    0xFFFF00, // 11 亮黄
    0x0000FF, // 12 亮蓝
    0xFF00FF, // 13 亮品红
    0x00FFFF, // 14 亮青
    0xFFFFFF, // 15 亮白
  ];

  /// 解析前景色。
  static int resolveForeground(int style, int defaultFore, int defaultBack) {
    final bold = TextStyle.isBold(style);
    final index = TextStyle.decodeForeColor(style);
    if (index >= 0 && index <= 15) {
      var color = _ansiColors[index];
      if (bold && index < 8) {
        // 亮色
        color = _ansiColors[index + 8];
      }
      return color;
    }
    if (TextStyle.isForegroundTrueColor(style)) {
      // 真彩色简化处理：返回索引对应的默认色
      return _ansiColors[index % 16];
    }
    return defaultFore;
  }

  /// 解析背景色。
  static int resolveBackground(int style, int defaultFore, int defaultBack) {
    final index = TextStyle.decodeBackColor(style);
    if (index >= 0 && index <= 15) {
      return _ansiColors[index];
    }
    if (TextStyle.isBackgroundTrueColor(style)) {
      return _ansiColors[index % 16];
    }
    return defaultBack;
  }
}
