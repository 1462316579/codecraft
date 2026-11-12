import '../../data/mcp/mcp_config.dart';
import 'tool.dart';

/// 让模型自行管理 MCP 服务器配置(对齐上游 ManageMcpTool):
/// list / add_stdio / add_http / remove,作用域 global(默认)或 project。
/// 只改配置不自动安装运行时,也不直接触发重连(新配置在下次会话生效)。
class ManageMcpTool extends AgentTool {
  ManageMcpTool(this.repository);

  final McpConfigRepository repository;

  @override
  String get name => 'manageMcp';

  @override
  String get description => '管理 Model Context Protocol (MCP) 服务器。支持添加、删除与列表查询。'
      '添加/删除会修改 Agent 配置,不会自动安装 Node/Python 等运行时。';

  @override
  ToolPermissionPolicy get permissionPolicy => ToolPermissionPolicy.ask;

  @override
  Set<ToolCapability> get capabilities => const {ToolCapability.modifyAgentConfig};

  @override
  Map<String, ToolParameter> get parameters => const {
        'action': ToolParameter(
          name: 'action',
          type: ParameterType.string,
          description:
              '操作类型:list=列出服务器;add_stdio=添加本地 stdio 服务;add_http=添加远程 HTTP 服务;remove=移除服务器',
          enumValues: ['list', 'add_stdio', 'add_http', 'remove'],
        ),
        'server_name': ToolParameter(
          name: 'server_name',
          type: ParameterType.string,
          description: 'MCP 服务器名称(操作非 list 时必填),只能含 ASCII 字母、数字、下划线与连字符',
          required: false,
        ),
        'command': ToolParameter(
          name: 'command',
          type: ParameterType.string,
          description: '执行命令,如 npx 或 python (仅 add_stdio 必填)',
          required: false,
        ),
        'args': ToolParameter(
          name: 'args',
          type: ParameterType.array,
          description: '命令参数数组 (仅 add_stdio 可选)',
          required: false,
          itemsSchema: {'type': 'string'},
        ),
        'url': ToolParameter(
          name: 'url',
          type: ParameterType.string,
          description: 'HTTP 远程服务地址 (仅 add_http 必填)',
          required: false,
        ),
        'scope': ToolParameter(
          name: 'scope',
          type: ParameterType.string,
          description: '配置作用域:global(全局,默认)或 project(当前项目,仅当前工作区生效,项目级优先于全局)',
          enumValues: ['global', 'project'],
          required: false,
        ),
      };

  @override
  PermissionRequestText permissionRequest(Map<String, dynamic> args, String argsPreview) {
    final action = '${args['action'] ?? 'unknown'}';
    final server = '${args['server_name'] ?? '未指定'}';
    final scopeLabel = _scopeOf(args) == McpScope.project ? '当前项目' : '全局';
    final summary = switch (action) {
      'add_stdio' => '添加本地 MCP server:$server($scopeLabel)',
      'add_http' => '添加 HTTP MCP server:$server($scopeLabel)',
      'remove' => '移除 MCP server:$server($scopeLabel)',
      'list' => '列出 MCP server($scopeLabel)',
      _ => '管理 MCP server',
    };
    return PermissionRequestText(
      title: '确认修改 MCP 配置',
      summary: summary,
      details: '操作:$action\n服务:$server\n作用域:$scopeLabel\n'
          '该操作会修改 Agent 的 MCP 配置,新增配置将在下一次会话生效。',
    );
  }

  @override
  Future<ToolResult> execute(Map<String, dynamic> args, {String? sessionId}) async {
    final action = switch (args['action']) {
      final String text when text.isNotEmpty => text,
      _ => null,
    };
    if (action == null) return const ToolError('缺少必需参数:action');

    final scope = _scopeOf(args);
    final scopeLabel = scope == McpScope.project ? '当前项目' : '全局';
    switch (action) {
      case 'list':
        final servers = await _read(scope);
        return ToolSuccess(McpConfigRepository.serialize(servers));
      case 'remove':
        final name = _stringOf(args['server_name']);
        if (name == null) return const ToolError('remove 缺少必需参数:server_name');
        final servers = [...await _read(scope)];
        final before = servers.length;
        servers.removeWhere((entry) => entry.name == name);
        if (servers.length == before) {
          return ToolError('未找到$scopeLabel MCP server:$name');
        }
        await _write(scope, servers);
        return ToolSuccess('已移除$scopeLabel MCP server:$name');
      case 'add_stdio':
        final name = _stringOf(args['server_name']);
        if (name == null) return const ToolError('add_stdio 缺少必需参数:server_name');
        if (!McpServerConfig.isValidName(name)) return ToolError(_invalidNameMessage(name));
        final command = _stringOf(args['command']);
        if (command == null) return const ToolError('add_stdio 缺少必需参数:command');
        final commandArgs = switch (args['args']) {
          final List<Object?> list => [for (final entry in list) if (entry is String) entry],
          _ => const <String>[],
        };
        await _upsert(
          scope,
          McpServerConfig(name: name, command: command, args: commandArgs),
        );
        return ToolSuccess(
          '已添加$scopeLabel本地 MCP server:$name,配置将在下一次会话生效。'
          '若命令依赖 Node/Python 等运行时,请通过命令工具在用户确认后安装。',
        );
      case 'add_http':
        final name = _stringOf(args['server_name']);
        if (name == null) return const ToolError('add_http 缺少必需参数:server_name');
        if (!McpServerConfig.isValidName(name)) return ToolError(_invalidNameMessage(name));
        final url = _stringOf(args['url']);
        if (url == null) return const ToolError('add_http 缺少必需参数:url');
        await _upsert(scope, McpServerConfig(name: name, url: url));
        return ToolSuccess('已添加$scopeLabel HTTP MCP server:$name,配置将在下一次会话生效。');
      default:
        return ToolError('未知的 action:$action');
    }
  }

  Future<List<McpServerConfig>> _read(McpScope scope) =>
      scope == McpScope.project ? repository.projectServers() : repository.globalServers();

  Future<void> _write(McpScope scope, List<McpServerConfig> servers) =>
      scope == McpScope.project
          ? repository.setProjectServers(servers)
          : repository.setGlobalServers(servers);

  Future<void> _upsert(McpScope scope, McpServerConfig server) async {
    final servers = [...await _read(scope)]..removeWhere((entry) => entry.name == server.name);
    servers.add(server);
    await _write(scope, servers);
  }

  McpScope _scopeOf(Map<String, dynamic> args) {
    final raw = '${args['scope'] ?? ''}'.toLowerCase();
    return raw == 'project' ? McpScope.project : McpScope.global;
  }

  String? _stringOf(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  String _invalidNameMessage(String name) =>
      'server_name 只能含 ASCII 字母、数字、下划线与连字符(当前:$name)。'
      'server 名称会拼成 mcp__<server_name>__<tool> 送给模型,必须符合工具命名规范。';
}