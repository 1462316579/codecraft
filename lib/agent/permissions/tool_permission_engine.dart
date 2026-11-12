import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/permissions.dart';
import '../models/chat_session.dart';
import '../tools/tool.dart';
import 'shell_parser.dart';

/// 一次工具调用的授权判定结论。
enum PermissionVerdict { allow, deny, ask }

/// 判定结果(对齐上游 EvalResult):ask 时带上「始终允许」会记忆的模式与不可记忆原因。
class PermissionEval {
  const PermissionEval({
    required this.verdict,
    this.rememberablePatterns = const [],
    this.denyReason,
    this.rememberDisabledReason,
    this.askTitle,
  });

  final PermissionVerdict verdict;

  /// 「始终允许」会记忆的模式;空表示不可记忆(UI 应禁用该按钮)。
  final List<String> rememberablePatterns;
  final String? denyReason;
  final String? rememberDisabledReason;

  /// ASK 时的弹窗标题覆盖(如「高危操作提权确认」);null 表示用工具默认标题。
  final String? askTitle;

  bool get rememberable => rememberablePatterns.isNotEmpty;
}

/// 工具授权策略引擎(对齐上游 ToolPermissionPolicyEngine 的通用分支):
/// 在弹窗之前评估一次工具调用应「自动放行 / 自动拒绝 / 询问」,并在用户选择「始终允许」后记忆规则。
///
/// 判定顺序:
///   1) 只读配置类工具(如 loadSkill)→ 放行;
///   2) 规则里整工具 DENY → 拒绝;
///   3) 规则里整工具 ALLOW → 放行;
///   4) 其余 → 询问;会改 Agent 配置或调用外部动态工具的能力不可记忆,其余可记忆「整工具」。
///
/// shell 工具的判定另有一套(逐条见 [_evaluateShell]):命令前缀规则、内置安全白名单、
/// 灾难性 rm 防护与 elevate 提权重试。
class ToolPermissionEngine {
  const ToolPermissionEngine(this._repository);

  final PermissionRulesRepository _repository;

  /// 只支持单次放行的能力(改 Agent 配置 / 调外部工具)。
  static const Set<ToolCapability> nonRememberableCapabilities = {
    ToolCapability.modifyAgentConfig,
    ToolCapability.externalTool,
    ToolCapability.modifyContainerEnv,
  };

  /// 以 `command` 参数承载 shell 命令、按命令前缀做指令级匹配的工具。
  static const Set<String> shellTools = {'Bash'};

  static const String nonRememberableReason =
      '该工具会修改 Agent 配置、容器环境或调用外部动态工具,为降低误授权风险,仅支持单次放行';

  static const String ruleDenyReason = '该工具被项目权限规则策略禁止执行';

  /// 浏览器只读动作(与 BrowserTool.readOnlyActions 保持一致,避免循环依赖)。
  static const Set<String> browserReadOnlyActions = {
    'getText',
    'getHtml',
    'getBackbone',
    'screenshot',
    'console',
    'wait',
    'listTabs',
  };

  Future<PermissionEval> evaluate({
    required AgentTool? tool,
    required String toolName,
    required AgentMode mode,
    Map<String, dynamic> args = const {},
  }) async {
    final capabilities = tool?.capabilities ?? const <ToolCapability>{};

    if (shellTools.contains(toolName)) {
      final rules = [
        for (final rule in await _repository.effectiveRules())
          if (rule.toolName == toolName) rule,
      ];
      return _evaluateShell(rules, args);
    }

    // 浏览器:只读查询自动放行;会改变页面/标签状态的动作走通用规则(可询问/记忆)。
    if (toolName == 'browser') {
      final action = (args['action'] as String?)?.trim() ?? '';
      if (browserReadOnlyActions.contains(action)) {
        return const PermissionEval(verdict: PermissionVerdict.allow);
      }
    }

    if (capabilities.length == 1 && capabilities.contains(ToolCapability.readAgentConfig)) {
      return const PermissionEval(verdict: PermissionVerdict.allow);
    }

    final rules = [
      for (final rule in await _repository.effectiveRules())
        if (rule.toolName == toolName) rule,
    ];
    return _evaluateGeneric(rules, capabilities);
  }

  /// 用户选择「始终允许」后把规则落库(写入当前项目 scope,对齐上游弹窗路径)。
  Future<void> remember(String toolName, List<String> patterns) async {
    for (final pattern in patterns.toSet()) {
      await _repository.add(
        PermissionScope.project,
        PermissionRule(toolName: toolName, pattern: pattern),
      );
    }
  }

  PermissionEval _evaluateGeneric(
    List<PermissionRule> rules,
    Set<ToolCapability> capabilities,
  ) {
    final whole = [
      for (final rule in rules)
        if (rule.pattern == PermissionRule.wholeTool) rule,
    ];
    if (whole.any((rule) => rule.decision == PermissionDecision.deny)) {
      return const PermissionEval(
        verdict: PermissionVerdict.deny,
        denyReason: ruleDenyReason,
      );
    }
    if (whole.any((rule) => rule.decision == PermissionDecision.allow)) {
      return const PermissionEval(verdict: PermissionVerdict.allow);
    }
    if (capabilities.any(nonRememberableCapabilities.contains)) {
      return const PermissionEval(
        verdict: PermissionVerdict.ask,
        rememberDisabledReason: nonRememberableReason,
      );
    }
    return const PermissionEval(
      verdict: PermissionVerdict.ask,
      rememberablePatterns: [PermissionRule.wholeTool],
    );
  }

  // ── shell 分支(逐值移植自上游 evaluateShell)──

  static const String shellUnrememberableReason =
      '含命令替换、管道或绝对路径重定向等无法静态判定的构造,仅可单次放行';
  static const String rmUnrememberableReason =
      '高风险删除操作(递归/通配/强制批量删除),为确保数据安全不可记忆,仅可单次放行';
  static const String elevateAskTitle = '高危操作提权确认';
  static const String elevateRememberDisabledReason =
      '命令命中内置安全防护,提权仅支持单次放行,不可记忆';

  static const String reasonRmRoot = '安全防护:禁止执行高危删除操作(根目录删除)';
  static const String reasonRmRelative = '安全防护:禁止执行高危删除操作(全局或相对路径通配删除)';
  static const String reasonRmHome = '安全防护:禁止执行高危删除操作(用户目录删除)';
  static const String reasonRmWorkspace = '安全防护:禁止执行高危删除操作(工作区根目录删除)';
  static const String reasonRmTmp = '安全防护:禁止执行高危删除操作(系统临时目录整体删除)';
  static const String reasonRmSystemDir = '安全防护:禁止执行高危删除操作(系统关键目录删除)';
  /// 相对/通配类删除目标(归一化后判定)。
  static const Set<String> relativeWildcardTargets = {'*', '.*', '.', '..', '../*', '../.*'};

  /// 工作区根目录的删除目标(归一化后判定)。
  static const Set<String> workspaceRootTargets = {
    'workspace', 'workspace/*', '/root/workspace', '/root/workspace/*',
  };

  /// 受保护的系统关键目录:命中其本身或其任意子路径即拦截。
  static const Set<String> protectedSystemDirs = {
    '/bin', '/boot', '/dev', '/etc', '/home', '/lib', '/lib64', '/lost+found',
    '/media', '/mnt', '/opt', '/proc', '/root', '/run', '/sbin', '/srv', '/sys', '/usr', '/var',
  };

  static final RegExp _rootLevelGlob = RegExp(r'^/[^/*?]*[*?]');

  /// 提权参数:命令因内置安全防护被拒时,可在调用时置 true 重试,降级为一次性用户授权。
  static const String elevateArg = 'elevate';

  bool _elevationRequested(Map<String, dynamic> args) =>
      args[elevateArg] == true || '${args[elevateArg]}'.toLowerCase() == 'true';

  /// 高危删除的处置:默认拒绝并提示可用 elevate 重试;带 elevate 时降级为一次性提权确认(弹窗、不可记忆)。
  PermissionEval _elevationOrDeny(String reason, Map<String, dynamic> args) {
    if (_elevationRequested(args)) {
      return const PermissionEval(
        verdict: PermissionVerdict.ask,
        askTitle: elevateAskTitle,
        rememberDisabledReason: elevateRememberDisabledReason,
      );
    }
    return PermissionEval(
      verdict: PermissionVerdict.deny,
      denyReason: '$reason(如确有必要,可加 elevate: true 重试,届时会弹窗请你一次性授权)',
    );
  }

  String? _catastrophicRemoveReason(List<List<String>> segments) {
    for (final segment in segments) {
      final rm = ShellCommandParser.parseRmInfo(segment);
      if (!rm.isRm) continue;
      for (final path in rm.targetPaths) {
        final reason = _catastrophicReasonFor(path);
        if (reason != null) return reason;
      }
    }
    return null;
  }

  /// 单个删除目标的裁决:命中受保护范围返回对应原因,否则 null。
  String? _catastrophicReasonFor(String rawPath) {
    final raw = rawPath.trim();
    if (raw.isEmpty) return null;
    final path = _normalizePath(raw);
    if (path == '/' || path == '/*') return reasonRmRoot;
    if (relativeWildcardTargets.contains(path)) return reasonRmRelative;
    if (_rootLevelGlob.hasMatch(path)) return reasonRmSystemDir;
    if (path == '/root' || path == '/root/*') return reasonRmHome;
    if (workspaceRootTargets.contains(path)) return reasonRmWorkspace;
    // 工作区子目录(构建产物等)属正常操作,置于系统目录判定之前放行。
    if (path.startsWith('/root/workspace/') || path.startsWith('workspace/')) return null;
    if (path == '/tmp' || path == '/tmp/*') return reasonRmTmp;
    for (final dir in protectedSystemDirs) {
      if (path == dir || path.startsWith('$dir/')) return reasonRmSystemDir;
    }
    return null;
  }

  /// 词法路径归一化:展开 `~`/`$HOME`,折叠重复 `/`,解析 `.` 与 `..`(不访问文件系统)。
  String _normalizePath(String raw) {
    final String expanded;
    if (raw == '~') {
      expanded = '/root';
    } else if (raw.startsWith('~/')) {
      expanded = '/root${raw.substring(1)}';
    } else if (raw == r'$HOME' || raw == r'${HOME}') {
      expanded = '/root';
    } else if (raw.startsWith(r'$HOME/')) {
      expanded = '/root${raw.substring(5)}';
    } else if (raw.startsWith(r'${HOME}/')) {
      expanded = '/root${raw.substring(7)}';
    } else {
      expanded = raw;
    }
    final absolute = expanded.startsWith('/');
    final parts = <String>[];
    for (final part in expanded.split('/')) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') {
        if (parts.isNotEmpty && parts.last != '..') {
          parts.removeLast();
        } else if (!absolute) {
          parts.add('..');
        }
      } else {
        parts.add(part);
      }
    }
    final joined = parts.join('/');
    if (absolute) return '/$joined';
    return joined.isEmpty ? '.' : joined;
  }

  PermissionEval _evaluateShell(List<PermissionRule> rules, Map<String, dynamic> args) {
    final command = args['command'];
    if (command is! String || command.trim().isEmpty) {
      return const PermissionEval(
        verdict: PermissionVerdict.ask,
        rememberDisabledReason: shellUnrememberableReason,
      );
    }
    final analysis = ShellCommandParser.analyze(command);
    final allow = [
      for (final rule in rules)
        if (rule.decision == PermissionDecision.allow) rule,
    ];
    final deny = [
      for (final rule in rules)
        if (rule.decision == PermissionDecision.deny) rule,
    ];

    // 0) rm 高危操作防护(提权可降级为一次性授权)。
    final catastrophic = _catastrophicRemoveReason(analysis.segments);
    if (catastrophic != null) return _elevationOrDeny(catastrophic, args);

    // 1) DENY 优先(含覆盖内置安全白名单)。
    if (analysis.segments
        .any((segment) => deny.any((rule) => ShellCommandParser.matches(rule.pattern, segment)))) {
      return const PermissionEval(
        verdict: PermissionVerdict.deny,
        denyReason: ruleDenyReason,
      );
    }

    // 2) 不可静态判定 → 必须弹窗、不可记忆(内置白名单也不适用)。
    if (!analysis.analyzable) {
      return const PermissionEval(
        verdict: PermissionVerdict.ask,
        rememberDisabledReason: shellUnrememberableReason,
      );
    }

    // 3) 内置安全白名单:每段都命中安全前缀 → 自动放行。
    if (analysis.segments.isNotEmpty &&
        analysis.segments.every(BuiltInSafeCommands.isSafe)) {
      return const PermissionEval(verdict: PermissionVerdict.allow);
    }

    // 4) 已记忆的 ALLOW:每段都命中 → 放行(rm 额外校验目标,避免宽泛的 rm 规则放行高风险删除)。
    final allAllowed = analysis.segments.isNotEmpty &&
        analysis.segments.every((segment) {
          final rm = ShellCommandParser.parseRmInfo(segment);
          return allow.any((rule) {
            if (!ShellCommandParser.matches(rule.pattern, segment)) return false;
            if (!rm.isRm) return true;
            final ruleRm = ShellCommandParser.parseRmInfo(
              rule.pattern.split(RegExp(r'\s+')),
            );
            return ruleRm.targetPaths.isNotEmpty && (!rm.isRecursive || ruleRm.isRecursive);
          });
        });
    if (allAllowed) return const PermissionEval(verdict: PermissionVerdict.allow);

    // 5) 高风险删除:不可记忆,只可单次放行。
    final hasRmUnrememberable = analysis.segments.any((segment) {
      final rm = ShellCommandParser.parseRmInfo(segment);
      return rm.isRm && (rm.targetPaths.isEmpty || rm.isRecursive || rm.isWildcard);
    });
    if (hasRmUnrememberable) {
      return const PermissionEval(
        verdict: PermissionVerdict.ask,
        rememberDisabledReason: rmUnrememberableReason,
      );
    }

    // 6) 否则弹窗,可记忆前缀(子命令分发器记「程序名+子命令」)。
    final rememberable = <String>{
      for (final segment in analysis.segments)
        if (ShellCommandParser.rememberablePrefix(segment) case final prefix?) prefix,
    };
    return PermissionEval(
      verdict: PermissionVerdict.ask,
      rememberablePatterns: rememberable.toList(),
    );
  }
}
/// 权限引擎(跟随当前工作区与规则文件)。
final toolPermissionEngineProvider = Provider<ToolPermissionEngine>(
  (ref) => ToolPermissionEngine(ref.watch(permissionRulesRepositoryProvider)),
);
