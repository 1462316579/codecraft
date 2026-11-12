import '../../data/prompts.dart';
import '../models/chat_session.dart';
import '../models/project.dart';
import '../models/skill.dart';
import '../prompts.dart' show composePromptFromBaseline, loadBuiltinPromptIndex;

/// 仅用内置 assets 片段组装系统提示词(无自定义层):
/// 编号片段按序拼接(去摘要注释)→ 就地展开 `{{CODECRAFT_*}}` 变量 → 追加场景提示词 / 写作模式段落。
///
/// 与 [buildSystemPrompt] 的区别:不走片段目录(不读 prompts.custom/ 等自定义层),
/// 面向测试与不需要落盘自定义的场景。
///
/// 场景提示词内置层直接取代码内嵌常量,不再走 rootBundle,避免测试路径产生 platform channel 往返。
Future<String> composeSystemPromptFromAssets({
  AgentMode mode = AgentMode.build,
  ProjectKind? projectKind,
  List<Skill> skills = const [],
}) async {
  final index = await loadBuiltinPromptIndex();
  final numbers = index.keys.toList()..sort();
  final baseline = [for (final n in numbers) PromptFragment.stripLeadingComment(index[n]!).trim()]
      .where((s) => s.isNotEmpty)
      .join('\n\n');
  // 场景提示词(按项目类型):测试路径只读内置常量,不走自定义层。
  final scenario = projectKind == null
      ? ''
      : PromptFragment.stripLeadingComment(
          builtinScenarioContent(projectKind) ?? '',
        ).trim();
  return composePromptFromBaseline(
    baseline: baseline,
    skills: skills,
    mode: mode,
    scenarioPrompt: scenario,
  );
}