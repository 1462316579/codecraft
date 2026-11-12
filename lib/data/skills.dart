import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../agent/models/skill.dart';
import '../agent/tools/workspace.dart';
import 'workspaces.dart';

/// 技能目录(对齐上游 SkillRepository + SkillDirectoryScanner + SkillConfigRepository):
/// - 全局技能 `~/.codecraft/skills`(跨项目共享);
/// - 项目技能 `<当前工作区>/.codecraft/skills`(随工作区走,可 git 追踪);
/// - 启停配置存各自目录旁的 `skills.json`(只存禁用名单,两者取并集)。
class SkillsStore {
  SkillsStore({required this.globalRoot, required this.projectRoot});

  /// 全局技能目录(本机绝对路径)。
  final String globalRoot;

  /// 项目技能目录(本机绝对路径)。
  final String projectRoot;

  /// 允许一定的嵌套深度(比如 repo/skills/my-skill/SKILL.md)。
  static const int maxDepth = 4;

  String rootFor(SkillScope scope) =>
      scope == SkillScope.global ? globalRoot : projectRoot;

  /// 模型看到的目录写法。
  String displayRoot(SkillScope scope) =>
      scope == SkillScope.global ? '~/.codecraft/skills' : '~/workspace/.codecraft/skills';

  /// 全部技能(含来源作用域),未过滤禁用;同名技能项目级优先。
  Future<List<SkillEntry>> listAll() async {
    final merged = <String, SkillEntry>{};
    for (final skill in await _scan(SkillScope.global)) {
      merged[skill.name.toLowerCase()] = SkillEntry(skill, SkillScope.global);
    }
    for (final skill in await _scan(SkillScope.project)) {
      merged[skill.name.toLowerCase()] = SkillEntry(skill, SkillScope.project);
    }
    final entries = merged.values.toList()
      ..sort((a, b) => a.skill.name.toLowerCase().compareTo(b.skill.name.toLowerCase()));
    return entries;
  }

  /// 启用的技能(注入系统提示词用),禁用技能被过滤。
  Future<List<Skill>> listEnabled() async {
    final disabled = await disabledNames();
    return [
      for (final entry in await listAll())
        if (!disabled.contains(entry.skill.name.toLowerCase())) entry.skill,
    ];
  }

  /// 当前生效的禁用技能名集合(全局 + 项目并集,归一化为小写)。
  Future<Set<String>> disabledNames() async {
    final names = <String>{
      ...await _readDisabled(globalRoot),
      ...await _readDisabled(projectRoot),
    };
    return names.map((name) => name.toLowerCase()).toSet();
  }

  /// 读取指定技能的完整指令正文;不存在 / 解析失败 / 已被禁用时返回 null。
  Future<String?> loadInstructions(String name) async {
    if ((await disabledNames()).contains(name.toLowerCase())) return null;
    for (final scope in [SkillScope.project, SkillScope.global]) {
      for (final skill in await _scan(scope)) {
        if (skill.name.toLowerCase() == name.toLowerCase()) return skill.instructions;
      }
    }
    return null;
  }

  /// 在指定作用域启用/禁用某个技能。
  Future<void> setDisabled(String name, bool disabled, SkillScope scope) async {
    final names = (await _readDisabled(rootFor(scope))).toSet();
    if (disabled) {
      names.add(name);
    } else {
      names.removeWhere((entry) => entry.toLowerCase() == name.toLowerCase());
    }
    await _writeDisabled(rootFor(scope), names);
  }

  /// 写入技能文件(新建或编辑)。[originalName] 为编辑前的名称,新建时传 null;返回 null 表示成功。
  ///
  /// 编辑时写回原目录里的原指令文件(可能叫 CLAUDE.md),改名只改 frontmatter 的 name、不动目录名——
  /// 技能正文常按 `~/.codecraft/skills/<目录>/run.py` 引用同目录脚本,跟着改名会把这些引用打断。
  Future<SkillSaveError?> save(
    SkillForm form,
    SkillScope scope, {
    String? originalName,
  }) async {
    final name = form.name.trim();
    if (!isValidSkillName(name)) return SkillSaveError.invalidName;
    if (form.instructions.trim().isEmpty) return SkillSaveError.emptyInstructions;

    final entries = await listAll();
    SkillEntry? existing;
    for (final entry in entries) {
      if (entry.scope == scope && entry.skill.name.toLowerCase() == name.toLowerCase()) {
        existing = entry;
        break;
      }
    }
    final keepingName = originalName != null && originalName.toLowerCase() == name.toLowerCase();
    if (existing != null && !keepingName) return SkillSaveError.nameConflict;

    Skill? edited;
    if (originalName != null) {
      for (final entry in entries) {
        if (entry.scope == scope && entry.skill.name.toLowerCase() == originalName.toLowerCase()) {
          edited = entry.skill;
          break;
        }
      }
    }

    try {
      final dir = edited?.dirPath != null
          ? _localDir(scope, edited!.dirPath!)
          : p.join(rootFor(scope), name);
      await Directory(dir).create(recursive: true);
      final target = await _instructionFileIn(dir) ?? p.join(dir, 'SKILL.md');
      await File(target).writeAsString(serializeSkill(form));
      return null;
    } catch (_) {
      return SkillSaveError.ioFailed;
    }
  }

  /// 从 Markdown 文本导入技能到指定作用域;名称非法 / 同名冲突 / 正文为空时整体失败,不落盘。
  Future<SkillImportResult> importMarkdown(
    String text,
    String fallbackName,
    SkillScope scope,
  ) async {
    final skill = parseSkillText(text, fallbackName);
    final name = skill.name.trim();
    if (!isValidSkillName(name)) {
      return SkillImportResult(
        failures: [SkillImportFailure(name, SkillImportError.invalidName)],
      );
    }
    if (skill.instructions.trim().isEmpty) {
      return SkillImportResult(
        failures: [SkillImportFailure(name, SkillImportError.emptyContent)],
      );
    }
    for (final entry in await listAll()) {
      if (entry.scope == scope && entry.skill.name.toLowerCase() == name.toLowerCase()) {
        return SkillImportResult(
          failures: [SkillImportFailure(name, SkillImportError.nameConflict)],
        );
      }
    }
    try {
      final dir = Directory(p.join(rootFor(scope), name));
      await dir.create(recursive: true);
      await File(p.join(dir.path, 'SKILL.md')).writeAsString(text);
      return SkillImportResult(imported: [name]);
    } catch (_) {
      return SkillImportResult(
        failures: [SkillImportFailure(name, SkillImportError.ioFailed)],
      );
    }
  }

  /// 删除指定作用域的技能(删除其目录,不可恢复)。返回是否成功。
  Future<bool> delete(String name, SkillScope scope) async {
    for (final entry in await listAll()) {
      if (entry.skill.name.toLowerCase() != name.toLowerCase() || entry.scope != scope) continue;
      final dirPath = entry.skill.dirPath;
      if (dirPath == null) return false;
      final dir = Directory(_localDir(scope, dirPath));
      if (!await dir.exists()) return false;
      // 仅当目录里确实有指令文件时才删,避免误删非技能目录。
      final names = await dir
          .list()
          .where((entity) => entity is File)
          .map((entity) => p.basename(entity.path))
          .toList();
      if (instructionFileName(names) == null) return false;
      try {
        await dir.delete(recursive: true);
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  Future<List<Skill>> _scan(SkillScope scope) async {
    final dir = Directory(rootFor(scope));
    if (!await dir.exists()) return const [];
    final found = <Skill>[];
    await _visit(dir, scope, 0, found);
    found.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return found;
  }

  /// 递归查找含 SKILL.md / CLAUDE.md 的目录;IO 失败降级为空,不向上抛(扫描失败不该让调用方崩溃)。
  Future<void> _visit(Directory dir, SkillScope scope, int depth, List<Skill> out) async {
    if (depth > maxDepth) return;
    List<FileSystemEntity> entries;
    try {
      entries = await dir.list().toList();
    } catch (_) {
      return;
    }
    final instruction = instructionFileName([
      for (final entity in entries)
        if (entity is File) p.basename(entity.path),
    ]);
    if (instruction != null) {
      final skill = await _parseDir(dir.path, instruction, scope);
      if (skill != null) out.add(skill);
    }
    for (final entity in entries) {
      if (entity is Directory) await _visit(entity, scope, depth + 1, out);
    }
  }

  Future<Skill?> _parseDir(String dirPath, String fileName, SkillScope scope) async {
    try {
      final text = await File(p.join(dirPath, fileName)).readAsString();
      final skill = parseSkillText(text, p.basename(dirPath));
      return Skill(
        name: skill.name,
        description: skill.description,
        requiredTools: skill.requiredTools,
        dirPath: '${displayRoot(scope)}/${p.relative(dirPath, from: rootFor(scope))}',
        instructions: skill.instructions,
      );
    } catch (_) {
      return null;
    }
  }

  /// 展示路径(`~/.codecraft/skills/x`)→ 本机绝对目录。
  String _localDir(SkillScope scope, String dirPath) {
    final relative = p.relative(dirPath, from: displayRoot(scope));
    return p.join(rootFor(scope), relative);
  }

  /// 目录里已有的指令文件完整路径:SKILL.md 优先,其次 CLAUDE.md。
  Future<String?> _instructionFileIn(String dirPath) async {
    try {
      final names = await Directory(dirPath)
          .list()
          .where((entity) => entity is File)
          .map((entity) => p.basename(entity.path))
          .toList();
      final name = instructionFileName(names);
      return name == null ? null : p.join(dirPath, name);
    } catch (_) {
      return null;
    }
  }

  Future<Set<String>> _readDisabled(String skillsRoot) async {
    final file = _configFile(skillsRoot);
    try {
      if (!await file.exists()) return const {};
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return const {};
      final disabled = decoded['disabled'];
      if (disabled is! List) return const {};
      return disabled.whereType<String>().toSet();
    } catch (_) {
      return const {};
    }
  }

  /// 临时文件 + rename 原子落盘,避免写一半崩溃损坏配置。
  Future<void> _writeDisabled(String skillsRoot, Set<String> names) async {
    final file = _configFile(skillsRoot);
    await file.parent.create(recursive: true);
    final json = const JsonEncoder.withIndent('  ')
        .convert({'disabled': names.toList()..sort()});
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(json);
    try {
      await tmp.rename(file.path);
    } catch (_) {
      await file.writeAsString(json);
    }
  }

  File _configFile(String skillsRoot) => File(p.join(p.dirname(skillsRoot), 'skills.json'));
}

/// 技能仓库:跟随当前工作区与全局配置目录。
final skillsStoreProvider = Provider<SkillsStore>((ref) {
  return SkillsStore(
    globalRoot: p.join(ref.watch(configDirProvider), 'skills'),
    projectRoot: p.join(ref.watch(currentWorkspaceProvider).rootPath, '.codecraft', 'skills'),
  );
});

/// 技能列表(设置页与系统提示词用);增删改后由调用方 invalidate 刷新。
final skillsProvider = FutureProvider<List<SkillEntry>>(
  (ref) => ref.watch(skillsStoreProvider).listAll(),
);

/// 当前生效的禁用技能名集合(小写)。
final disabledSkillsProvider = FutureProvider<Set<String>>(
  (ref) => ref.watch(skillsStoreProvider).disabledNames(),
);