import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../data/mcp/mcp_client.dart';
import '../../data/mcp/mcp_transport.dart';
import 'tool.dart';

/// 把一个 MCP server 工具适配成应用内的 [AgentTool](对齐上游 McpTool)。
///
/// 对模型暴露的名字做命名空间化(`mcp__<server>__<工具>`)并清洗成 function-calling
/// 合法字符;真正调用时用 server 上的原始工具名走 `tools/call`。
/// 入参 schema 直接透传 server 的 `inputSchema`,不走受限的 [ToolParameter]。
class McpTool extends AgentTool {
  McpTool({
    required this.client,
    required this.descriptor,
    required this.serverName,
    this.onCall,
  });

  final McpClient client;
  final McpToolDescriptor descriptor;
  final String serverName;

  /// 每次调用后的回调(管理器用它记录 MCP 日志)。
  final void Function(String toolName, bool isError)? onCall;

  /// function-calling 名称前缀与长度上限(provider 约束 `^[a-zA-Z0-9_-]{1,64}$`)。
  static const String namePrefix = 'mcp';
  static const int maxNameLength = 64;

  /// server 上的原始工具名(`tools/call` 必须用它)。
  String get remoteName => descriptor.name;

  @override
  late final String name = buildNamespacedName(serverName, remoteName);

  @override
  String get description => descriptor.description.trim().isEmpty
      ? 'MCP 工具 $remoteName(来自 $serverName)'
      : descriptor.description;

  /// MCP 工具的 schema 由 server 决定,这里只满足基类契约。
  @override
  Map<String, ToolParameter> get parameters => const {};

  /// 所有 MCP 工具统一走「需要用户确认」。
  @override
  ToolPermissionPolicy get permissionPolicy => ToolPermissionPolicy.ask;

  @override
  Set<ToolCapability> get capabilities => const {ToolCapability.externalTool};

  @override
  Map<String, dynamic> toJsonSchema() {
    final schema = descriptor.inputSchema;
    if (schema == null || schema.isEmpty) {
      return {'type': 'object', 'properties': <String, dynamic>{}};
    }
    return schema;
  }

  @override
  PermissionRequestText permissionRequest(Map<String, dynamic> args, String argsPreview) =>
      PermissionRequestText(
        title: '确认调用 MCP 工具',
        summary: 'AI 请求调用 MCP 工具「$remoteName」(服务 $serverName)',
        details: 'MCP 工具:$remoteName\n服务:$serverName\n参数:$argsPreview',
      );

  @override
  Future<ToolResult> execute(Map<String, dynamic> args, {String? sessionId}) async {
    try {
      final result = await client.callTool(remoteName, args);
      onCall?.call(remoteName, result.isError);
      return result.isError ? ToolError(result.text) : ToolSuccess(result.text);
    } on McpException catch (error) {
      onCall?.call(remoteName, true);
      return ToolError('MCP 工具执行失败:${error.message}');
    } catch (error) {
      onCall?.call(remoteName, true);
      return ToolError('MCP 工具执行异常:$error');
    }
  }

  /// 拼接命名空间名并清洗成合法字符;超长时截断并附 sha1 前 8 位(对齐上游)。
  static String buildNamespacedName(String server, String tool) {
    final raw = '${namePrefix}__${sanitize(server)}__${sanitize(tool)}';
    if (raw.length <= maxNameLength) return raw;
    final hash = sha1.convert(utf8.encode(raw)).toString().substring(0, 8);
    final suffix = '__$hash';
    return raw
            .substring(0, maxNameLength - suffix.length)
            .replaceAll(RegExp(r'[_-]+$'), '') +
        suffix;
  }

  /// 只按 ASCII 判定:中文等 Unicode 字母在 provider 的工具命名规范里不合法。
  static String sanitize(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
}