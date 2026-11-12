import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';

import '../agent/models/chat_session.dart';
import '../agent/models/project.dart';
import '../agent/models/run_mode.dart';
import '../agent/models/skill.dart';
import '../data/prompts.dart' show builtinScenarioContent, PromptFragment, PromptFragmentResolver, PromptFragmentCatalog;

/// 系统提示词构建:以片段目录渲染静态基线,就地展开运行期变量,
/// 再追加写作模式 / 逆向项目段落。
///
/// 对齐上游 SystemPromptProvider:静态基线来自四层合并的片段(assets/prompts/ 顶层编号片段),
/// 运行期变量(技能、记忆、子代理、项目规则、工作区、环境、日期、目标)在注入时就地展开。
String buildSystemPrompt({
  required PromptFragmentCatalog catalog,
  required String projectRoot,
  required List<Skill> skills,
  required AgentMode mode,
  required Map<int, String> builtinIndex,
  String scenarioPrompt = '',
}) {
  return composePromptFromBaseline(
    baseline: catalog.renderStatic(builtinIndex),
    projectRoot: projectRoot,
    skills: skills,
    mode: mode,
    scenarioPrompt: scenarioPrompt,
  );
}

/// 把静态基线(已去摘要的片段正文按编号拼接)展开变量并追加模式 / 项目类型段落。
///
/// [baseline] 为四层合并后的片段正文(内置-only 场景可传纯 assets 拼接结果)。
String composePromptFromBaseline({
  required String baseline,
  required List<Skill> skills,
  required AgentMode mode,
  String projectRoot = '',
  String scenarioPrompt = '',
}) {
  // 1. 变量就地展开:`{{CODECRAFT_*}}` 替换为纯数据;未写变量的片段原样保留。
  var prompt = _expandVariables(
    baseline,
    projectRoot: projectRoot,
    skills: skills,
  );

  // 2. 项目类型场景提示词(写作 / 编程 / 应用逆向):摘要在内层剥离,只注入正文。
  final scenario = PromptFragment.stripLeadingComment(scenarioPrompt).trim();
  if (scenario.isNotEmpty) prompt += '\n\n$scenario';

  // 3. 模式特定段落(写作模式)。
  if (mode == AgentMode.write) {
    prompt = '$_writeModePrompt\n\n$prompt';
  }

  return prompt;
}

/// 内置编号片段正文(编号 → 内容)的进程级缓存:assets 不可变,
/// 聊天每轮构建系统提示词不必重扫 AssetManifest 与重读全部片段。
Map<int, String>? _builtinPromptCache;

/// 从内置 assets 读取带编号的片段正文(编号 → 内容)。
///
/// 用 [AssetManifest] 枚举(与 container_installer 一致),只取顶层编号片段
/// (agent/ 与 scenarios/ 子目录除外),并行读取正文,结果进程级缓存。
///
/// 生产路径([buildSystemPrompt])与测试路径(composeSystemPromptFromAssets)共用。
Future<Map<int, String>> loadBuiltinPromptIndex() async {
  final cached = _builtinPromptCache;
  if (cached != null) return cached;
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final names = manifest.listAssets()
        .where((k) => k.startsWith('assets/prompts/') && k.endsWith('.md') && !k.contains('/agent/'))
        .map(p.basename)
        .toList()
      ..sort();
    final paths = <int, String>{};
    for (final name in names) {
      final number = PromptFragmentResolver.parseNumber(name);
      if (number != null && !paths.containsKey(number)) {
        paths[number] = 'assets/prompts/$name';
      }
    }
    final entries = await Future.wait(
      paths.entries.map((e) async => MapEntry(e.key, await rootBundle.loadString(e.value))),
    );
    final byNumber = {for (final e in entries) e.key: e.value};
    _builtinPromptCache = byNumber;
    return byNumber;
  } catch (_) {
    return {};
  }
}

/// 解析某项目类型的场景提示词:项目层 > 全局层 > 内置常量。
///
/// 内置禁用(`.no-builtin`)或无项目类型时返回空串——场景提示词属于内置来源。
///
/// 内置层改为代码内嵌常量,不再走 rootBundle,避免每次构建系统提示词都产生 platform channel 往返。
String loadScenarioPrompt(PromptFragmentCatalog catalog, ProjectKind? kind) {
  if (kind == null || catalog.isBuiltinDisabled()) return '';
  final project = catalog.scenarioProjectFile(kind);
  if (project != null) return project.readAsStringSync();
  final global = catalog.scenarioGlobalFile(kind);
  if (global != null) return global.readAsStringSync();
  return builtinScenarioContent(kind) ?? '';
}

/// 构建运行期变量映射并就地展开。
String _expandVariables(
  String text, {
  required String projectRoot,
  required List<Skill> skills,
}) {
  var out = text;
  out = out.replaceAll('{{CODECRAFT_SKILLS}}', _skillsList(skills));
  // 记忆 / 子代理 / 项目规则等运行期内容暂未移植,留空占位。
  out = out.replaceAll('{{CODECRAFT_MEMORY_GLOBAL}}', '');
  out = out.replaceAll('{{CODECRAFT_MEMORY_PROJECT}}', '');
  out = out.replaceAll('{{CODECRAFT_SUBAGENTS}}', '');
  out = out.replaceAll('{{CODECRAFT_PROJECT_RULES_GLOBAL}}', '');
  out = out.replaceAll('{{CODECRAFT_PROJECT_RULES_PROJECT}}', '');
  out = out.replaceAll('{{CODECRAFT_PROJECT_RULES}}', '');
  out = out.replaceAll('{{CODECRAFT_WORKSPACE}}', projectRoot);
  out = out.replaceAll('{{CODECRAFT_ENVIRONMENT}}', '本地容器(PRoot)');
  out = out.replaceAll('{{CODECRAFT_DATE}}', DateTime.now().toIso8601String().substring(0, 10));
  out = out.replaceAll('{{CODECRAFT_GOAL}}', '');
  out = out.replaceAll('{{CODECRAFT_SUBAGENT_NAME}}', '');
  // 变量展开后空清单会留下额外空行,压缩连续空行。
  return out.trim().replaceAll(RegExp(r'\n{3,}'), '\n\n');
}

String _skillsList(List<Skill> skills) {
  if (skills.isEmpty) return '';
  return skills
      .map((s) => '- ${s.name}: ${s.description.isEmpty ? '(无描述)' : s.description}')
      .join('\n');
}

/// 写作模式提示词段落。
const String _writeModePrompt = '''## 写作模式(WRITE MODE)
你处于写作模式,角色是文字工作者与编辑:把用户的想法、材料与口述整理成结构清楚、可直接使用的文字。

## 工作方式
- 先明确写作目标:体裁(文章/报告/说明/文案/邮件/文档)、读者、篇幅与语气。信息不足时先问最关键的一两个问题,或先给一版再按反馈调整。
- 动笔前先定结构:长文给提纲或直接分节写作并用标题分层,短文案直接给成品。
- 忠于用户提供的材料:不臆造数据、引用与结论;缺事实时标明「这里需要你确认」,不要编造后混进正文。
- 保留用户原意与既有风格:改写时不擅自扩写或删减;修改既有文字要说明改了什么、为什么。
- 需要落盘时写成工作区内的 Markdown 或纯文本文件(`writeFile`/`editFile`),并在回复里说明写到了哪个路径。
- 写作项目的工作区是手机上的普通目录,不经过容器,也没有命令工具:读写文件一律用 `readFile`/`writeFile`/`editFile`/`list`/`search`。

## 边界
- 除非用户明确要求,不改代码、不跑构建或测试、不提交。
- 权限行为与开发模式一致:需要授权时照常询问,不要为绕开确认而改写任务目标。''';
