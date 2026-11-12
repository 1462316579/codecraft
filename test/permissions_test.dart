import 'dart:io';

import 'package:codecraft/data/permissions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('规则模型与紧凑格式', () {
    test('往返:整工具与带前缀两种写法', () {
      expect(PermissionRule.fromCompact('writeFile').toolName, 'writeFile');
      expect(PermissionRule.fromCompact('writeFile').pattern, PermissionRule.wholeTool);
      expect(PermissionRule.fromCompact('writeFile').toCompact(), 'writeFile');

      final prefix = PermissionRule.fromCompact('Bash(git pull)');
      expect(prefix.toolName, 'Bash');
      expect(prefix.pattern, 'git pull');
      expect(prefix.toCompact(), 'Bash(git pull)');
      expect(prefix.decision, PermissionDecision.allow);
    });

    test('deny 方向可解析;相同规则相等(用于去重)', () {
      final deny = PermissionRule.fromCompact('writeFile', decision: PermissionDecision.deny);
      expect(deny.decision, PermissionDecision.deny);
      expect(
        deny,
        const PermissionRule(toolName: 'writeFile', decision: PermissionDecision.deny),
      );
      expect(
        deny,
        isNot(const PermissionRule(toolName: 'writeFile')),
      );
    });
  });

  group('规则文件解析与序列化', () {
    test('解析 allow/deny;坏 JSON 与非法条目被跳过', () {
      final rules = PermissionRulesRepository.parse(
        '{"permissions":{"allow":["writeFile","Bash(git status)"],"deny":["manageMcp",42,""]}}',
      );
      expect(rules.map((rule) => rule.toCompact()), ['writeFile', 'Bash(git status)', 'manageMcp']);
      expect(rules.last.decision, PermissionDecision.deny);

      expect(PermissionRulesRepository.parse('not json'), isEmpty);
      expect(PermissionRulesRepository.parse('{"foo":1}'), isEmpty);
      expect(PermissionRulesRepository.parse('{"permissions":{}}'), isEmpty);
    });
  });

  group('规则仓库', () {
    late Directory configDir;
    late Directory workspace;
    late PermissionRulesRepository repository;

    setUp(() {
      configDir = Directory.systemTemp.createTempSync('perm_config');
      workspace = Directory.systemTemp.createTempSync('perm_workspace');
      repository = PermissionRulesRepository(
        globalFile: File(p.join(configDir.path, 'permissions.json')),
        workspaceRoot: workspace.path,
      );
    });

    tearDown(() {
      configDir.deleteSync(recursive: true);
      workspace.deleteSync(recursive: true);
    });

    test('写入位置:项目在 <工作区>/.codecraft,全局在配置目录;重复添加去重', () async {
      const rule = PermissionRule(toolName: 'writeFile');
      await repository.add(PermissionScope.project, rule);
      await repository.add(PermissionScope.project, rule);

      expect(File(p.join(workspace.path, '.codecraft', 'permissions.json')).existsSync(), isTrue);
      expect((await repository.projectRules()), hasLength(1));

      await repository.add(PermissionScope.global, rule);
      expect(File(p.join(configDir.path, 'permissions.json')).existsSync(), isTrue);
      expect((await repository.globalRules()), hasLength(1));
    });

    test('生效规则 = 项目 + 全局(项目在前)', () async {
      await repository.add(
        PermissionScope.project,
        const PermissionRule(toolName: 'writeFile'),
      );
      await repository.add(
        PermissionScope.global,
        const PermissionRule(toolName: 'manageMcp', decision: PermissionDecision.deny),
      );
      final effective = await repository.effectiveRules();
      expect(effective.map((rule) => rule.toolName), ['writeFile', 'manageMcp']);
    });

    test('删除各自作用域;提升为全局 = 项目删 + 全局加', () async {
      const rule = PermissionRule(toolName: 'writeFile');
      await repository.add(PermissionScope.project, rule);
      await repository.add(
        PermissionScope.global,
        const PermissionRule(toolName: 'loadSkill'),
      );

      await repository.removeGlobalRule(const PermissionRule(toolName: 'loadSkill'));
      expect(await repository.globalRules(), isEmpty);
      expect(await repository.projectRules(), hasLength(1));

      await repository.promoteToGlobal(rule);
      expect(await repository.projectRules(), isEmpty);
      expect((await repository.globalRules()).single, rule);
    });
  });
}