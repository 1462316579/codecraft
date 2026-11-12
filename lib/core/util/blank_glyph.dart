/// 「不出墨」的码点集合:虽非空白、也不属格式/控制类,却渲染为零宽或纯空白。
/// 逐值移植自原仓库 AgentUiModels.kt 的 BLANK_GLYPH_CODE_POINTS
/// (Hangul filler 一族属 Lo 类别,按类别判定抓不到,必须显式列举)。
const Set<int> blankGlyphCodePoints = {
  0x115F, 0x1160, 0x3164, 0xFFA0, // Hangul filler
  0x2800, // Braille pattern blank
  0x034F, // CGJ
  0x17B4, 0x17B5, // Khmer 固有元音
  0x2060, 0xFEFF, // 词连接符 / BOM
  0x200B, 0x200C, 0x200D, // ZWSP / ZWNJ / ZWJ
};

/// 文本是否含「可见(出墨)」内容。判定 = 至少一个字符既非空白、又不可见
/// (控制/格式/零宽填充字形),且代理对仅在成对合法时算可见(emoji 不受影响)。
/// 这是「是否渲染助手气泡」的唯一关门。
bool hasVisibleContent(String text) {
  for (var i = 0; i < text.length; i++) {
    final ch = text.codeUnitAt(i);
    if (ch <= 0x20) continue; // 空白与控制字符
    if (ch == 0x7F) continue;
    if (blankGlyphCodePoints.contains(ch)) continue;
    // 格式类(Cf):双向控制、词连接符等
    if (ch == 0x200E || ch == 0x200F) continue;
    if (ch >= 0x202A && ch <= 0x202E) continue;
    if (ch >= 0x2066 && ch <= 0x2069) continue;
    if (ch == 0x00AD) continue; // 软连字符
    // 代理对:合法高/低代理组合(emoji 等补全平面字符)算可见;孤立代理算不可见
    if (ch >= 0xD800 && ch <= 0xDBFF) {
      if (i + 1 < text.length) {
        final lo = text.codeUnitAt(i + 1);
        if (lo >= 0xDC00 && lo <= 0xDFFF) return true;
      }
      continue;
    }
    if (ch >= 0xDC00 && ch <= 0xDFFF) continue;
    return true;
  }
  return false;
}