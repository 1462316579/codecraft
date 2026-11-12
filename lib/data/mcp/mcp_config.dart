import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../agent/tools/workspace.dart';
import '../workspaces.dart';

/// MCP 配置作用域:全局(跨项目共享)或项目级(仅当前工作区生效)。
enum McpScope { global, project }

/// 远程 MCP server 的认证配置(对齐上游 McpAuthConfig)。目前只支持 OAuth;
/// 令牌与 client_secret 不在此结构里,另存于 McpTokenStore(`mcp-oauth.json`)。
class McpAuthConfig {
  const McpAuthConfig({
    this.type = typeOAuth,
    this.clientId,
    this.authServer,
    this.scopes,
  });

  static const String typeOAuth = 'oauth';

  final String type;

  /// 预注册的 OAuth client_id;留空则尝试动态客户端注册。
  final String? clientId;

  /// 覆盖发现到的授权服务器 issuer。
  final String? authServer;

  /// 显式请求的 scope;留空则按 401 挑战与元数据推导。
  final List<String>? scopes;

  Map<String, dynamic> toJson() => {
        'type': type,
        if (clientId != null && clientId!.isNotEmpty) 'clientId': clientId,
        if (authServer != null && authServer!.isNotEmpty) 'authServer': authServer,
        if (scopes != null && scopes!.isNotEmpty) 'scopes': scopes,
      };

  static McpAuthConfig? fromJson(Object? value) {
    if (value is! Map) return null;
    final map = value.cast<String, dynamic>();
    return McpAuthConfig(
      type: map['type'] is String ? map['type'] as String : typeOAuth,
      clientId: map['clientId'] is String ? map['clientId'] as String : null,
      authServer: map['authServer'] is String ? map['authServer'] as String : null,
      scopes: switch (map['scopes']) {
        final List<Object?> list => [for (final item in list) if (item is String) item],
        _ => null,
      },
    );
  }
}

/// 一条 MCP 服务器配置(对齐上游 McpServerConfig):
/// 远程 HTTP(有 url)或本地 stdio(有 command)两种形态,由 [isStdio] 推断。
class McpServerConfig {
  const McpServerConfig({
    required this.name,
    this.url = '',
    this.headers = const {},
    this.command = '',
    this.args = const [],
    this.env = const {},
    this.enabled = true,
    this.disabledTools = const {},
    this.auth,
  });

  final String name;
  final String url;
  final Map<String, String> headers;
  final String command;
  final List<String> args;
  final Map<String, String> env;
  final bool enabled;

  /// 被用户关掉的工具名(server 上的原始名),连接后不注册给模型。
  final Set<String> disabledTools;

  /// 远程 HTTP 形态的 OAuth 认证配置;null 表示不使用 OAuth。
  final McpAuthConfig? auth;

  bool get isStdio => command.trim().isNotEmpty;

  static final RegExp _namePattern = RegExp(r'^[a-zA-Z0-9_-]+$');

  /// server 名会拼进工具名 `mcp__<server>__<tool>`,只允许 ASCII 字母数字下划线连字符。
  static bool isValidName(String name) => _namePattern.hasMatch(name);

  McpServerConfig copyWith({
    String? name,
    String? url,
    Map<String, String>? headers,
    String? command,
    List<String>? args,
    Map<String, String>? env,
    bool? enabled,
    Set<String>? disabledTools,
    McpAuthConfig? Function()? auth,
  }) =>
      McpServerConfig(
        name: name ?? this.name,
        url: url ?? this.url,
        headers: headers ?? this.headers,
        command: command ?? this.command,
        args: args ?? this.args,
        env: env ?? this.env,
        enabled: enabled ?? this.enabled,
        disabledTools: disabledTools ?? this.disabledTools,
        auth: auth == null ? this.auth : auth(),
      );

  /// 序列化为 mcpServers 里的一条(name 是外层的键,不写进值里)。
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (isStdio) {
      map['command'] = command;
      if (args.isNotEmpty) map['args'] = args;
      if (env.isNotEmpty) map['env'] = env;
    } else {
      map['url'] = url;
      if (headers.isNotEmpty) map['headers'] = headers;
    }
    if (auth != null) map['auth'] = auth!.toJson();
    map['enabled'] = enabled;
    if (disabledTools.isNotEmpty) map['disabledTools'] = disabledTools.toList();
    return map;
  }

  /// 解析 mcpServers 里的一条;缺 url 与 command 时返回 null(无法识别)。
  static McpServerConfig? fromJson(String name, Object? value) {
    if (value is! Map) return null;
    final map = value.cast<String, dynamic>();
    final command = switch (map['command']) {
      final String text when text.trim().isNotEmpty => text,
      _ => '',
    };
    final url = switch (map['url']) {
      final String text when text.trim().isNotEmpty => text,
      _ => '',
    };
    final disabledTools = switch (map['disabledTools']) {
      final List<Object?> list => {
          for (final entry in list)
            if (entry is String && entry.isNotEmpty) entry,
        },
      _ => <String>{},
    };
    final enabled = map['enabled'] is bool ? map['enabled'] as bool : true;
    if (command.isNotEmpty) {
      return McpServerConfig(
        name: name,
        command: command,
        args: switch (map['args']) {
          final List<Object?> list => [for (final entry in list) if (entry is String) entry],
          _ => const <String>[],
        },
        env: _stringMap(map['env']),
        enabled: enabled,
        disabledTools: disabledTools,
      );
    }
    if (url.isNotEmpty) {
      return McpServerConfig(
        name: name,
        url: url,
        headers: _stringMap(map['headers']),
        enabled: enabled,
        disabledTools: disabledTools,
        auth: McpAuthConfig.fromJson(map['auth']),
      );
    }
    return null;
  }

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return const {};
    return {
      for (final entry in value.entries)
        if (entry.value is String) '${entry.key}': entry.value as String,
    };
  }
}

/// 一个生效的 MCP 条目:配置 + 来源作用域(UI 上标注「全局/项目」)。
class McpServerEntry {
  const McpServerEntry(this.server, this.scope);

  final McpServerConfig server;
  final McpScope scope;
}

/// MCP 配置持久化(对齐上游 McpConfigRepository):
/// - 全局:`<配置目录>/mcp.json`(与容器内 `~/.codecraft/mcp.json` 是同一份);
/// - 项目级:`<工作区>/.codecraft/mcp.json`(随工作区走,可 git 追踪)。
/// 生效配置 = 全局 + 项目合并,项目级优先覆盖同名。
class McpConfigRepository {
  McpConfigRepository({required this.globalFile, required this.workspaceRoot});

  /// 全局配置文件。
  final File globalFile;

  /// 当前工作区根目录(项目级配置在其下的 `.codecraft/mcp.json`)。
  final String workspaceRoot;

  static const String _defaultJson = '{"mcpServers":{}}';
  static const String _codecraftDirName = '.codecraft';
  static const String _configFileName = 'mcp.json';

  File get projectFile => File(p.join(workspaceRoot, _codecraftDirName, _configFileName));

  /// 全局配置(文件不存在/读失败视为空)。
  Future<List<McpServerConfig>> globalServers() async => parse(await _read(globalFile));

  /// 项目级配置。
  Future<List<McpServerConfig>> projectServers() async => parse(await _read(projectFile));

  Future<void> setGlobalServers(List<McpServerConfig> servers) =>
      _write(globalFile, serialize(servers));

  Future<void> setProjectServers(List<McpServerConfig> servers) =>
      _write(projectFile, serialize(servers));

  /// 生效条目(全局在前,项目覆盖同名并保持原位置),供连接与列表使用。
  Future<List<McpServerEntry>> effectiveEntries() async {
    final byName = <String, McpServerEntry>{};
    for (final server in await globalServers()) {
      byName[server.name] = McpServerEntry(server, McpScope.global);
    }
    for (final server in await projectServers()) {
      byName[server.name] = McpServerEntry(server, McpScope.project);
    }
    return byName.values.toList();
  }

  Future<List<McpServerConfig>> effectiveServers() async =>
      [for (final entry in await effectiveEntries()) entry.server];

  /// 新建/覆盖某个作用域下的一条配置(同名覆盖,保持原有顺序)。
  Future<void> saveServer(McpServerConfig server, McpScope scope) async {
    final servers = [...await _serversOf(scope)];
    final index = servers.indexWhere((entry) => entry.name == server.name);
    if (index >= 0) {
      servers[index] = server;
    } else {
      servers.add(server);
    }
    await _setServersOf(scope, servers);
  }

  Future<void> removeServer(String name, McpScope scope) async {
    final servers = [...await _serversOf(scope)]..removeWhere((entry) => entry.name == name);
    await _setServersOf(scope, servers);
  }

  /// 批量导入(JSON 导入用):同名覆盖,新增的追加到末尾。
  Future<int> importServers(List<McpServerConfig> incoming, McpScope scope) async {
    final servers = [...await _serversOf(scope)];
    for (final server in incoming) {
      final index = servers.indexWhere((entry) => entry.name == server.name);
      if (index >= 0) {
        servers[index] = server;
      } else {
        servers.add(server);
      }
    }
    await _setServersOf(scope, servers);
    return incoming.length;
  }

  Future<List<McpServerConfig>> _serversOf(McpScope scope) =>
      scope == McpScope.project ? projectServers() : globalServers();

  Future<void> _setServersOf(McpScope scope, List<McpServerConfig> servers) =>
      scope == McpScope.project ? setProjectServers(servers) : setGlobalServers(servers);

  Future<String> _read(File file) async {
    try {
      if (!await file.exists()) return _defaultJson;
      final text = await file.readAsString();
      return text.trim().isEmpty ? _defaultJson : text;
    } catch (_) {
      return _defaultJson;
    }
  }

  /// 先写临时文件再改名,避免读到半截文件。
  Future<void> _write(File file, String content) async {
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(content, flush: true);
    await temp.rename(file.path);
  }

  /// 序列化为标准 mcpServers 格式(漂亮打印,便于手工查看/纳入版本控制)。
  static String serialize(List<McpServerConfig> servers) {
    final root = <String, dynamic>{
      'mcpServers': {
        for (final server in servers) server.name: server.toJson(),
      },
    };
    return const JsonEncoder.withIndent('  ').convert(root);
  }

  /// 解析标准 mcpServers 格式;JSON 坏掉或缺 mcpServers 时返回空列表。
  static List<McpServerConfig> parse(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const [];
    }
    if (decoded is! Map) return const [];
    final servers = decoded['mcpServers'];
    if (servers is! Map) return const [];
    final result = <McpServerConfig>[];
    servers.forEach((key, value) {
      final server = McpServerConfig.fromJson('$key', value);
      if (server != null) result.add(server);
    });
    return result;
  }
}

/// MCP 配置仓库(跟随当前工作区:切换工作区会重建,项目级配置随之切换)。
final mcpConfigRepositoryProvider = Provider<McpConfigRepository>((ref) {
  return McpConfigRepository(
    globalFile: File(p.join(ref.watch(configDirProvider), 'mcp.json')),
    workspaceRoot: ref.watch(currentWorkspaceProvider).rootPath,
  );
});

/// 生效的 MCP 条目(全局 + 项目合并)。保存/删除后由调用方 invalidate。
final mcpEntriesProvider = FutureProvider<List<McpServerEntry>>(
  (ref) => ref.watch(mcpConfigRepositoryProvider).effectiveEntries(),
);