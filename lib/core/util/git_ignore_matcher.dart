/// 工作区 `.gitignore` 的行级匹配器(逐值移植上游 `GitIgnoreMatcher`)。
///
/// 只处理**根 `.gitignore`**(不读嵌套的),语义按 git 的常用子集实现:
/// - `*.ext`(不含 `/`)匹配任意层级的文件名后缀;
/// - `**/` 前缀表示任意层级开始(此时忽略 [anchored]);
/// - 其余按 `/` 切段逐段匹配,`**` 段匹配任意段、`*` 段内展开为 `.*`;
/// - [anchored] 为真时只允许从路径第 0 段开始匹配。
///
/// 空行与 `#` 注释、`!` 否定行由调用方在读取时过滤(与上游一致:这里不做否定规则)。
class GitIgnoreMatcher {
  GitIgnoreMatcher._();

  /// 任一模式命中即忽略。
  static bool isIgnored(
    List<String> patterns,
    List<String> parts, {
    bool anchored = false,
  }) =>
      patterns.any((pattern) => matches(pattern, parts, anchored: anchored));

  static bool matches(
    String pattern,
    List<String> parts, {
    bool anchored = false,
  }) {
    // 与上游同序:先去首尾斜杠,再判断 `**/` 前缀。注意 `**/` 会被去尾斜杠变成 `**`,
    // 于是走下面的单段 `**` 规则(而不是「任意层级」),这是上游的实际行为。
    var p = pattern.trim().replaceAll(RegExp(r'/+$'), '').replaceAll(RegExp(r'^/+'), '');
    if (p.isEmpty) return false;

    // `**/` 前缀:任意层级开始(`**/` 本身即非锚定语义)。
    final recursive = p.startsWith('**/');
    if (recursive) p = p.substring(3);
    if (p.isEmpty) return false;

    // `*.ext` 文件模式:匹配任意层级的文件名后缀。
    if (p.startsWith('*.') && !p.contains('/')) {
      final ext = p.substring(2);
      return parts.any((part) => part.endsWith(ext));
    }

    final segments = p.split('/');
    if (segments.length > parts.length) return false;
    final startMax = anchored && !recursive ? 0 : parts.length - segments.length;
    for (var start = 0; start <= startMax; start++) {
      var all = true;
      for (var i = 0; i < segments.length; i++) {
        if (!_segmentMatches(segments[i], parts[start + i])) {
          all = false;
          break;
        }
      }
      if (all) return true;
    }
    return false;
  }

  /// 单段匹配:`**` 匹配任意段,`*` 在段内展开,其余按字面量比较。
  static bool _segmentMatches(String pattern, String segment) {
    if (pattern == '**') return true;
    if (!pattern.contains('*')) return pattern == segment;
    final buffer = StringBuffer('^');
    for (final rune in pattern.runes) {
      final ch = String.fromCharCode(rune);
      if (ch == '*') {
        buffer.write('.*');
      } else if (r'.+?()[]{}^$|\'.contains(ch)) {
        buffer
          ..write(r'\')
          ..write(ch);
      } else {
        buffer.write(ch);
      }
    }
    buffer.write(r'$');
    return RegExp(buffer.toString()).hasMatch(segment);
  }

  /// 从 `.gitignore` 文本里取出有效模式:去空行、`#` 注释与 `!` 否定行,去掉目录尾斜杠。
  static List<String> parse(String content) => [
        for (final raw in content.split('\n'))
          if (raw.trim().isNotEmpty &&
              !raw.trim().startsWith('#') &&
              !raw.trim().startsWith('!'))
            raw.trim().replaceAll(RegExp(r'/+$'), ''),
      ];
}