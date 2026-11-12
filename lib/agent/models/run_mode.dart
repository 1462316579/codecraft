/// AI Agent 的权限运行模式。
/// 决定了 AI 调用工具时的授权级别。
enum AgentRunMode {
  /// 自动模式:所有工具调用均无需用户授权,直接执行。
  auto,
  /// 构建模式:写操作工具(如修改文件)需经用户逐条授权。
  build,
  /// 计划模式:只读模式。所有写操作被拦截,仅允许读取和分析。
  plan;

  static AgentRunMode parse(String? value) =>
      values.firstWhere((m) => m.name == value, orElse: () => AgentRunMode.build);
}
