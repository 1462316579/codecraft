import '../container/command_engine.dart';

/// Git 操作失败(携带 git 的错误信息,供 UI 原样展示)。
class GitException implements Exception {
  const GitException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 文件超过 diff 字节上限时抛出(上游 `GitOutputTooLargeException`)。
class GitOutputTooLargeException extends GitException {
  const GitOutputTooLargeException() : super('文件过大,无法显示差异');
}

/// 仓库内的 git 命令执行层(对齐上游 GitRepository 的命令部分):
/// 命令在容器里跑,cwd 固定为仓库路径;统一带 `-c core.quotepath=false`
/// 让非 ASCII 路径按 UTF-8 原样输出,逐参数 shell 转义后交给 `/bin/sh -c`。
class GitRunner {
  GitRunner(this._engine);

  /// 懒取容器引擎:Git 页可先于容器就绪被打开。
  final Future<CommandEngine> Function() _engine;

  static const List<String> _prefix = ['git', '-c', 'core.quotepath=false'];

  /// 默认超时(与 [CommandEngine.runCommandSync] 的默认值一致)。
  static const Duration defaultTimeout = Duration(seconds: 120);

  /// 提交页每页拉取的提交条数。
  static const int graphPageSize = 100;

  /// 单个文件 diff 的字节上限,超过则抛 [GitOutputTooLargeException]。
  static const int maxDiffFileBytes = 2 * 1024 * 1024;

  /// 单参数 shell 转义:单引号包裹,内部单引号写成 `'\''`。
  static String quote(String arg) => "'${arg.replaceAll("'", r"'\''")}'";

  String buildCommand(List<String> args) =>
      [..._prefix, ...args].map(quote).join(' ');

  /// 执行 git 命令并返回合并后的输出(stdout+stderr);非零退出码抛 [GitException]。
  Future<String> checked(
    String cwd,
    List<String> args, {
    Duration? timeout,
  }) async {
    final result = await run(cwd, args, timeout: timeout);
    if (result.exitCode != 0) {
      throw GitException(_failureMessage(result.output));
    }
    return result.output;
  }

  /// 执行 git 命令,不检查退出码(调用方自行判断,如 `rev-parse --is-inside-work-tree`)。
  Future<CommandResult> run(
    String cwd,
    List<String> args, {
    Duration? timeout,
  }) async {
    final engine = await _engine();
    return engine.runCommandSync(
      buildCommand(args),
      workdir: cwd,
      timeout: timeout ?? defaultTimeout,
    );
  }

  /// 在仓库目录下执行任意 shell 命令(`.gitignore` 追加、`cat` 读文件等非 git 子命令)。
  Future<CommandResult> runShell(
    String cwd,
    String command, {
    Duration? timeout,
  }) async {
    final engine = await _engine();
    return engine.runCommandSync(
      command,
      workdir: cwd,
      timeout: timeout ?? defaultTimeout,
    );
  }

  /// 失败信息:优先取 stderr 里 `fatal:`/`error:` 那行,否则整段输出,最后兜底一句通用文案。
  static String _failureMessage(String output) {
    final lines = output
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    for (final line in lines.reversed) {
      if (line.startsWith('fatal:') || line.startsWith('error:')) return line;
    }
    if (lines.isNotEmpty) return lines.last;
    return 'git 命令执行失败';
  }
}