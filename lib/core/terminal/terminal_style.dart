/// 终端单元格样式与调色板。
///
/// 颜色统一以 `0xRRGGBB`（不带 alpha）存储，`kDefaultColor` 表示使用主题默认色。
/// 之所以不带 alpha：单元格用 Int32List 存储，若把 0xFF 放进高位会让白色变成 -1，
/// 与 `kDefaultColor` 冲突。
library;

/// 默认色哨兵：前景/背景取主题配置的颜色。
const int kDefaultColor = -1;

/// 单元格属性位。
class CellAttr {
  static const int bold = 1 << 0;
  static const int faint = 1 << 1;
  static const int italic = 1 << 2;
  static const int underline = 1 << 3;
  static const int blink = 1 << 4;
  static const int reverse = 1 << 5;
  static const int hidden = 1 << 6;
  static const int strike = 1 << 7;

  /// 宽字符的右半格（不单独绘制字形）。
  static const int wideTail = 1 << 8;

  static bool has(int attrs, int flag) => (attrs & flag) != 0;
}

/// 终端调色板：16 个 ANSI 基础色 + 256 色。
class TerminalPalette {
  TerminalPalette._();

  /// 16 个 ANSI 颜色（暗色主题，对齐 VS Code 终端配色）。
  static const List<int> ansi16 = [
    0x000000, // 0 黑
    0xCD3131, // 1 红
    0x0DBC79, // 2 绿
    0xE5E510, // 3 黄
    0x2472C8, // 4 蓝
    0xBC3FBC, // 5 品红
    0x11A8CD, // 6 青
    0xE5E5E5, // 7 白
    0x666666, // 8 亮黑
    0xF14C4C, // 9 亮红
    0x23D18B, // 10 亮绿
    0xF5F543, // 11 亮黄
    0x3B8EEA, // 12 亮蓝
    0xD670D6, // 13 亮品红
    0x29B8DB, // 14 亮青
    0xFFFFFF, // 15 亮白
  ];

  static final Map<int, int> _cache = {};

  /// 把 0-255 的颜色索引解析为 0xRRGGBB。
  static int color256(int index) {
    if (index < 0) return kDefaultColor;
    if (index < 16) return ansi16[index];
    final cached = _cache[index];
    if (cached != null) return cached;
    int rgb;
    if (index < 232) {
      // 6x6x6 颜色立方体
      final i = index - 16;
      final r = i ~/ 36;
      final g = (i % 36) ~/ 6;
      final b = i % 6;
      int level(int v) => v == 0 ? 0 : 55 + v * 40;
      rgb = (level(r) << 16) | (level(g) << 8) | level(b);
    } else {
      // 24 级灰阶
      final v = 8 + (index - 232) * 10;
      rgb = (v << 16) | (v << 8) | v;
    }
    _cache[index] = rgb;
    return rgb;
  }
}
