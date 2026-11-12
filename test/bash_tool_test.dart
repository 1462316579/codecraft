import 'package:codecraft/agent/tools/command_tools.dart';
import 'package:codecraft/agent/tools/tool.dart';
import 'package:codecraft/data/container/command_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// 假执行引擎:只返回预设结果,并记录收到的命令。
class _Engine implements CommandEngine {
  _Engine(this.result);

  final CommandResult result;
  final List<String> commands = [];
  final List<String?> workdirs = [];

  @override
  Future<CommandResult> runCommandSync(
    String command, {
    String? workdir,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    commands.add(command);
    workdirs.add(workdir);
    return result;
  }

  @override
  Future<TerminalProcess> openTerminal({
    String? command,
    int cols = 80,
    int rows = 24,
    String? workdir,
  }) =>
      throw UnimplementedError();

  @override
  Future<bool> isReady() async => true;

  @override
  Future<String?> notReadyHint() async => null;

  @override
  Stream<Object> runCommandStream(
    String command, {
    String? workdir,
    Duration timeout = const Duration(seconds: 120),
  }) =>
      const Stream.empty();
}

/// Bash 工具要把它跑了什么、输出了什么告诉外部,终端页才能显示出来。
void main() {
  test('执行命令时回调命令本身与最终输出', () async {
    final engine = _Engine(const CommandResult(output: 'hello\n', exitCode: 0));
    final started = <String>[];
    final finished = <(String, int?)>[];

    final tool = BashTool(
      engine: () async => engine,
      onStart: started.add,
      onFinish: (output, exitCode) => finished.add((output, exitCode)),
    );

    final result = await tool.execute({'command': 'echo hello'});

    expect(result, isA<ToolSuccess>());
    expect(engine.commands, ['echo hello']);
    expect(started, ['echo hello'], reason: '命令开始就该显示在终端里');
    expect(finished, hasLength(1));
    expect(finished.single.$1, 'hello\n');
    expect(finished.single.$2, 0);
  });

  test('失败命令也回报退出码(便于终端标红)', () async {
    final engine = _Engine(const CommandResult(output: 'boom\n', exitCode: 2));
    final finished = <(String, int?)>[];

    final tool = BashTool(
      engine: () async => engine,
      onFinish: (output, exitCode) => finished.add((output, exitCode)),
    );

    await tool.execute({'command': 'exit 2'});

    expect(finished.single.$2, 2);
  });

  test('缺少 command 时不执行、不回调', () async {
    final engine = _Engine(const CommandResult(output: '', exitCode: 0));
    var started = 0;

    final tool = BashTool(engine: () async => engine, onStart: (_) => started++);
    final result = await tool.execute(const {});

    expect(result, isA<ToolError>());
    expect(started, 0);
    expect(engine.commands, isEmpty);
  });

  test('没有回调时照常执行(回调可选)', () async {
    final engine = _Engine(const CommandResult(output: 'ok', exitCode: 0));
    final tool = BashTool(engine: () async => engine);

    final result = await tool.execute({'command': 'true'});
    expect(result, isA<ToolSuccess>());
    expect(engine.commands, ['true']);
  });

  test('把工作区作为 workdir 传给执行环境', () async {
    final engine = _Engine(const CommandResult(output: '', exitCode: 0));
    final tool = BashTool(engine: () async => engine, workdir: '/data/app/projects/apk-p1');

    await tool.execute({'command': 'strings lib/arm64-v8a/libapp.so'});

    expect(engine.workdirs.single, '/data/app/projects/apk-p1',
        reason: '不传 workdir 时命令跑在沙盒根目录,逆向项目里会找不到 APK 里的文件');
  });
}
