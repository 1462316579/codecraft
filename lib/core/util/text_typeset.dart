/// 写作项目「自动排版」:把正文整理成统一的中文段落格式。
///
/// 规则:
/// - 去掉每行首尾空白;
/// - 连续空行合并为一个,段落之间只留一个空行,文末空行去掉;
/// - 半角标点转为全角,但**只在紧邻中文时**转——`3.14`、`v1.2`、`http://a.b`、
///   英文缩写里的半角符号原样保留,否则会把数字和网址改坏;转成全角后紧跟的
///   多余空格一并去掉;
/// - 普通段落首行缩进两个全角空格;Markdown 的结构行(标题、列表、引用、表格、
///   分隔线、围栏标记)不缩进,围栏代码块内部整体不动——排版不该破坏文档结构。
library;

/// 段落首行缩进:两个全角空格(U+3000),不是两个 ASCII 空格。
const String _indent = '\u3000\u3000';

/// 半角标点到全角标点的映射。
const Map<String, String> _halfToFull = {
  ',': ',',
  '.': '。',
  '?': '?',
  '!': '!',
  ':': ':',
  ';': ';',
  '(': '(',
  ')': ')',
};

/// 中日韩文字与中文标点的码位区间。
bool _isCjk(int codeUnit) =>
    (codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) ||
    (codeUnit >= 0x3400 && codeUnit <= 0x4DBF) ||
    (codeUnit >= 0xF900 && codeUnit <= 0xFAFF) ||
    (codeUnit >= 0x3000 && codeUnit <= 0x303F);

/// 全角标点后面多出来的空白:中文排版里标点自带间距,再跟一个半角空格会显得松散。
final RegExp _spaceAfterFullPunctuation = RegExp(r'([,。?!:;、()“”])\s+');

/// 整理单行正文的标点:只在中文旁边把半角换成全角。
String _convertPunctuation(String line) {
  final hasCjk = line.codeUnits.any(_isCjk);
  final buffer = StringBuffer();
  // 中文引号成对出现:按出现顺序交替,才能得到“前开后闭”。
  var openingQuote = true;
  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '"' && hasCjk) {
      buffer.write(openingQuote ? '“' : '”');
      openingQuote = !openingQuote;
      continue;
    }
    final full = _halfToFull[char];
    if (full == null) {
      buffer.write(char);
      continue;
    }
    final before = i > 0 ? line.codeUnitAt(i - 1) : -1;
    final after = i + 1 < line.length ? line.codeUnitAt(i + 1) : -1;
    buffer.write(_isCjk(before) || _isCjk(after) ? full : char);
  }
  return buffer.toString().replaceAllMapped(_spaceAfterFullPunctuation, (m) => m[1]!);
}

/// Markdown 结构行:标题、列表项、引用、表格、分隔线、围栏标记。
bool _isStructural(String line) {
  if (line.startsWith('#') || line.startsWith('>') || line.startsWith('|')) return true;
  if (line.startsWith('```') || line.startsWith('~~~')) return true;
  if (RegExp(r'^([-*+]|\d+[.)])\s').hasMatch(line)) return true;
  return RegExp(r'^(-{3,}|\*{3,}|_{3,})$').hasMatch(line);
}

/// 排版:见文件头部的规则说明。输入与输出都是纯文本,不做任何 I/O。
String typesetText(String input) {
  if (input.isEmpty) return input;
  final endsWithNewline = input.endsWith('\n');
  final lines = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');

  final out = <String>[];
  var inFence = false;
  for (final raw in lines) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
      inFence = !inFence;
      out.add(trimmed);
      continue;
    }
    if (inFence) {
      // 代码块内的缩进与符号都有语义,整行原样保留。
      out.add(raw);
      continue;
    }
    if (trimmed.isEmpty) {
      // 连续空行合并:上一行已经空了就不再补,文末空行在收尾统一去掉。
      if (out.isNotEmpty && out.last.isNotEmpty) out.add('');
      continue;
    }
    final text = _convertPunctuation(trimmed);
    out.add(_isStructural(trimmed) ? text : '$_indent$text');
  }
  while (out.isNotEmpty && out.last.isEmpty) {
    out.removeLast();
  }
  if (out.isEmpty) return '';
  return endsWithNewline ? '${out.join('\n')}\n' : out.join('\n');
}

/// 字数:去掉所有空白(含全角空格)后的字符数,与写作软件的口径一致。
int countWords(String text) => text.replaceAll(RegExp(r'\s'), '').length;