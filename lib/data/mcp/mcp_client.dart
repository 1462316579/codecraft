import 'mcp_transport.dart';

/// 一个 MCP 工具的描述(对齐上游 McpToolDescriptor)。
class McpToolDescriptor {
  const McpToolDescriptor({
    required this.name,
    this.description = '',
    this.inputSchema,
  });

  /// server 上的原始工具名(`tools/call` 用它)。
  final String name;
  final String description;
  final Map<String, dynamic>? inputSchema;

  static McpToolDescriptor? fromJson(Map<String, dynamic> map) {
    final name = map['name'];
    if (name is! String || name.isEmpty) return null;
    final schema = map['inputSchema'];
    return McpToolDescriptor(
      name: name,
      description: switch (map['description']) {
        final String text => text,
        _ => '',
      },
      inputSchema: schema is Map ? schema.cast<String, dynamic>() : null,
    );
  }
}

/// 一次 `tools/call` 的结果:拍平成文本的内容 + 是否报错(源自 MCP 的 `isError` 字段)。
class McpCallResult {
  const McpCallResult(this.text, this.isError);

  final String text;
  final bool isError;
}

/// 单个 MCP server 的会话客户端(对齐上游 McpClient):
/// [connect] 完成 initialize → notifications/initialized → tools/list 后,[tools] 即可用;
/// [callTool] 把一次调用转成 `tools/call`。任何一步失败都抛 [McpException],由上层按 server 兜底。
class McpClient {
  McpClient({required this.serverName, required this.transport});

  /// 协议版本(对齐上游;双方按此协商)。
  static const String protocolVersion = '2025-06-18';

  final String serverName;
  final McpTransport transport;

  List<McpToolDescriptor> tools = const [];

  /// 完整握手,返回拿到的工具数。
  Future<int> connect() async {
    await transport.request('initialize', {
      'protocolVersion': protocolVersion,
      'capabilities': <String, dynamic>{},
      'clientInfo': {'name': 'ai-code-editor', 'version': '1.0.0'},
    });
    await transport.notify('notifications/initialized');
    return refreshTools();
  }

  /// 重新拉取工具列表(配置变更或手动刷新时调用)。
  Future<int> refreshTools() async {
    final result = await transport.request('tools/list');
    final list = result?['tools'];
    if (list is! List) throw McpException('[$serverName] tools/list 未返回工具数组');
    tools = [
      for (final entry in list)
        if (entry is Map) McpToolDescriptor.fromJson(entry.cast<String, dynamic>()),
    ].whereType<McpToolDescriptor>().toList();
    return tools.length;
  }

  /// 执行一次工具调用,结果拍平为文本喂回模型。
  Future<McpCallResult> callTool(String toolName, Map<String, dynamic> arguments) async {
    final result = await transport.request('tools/call', {
      'name': toolName,
      'arguments': arguments,
    });
    final rawError = result?['isError'];
    final isError = rawError == true || '$rawError' == 'true';
    return McpCallResult(flattenContent(result?['content']), isError);
  }

  void close() => transport.close();

  /// 把 content 数组里各块转成纯文本:text 取正文,其余给类型占位。
  static String flattenContent(Object? content) {
    if (content is! List) return '';
    final buffer = StringBuffer();
    for (final block in content) {
      if (block is! Map) continue;
      final map = block.cast<String, dynamic>();
      switch (map['type']) {
        case 'text':
          buffer.write(switch (map['text']) {
            final String text => text,
            _ => '',
          });
        case 'image':
          buffer.write('[image content]');
        case 'resource':
          buffer.write('[resource content]');
        default:
          if (map['text'] is String) buffer.write(map['text'] as String);
      }
      buffer.write('\n');
    }
    return buffer.toString().trimRight();
  }
}