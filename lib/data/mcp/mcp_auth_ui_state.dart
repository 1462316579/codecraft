import 'package:flutter_riverpod/flutter_riverpod.dart';

/// OAuth 授权弹层/区块的界面状态(对齐上游 McpAuthUiState):按 server 隔离,
/// 只展示属于当前 server 的进行中/成功/失败信息,避免 A 的报错串到 B。
class McpAuthUiState {
  const McpAuthUiState({
    this.serverName,
    this.inProgress = false,
    this.success = false,
    this.error,
  });

  final String? serverName;
  final bool inProgress;
  final bool success;
  final String? error;
}

final mcpAuthUiStateProvider =
    NotifierProvider<McpAuthUiNotifier, McpAuthUiState>(McpAuthUiNotifier.new);

class McpAuthUiNotifier extends Notifier<McpAuthUiState> {
  @override
  McpAuthUiState build() => const McpAuthUiState();

  void start(String serverName) {
    state = McpAuthUiState(serverName: serverName, inProgress: true);
  }

  void succeed(String serverName) {
    state = McpAuthUiState(serverName: serverName, success: true);
  }

  void fail(String serverName, String message) {
    state = McpAuthUiState(serverName: serverName, error: message);
  }

  void clear() {
    state = const McpAuthUiState();
  }
}
