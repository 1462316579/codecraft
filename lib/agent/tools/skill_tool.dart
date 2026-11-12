import '../../data/skills.dart';
import 'tool.dart';

/// 让 AI 按需加载一个技能的完整指令正文。
///
/// 系统提示里只注入了各 skill 的 name + description 清单;AI 判断某个 skill 适用时,调用本工具拿到
/// SKILL.md 正文,随后用文件工具按正文行事。技能目录为 `~/.codecraft/skills/<name>/`(全局)
/// 或 `~/workspace/.codecraft/skills/<name>/`(项目级)。
class LoadSkillTool extends AgentTool {
  LoadSkillTool(this._skills);

  final SkillsStore _skills;

  @override
  String get name => 'loadSkill';

  @override
  String get description => '加载指定技能的完整指令正文。当系统提示「可用技能」清单中的技能适用于当前任务时使用。';

  @override
  Set<ToolCapability> get capabilities => const {ToolCapability.readAgentConfig};

  @override
  Map<String, ToolParameter> get parameters => const {
        'skill_name': ToolParameter(
          name: 'skill_name',
          type: ParameterType.string,
          description: '要加载的技能名称(与系统提示「可用技能」清单中的名称一致)。',
        ),
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args, {String? sessionId}) async {
    final raw = args['skill_name'];
    final skillName = raw is String ? raw.trim() : '';
    if (skillName.isEmpty) {
      return const ToolError('缺少必需参数:skill_name', code: 'MISSING_SKILL_NAME');
    }

    final instructions = await _skills.loadInstructions(skillName);
    if (instructions == null) {
      final available = (await _skills.listEnabled()).map((skill) => skill.name).join(', ');
      return ToolError(
        '未找到技能「$skillName」。可用技能:${available.isEmpty ? '(无)' : available}',
        code: 'SKILL_NOT_FOUND',
      );
    }
    return ToolSuccess({'output': instructions});
  }
}