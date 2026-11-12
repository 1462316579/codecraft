import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart' as hl;

/// 一段高亮区间:相对整段文本的字符偏移 + 样式。
class CodeHighlightSpan {
  const CodeHighlightSpan({required this.start, required this.end, required this.style});

  final int start;
  final int end;
  final TextStyle style;
}

/// 扩展名 → highlight.js 语言 id(对齐上游 `inferSyntaxLanguage`);未识别返回 null。
String? syntaxLanguageFor(String filePath) {
  final dot = filePath.lastIndexOf('.');
  final ext = dot < 0 ? '' : filePath.substring(dot + 1).toLowerCase();
  return switch (ext) {
    'kt' || 'kts' => 'kotlin',
    'java' => 'java',
    'py' => 'python',
    'js' || 'mjs' => 'javascript',
    'ts' => 'typescript',
    'go' => 'go',
    'rb' => 'ruby',
    'php' => 'php',
    'swift' => 'swift',
    'rs' => 'rust',
    'c' || 'h' || 'cpp' || 'cc' || 'cxx' || 'hpp' => 'cpp',
    'cs' => 'cs',
    'sh' || 'bash' => 'shell',
    'dart' => 'dart',
    'pl' || 'pm' => 'perl',
    'coffee' => 'coffeescript',
    _ => null,
  };
}

/// 对整段代码求高亮区间;语言未知或解析失败返回空列表(调用方降级纯文本)。
///
/// 配色取自上游自带的 highlight.js GitHub 主题(`assets/markdown/highlight-github*.min.css`),
/// 与上游差异页使用的 dev.snipme:highlights 默认主题并非同一套,token 颜色为近似值。
List<CodeHighlightSpan> highlightSpans(String code, String? language, {required bool dark}) {
  if (language == null || code.trim().isEmpty) return const [];
  final palette = dark ? _darkPalette : _lightPalette;
  try {
    final nodes = hl.highlight.parse(code, language: language).nodes;
    if (nodes == null) return const [];
    final spans = <CodeHighlightSpan>[];
    var offset = 0;

    void visit(hl.Node node, List<String> inherited) {
      final classes = node.className == null || node.className!.isEmpty
          ? inherited
          : [...inherited, ...node.className!.split(' ')];
      final value = node.value;
      if (value != null) {
        if (value.isNotEmpty) {
          final style = _styleFor(classes, palette);
          if (style != null) {
            spans.add(CodeHighlightSpan(start: offset, end: offset + value.length, style: style));
          }
          offset += value.length;
        }
        return;
      }
      for (final child in node.children ?? const <hl.Node>[]) {
        visit(child, classes);
      }
    }

    for (final node in nodes) {
      visit(node, const []);
    }
    return spans;
  } catch (_) {
    return const [];
  }
}

/// 把整段文本的高亮区间裁剪到某一行,并把偏移换算成行内偏移。
List<CodeHighlightSpan> sliceSpansForLine(
  List<CodeHighlightSpan> spans,
  int lineStart,
  int lineEnd,
) {
  if (spans.isEmpty || lineEnd <= lineStart) return const [];
  final result = <CodeHighlightSpan>[];
  for (final span in spans) {
    if (span.end <= lineStart) continue;
    if (span.start >= lineEnd) break;
    final start = span.start < lineStart ? lineStart : span.start;
    final end = span.end > lineEnd ? lineEnd : span.end;
    if (end <= start) continue;
    result.add(CodeHighlightSpan(
      start: start - lineStart,
      end: end - lineStart,
      style: span.style,
    ));
  }
  return result;
}

/// 每行在整段文本中的起始偏移(末行后一项为文本长度)。
List<int> lineStartOffsets(String text) {
  final lines = text.split('\n');
  final offsets = List<int>.filled(lines.length + 1, 0);
  var position = 0;
  for (var i = 0; i < lines.length; i++) {
    offsets[i] = position;
    position += lines[i].length + 1; // +1 为换行符
  }
  offsets[lines.length] = position;
  return offsets;
}

TextStyle? _styleFor(List<String> classes, _Palette palette) {
  final key = classes.join(' ');
  for (final rule in _rules) {
    if (rule.matches(classes, key)) {
      return palette.styleFor(rule.token);
    }
  }
  return null;
}

enum _Token { keyword, title, literal, string, builtIn, comment, name, subst, section, bullet }

class _Rule {
  const _Rule(this.token, this.exact, this.fallback);

  final _Token token;

  /// 精确匹配的组合(如 `meta string` 优先于单独的 `string`)。
  final List<String> exact;

  /// 单类名兜底匹配。
  final List<String> fallback;

  bool matches(List<String> classes, String key) {
    if (exact.contains(key)) return true;
    for (final name in fallback) {
      if (classes.contains(name)) return true;
    }
    return false;
  }
}

const List<_Rule> _rules = [
  _Rule(_Token.string, ['meta string'], ['regexp', 'string']),
  _Rule(_Token.title, ['title class_', 'title class_ inherited__', 'title function_'],
      ['title']),
  _Rule(_Token.keyword, ['variable language_'],
      ['doctag', 'keyword', 'type', 'template-tag', 'template-variable']),
  _Rule(
    _Token.literal,
    [],
    ['attr', 'attribute', 'literal', 'meta', 'number', 'operator', 'selector-attr',
      'selector-class', 'selector-id', 'variable'],
  ),
  _Rule(_Token.builtIn, [], ['built_in', 'symbol']),
  _Rule(_Token.comment, [], ['code', 'comment', 'formula']),
  _Rule(_Token.name, [], ['name', 'quote', 'selector-pseudo', 'selector-tag']),
  _Rule(_Token.subst, [], ['subst']),
  _Rule(_Token.section, [], ['section']),
  _Rule(_Token.bullet, [], ['bullet']),
];

class _Palette {
  const _Palette(this.colors, this.substColor);

  final Map<_Token, Color> colors;
  final Color substColor;

  TextStyle styleFor(_Token token) {
    final color = token == _Token.subst ? substColor : colors[token]!;
    return TextStyle(
      color: color,
      fontWeight: token == _Token.section ? FontWeight.bold : null,
    );
  }
}

/// GitHub light(取自 upstream 自带 highlight-github.min.css)。
const _Palette _lightPalette = _Palette(
  {
    _Token.keyword: Color(0xFFD73A49),
    _Token.title: Color(0xFF6F42C1),
    _Token.literal: Color(0xFF005CC5),
    _Token.string: Color(0xFF032F62),
    _Token.builtIn: Color(0xFFE36209),
    _Token.comment: Color(0xFF6A737D),
    _Token.name: Color(0xFF22863A),
    _Token.section: Color(0xFF005CC5),
    _Token.bullet: Color(0xFF735C0F),
  },
  Color(0xFF24292E),
);

/// GitHub dark。
const _Palette _darkPalette = _Palette(
  {
    _Token.keyword: Color(0xFFFF7B72),
    _Token.title: Color(0xFFD2A8FF),
    _Token.literal: Color(0xFF79C0FF),
    _Token.string: Color(0xFFA5D6FF),
    _Token.builtIn: Color(0xFFFFA657),
    _Token.comment: Color(0xFF8B949E),
    _Token.name: Color(0xFF7EE787),
    _Token.section: Color(0xFF1F6FEB),
    _Token.bullet: Color(0xFFF2CC60),
  },
  Color(0xFFC9D1D9),
);