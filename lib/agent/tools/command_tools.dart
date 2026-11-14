import '../../data/container/command_engine.dart';
import 'tool.dart';

/// 在当前执行环境中执行一次性 shell 命令(对齐上游 Bash 工具)。
/// 命令在当前工作区目录内执行,使 shell 操作与文件工具作用于同一目录。
class BashTool extends AgentTool {
  BashTool({
    required Future<CommandEngine> Function() engine,
    this.workdir,
    this.onStart,
    this.onFinish,
  }) : _engine = engine;

  final Future<CommandEngine> Function() _engine;

  /// 命令的工作目录(宿主路径)。
  ///
  /// 必须传当前工作区,否则命令跑在沙盒根目录——逆向项目里 `strings lib/...so`
  /// 这类命令就会找不到文件。
  final String? workdir;

  /// 命令开始执行时的回调(用于把它显示到终端)。
  final void Function(String command)? onStart;

  /// 命令结束时的回调(输出 + 退出码)。
  final void Function(String output, int? exitCode)? onFinish;

  static const int defaultTimeoutSeconds = 120;
  static const int maxTimeoutSeconds = 1800;

  @override
  String get name => 'Bash';

  @override
  String get description =>
      '在当前执行环境中执行一次性 Shell 命令,同步返回输出。需要实时输出的长任务请拆分成多次短命令或调大 timeout,不要用 `&` 挂后台。';

  @override
  ToolPermissionPolicy get permissionPolicy => ToolPermissionPolicy.ask;

  @override
  Set<ToolCapability> get capabilities => const {ToolCapability.executeCommands};

  @override
  Map<String, ToolParameter> get parameters => const {
        'command': ToolParameter(
          name: 'command',
          type: ParameterType.string,
          description: '要执行的 shell 命令',
        ),
        'timeout': ToolParameter(
          name: 'timeout',
          type: ParameterType.integer,
          description: '命令最长执行时间(秒),超时将被强制终止。'
              '默认 $defaultTimeoutSeconds 秒,上限 $maxTimeoutSeconds 秒;安装依赖等耗时命令可调大。',
          required: false,
        ),
        'elevate': ToolParameter(
          name: 'elevate',
          type: ParameterType.boolean,
          description: '提权重试:命令因内置安全防护(灾难性删除等)被拒且确有必要时置为 true 重试,'
              '会弹窗请用户一次性授权(不可记忆)。',
          required: false,
        ),
      };

  int _resolveTimeoutSeconds(Map<String, dynamic> args) {
    final raw = args['timeout'];
    final seconds = switch (raw) {
      final num value => value.toInt(),
      final String value => int.tryParse(value) ?? defaultTimeoutSeconds,
      _ => defaultTimeoutSeconds,
    };
    return seconds.clamp(1, maxTimeoutSeconds);
  }

  @override
  PermissionRequestText permissionRequest(Map<String, dynamic> args, String argsPreview) {
    final command = switch (args['command']) {
      final String value when value.trim().isNotEmpty => value,
      _ => '未知命令',
    };
    return PermissionRequestText(
      title: '确认执行命令',
      summary: command,
      details: '将在当前执行环境中执行。\n超时:${_resolveTimeoutSeconds(args)} 秒',
    );
  }

  @override
  Future<ToolResult> execute(Map<String, dynamic> args, {String? sessionId}) async {
    final command = switch (args['command']) {
      final String value when value.trim().isNotEmpty => value,
      _ => null,
    };
    if (command == null) return const ToolError('缺少必需参数:command');

    final CommandEngine engine;
    try {
      engine = await _engine();
    } catch (error) {
      return ToolError('执行环境不可用:$error', code: 'EXEC_ENV_UNAVAILABLE');
    }
    final timeoutSeconds = _resolveTimeoutSeconds(args);
    onStart?.call(command);
    final result = await engine.runCommandSync(
      command,
      workdir: workdir,
      timeout: Duration(seconds: timeoutSeconds),
    );
    onFinish?.call(result.output, result.exitCode);
    if (result.timedOut) {
      return ToolError('命令超时($timeoutSeconds 秒)已被终止。\n${result.output}'.trim(),
          code: 'TIMEOUT');
    }
    if (result.exitCode == -1 && result.output.contains('尚未初始化')) {
      return ToolError(result.output, code: 'EXEC_ENV_NOT_READY');
    }
    return ToolSuccess(result.output);
  }
}

/// 执行环境未就绪的提示文案(供 UI 复用)。
const String containerNotReadyHint = '执行环境未就绪，请稍后重试。';