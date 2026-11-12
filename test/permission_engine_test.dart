import 'dart:io';

import 'package:codecraft/agent/permissions/tool_permission_engine.dart';
import 'package:codecraft/agent/tools/file_tools.dart';
import 'package:codecraft/data/workspace_files.dart';
import 'package:codecraft/agent/tools/manage_mcp_tool.dart';
import 'package:codecraft/agent/tools/mcp_tools.dart';
import 'package:codecraft/agent/tools/skill_tool.dart';
import 'package:codecraft/agent/tools/tool.dart';
import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/agent/models/chat_session.dart';
import 'package:codecraft/data/mcp/mcp_client.dart';
import 'package:codecraft/data/mcp/mcp_config.dart';
import 'package:codecraft/data/mcp/mcp_transport.dart';
import 'package:codecraft/data/permissions.dart';
import 'package:codecraft/data/skills.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class _NoopTransport implements McpTransport {
  @override
  Future<Map<String, dynamic>?> request(String method, [Map<String, dynamic>? params]) async =>
      const {};

  @override
  Future<void> notify(String method, [Map<String, dynamic>? params]) async {}

  @override
  void close() {}
}

void main() {
  late Directory configDir;
  late Directory workspace;
  late PermissionRulesRepository repository;
  late ToolPermissionEngine engine;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('engine_config');
    workspace = Directory.systemTemp.createTempSync('engine_ws');
    repository = PermissionRulesRepository(
      globalFile: File(p.join(configDir.path, 'permissions.json')),
      workspaceRoot: workspace.path,
    );
    engine = ToolPermissionEngine(repository);
  });

  tearDown(() {
    configDir.deleteSync(recursive: true);
    workspace.deleteSync(recursive: true);
  });

  final ws = Workspace('/root/workspace');
  Future<WorkspaceFiles> localFiles() async => const LocalWorkspaceFiles();
  final writeFile = WriteFileTool(ws, localFiles);
  final readFile = ReadFileTool(ws, localFiles);
  final mcpTool = McpTool(
    client: McpClient(serverName: 'demo', transport: _NoopTransport()),
    serverName: 'demo',
    descriptor: const McpToolDescriptor(name: 'search'),
  );
  final manageMcp = ManageMcpTool(
    McpConfigRepository(
      globalFile: File('/root/workspace/.codecraft/mcp.json'),
      workspaceRoot: '/root/workspace',
    ),
  );
  final loadSkill = LoadSkillTool(
    SkillsStore(globalRoot: '/tmp/skills-g', projectRoot: '/tmp/skills-p'),
  );

  Future<PermissionEval> evaluate(
    AgentTool tool, {
    AgentMode mode = AgentMode.build,
  }) =>
      engine.evaluate(tool: tool, toolName: tool.name, mode: mode);

  group('无规则时的默认判定', () {
    test('写类工具 → 询问且可记忆整工具', () async {
      final eval = await evaluate(writeFile);
      expect(eval.verdict, PermissionVerdict.ask);
      expect(eval.rememberablePatterns, [PermissionRule.wholeTool]);
      expect(eval.rememberDisabledReason, isNull);
    });

    test('MCP 工具与 manageMcp → 询问但不可记忆', () async {
      for (final tool in [mcpTool, manageMcp]) {
        final eval = await evaluate(tool);
        expect(eval.verdict, PermissionVerdict.ask, reason: tool.name);
        expect(eval.rememberablePatterns, isEmpty);
        expect(eval.rememberDisabledReason, isNotNull);
      }
    });

    test('只读配置类工具(loadSkill)→ 直接放行', () async {
      final eval = await evaluate(loadSkill);
      expect(eval.verdict, PermissionVerdict.allow);
    });

    test('只读工作区工具(readFile):引擎给 ask,但工具自身为自动放行 → 控制器直接执行不弹窗', () async {
      final eval = await evaluate(readFile);
      expect(eval.verdict, PermissionVerdict.ask);
      expect(readFile.permissionPolicy, ToolPermissionPolicy.autoApprove,
          reason: '对齐上游判定顺序:DENY 之后,AUTO_APPROVE 策略的工具直接执行');
    });
  });

  group('规则判定', () {
    test('项目 ALLOW 规则 → 直接放行', () async {
      await repository.add(PermissionScope.project, const PermissionRule(toolName: 'writeFile'));
      final eval = await evaluate(writeFile);
      expect(eval.verdict, PermissionVerdict.allow);
    });

    test('全局 DENY 规则 → 拒绝(跨作用域优先于项目 ALLOW)', () async {
      await repository.add(PermissionScope.project, const PermissionRule(toolName: 'writeFile'));
      await repository.add(
        PermissionScope.global,
        const PermissionRule(toolName: 'writeFile', decision: PermissionDecision.deny),
      );
      final eval = await evaluate(writeFile);
      expect(eval.verdict, PermissionVerdict.deny);
      expect(eval.denyReason, contains('禁止执行'));
    });

    test('带前缀的规则不命中整工具调用(前缀只对 shell 类工具有意义)', () async {
      await repository.add(
        PermissionScope.project,
        const PermissionRule(toolName: 'writeFile', pattern: 'git pull'),
      );
      final eval = await evaluate(writeFile);
      expect(eval.verdict, PermissionVerdict.ask);
    });
  });

  group('记忆规则', () {
    test('remember 写入项目规则,随后同类调用直接放行', () async {
      await engine.remember('writeFile', [PermissionRule.wholeTool]);
      expect(
        (await repository.projectRules()).single,
        const PermissionRule(toolName: 'writeFile'),
      );
      expect((await evaluate(writeFile)).verdict, PermissionVerdict.allow);
    });

    test('remember 对重复模式去重', () async {
      await engine.remember('writeFile', [PermissionRule.wholeTool, PermissionRule.wholeTool]);
      expect(await repository.projectRules(), hasLength(1));
    });
  });
}