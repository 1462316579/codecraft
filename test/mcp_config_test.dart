import 'dart:convert';
import 'dart:io';

import 'package:codecraft/data/mcp/mcp_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('MCP 配置:序列化与解析', () {
    test('往返:HTTP(含请求头)与 stdio(含参数/环境)都保留', () {
      const servers = [
        McpServerConfig(
          name: 'remote',
          url: 'https://example.com/mcp',
          headers: {'Authorization': 'Bearer x', 'X-Trace': '1'},
          disabledTools: {'dangerous'},
        ),
        McpServerConfig(
          name: 'local',
          command: 'npx',
          args: ['-y', '@modelcontextprotocol/server-filesystem'],
          env: {'HOME': '/root'},
          enabled: false,
        ),
      ];

      final json = McpConfigRepository.serialize(servers);
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect((decoded['mcpServers'] as Map).keys, ['remote', 'local']);

      final parsed = McpConfigRepository.parse(json);
      expect(parsed, hasLength(2));
      expect(parsed[0].name, 'remote');
      expect(parsed[0].url, 'https://example.com/mcp');
      expect(parsed[0].headers['Authorization'], 'Bearer x');
      expect(parsed[0].disabledTools, {'dangerous'});
      expect(parsed[0].isStdio, isFalse);
      expect(parsed[1].isStdio, isTrue);
      expect(parsed[1].args, ['-y', '@modelcontextprotocol/server-filesystem']);
      expect(parsed[1].env['HOME'], '/root');
      expect(parsed[1].enabled, isFalse);
    });

    test('约定字段省略/缺省:enabled 默认 true,空 heads/args 不写进 JSON', () {
      final json = McpConfigRepository.serialize(
        const [McpServerConfig(name: 'demo', url: 'https://x/mcp')],
      );
      final entry = (jsonDecode(json) as Map)['mcpServers']['demo'] as Map;
      expect(entry['url'], 'https://x/mcp');
      expect(entry['enabled'], isTrue);
      expect(entry.containsKey('headers'), isFalse);
      expect(entry.containsKey('command'), isFalse);
    });

    test('容错:坏 JSON / 缺 mcpServers / 缺 url 与 command 的条目都被跳过', () {
      expect(McpConfigRepository.parse('not json'), isEmpty);
      expect(McpConfigRepository.parse('{"foo":1}'), isEmpty);
      expect(
        McpConfigRepository.parse(
          '{"mcpServers":{"ok":{"url":"https://x/mcp"},"bad":{"enabled":true},"weird":3}}',
        ),
        hasLength(1),
      );
    });

    test('名称校验:只允许 ASCII 字母数字下划线连字符', () {
      expect(McpServerConfig.isValidName('fetch'), isTrue);
      expect(McpServerConfig.isValidName('my-server_2'), isTrue);
      expect(McpServerConfig.isValidName('中文'), isFalse);
      expect(McpServerConfig.isValidName('has space'), isFalse);
      expect(McpServerConfig.isValidName(''), isFalse);
    });
  });

  group('MCP 配置仓库:两级作用域', () {
    late Directory configDir;
    late Directory workspace;
    late McpConfigRepository repository;

    setUp(() {
      configDir = Directory.systemTemp.createTempSync('mcp_config');
      workspace = Directory.systemTemp.createTempSync('mcp_workspace');
      repository = McpConfigRepository(
        globalFile: File(p.join(configDir.path, 'mcp.json')),
        workspaceRoot: workspace.path,
      );
    });

    tearDown(() {
      configDir.deleteSync(recursive: true);
      workspace.deleteSync(recursive: true);
    });

    test('全局写在配置目录,项目写在 <工作区>/.codecraft/mcp.json', () async {
      await repository.saveServer(
        const McpServerConfig(name: 'global-one', url: 'https://g/mcp'),
        McpScope.global,
      );
      await repository.saveServer(
        const McpServerConfig(name: 'project-one', url: 'https://p/mcp'),
        McpScope.project,
      );

      expect(File(p.join(configDir.path, 'mcp.json')).existsSync(), isTrue);
      expect(File(p.join(workspace.path, '.codecraft', 'mcp.json')).existsSync(), isTrue);
      expect((await repository.globalServers()).single.name, 'global-one');
      expect((await repository.projectServers()).single.name, 'project-one');
    });

    test('生效配置:全局在前,同名项目项覆盖并保持位置', () async {
      await repository.setGlobalServers(const [
        McpServerConfig(name: 'a', url: 'https://a/mcp'),
        McpServerConfig(name: 'shared', url: 'https://global/shared'),
      ]);
      await repository.setProjectServers(const [
        McpServerConfig(name: 'shared', url: 'https://project/shared'),
        McpServerConfig(name: 'b', url: 'https://b/mcp'),
      ]);

      final entries = await repository.effectiveEntries();
      expect([for (final entry in entries) entry.server.name], ['a', 'shared', 'b']);
      expect(entries[1].server.url, 'https://project/shared');
      expect(entries[1].scope, McpScope.project);
      expect(entries[0].scope, McpScope.global);
    });

    test('保存同名覆盖、导入批量写入、删除只影响目标作用域', () async {
      await repository.saveServer(
        const McpServerConfig(name: 'demo', url: 'https://old/mcp'),
        McpScope.global,
      );
      await repository.saveServer(
        const McpServerConfig(name: 'demo', url: 'https://new/mcp'),
        McpScope.global,
      );
      expect((await repository.globalServers()).single.url, 'https://new/mcp');

      final imported = McpConfigRepository.parse(
        '{"mcpServers":{"x":{"url":"https://x/mcp"},"y":{"command":"npx"}}}',
      );
      expect(await repository.importServers(imported, McpScope.project), 2);
      expect((await repository.projectServers()).map((s) => s.name), ['x', 'y']);

      await repository.removeServer('x', McpScope.project);
      expect((await repository.projectServers()).map((s) => s.name), ['y']);
      expect((await repository.globalServers()).single.name, 'demo');
    });
  });
}