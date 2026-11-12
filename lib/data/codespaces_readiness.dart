import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'codespaces.dart';
import 'codespaces_engine.dart';
import 'codespaces_gh.dart';
import 'container/container_engine_provider.dart';
import 'container/command_engine.dart';
import 'credentials.dart';
import 'execution_target.dart';

/// GitHub Codespaces 就绪状态：凭证、gh/SSH helper、当前执行环境。
class CodespacesReadiness {
  const CodespacesReadiness({
    required this.hasGitHubCredential,
    required this.hasGh,
    this.ghHint,
    required this.target,
  });

  /// Git 凭据中是否存在可用于 github.com / Codespaces 的令牌。
  final bool hasGitHubCredential;

  /// 本地容器是否具备 `gh` 与 `gh-codespaces.sh`。
  final bool hasGh;

  /// gh 未就绪时的引导文案（与 [CodespacesEngine.ghMissingHint] 对齐）。
  final String? ghHint;

  final ExecutionTarget target;

  bool get canUseCodespaceCli => hasGitHubCredential && hasGh;
}

/// 探测 Codespaces 连接所需前置条件（不触发 GitHub REST）。
final codespacesReadinessProvider = FutureProvider<CodespacesReadiness>((ref) async {
  final store = ref.watch(credentialStoreProvider);
  final token = await codespacesTokenFrom(store);
  final hasCred = token.isNotEmpty;
  final local = await ref.watch(containerEngineProvider.future);
  final hasGh = await _hasGh(local);
  final target = ref.watch(executionTargetProvider);
  return CodespacesReadiness(
    hasGitHubCredential: hasCred,
    hasGh: hasGh,
    ghHint: hasGh ? null : CodespacesEngine.ghMissingHint,
    target: target,
  );
});

Future<bool> _hasGh(CommandEngine engine) async {
  final helper = CodespacesGhService.defaultGhHelper;
  final result = await engine.runCommandSync(
    'command -v gh >/dev/null 2>&1 && gh --version >/dev/null 2>&1 && test -x "$helper"',
    timeout: const Duration(seconds: 30),
  );
  return result.exitCode == 0;
}

/// 从 REST / gh / SSH 错误文本判断是否应引导用户去「Git 凭据」页。
bool codespacesErrorSuggestsCredentials(String? error) {
  if (error == null || error.trim().isEmpty) return false;
  final lower = error.toLowerCase();
  if (lower.contains(CodespacesEngine.credentialMissingHint.toLowerCase())) return true;
  return lower.contains('401') ||
      lower.contains('403') ||
      lower.contains('scope') ||
      lower.contains('credential') ||
      lower.contains('unauthorized') ||
      lower.contains('forbidden') ||
      lower.contains('permission denied') ||
      lower.contains('未配置') ||
      lower.contains('权限') ||
      lower.contains('凭据') ||
      lower.contains('令牌') ||
      lower.contains('auth') ||
      lower.contains('token');
}

/// 从错误文本判断是否与 gh/隧道/SSH 连接相关（应提示安装 gh 或检查网络/Codespace 状态）。
bool codespacesErrorSuggestsGhOrConnection(String? error) {
  if (error == null || error.trim().isEmpty) return false;
  final lower = error.toLowerCase();
  return lower.contains('gh') ||
      lower.contains('gh-codespaces') ||
      lower.contains('command not found') ||
      lower.contains('未找到命令') ||
      lower.contains(CodespacesEngine.connectionHint.toLowerCase().split('。').first) ||
      lower.contains('ssh') ||
      lower.contains('tunnel') ||
      lower.contains('隧道') ||
      lower.contains('连接') && lower.contains('codespace');
}
