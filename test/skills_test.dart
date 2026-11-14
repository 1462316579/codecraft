import 'dart:convert';
import 'dart:io';

import 'package:codecraft/agent/models/skill.dart';
import 'package:codecraft/agent/prompt/system_prompt.dart';
import 'package:codecraft/agent/tools/skill_tool.dart';
import 'package:codecraft/agent/tools/tool.dart';
import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/data/settings/app_settings.dart';
import 'package:codecraft/data/skills.dart';
import 'package:codecraft/features/settings/settings_page.dart';
import 'package:codecraft/features/settings/theme_page.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../lib/core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:codecraft/agent/models/chat_session.dart';

void writeSkill(String root, String dirName, String text) {
  final dir = Directory(p.join(root, dirName));
  dir.createSync(recursive: true);
  File(p.join(dir.path, 'SKILL.md')).writeAsStringSync(text);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory configDir;
  late Directory workspaceRoot;
  late SkillsStore store;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('skills_config');
    workspaceRoot = Directory.systemTemp.createTempSync('skills_project');
    store = SkillsStore(
      globalRoot: p.join(configDir.path, 'skills'),
      projectRoot: p.join(workspaceRoot.path, '.codecraft', 'skills'),
    );
  });

  tearDown(() {
    configDir.deleteSync(recursive: true);
    workspaceRoot.deleteSync(recursive: true);
  });

  group('技能解析与序列化', () {
    test('frontmatter 解析 name/description/required_tools,正文剥离', () {
      final skill = parseSkillText(
        '---\n'
        'name: "ppt-maker"\n'
        'description: "做演示文稿"\n'
        'required_tools: [readFile, writeFile]\n'
        '---\n'
        '第一步:先读模板\n',
        'fallback',
      );

      expect(skill.name, 'ppt-maker');
      expect(skill.description, '做演示文稿');
      expect(skill.requiredTools, ['readFile', 'writeFile']);
      expect(skill.instructions, '第一步:先读模板');
    });

    test('缺 name 回退到兜底名;无 frontmatter 时正文原样', () {
      expect(parseSkillText('# 标题\n正文', 'dir-name').name, 'dir-name');
      expect(parseSkillText('# 标题\n正文', 'dir-name').instructions, '# 标题\n正文');
    });

    test('serialize 与 parse 成对:引号转义与换行压平', () {
      final text = serializeSkill(const SkillForm(
        name: 'quote"test',
        description: '第一行\n第二行: 带冒号',
        requiredTools: ['readFile'],
        instructions: '正文',
      ));

      final parsed = parseSkillText(text, 'fallback');
      expect(parsed.name, 'quote"test');
      expect(parsed.description, '第一行 第二行: 带冒号');
      expect(parsed.requiredTools, ['readFile']);
      expect(parsed.instructions, '正文');
    });

    test('技能名合法性:路径分隔符、保留字符与空名均非法', () {
      expect(isValidSkillName('ppt-maker'), isTrue);
      expect(isValidSkillName('a/b'), isFalse);
      expect(isValidSkillName('a:b'), isFalse);
      expect(isValidSkillName('   '), isFalse);
      expect(isValidSkillName('x' * 65), isFalse);
    });
  });

  group('技能仓库', () {
    test('扫描两级目录:项目级同名覆盖全局,展示路径带作用域前缀', () async {
      writeSkill(store.globalRoot, 'writer', '---\nname: writer\ndescription: 全局版\n---\n全局正文');
      writeSkill(store.globalRoot, 'reader', '---\nname: reader\n---\n读');
      writeSkill(store.projectRoot, 'writer', '---\nname: writer\ndescription: 项目版\n---\n项目正文');
      // 嵌套一层的技能(repo/skills/my-skill/SKILL.md)
      writeSkill(p.join(store.projectRoot, 'repo'), p.join('skills', 'nested'),
          '---\nname: nested\n---\n嵌套');

      final entries = await store.listAll();
      expect(entries.map((entry) => entry.skill.name), ['nested', 'reader', 'writer']);

      final writer = entries.firstWhere((entry) => entry.skill.name == 'writer');
      expect(writer.scope, SkillScope.project);
      expect(writer.skill.description, '项目版');
      expect(writer.skill.dirPath, '~/workspace/.codecraft/skills/writer');

      final reader = entries.firstWhere((entry) => entry.skill.name == 'reader');
      expect(reader.scope, SkillScope.global);
      expect(reader.skill.dirPath, '~/.codecraft/skills/reader');
    });

    test('CLAUDE.md 也能识别;目录名作为名称兜底', () async {
      final dir = Directory(p.join(store.globalRoot, 'legacy'))..createSync(recursive: true);
      File(p.join(dir.path, 'CLAUDE.md')).writeAsStringSync('按这个流程做');

      final entries = await store.listAll();
      expect(entries.single.skill.name, 'legacy');
      expect(entries.single.skill.instructions, '按这个流程做');
    });

    test('保存:写入 SKILL.md,非法名 / 空正文 / 重名各自报错', () async {
      final form = const SkillForm(name: 'ppt', description: '做幻灯片', instructions: '步骤一');
      expect(await store.save(form, SkillScope.global), isNull);
      expect(
        File(p.join(store.globalRoot, 'ppt', 'SKILL.md')).readAsStringSync(),
        contains('name: "ppt"'),
      );

      expect(
        await store.save(const SkillForm(name: 'a/b', instructions: 'x'), SkillScope.global),
        SkillSaveError.invalidName,
      );
      expect(
        await store.save(const SkillForm(name: 'other', instructions: '  '), SkillScope.global),
        SkillSaveError.emptyInstructions,
      );
      expect(await store.save(form, SkillScope.global), SkillSaveError.nameConflict);
      // 同名的项目级技能不冲突
      expect(await store.save(form, SkillScope.project), isNull);
    });

    test('编辑:改名只改 frontmatter,目录不动;CLAUDE.md 目录写回 CLAUDE.md', () async {
      final dir = Directory(p.join(store.projectRoot, 'legacy'))..createSync(recursive: true);
      File(p.join(dir.path, 'CLAUDE.md')).writeAsStringSync('---\nname: legacy\n---\n旧正文');

      final error = await store.save(
        const SkillForm(name: 'renamed', description: '', instructions: '新正文'),
        SkillScope.project,
        originalName: 'legacy',
      );
      expect(error, isNull);
      expect(File(p.join(dir.path, 'SKILL.md')).existsSync(), isFalse, reason: '目录名与时不变');
      final text = File(p.join(dir.path, 'CLAUDE.md')).readAsStringSync();
      expect(text, contains('name: "renamed"'));
      expect(text, contains('新正文'));
    });

    test('启停:禁用名单落 skills.json,禁用后不进启用列表也加载不到', () async {
      writeSkill(store.globalRoot, 'writer', '---\nname: writer\n---\n正文');

      await store.setDisabled('writer', true, SkillScope.global);
      expect(await store.disabledNames(), {'writer'});
      expect(await store.listEnabled(), isEmpty);
      expect(await store.loadInstructions('writer'), isNull);

      final config = jsonDecode(
        File(p.join(configDir.path, 'skills.json')).readAsStringSync(),
      );
      expect(config['disabled'], ['writer']);

      await store.setDisabled('writer', false, SkillScope.global);
      expect(await store.disabledNames(), isEmpty);
      expect((await store.listEnabled()).single.name, 'writer');
      expect(await store.loadInstructions('writer'), '正文');
    });

    test('导入 Markdown:成功落盘,重名与空正文失败', () async {
      final ok = await store.importMarkdown(
        '---\nname: imported\ndescription: 导入的\n---\n正文',
        'fallback',
        SkillScope.project,
      );
      expect(ok.imported, ['imported']);
      expect(
        File(p.join(store.projectRoot, 'imported', 'SKILL.md')).existsSync(),
        isTrue,
      );

      final conflict = await store.importMarkdown(
        '---\nname: imported\n---\n正文',
        'fallback',
        SkillScope.project,
      );
      expect(conflict.imported, isEmpty);
      expect(conflict.failures.single.error, SkillImportError.nameConflict);

      final empty = await store.importMarkdown(
        '---\nname: blank\n---\n',
        'fallback',
        SkillScope.project,
      );
      expect(empty.failures.single.error, SkillImportError.emptyContent);
    });

    test('删除:只删含指令文件的目录,删掉后列表为空', () async {
      writeSkill(store.globalRoot, 'victim', '---\nname: victim\n---\n正文');
      final notASkill = Directory(p.join(store.globalRoot, 'plain'))..createSync(recursive: true);
      File(p.join(notASkill.path, 'notes.txt')).writeAsStringSync('x');

      expect(await store.delete('victim', SkillScope.global), isTrue);
      expect(Directory(p.join(store.globalRoot, 'victim')).existsSync(), isFalse);
      expect(await store.delete('victim', SkillScope.global), isFalse);
      expect(await store.listAll(), isEmpty);
    });
  });

  group('loadSkill 与系统提示词', () {
    test('loadSkill 返回指令正文;未知技能提示可用清单', () async {
      writeSkill(store.globalRoot, 'writer', '---\nname: writer\ndescription: 写作\n---\n按这个写');
      final tool = LoadSkillTool(store);

      final found = await tool.execute({'skill_name': 'writer'});
      expect(((found as ToolSuccess).data as Map<String, dynamic>)['output'], '按这个写');

      final missing = await tool.execute(const {});
      expect((missing as ToolError).code, 'MISSING_SKILL_NAME');

      final unknown = await tool.execute({'skill_name': 'nope'});
      expect((unknown as ToolError).code, 'SKILL_NOT_FOUND');
      expect(unknown.message, contains('writer'));
    });

    test('写作模式注入写作段落,开发模式不注入模式段落', () async {
      final write = await composeSystemPromptFromAssets(mode: AgentMode.write);
      expect(write, contains('## 写作模式(WRITE MODE)'));
      expect(write, contains('不改代码'));

      final build = await composeSystemPromptFromAssets(mode: AgentMode.build);
      expect(build, isNot(contains('## 写作模式')));
      // 开发模式不追加任何模式段落:与不传 mode 的结果一致。
      expect(build, await composeSystemPromptFromAssets());
    });

    test('模式解析:新值直读,已下线的 plan/auto 与未知值一律回落到开发', () {
      expect(AgentMode.parse('write'), AgentMode.write);
      expect(AgentMode.parse('build'), AgentMode.build);
      expect(AgentMode.parse('plan'), AgentMode.build, reason: '旧会话里的计划模式回落到开发');
      expect(AgentMode.parse('auto'), AgentMode.build, reason: '旧会话里的自动模式回落到开发');
      expect(AgentMode.parse(null), AgentMode.build);
      expect(AgentMode.parse('nonsense'), AgentMode.build);
    });

    test('系统提示词注入技能清单;无技能时该段只有标题', () async {
      final withSkills = await composeSystemPromptFromAssets(skills: const [
        Skill(name: 'writer', description: '写作方法论', instructions: '正文'),
        Skill(name: 'quiet', instructions: '正文'),
      ]);
      expect(withSkills, contains('## 可用技能'));
      expect(withSkills, contains('- writer: 写作方法论'));
      expect(withSkills, contains('- quiet: (无描述)'));

      final without = await composeSystemPromptFromAssets();
      expect(without, contains('## 可用技能'), reason: '标题由内置片段承载,不再由代码拼接');
      expect(without, isNot(contains('- writer:')));
    });
  });

  testWidgets('设置页:大标题+副标题,首组 AI 提供商 / Skill 管理 / 主题,「账户与数据」组放关于', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        workspaceProvider.overrideWithValue(Workspace(workspaceRoot.path)),
        configDirProvider.overrideWithValue(configDir.path),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('设置'), findsOneWidget);
    expect(find.text('管理 AI、外观、同步和应用数据'), findsOneWidget);
    expect(find.text('AI 提供商'), findsOneWidget);
    expect(find.text('Skill 管理'), findsOneWidget);
    expect(find.text('主题'), findsOneWidget);
    expect(find.text('MCP 服务器'), findsOneWidget);
    expect(find.text('容器与镜像'), findsOneWidget);
    expect(find.text('工具授权'), findsOneWidget);
    expect(find.text('偏好设置'), findsOneWidget);
    expect(find.text('账户与数据'), findsOneWidget);
    expect(find.text('数据与诊断'), findsOneWidget);
    expect(find.text('Token 统计'), findsOneWidget);
    expect(find.text('存储空间'), findsOneWidget);
    expect(find.text('日志'), findsOneWidget);
    expect(find.text('关于'), findsOneWidget);

    final generalTop = tester.getTopLeft(find.text('偏好设置')).dy;
    final aiTop = tester.getTopLeft(find.text('AI 提供商')).dy;
    expect(generalTop, lessThan(aiTop), reason: '偏好设置应为第一项(对齐上游菜单顺序)');
    final skillTop = tester.getTopLeft(find.text('Skill 管理')).dy;
    final themeTop = tester.getTopLeft(find.text('主题')).dy;
    final aboutTop = tester.getTopLeft(find.text('关于')).dy;
    expect(aiTop, lessThan(skillTop), reason: 'AI 提供商应为第一项');
    expect(skillTop, lessThan(themeTop), reason: 'Skill 管理应为第二项');
    expect(themeTop, lessThan(aboutTop), reason: '关于在「账户与数据」组,排在首组之后');

    // 行样式:圆角色块图标 + 行尾箭头
    // 偏好设置 / AI 提供商 / Skill 管理 / 提示词 / 子代理 / MCP 服务器 / 容器与镜像 / 工具授权 / 软件权限 /
    // 主题 / Token 统计 / 存储空间 / 日志 / 关于,共 14 行导航
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(14));
    expect(find.byIcon(Iconfont.cpu), findsOneWidget);
    expect(find.byIcon(Iconfont.barChart), findsOneWidget);
    expect(find.byIcon(Iconfont.server), findsOneWidget);
    expect(find.byIcon(Iconfont.puzzle), findsOneWidget);
    expect(find.byIcon(Iconfont.palette), findsOneWidget);
    expect(find.byIcon(Iconfont.plug), findsOneWidget);
    expect(find.byIcon(Iconfont.shield), findsOneWidget);
    expect(find.byIcon(Iconfont.smartphone), findsOneWidget);
    expect(find.byIcon(Iconfont.box), findsOneWidget);
    expect(find.byIcon(Iconfont.info), findsOneWidget);
    expect(find.byIcon(Iconfont.fileText), findsOneWidget);
  });

  testWidgets('主题页:主题模式与语言,带当前值与行尾箭头', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ThemePage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('主题'), findsOneWidget);
    expect(find.text('外观、背景与显示'), findsOneWidget);
    expect(find.text('主题模式'), findsOneWidget);
    expect(find.text('语言'), findsOneWidget);
    // 主题模式与语言(系统默认)的当前值都是「跟随系统」,因此两处匹配
    expect(find.text('跟随系统'), findsNWidgets(2));
    expect(find.byIcon(Iconfont.sunMoon), findsOneWidget);
    expect(find.byIcon(Iconfont.languages), findsOneWidget);
  });
}