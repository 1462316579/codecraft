import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agent/tools/mcp_tools.dart';
import '../../agent/tools/tool.dart';
import '../../core/log/file_logger.dart';
import '../workspaces.dart';
import 'mcp_client.dart';
import 'mcp_config.dart';
import 'mcp_oauth.dart';
import 'mcp_stdio_transport.dart';
import 'mcp_transport.dart';

/// 单个 MCP server 的连接状态(对齐上游 McpServerStatus)。
enum McpServerState { connecting, connected, needsAuth, failed, disabled }

class McpServerStatus {
  const McpServerStatus({
    required this.name,
    required this.state,
    this.toolCount = 0,
    this.error,
  });

  final String name;
  final McpServerState state;

  /// 已注册给模型的工具数(不含被用户关掉的)。
  final int toolCount;
  final String? error;
}

class McpUiState {
  const McpUiState({
    this.statuses = const [],
    this.toolsByServer = const {},
    this.reloading = false,
  });

  final List<McpServerStatus> statuses;

  /// 每个已连接 server 的全部工具(含被关掉的,供设置页开关使用)。
  final Map<String, List<McpToolDescriptor>> toolsByServer;

  final bool reloading;

  McpUiState copyWith({
    List<McpServerStatus>? statuses,
    Map<String, List<McpToolDescriptor>>? toolsByServer,
    bool? reloading,
  }) =>
      McpUiState(
        statuses: statuses ?? this.statuses,
        toolsByServer: toolsByServer ?? this.toolsByServer,
        reloading: reloading ?? this.reloading,
      );
}

final mcpManagerProvider = NotifierProvider<McpManager, McpUiState>(McpManager.new);

/// MCP 连接编排(对齐上游 McpManager):
/// 读生效配置 → 并行连接全部启用的 server(各自独立失败)→ 注册工具给 Agent 循环。
/// CLI/stdio 型需要容器能力,暂时只标记状态不连接。
class McpManager extends Notifier<McpUiState> {
  final Map<String, McpClient> _clients = {};
  final Map<String, McpServerConfig> _configs = {};
  List<AgentTool> _activeTools = const [];
  Future<void>? _reloadFuture;

  /// 当前已连接 server 暴露给模型的工具(聊天循环同步读取)。
  List<AgentTool> get activeTools => _activeTools;

  /// MCP 连接/授权/工具调用事件写入文件日志(tag McpManager,消息带 [server] 前缀),
  /// 日志页按 server 名过滤查看(对齐上游 FileLogger + isMcpServerLogLine)。
  void _log(String serverName, String message, {bool isError = false}) {
    final line = '[$serverName] $message';
    if (isError) {
      AppLog.e('McpManager', line);
    } else {
      AppLog.i('McpManager', line);
    }
  }

  @override
  McpUiState build() {
    // 工作区/配置仓库变化(含 mcp.json 所在目录切换)后重连。
    ref.listen(mcpConfigRepositoryProvider, (previous, next) {
      if (!identical(previous, next)) unawaited(reload());
    });
    ref.onDispose(() {
      _teardown();
    });
    unawaited(reload());
    return const McpUiState();
  }

  /// 全量重连;并发调用时复用同一次重连。
  Future<void> reload() {
    final pending = _reloadFuture;
    if (pending != null) return pending;
    final future = _reload();
    _reloadFuture = future;
    return future.whenComplete(() {
      if (identical(_reloadFuture, future)) _reloadFuture = null;
    });
  }

  /// 新会话兜底:把尚未连接的启用 server 连上(不打断已连接的)。
  Future<void> reconnectUnconnected() async {
    final entries = await ref.read(mcpConfigRepositoryProvider).effectiveEntries();
    for (final entry in entries) {
      if (!entry.server.enabled) continue;
      if (_clients.containsKey(entry.server.name)) continue;
      await _connectOne(entry);
    }
  }

  /// 不阻塞调用方(新会话创建不应等待 MCP 就绪)。
  void reconnectUnconnectedAsync() {
    unawaited(reconnectUnconnected());
  }

  /// 只重连一个 server(保存配置 / 启用开关后用)。
  Future<void> reloadServer(String name) async {
    final entries = await ref.read(mcpConfigRepositoryProvider).effectiveEntries();
    final entry = entries.firstWhere(
      (item) => item.server.name == name,
      orElse: () => McpServerEntry(
        McpServerConfig(name: name),
        McpScope.global,
      ),
    );
    _teardownServer(name);
    if (!entry.server.enabled) {
      _setStatus(McpServerStatus(name: name, state: McpServerState.disabled));
      _setTools(name, const []);
      return;
    }
    _setStatus(McpServerStatus(name: name, state: McpServerState.connecting));
    await _connectOne(entry);
  }

  /// 触发某个 server 的 OAuth 授权;成功后重连使其工具可用。
  Future<void> authorize(String name) async {
    final entries = await ref.read(mcpConfigRepositoryProvider).effectiveEntries();
    final match = entries.where((item) => item.server.name == name).toList();
    if (match.isEmpty) throw StateError('未找到 MCP server: $name');
    await ref.read(mcpOAuthManagerProvider).authorize(match.first.server);
    _log(name, 'OAuth 授权成功');
    await reloadServer(name);
  }

  /// 退出登录:清除令牌并重连(将再次变为需要授权)。
  Future<void> logout(String name) async {
    final entries = await ref.read(mcpConfigRepositoryProvider).effectiveEntries();
    final match = entries.where((item) => item.server.name == name).toList();
    if (match.isEmpty) return;
    await ref.read(mcpOAuthManagerProvider).logout(match.first.server);
    _log(name, '已退出登录');
    await reloadServer(name);
  }

  /// 取消某个 server 正在进行的 OAuth 授权。
  Future<void> cancelAuthorize(String name) => ref.read(mcpOAuthManagerProvider).cancel(name);

  /// 该 server 是否已持有有效 OAuth 会话。
  bool isAuthorized(String name) => ref.read(mcpOAuthManagerProvider).isAuthorized(name);

  /// 重新拉取某个已连接 server 的工具列表(设置页「刷新工具」)。
  Future<void> refreshServerTools(String name) async {
    final client = _clients[name];
    if (client == null) {
      await reloadServer(name);
      return;
    }
    try {
      await client.refreshTools();
      _registerTools(name);
    } catch (error) {
      _setStatus(McpServerStatus(
        name: name,
        state: _stateFor(error),
        error: '$error',
      ));
    }
  }

  /// 记录一次 MCP 工具调用(聊天循环调用)。
  void logToolCall(String serverName, String toolName, {required bool isError}) {
    _log(serverName, '调用工具 $toolName${isError ? '(失败)' : ''}', isError: isError);
  }

  /// 删除 server:断开其连接并反注册工具,不影响其它 server。
  Future<void> removeServer(String name) async {
    final entries = await ref.read(mcpConfigRepositoryProvider).effectiveEntries();
    final match = entries.where((item) => item.server.name == name).toList();
    final scope = match.isEmpty ? McpScope.global : match.first.scope;
    await ref.read(mcpConfigRepositoryProvider).removeServer(name, scope);
    _teardownServer(name);
    state = state.copyWith(
      statuses: [for (final status in state.statuses) if (status.name != name) status],
      toolsByServer: {
        for (final entry in state.toolsByServer.entries)
          if (entry.key != name) entry.key: entry.value,
      },
    );
  }

  Future<void> _reload() async {
    final entries = await ref.read(mcpConfigRepositoryProvider).effectiveEntries();
    _teardown();
    state = McpUiState(
      statuses: [
        for (final entry in entries)
          McpServerStatus(
            name: entry.server.name,
            state: entry.server.enabled ? McpServerState.connecting : McpServerState.disabled,
          ),
      ],
      reloading: true,
    );
    await Future.wait([
      for (final entry in entries)
        if (entry.server.enabled) _connectOne(entry),
    ]);
    state = state.copyWith(reloading: false);
  }


  Future<void> _connectOne(McpServerEntry entry) async {
    final server = entry.server;
    _configs[server.name] = server;
    if (server.isStdio) {
      // 本地 stdio server 作为宿主 Termux 进程运行(对齐上游 StdioTransport)。
      final stdioTransport = McpStdioTransport(
        command: server.command.trim(),
        arguments: server.args,
        extraEnv: server.env,
      );
      final stdioClient = McpClient(serverName: server.name, transport: stdioTransport);
      _log(server.name, '启动 stdio server:${server.command} ${server.args.join(' ')}');
      try {
        await stdioTransport.start(
          projectPath: ref.read(currentWorkspaceProvider).rootPath,
        );
        final count = await stdioClient.connect();
        _clients[server.name] = stdioClient;
        _registerTools(server.name);
        _log(server.name, '连接成功,发现 $count 个工具');
      } catch (error) {
        try {
          stdioClient.close();
        } catch (_) {}
        _log(server.name, 'stdio server 启动失败:$error', isError: true);
        _setStatus(McpServerStatus(
          name: server.name,
          state: McpServerState.failed,
          error: '$error',
        ));
        _setTools(server.name, const []);
      }
      return;
    }
    if (server.url.trim().isEmpty) {
      _setStatus(McpServerStatus(
        name: server.name,
        state: McpServerState.failed,
        error: '缺少服务器地址',
      ));
      return;
    }
    // OAuth:恢复已有会话并在令牌过期时刷新(失败不阻塞,连接按 401 处理)。
    final oauth = ref.read(mcpOAuthManagerProvider);
    if (server.auth != null) {
      try {
        await oauth.prepare(server);
      } catch (_) {}
    }
    _log(server.name, '开始连接(HTTP ${server.url.trim()})');
    final client = McpClient(
      serverName: server.name,
      transport: McpHttpTransport(
        endpoint: server.url.trim(),
        headers: server.headers,
        authorizationProvider: () => oauth.cachedToken(server.name),
      ),
    );
    try {
      final count = await client.connect();
      _clients[server.name] = client;
      _registerTools(server.name);
      _log(server.name, '连接成功,发现 $count 个工具');
    } catch (error) {
      try {
        client.close();
      } catch (_) {}
      _log(
        server.name,
        error is McpAuthRequiredException ? '需要登录授权(HTTP 401)' : '连接失败:$error',
        isError: true,
      );
      _setStatus(McpServerStatus(
        name: server.name,
        state: _stateFor(error),
        error: error is McpAuthRequiredException ? null : '$error',
      ));
      _setTools(server.name, const []);
    }
  }

  /// 按当前配置的 disabledTools 重新生成该 server 的工具并注册。
  void _registerTools(String name) {
    final client = _clients[name];
    if (client == null) return;
    final config = _configs[name] ?? McpServerConfig(name: name);
    final tools = [
      for (final descriptor in client.tools)
        if (!config.disabledTools.contains(descriptor.name))
          McpTool(
            client: client,
            descriptor: descriptor,
            serverName: name,
            onCall: (toolName, isError) =>
                logToolCall(name, toolName, isError: isError),
          ),
    ];
    _activeTools = [
      for (final tool in _activeTools)
        if (!(tool is McpTool && tool.serverName == name)) tool,
      ...tools,
    ];
    _setTools(name, client.tools);
    _setStatus(McpServerStatus(
      name: name,
      state: McpServerState.connected,
      toolCount: tools.length,
    ));
  }

  void _setStatus(McpServerStatus status) {
    final replaced = [
      for (final existing in state.statuses)
        if (existing.name != status.name) existing,
    ];
    // 保持配置顺序:已有条目替换,新条目追加。
    final index = state.statuses.indexWhere((existing) => existing.name == status.name);
    if (index >= 0) {
      replaced.insert(index, status);
    } else {
      replaced.add(status);
    }
    state = state.copyWith(statuses: replaced);
  }

  void _setTools(String name, List<McpToolDescriptor> tools) {
    state = state.copyWith(toolsByServer: {...state.toolsByServer, name: tools});
  }

  McpServerState _stateFor(Object error) =>
      error is McpAuthRequiredException ? McpServerState.needsAuth : McpServerState.failed;

  void _teardownServer(String name) {
    final client = _clients.remove(name);
    if (client != null) {
      try {
        client.close();
      } catch (_) {}
    }
    _activeTools = [
      for (final tool in _activeTools)
        if (!(tool is McpTool && tool.serverName == name)) tool,
    ];
  }

  void _teardown() {
    for (final client in _clients.values) {
      try {
        client.close();
      } catch (_) {}
    }
    _clients.clear();
    _configs.clear();
    _activeTools = const [];
  }
}