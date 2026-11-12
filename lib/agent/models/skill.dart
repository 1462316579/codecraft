// 技能(Skill)领域模型(对齐上游 skill/Skill.kt、SkillScope.kt、SkillParser.kt 的数据部分)。

/// 技能来源作用域:全局(跨项目共享)或项目级(仅当前工作区生效)。
enum SkillScope { global, project }

/// 解析后的单个 Skill。
class Skill {
  const Skill({
    required this.name,
    this.description = '',
    this.requiredTools = const [],
    this.dirPath,
    required this.instructions,
  });

  /// 技能名称(供大模型调用的唯一标识)。
  final String name;

  /// 技能描述(何时使用该技能)。
  final String description;

  /// 该技能所需的专属工具列表(可选)。
  final List<String> requiredTools;

  /// 技能所在目录(相对沙盒的展示路径,如 `~/.codecraft/skills/foo`)。
  final String? dirPath;

  /// 技能指令正文(剥离 Frontmatter 后的内容)。
  final String instructions;
}

/// 一个生效的技能条目:技能本体 + 其来源作用域。
class SkillEntry {
  const SkillEntry(this.skill, this.scope);

  final Skill skill;
  final SkillScope scope;
}

/// 设置页新建/编辑技能时提交的表单快照。
class SkillForm {
  const SkillForm({
    required this.name,
    this.description = '',
    this.instructions = '',
    this.requiredTools = const [],
  });

  final String name;
  final String description;
  final String instructions;

  /// 手写技能里的 `required_tools`,编辑页不暴露但原样写回,避免保存后丢字段。
  final List<String> requiredTools;
}

/// 保存技能失败的原因。
enum SkillSaveError {
  /// 名称为空、过长或含不能做目录名的字符。
  invalidName,

  /// 指令正文为空:这种技能加载出来对 AI 没有任何指导价值。
  emptyInstructions,

  /// 同作用域已有同名技能。
  nameConflict,

  /// 写盘失败。
  ioFailed,
}

/// 导入技能的结果。
class SkillImportResult {
  const SkillImportResult({this.imported = const [], this.failures = const []});

  final List<String> imported;
  final List<SkillImportFailure> failures;
}

class SkillImportFailure {
  const SkillImportFailure(this.name, this.error);

  final String name;
  final SkillImportError error;
}

enum SkillImportError { invalidName, nameConflict, emptyContent, noSkillFound, ioFailed }

const String _skillFile = 'SKILL.md';
const String _claudeFile = 'CLAUDE.md';

/// 技能名合法性(上游 SkillRepository.isValidName):同时用作目录名,禁掉路径分隔符与保留字符。
bool isValidSkillName(String name) {
  if (name.trim().isEmpty || name.length > 64) return false;
  if (name == '.' || name == '..') return false;
  return !name.split('').any((ch) {
    final code = ch.codeUnitAt(0);
    return code < 32 || r'\/:*?"<>|'.contains(ch);
  });
}

/// 从目录内文件名里挑出指令文件(忽略大小写):SKILL.md 优先,其次 CLAUDE.md;都没有返回 null。
String? instructionFileName(Iterable<String> names) {
  for (final name in names) {
    if (name.toLowerCase() == _skillFile.toLowerCase()) return name;
  }
  for (final name in names) {
    if (name.toLowerCase() == _claudeFile.toLowerCase()) return name;
  }
  return null;
}

/// 从原始 Markdown 文本解析技能(不依赖磁盘):
/// frontmatter 的 `name` 优先,缺省回退 [fallbackName];正文为剥离 frontmatter 后的内容。
Skill parseSkillText(String text, String fallbackName) {
  final (frontmatter, body) = _splitFrontmatter(text);
  final name = (frontmatter['name'] ?? '').trim();
  final description = frontmatter['description'] ?? '';
  final requiredTools = _parseTools(frontmatter['required_tools']);
  return Skill(
    name: name.isEmpty ? fallbackName : name,
    description: description.length > 500 ? description.substring(0, 500) : description,
    requiredTools: requiredTools,
    instructions: body.trim(),
  );
}

/// 把表单写回 `SKILL.md` 文本(frontmatter + 正文),与 [parseSkillText] 成对。
///
/// `name` 总是写出来:技能名优先取 frontmatter,改名只需改这里而不必动目录名——
/// 技能目录里的脚本常被正文按原路径引用,跟着改名会把引用打断。
String serializeSkill(SkillForm form) {
  final buffer = StringBuffer('---\n')
    ..write('name: ${_quote(form.name)}\n')
    ..write('description: ${_quote(form.description)}\n');
  if (form.requiredTools.isNotEmpty) {
    buffer.write('required_tools: [${form.requiredTools.join(', ')}]\n');
  }
  buffer
    ..write('---\n')
    ..write('${form.instructions.trim()}\n');
  return buffer.toString();
}

/// frontmatter 字符串值:双引号包裹,转义反斜杠与引号,换行压成空格保证单行。
String _quote(String value) {
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll(RegExp(r'\s*\n\s*'), ' ')
      .trim();
  return '"$escaped"';
}

/// 切分 YAML frontmatter(健壮子集:`key: value` 与 `key: [a, b]`)与正文。
(Map<String, String>, String) _splitFrontmatter(String text) {
  final normalized = text.replaceAll('\r\n', '\n');
  if (!normalized.startsWith('---\n')) return (const {}, normalized);
  final end = normalized.indexOf('\n---', 3);
  if (end < 0) return (const {}, normalized);
  final block = normalized.substring(4, end);
  final rest = normalized.substring(end + 4).replaceFirst('\n', '');
  final values = <String, String>{};
  for (final line in block.split('\n')) {
    final separator = line.indexOf(':');
    if (separator <= 0) continue;
    final key = line.substring(0, separator).trim();
    final value = line.substring(separator + 1).trim();
    if (key.isEmpty || value.isEmpty) continue;
    values[key] = _unquote(value);
  }
  return (values, rest);
}

String _unquote(String value) {
  if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
    return value
        .substring(1, value.length - 1)
        .replaceAll(r'\"', '"')
        .replaceAll(r'\\', r'\');
  }
  return value;
}

List<String> _parseTools(String? raw) {
  final value = raw?.trim() ?? '';
  if (!value.startsWith('[') || !value.endsWith(']')) return const [];
  return value
      .substring(1, value.length - 1)
      .split(',')
      .map((tool) => tool.trim().replaceAll('"', '').replaceAll("'", ''))
      .where((tool) => tool.isNotEmpty)
      .toList();
}