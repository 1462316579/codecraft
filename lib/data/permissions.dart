import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../agent/tools/workspace.dart';
import 'workspaces.dart';

/// 工具授权规则的作用域(对齐上游 PermissionScope):
/// scope 不存在规则对象里,而是由「存在哪个文件」隐含。
enum PermissionScope { project, global }

/// 规则判定方向:弹窗的「始终允许」只会产生 [allow];[deny] 仅由配置文件提供,
/// 评估时 deny 跨 scope 优先于 allow(安全优先:全局禁可挡项目允许)。
enum PermissionDecision { allow, deny }

/// 授权弹窗的用户选择:拒绝本次 / 仅放行本次 / 放行并记忆为规则。
enum PermissionChoice { reject, once, always }

/// 一条工具授权规则(对齐上游 PermissionRule)。
///
/// [pattern] 对 shell 命令是命令前缀(`git pull` 只命中 `git pull ...`),
/// 对非 shell 工具是通配 [wholeTool](整工具匹配)。
class PermissionRule {
  const PermissionRule({
    required this.toolName,
    this.pattern = wholeTool,
    this.decision = PermissionDecision.allow,
  });

  /// 非 shell 工具的整工具匹配模式。
  static const String wholeTool = '*';

  final String toolName;
  final String pattern;
  final PermissionDecision decision;

  /// 紧凑格式:`writeFile`(整工具)或 `Bash(git pull)`(带前缀)。
  static PermissionRule fromCompact(
    String compact, {
    PermissionDecision decision = PermissionDecision.allow,
  }) {
    final open = compact.indexOf('(');
    if (open >= 0 && compact.endsWith(')')) {
      return PermissionRule(
        toolName: compact.substring(0, open),
        pattern: compact.substring(open + 1, compact.length - 1),
        decision: decision,
      );
    }
    return PermissionRule(toolName: compact, decision: decision);
  }

  String toCompact() => pattern == wholeTool ? toolName : '$toolName($pattern)';

  @override
  bool operator ==(Object other) =>
      other is PermissionRule &&
      other.toolName == toolName &&
      other.pattern == pattern &&
      other.decision == decision;

  @override
  int get hashCode => Object.hash(toolName, pattern, decision);
}

/// 规则文件持久化(对齐上游 PermissionRulesRepository):
/// 项目级 `<工作区>/.codecraft/permissions.json`(随工作区走,可 git 追踪)、
/// 全局 `<配置目录>/permissions.json`;生效规则 = 项目 + 全局。
class PermissionRulesRepository {
  PermissionRulesRepository({required this.globalFile, required this.workspaceRoot});

  final File globalFile;

  /// 当前工作区根目录(项目级规则文件在其下的 `.codecraft/permissions.json`)。
  final String workspaceRoot;

  File get projectFile => File(p.join(workspaceRoot, '.codecraft', 'permissions.json'));

  Future<List<PermissionRule>> globalRules() => _read(globalFile);

  Future<List<PermissionRule>> projectRules() => _read(projectFile);

  /// 生效规则:项目在前、全局在后(deny 跨 scope 优先由引擎保证)。
  Future<List<PermissionRule>> effectiveRules() async => [
        ...await projectRules(),
        ...await globalRules(),
      ];

  Future<void> add(PermissionScope scope, PermissionRule rule) async {
    final rules = [...await _rulesOf(scope)];
    if (!rules.contains(rule)) rules.add(rule);
    await _setRulesOf(scope, rules);
  }

  Future<void> removeProjectRule(PermissionRule rule) async {
    final rules = [...await projectRules()]..remove(rule);
    await setProjectRules(rules);
  }

  Future<void> removeGlobalRule(PermissionRule rule) async {
    final rules = [...await globalRules()]..remove(rule);
    await setGlobalRules(rules);
  }

  /// 把一条项目规则提升为全局:项目删、全局加。
  Future<void> promoteToGlobal(PermissionRule rule) async {
    await removeProjectRule(rule);
    await add(PermissionScope.global, rule);
  }

  Future<void> setGlobalRules(List<PermissionRule> rules) => _write(globalFile, _serialize(rules));

  Future<void> setProjectRules(List<PermissionRule> rules) async {
    try {
      await _write(projectFile, _serialize(rules));
    } on FileSystemException {
      // Android Scoped Storage 未授权时项目级文件不可写：回退到全局文件,
      // 避免权限记忆功能完全失效(代价:规则变成全局而非项目级)。
      await _write(globalFile, _serialize(rules));
    }
  }

  Future<List<PermissionRule>> _rulesOf(PermissionScope scope) =>
      scope == PermissionScope.global ? globalRules() : projectRules();

  Future<void> _setRulesOf(PermissionScope scope, List<PermissionRule> rules) =>
      scope == PermissionScope.global ? setGlobalRules(rules) : setProjectRules(rules);

  Future<List<PermissionRule>> _read(File file) async {
    try {
      if (!await file.exists()) return const [];
      return parse(await file.readAsString());
    } catch (_) {
      return const [];
    }
  }

  /// 先写临时文件再改名,避免读到半截文件。
  Future<void> _write(File file, String content) async {
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(content, flush: true);
    await temp.rename(file.path);
  }

  /// 序列化为 `{"permissions":{"allow":[...],"deny":[...]}}`(漂亮打印,便于手工查看)。
  static String _serialize(List<PermissionRule> rules) {
    final root = <String, dynamic>{
      'permissions': {
        'allow': [
          for (final rule in rules)
            if (rule.decision == PermissionDecision.allow) rule.toCompact(),
        ],
        'deny': [
          for (final rule in rules)
            if (rule.decision == PermissionDecision.deny) rule.toCompact(),
        ],
      },
    };
    return const JsonEncoder.withIndent('  ').convert(root);
  }

  /// 解析规则文件;坏 JSON / 缺 permissions 时返回空列表,非法条目跳过。
  static List<PermissionRule> parse(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const [];
    }
    if (decoded is! Map) return const [];
    final permissions = decoded['permissions'];
    if (permissions is! Map) return const [];
    final result = <PermissionRule>[];
    void collect(Object? list, PermissionDecision decision) {
      if (list is! List) return;
      for (final entry in list) {
        if (entry is! String || entry.trim().isEmpty) continue;
        result.add(PermissionRule.fromCompact(entry.trim(), decision: decision));
      }
    }

    collect(permissions['allow'], PermissionDecision.allow);
    collect(permissions['deny'], PermissionDecision.deny);
    return result;
  }
}

/// 规则仓库(跟随当前工作区:切换工作区后项目级规则随之切换)。
final permissionRulesRepositoryProvider = Provider<PermissionRulesRepository>((ref) {
  return PermissionRulesRepository(
    globalFile: File(p.join(ref.watch(configDirProvider), 'permissions.json')),
    workspaceRoot: ref.watch(currentWorkspaceProvider).rootPath,
  );
});

/// 设置页用:项目与全局两份规则(增删后 invalidate 自身或 reload)。
class PermissionRulesState {
  const PermissionRulesState({required this.project, required this.global});

  final List<PermissionRule> project;
  final List<PermissionRule> global;
}

final permissionRulesProvider =
    AsyncNotifierProvider<PermissionRulesNotifier, PermissionRulesState>(
  PermissionRulesNotifier.new,
);

class PermissionRulesNotifier extends AsyncNotifier<PermissionRulesState> {
  @override
  Future<PermissionRulesState> build() async {
    final repository = ref.watch(permissionRulesRepositoryProvider);
    return PermissionRulesState(
      project: await repository.projectRules(),
      global: await repository.globalRules(),
    );
  }

  Future<void> removeProject(PermissionRule rule) async {
    await ref.read(permissionRulesRepositoryProvider).removeProjectRule(rule);
    ref.invalidateSelf();
  }

  Future<void> removeGlobal(PermissionRule rule) async {
    await ref.read(permissionRulesRepositoryProvider).removeGlobalRule(rule);
    ref.invalidateSelf();
  }

  Future<void> promote(PermissionRule rule) async {
    await ref.read(permissionRulesRepositoryProvider).promoteToGlobal(rule);
    ref.invalidateSelf();
  }
}