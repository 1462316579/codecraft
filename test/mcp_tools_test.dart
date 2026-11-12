import 'dart:convert';
import 'dart:io';

import 'package:codecraft/agent/tools/manage_mcp_tool.dart';
import 'package:codecraft/agent/tools/mcp_tools.dart';
import 'package:codecraft/agent/tools/tool.dart';
import 'package:codecraft/data/mcp/mcp_client.dart';
import 'package:codecraft/data/mcp/mcp_config.dart';
import 'package:codecraft/data/mcp/mcp_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// 记录调用的假传输:可注入 tools/call 的返回。
class _RecordingTransport implements McpTransport {
  _RecordingTransport({this.callResult});

  Map<String, dynamic>? callResult;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<Map<String, dynamic>?> request(String method, [Map<String, dynamic>? params]) async {
    calls.add({'method': method, if (params != null) 'params': params});
    if (method == 'tools/call') {
      return callResult ?? {'content': [{'type': 'text', 'text': 'ok'}]};
    }
    return const {};
  }

  @override
  Future<void> notify(String method, [Map<String, dynamic>? params]) async {}

  @override
  void close() {}
}

McpTool _tool({
  String server = 'demo',
  String remote = 'search',
  String description = '搜一搜',
  Map<String, dynamic>? schema,
  McpTransport? transport,
}) {
  final client = McpClient(serverName: server, transport: transport ?? _RecordingTransport());
  return McpTool(
    client: client,
    serverName: server,
    descriptor: McpToolDescriptor(
      name: remote,
      description: description,
      inputSchema: schema,
    ),
  );
}

void main() {
  group('McpTool:命名与 schema', () {
    test('命名空间化前缀,中文与非 ASCII 字符清洗成下划线', () {
      expect(McpTool.buildNamespacedName('demo', 'search'), 'mcp__demo__search');
      // 中文与非 ASCII 字符全部清洗成下划线(数量按原字符数)
      expect(McpTool.buildNamespacedName('我的服务', '工具/一'), matches(RegExp(r'^mcp_+$')));
      expect(McpTool.sanitize('a.b c'), 'a_b_c');
    });

    test('超长名字截断并附 8 位哈希,长度不超过 64', () {
      final long = McpTool.buildNamespacedName('s' * 40, 't' * 40);
      expect(long.length, lessThanOrEqualTo(McpTool.maxNameLength));
      expect(long, matches(RegExp(r'^[a-zA-Z0-9_-]+$')));
      expect(long, contains('__'));
      // 同样的输入稳定(幂等),不同输入不冲突
      expect(McpTool.buildNamespacedName('s' * 40, 't' * 40), long);
      expect(McpTool.buildNamespacedName('s' * 40, 't' * 39), isNot(long));
    });

    test('描述缺省时回落,schema 直接透传 server 的 inputSchema', () {
      final tool = _tool(
        description: '',
        schema: {
          'type': 'object',
          'properties': {
            'q': {'type': 'string'},
          },
          'required': ['q'],
        },
      );
      expect(tool.description, 'MCP 工具 search(来自 demo)');
      expect(tool.capabilities, {ToolCapability.externalTool});
      expect(tool.permissionPolicy, ToolPermissionPolicy.ask);
      expect(tool.name, 'mcp__demo__search');
      expect(tool.remoteName, 'search');
      expect(tool.toJsonSchema()['required'], ['q']);

      final empty = _tool(schema: null);
      expect(empty.toJsonSchema(), {'type': 'object', 'properties': <String, dynamic>{}});
    });

    test('授权文案带工具名与服务名', () {
      final request = _tool().permissionRequest(const {}, '{}');
      expect(request.title, '确认调用 MCP 工具');
      expect(request.summary, 'AI 请求调用 MCP 工具「search」(服务 demo)');
      expect(request.details, contains('MCP 工具:search'));
    });
  });

  group('McpTool:执行', () {
    test('成功:tools/call 用 server 上的原始名,结果是拍平文本', () async {
      final transport = _RecordingTransport(
        callResult: {
          'content': [
            {'type': 'text', 'text': 'hello'},
          ],
        },
      );
      final tool = _tool(transport: transport);
      final result = await tool.execute({'q': 'x'});

      expect(result, isA<ToolSuccess>());
      expect((result as ToolSuccess).data, 'hello');
      expect(transport.calls.single['method'], 'tools/call');
      expect((transport.calls.single['params'] as Map)['name'], 'search');
      expect((transport.calls.single['params'] as Map)['arguments'], {'q': 'x'});
    });

    test('isError 为真时返回错误结果', () async {
      final transport = _RecordingTransport(
        callResult: {
          'content': [
            {'type': 'text', 'text': 'boom'},
          ],
          'isError': true,
        },
      );
      final result = await _tool(transport: transport).execute(const {});
      expect(result, isA<ToolError>());
      expect((result as ToolError).message, 'boom');
    });

    test('传输异常转成 ToolError 而不是抛出', () async {
      final result = await _tool(transport: _ThrowingTransport()).execute(const {});
      expect(result, isA<ToolError>());
      expect((result as ToolError).message, contains('MCP 工具执行失败'));
    });
  });

  group('manageMcp 工具', () {
    late Directory configDir;
    late Directory workspace;
    late McpConfigRepository repository;
    late ManageMcpTool tool;

    setUp(() {
      configDir = Directory.systemTemp.createTempSync('manage_mcp_config');
      workspace = Directory.systemTemp.createTempSync('manage_mcp_ws');
      repository = McpConfigRepository(
        globalFile: File(p.join(configDir.path, 'mcp.json')),
        workspaceRoot: workspace.path,
      );
      tool = ManageMcpTool(repository);
    });

    tearDown(() {
      configDir.deleteSync(recursive: true);
      workspace.deleteSync(recursive: true);
    });

    test('名称/权限/参数 schema', () {
      expect(tool.name, 'manageMcp');
      expect(tool.permissionPolicy, ToolPermissionPolicy.ask);
      expect(tool.capabilities, {ToolCapability.modifyAgentConfig});
      expect(tool.parameters.keys,
          ['action', 'server_name', 'command', 'args', 'url', 'scope']);
      expect(tool.parameters['action']!.enumValues, ['list', 'add_stdio', 'add_http', 'remove']);
    });

    test('add_http 写入全局,重复添加覆盖', () async {
      final result = await tool.execute({
        'action': 'add_http',
        'server_name': 'demo',
        'url': 'https://x/mcp',
      }) as ToolSuccess;
      expect('${result.data}', contains('已添加全局 HTTP MCP server:demo'));
      expect((await repository.globalServers()).single.url, 'https://x/mcp');

      await tool.execute({
        'action': 'add_http',
        'server_name': 'demo',
        'url': 'https://y/mcp',
        'scope': 'project',
      });
      expect((await repository.projectServers()).single.url, 'https://y/mcp');
      expect((await repository.globalServers()).single.url, 'https://x/mcp');
    });

    test('add_stdio 写参数数组;非法名与缺参数分别报错', () async {
      final result = await tool.execute({
        'action': 'add_stdio',
        'server_name': 'local',
        'command': 'npx',
        'args': ['-y', 'server-x'],
      }) as ToolSuccess;
      expect('${result.data}', contains('已添加全局本地 MCP server:local'));
      final saved = (await repository.globalServers()).single;
      expect(saved.command, 'npx');
      expect(saved.args, ['-y', 'server-x']);

      final invalid = await tool.execute({
        'action': 'add_http',
        'server_name': '中文名',
        'url': 'https://x/mcp',
      });
      expect(invalid, isA<ToolError>());
      expect((invalid as ToolError).message, contains('ASCII'));

      final missing = await tool.execute({'action': 'add_http', 'server_name': 'demo'});
      expect((missing as ToolError).message, contains('缺少必需参数:url'));
    });

    test('list 返回当前作用域配置 JSON;remove 删除并报未找到', () async {
      await tool.execute({
        'action': 'add_http',
        'server_name': 'demo',
        'url': 'https://x/mcp',
      });
      final listed = await tool.execute({'action': 'list'}) as ToolSuccess;
      final decoded = jsonDecode('${listed.data}') as Map<String, dynamic>;
      expect((decoded['mcpServers'] as Map).keys, ['demo']);

      final removed = await tool.execute({'action': 'remove', 'server_name': 'demo'}) as ToolSuccess;
      expect('${removed.data}', contains('已移除全局 MCP server:demo'));
      expect(await repository.globalServers(), isEmpty);

      final again = await tool.execute({'action': 'remove', 'server_name': 'demo'});
      expect((again as ToolError).message, contains('未找到全局 MCP server'));
    });

    test('缺 action / 未知 action 报错', () async {
      expect((await tool.execute(const {}) as ToolError).message, contains('缺少必需参数:action'));
      expect((await tool.execute({'action': 'nope'}) as ToolError).message, contains('未知的 action'));
    });

    test('授权文案按 action 与作用域拼接', () {
      expect(
        tool.permissionRequest({'action': 'add_http', 'server_name': 'demo', 'scope': 'project'}, '{}')
            .summary,
        '添加 HTTP MCP server:demo(当前项目)',
      );
      expect(
        tool.permissionRequest({'action': 'remove', 'server_name': 'demo'}, '{}').summary,
        '移除 MCP server:demo(全局)',
      );
    });
  });
}

class _ThrowingTransport implements McpTransport {
  @override
  Future<Map<String, dynamic>?> request(String method, [Map<String, dynamic>? params]) async =>
      throw const McpException('连接断开');

  @override
  Future<void> notify(String method, [Map<String, dynamic>? params]) async {}

  @override
  void close() {}
}