import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;

import 'container/command_engine.dart';
import 'git/git_runner.dart';

/// 把命令与终端会话转发到某个 GitHub Codespace 执行。
///
/// 不是直连:`gh` 跑在本地 PRoot 容器里(由环境安装装好),由 `$gh codespace ssh`
/// 建立到 codespace 的隧道,命令在远端 shell 里执行。这样无需自己实现 SSH 隧道协议,
/// 也复用容器里已有的 gh 凭据(GH_TOKEN)。
class CodespacesEngine extends CommandEngine {
  CodespacesEngine({
    required this.transport,
    required this.codespace,
    this.localRoot,
    this.ghHelper = '/root/.codecraft/gh-codecraft.sh',
  });

  /// 本地容器引擎(gh 与网络都在这一层)。
  final CommandEngine transport;

  /// Codespace 名。
  final String codespace;

  /// 容器内包装 gh 的脚本路径(从 Git 凭据解码令牌并注入 GH_TOKEN)。
  final String ghHelper;

  /// 本地视角的工作区根;给出后 [runCommandSync] 的 workdir 会映射到远端同一位置。
  final String? localRoot;

  String? _remoteRoot;
  Future<String>? _remoteRootFuture;

  /// 清除远端根缓存；下次 [remoteRoot] 会重新探测。用于隧道恢复或路径映射失效后的自愈。
  void resetRemoteRoot() {
    _remoteRoot = null;
    _remoteRootFuture = null;
  }

  /// 远端工作目录(codespace 的默认 cwd,一般是 `/workspaces/<repo>`),首次使用时探测并缓存。
  /// 必须在 codespace 内执行,不能用本地容器的 cwd。
  Future<String> remoteRoot() {
    final cached = _remoteRoot;
    if (cached != null) return Future.value(cached);
    // 快速路径：如果 codespace 名能推断仓库名，先尝试直接猜测 /workspaces/<repo>
    // 避免每次都走完整的 SSH 探测链（在慢网络下会导致文件树/终端超时）
    final guessed = _guessRemoteRoot();
    if (guessed != null) {
      return _remoteRootFuture ??= _validateOrResolve(guessed).catchError((e) {
        _remoteRootFuture = null;
        throw e;
      });
    }
    return _remoteRootFuture ??= _resolveRemoteRoot().catchError((e) {
      _remoteRootFuture = null;
      throw e;
    });
  }

  /// 从 codespace 名称猜测远端根目录。
  /// Codespace 名格式通常为 `<user>-<repo>-<hash>` 或类似，仓库目录在 `/workspaces/<repo>`。
  String? _guessRemoteRoot() {
    // 常见格式: literalcoppola-codecraft-xxxx -> 尝试 /workspaces/codecraft
    // 但不够可靠；更稳妥的是直接检查 /workspaces 下的目录
    return null; // 由 _validateOrResolve 中的快速检查处理
  }

  Future<String> _validateOrResolve(String candidate) async {
    // 快速验证猜测的路径是否存在
    final ok = await _probeRemote('[ -d ${GitRunner.quote(candidate)} ] && echo __ok__',
        timeout: const Duration(seconds: 15));
    if (ok.contains('__ok__')) {
      _remoteRoot = candidate;
      return candidate;
    }
    return _resolveRemoteRoot();
  }

  /// 单次重探(不动缓存):给 [remotePath] 的自愈路径用,由调用方决定是否采纳。
  Future<String> _resolveRemoteRootOnce() => _resolveRemoteRoot(persist: false);

  Future<String> _resolveRemoteRoot({bool persist = true}) async {
    void save(String root) {
      if (persist) _remoteRoot = root;
    }
    // 快速路径：探测 /workspaces 下的第一个目录（通用，不硬编码仓库名）
    try {
      final quick = await _probeRemote(
        'ls -1d /workspaces/*/ 2>/dev/null | head -n 1',
        timeout: const Duration(seconds: 45),
      );
      final quickPath = quick.trim().split('\n').lastWhere(
        (l) => l.trim().isNotEmpty && l.trim().startsWith('/workspaces/'),
        orElse: () => '',
      ).trim();
      final cleaned = quickPath.endsWith('/')
          ? quickPath.substring(0, quickPath.length - 1)
          : quickPath;
      if (cleaned.isNotEmpty && cleaned.startsWith('/workspaces/') && cleaned != '/workspaces') {
        save(cleaned);
        return cleaned;
      }
    } catch (_) {}
    // 尝试 $CODESPACE_REPO_ROOT
    try {
      final repoRoot = await _probeRemote('echo \$CODESPACE_REPO_ROOT', timeout: const Duration(seconds: 30));
      final trimmedRepo = repoRoot.trim().split('\n').lastWhere(
        (l) => l.trim().startsWith('/'),
        orElse: () => '',
      ).trim();
      if (trimmedRepo.isNotEmpty && trimmedRepo.startsWith('/')) {
        save(trimmedRepo);
        return trimmedRepo;
      }
    } catch (_) {}
    // 完整探测链：gh 可用性 + 预热 + 多种方式定位
    String helper = ghHelper;
    if (await _isHelperMissing(helper)) helper = 'gh';
    final ghCheck = await transport.runCommandSync(
      '${GitRunner.quote(helper)} --version',
      timeout: const Duration(seconds: 15),
    );
    if (ghCheck.exitCode != 0) {
      final output = ghCheck.output.trim();
      if (output.contains('容器里没有 gh') || output.contains('command not found') || output.contains('not found')) {
        throw StateError('容器里没有 gh（GitHub CLI），请在终端执行命令 codecraft 安装依赖。');
      }
      throw StateError('gh 检查失败: ${output.isEmpty ? '未知错误' : output}');
    }
    final warmUp = await _probeRemote('echo __codecraft_ok__', timeout: const Duration(seconds: 60));
    if (!warmUp.contains('__codecraft_ok__')) {
      final raw = warmUp.trim();
      if (raw.isEmpty) throw StateError('连接 Codespace 超时,请检查网络或确认 Codespace 已启动。');
      throw StateError('连接 Codespace 失败: $raw');
    }
    // 尝试多种方式定位根目录
    for (final cmd in [
      'echo \$CODESPACE_REPO_ROOT',
      'git rev-parse --show-toplevel 2>/dev/null',
      'pwd',
    ]) {
      try {
        final out = await _probeRemote(cmd, timeout: const Duration(seconds: 30));
        final line = out.trim().split('\n').lastWhere(
          (l) => l.trim().startsWith('/'),
          orElse: () => '',
        ).trim();
        if (line.isNotEmpty && line.startsWith('/')) {
          save(line);
          return line;
        }
      } catch (_) {}
    }
    final lastDir = await _probeRemote('ls -1 /workspaces 2>/dev/null | head -n 1', timeout: const Duration(seconds: 30));
    final lastName = lastDir.trim().split('\n').lastWhere(
      (l) => l.trim().isNotEmpty,
      orElse: () => '',
    ).trim();
    if (lastName.isNotEmpty) {
      save('/workspaces/$lastName');
      return '/workspaces/$lastName';
    }
    throw StateError('无法在 Codespace 中定位项目根目录');
  }

  Future<bool> _remoteDirExists(String path) async {
    final out = await _probeRemote('[ -d ${GitRunner.quote(path)} ] && echo __ok__',
        timeout: const Duration(seconds: 15));
    return out.contains('__ok__');
  }

  Future<bool> _isHelperMissing(String path) async {
    final result = await transport.runCommandSync('test -x ${GitRunner.quote(path)}');
    return result.exitCode != 0;
  }

  Future<String> _probeRemote(String command, {Duration timeout = const Duration(seconds: 30)}) async {
    // 确定使用哪个助手: 优先使用 ghHelper,若不存在则退回到 gh
    String helper = ghHelper;
    if (await _isHelperMissing(helper)) {
      helper = 'gh';
    }
    // 优先使用 sh -c 包装（支持变量展开等），但某些 Codespace 环境可能不支持；
    // 简单命令（如 echo）直接传递更可靠。
    final bool needShell = command.contains('\$') || command.contains('|') || command.contains(';');
    final remoteCmd = needShell
        ? 'sh -c ${GitRunner.quote(command)}'
        : command;
    final cmd =
        '${GitRunner.quote(helper)} codespace ssh -c ${GitRunner.quote(codespace)} -- $remoteCmd 2>&1';
    
    String lastOutput = '';
    const maxAttempts = 2;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final result = await transport.runCommandSync(cmd).timeout(
          timeout,
          onTimeout: () => CommandResult(output: 'timeout after ${timeout.inSeconds}s', exitCode: -1),
        );
        
        if (result.exitCode == 0) return result.output;
        
        final lower = result.output.toLowerCase();
        final isRetryable = lower.contains('deadline exceeded') || 
                           lower.contains('connection closed') || 
                           lower.contains('broken pipe') ||
                           lower.contains('timed out') ||
                           result.exitCode == -1;
                           
        lastOutput = result.output;
        if (!isRetryable || attempt == maxAttempts) return result.output;
        
        await Future.delayed(Duration(seconds: attempt));
      } catch (e) {
        lastOutput = '$e';
        if (attempt == maxAttempts) return lastOutput;
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    return lastOutput;
  }

  Future<String?> _findGitProject(String baseDir) async {
    final out = await _probeRemote(
      'find ${GitRunner.quote(baseDir)} -maxdepth 8 -type d -name .git 2>/dev/null | head -n 1',
    );
    final gitDir = out.trim();
    if (gitDir.isEmpty) return null;
    
    final parent = p.dirname(gitDir);
    if (parent.isEmpty || parent == '/' || !parent.startsWith('/')) return null;
    return parent;
  }

  Future<String?> _firstWorkspaceRepo() async {
    final out = await _probeRemote('ls -1 /workspaces 2>/dev/null | head -1');
    final name = out.trim().split('\n').lastWhere(
          (e) => e.trim().isNotEmpty,
          orElse: () => '',
        ).trim();
    if (name.isEmpty || name.contains('/')) return null;
    final candidate = '/workspaces/$name';
    if (!await _remoteDirExists(candidate)) return null;
    return candidate;
  }

  Future<String?> _firstWorkspaceDir() async {
    final out = await _probeRemote('ls -1d /workspaces/* 2>/dev/null');
    final name = out.trim().split('\n').firstWhere(
          (e) => e.trim().isNotEmpty,
          orElse: () => '',
        ).trim();
    if (name.isEmpty) return null;
    if (await _remoteDirExists(name)) return name;
    return null;
  }

  bool _isNonWorkspaceHome(String path) {
    if (path.isEmpty || path == '/' || path == '/root') return true;
    if (path.startsWith('/root/') || path.startsWith('/home/')) return true;
    return false;
  }

  Future<String> remotePath(String localPathValue) async {
    final root = localRoot;
    if (root == null) return localPathValue;
    final remote = await remoteRoot();
    if (localPathValue == root) return remote;
    if (!localPathValue.startsWith('$root/')) {
      throw StateError('路径不在工作区内,无法映射到 Codespace:$localPathValue');
    }
    
    final relative = p.relative(localPathValue, from: root);
    String mapped = p.join(remote, relative);
    
    if (!mapped.startsWith('/')) {
      mapped = '/$mapped';
    }
    
    if (!await _remoteExists(mapped)) {
      // 映射目标不存在有两种可能:文件真不存在,或远端根变了(仓库切换)。
      // 先用一条便宜的 [ -d ] 确认根目录还在:在,则只是文件不存在,直接返回,
      // 不重跑探测链;不在,才值得重探一次新根。
      if (!await _remoteDirExists(remote)) {
        final freshFuture = _resolveRemoteRootOnce();
        try {
          final freshRemote = await freshFuture;
          if (freshRemote != remote) {
            final alt = p.join(freshRemote, relative);
            final validatedAlt = alt.startsWith('/') ? alt : '/$alt';
            if (await _remoteExists(validatedAlt)) return validatedAlt;
            if (await _remoteDirExists(freshRemote)) {
              _remoteRoot = freshRemote;
              return freshRemote;
            }
          }
        } catch (_) {
          // 重探失败(如临时网络问题)时退回旧映射,不把探测错误暴露给调用方。
        }
      }
    }
    return mapped;
  }

  Future<bool> _remoteExists(String path) async {
    final out = await _probeRemote('[ -e ${GitRunner.quote(path)} ] && echo __ok__', timeout: const Duration(seconds: 15));
    return out.contains('__ok__');
  }

  Future<String> localPath(String remotePathValue) async {
    final root = localRoot;
    if (root == null) return remotePathValue;
    final remote = await remoteRoot();
    if (remotePathValue == remote) return root;
    if (!remotePathValue.startsWith('$remote/')) return remotePathValue;
    
    final relative = p.relative(remotePathValue, from: remote);
    return p.join(root, relative);
  }

  static const String ghMissingHint =
      '容器环境未就绪(缺少 gh 或 gh-codecraft.sh),请确认已安装最新 APK 并重启 App/容器,\n'
      '或在终端执行 codecraft 打开「环境安装」安装 GitHub Codespaces 场景。';

  static const String credentialMissingHint =
      '未配置 GitHub 凭据:请在「Git 凭据」里填写带 codespace 权限的令牌(与 Git 推送共用)。';

  static const List<String> _ghFailureMarkers = [
    'command not found',
    '没有那个文件或目录',
    '未找到命令',
    '未配置 GitHub 凭据',
    'git 凭据为空',
    '没有 github.com',
    'gh-codecraft.sh',
  ];

  static const List<String> _sshFailureMarkers = [
    'shell closed',
    'connection closed',
    'connection reset',
    'broken pipe',
    'kex_exchange',
    'permission denied',
    'no route to host',
    'could not resolve',
    'timed out',
    'operation timed out',
    'failed to connect',
    'ssh:',
  ];

  static const String connectionHint =
      '无法连接到 Codespace:请确认该 Codespace 已启动(Available),网络可用,且 gh 已完成授权.\n'
      '可在终端执行: gh codespace ssh -c <名称> 测试连接。';

  String remoteCommand(String command, {String? remoteWorkdir}) {
    final body = remoteWorkdir == null
        ? command
        : 'cd ${GitRunner.quote(remoteWorkdir)} || exit 1\n$command';
    
    final encoded = base64Encode(utf8.encode(body));
    // 使用 printf 管道替代 Heredoc，彻底解决换行符导致远端 Shell 无法识别结束标志而导致输出为空的问题。
    final inner = "printf '%s' '$encoded' | base64 -d | sh";
    
    return '${GitRunner.quote(ghHelper)} codespace ssh -c ${GitRunner.quote(codespace)} -- sh -c ${GitRunner.quote(inner)}';
  }

  @override
  Future<bool> isReady() async {
    if (!await transport.isReady()) return false;
    return await hasGh();
  }

  Future<bool> hasGh() async {
    final result = await transport.runCommandSync(
      'command -v gh >/dev/null 2>&1 && gh --version >/dev/null 2>&1 && test -x ${GitRunner.quote(ghHelper)}',
      timeout: const Duration(seconds: 30),
    );
    return result.exitCode == 0;
  }

  @override
  Future<String?> notReadyHint() async {
    final localHint = await transport.notReadyHint();
    if (localHint != null) return localHint;
    if (!await hasGh()) return ghMissingHint;
    return null;
  }

  @override
  Future<CommandResult> runCommandSync(
    String command, {
    String? workdir,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    final remoteWorkdir = workdir == null ? null : await remotePath(workdir);
    final result = await transport.runCommandSync(
      remoteCommand(command, remoteWorkdir: remoteWorkdir),
      timeout: timeout,
    );
    final rewritten = _rewriteGhFailure(result);
    if (!rewritten.ok && remoteWorkdir != null) {
      final lower = rewritten.output.toLowerCase();
      final looksLikeCdFail = lower.contains('exit status 1') ||
          lower.contains('exit status 2') ||
          lower.contains('no such file') ||
          lower.contains('not a directory') ||
          lower.contains('没有那个文件') ||
          lower.contains('不是目录');
      if (looksLikeCdFail) {
        resetRemoteRoot();
        try {
          final freshWorkdir = await remotePath(workdir!);
          if (freshWorkdir != remoteWorkdir) {
            final retry = await transport.runCommandSync(
              remoteCommand(command, remoteWorkdir: freshWorkdir),
              timeout: timeout,
            );
            return _rewriteGhFailure(retry);
          }
        } catch (_) {}
      }
    }
    return rewritten;
  }

  @override
  Stream<Object> runCommandStream(
    String command, {
    String? workdir,
    Duration timeout = const Duration(seconds: 120),
  }) async* {
    final result = await runCommandSync(command, workdir: workdir, timeout: timeout);
    for (final line in const LineSplitter().convert(result.output)) {
      yield CommandLineEvent(line);
    }
    yield CommandExitEvent(result.exitCode, timedOut: result.timedOut);
  }

  @override
  Future<TerminalProcess> openTerminal({
    String? command,
    int cols = 80,
    int rows = 24,
    String? workdir,
  }) async {
    final gh = GitRunner.quote(ghHelper);
    // Codespace 终端始终进入远端项目根目录（忽略本地 workdir）
    String? targetDir;
    try {
      targetDir = await remoteRoot();
    } catch (_) {
      targetDir = null;
    }
    // 确保目标目录在远端存在且可进入
    String cdPrefix = '';
    if (targetDir != null && targetDir.isNotEmpty) {
      final exists = await _remoteDirExists(targetDir);
      if (exists) {
        cdPrefix = 'cd ${GitRunner.quote(targetDir)} && ';
      } else {
        // 回退：尝试 /workspaces 下第一个目录
        final fallback = await _probeRemote(
            'ls -1d /workspaces/*/ 2>/dev/null | head -n 1');
        final fb = fallback.trim();
        if (fb.isNotEmpty) {
          cdPrefix = 'cd ${GitRunner.quote(fb)} && ';
        }
      }
    }

    // 交互式 shell：用 bash -l/-i 启动并先 cd，避免 exec 替换导致的 cwd 丢失
    // 非交互命令：同样先 cd 再执行
    final cmdStr = command == null
        ? '${cdPrefix}exec \${SHELL:-/bin/bash} -il'
        : '${cdPrefix}exec ${_remoteArgv(command)}';

    final interactive =
        '$gh codespace ssh -c ${GitRunner.quote(codespace)} -- ${GitRunner.quote(cmdStr)}';
    return transport.openTerminal(command: interactive, cols: cols, rows: rows);
  }

  String _remoteArgv(String command) {
    final encoded = base64Encode(utf8.encode(command));
    return 'sh -c ${GitRunner.quote('printf \'%s\' "$encoded" | base64 -d | sh')}';
  }

  CommandResult _rewriteGhFailure(CommandResult result) {
    if (result.ok) return result;
    final output = result.output;
    final lower = output.toLowerCase();
    final timedOut = result.timedOut;

    final isCredentialIssue = lower.contains('凭据') ||
        lower.contains('credential') ||
        lower.contains('git-credentials') ||
        lower.contains('git 凭据') ||
        lower.contains('令牌') ||
        (lower.contains('token') && !lower.contains('unexpected token'));
    final isGhMissing = lower.contains('command not found') ||
        lower.contains('未找到命令') ||
        lower.contains('没有那个文件或目录') ||
        lower.contains('gh-codecraft.sh') ||
        (lower.contains('not found') && lower.contains('gh'));

    if (isCredentialIssue) {
      return CommandResult(
        output: credentialMissingHint,
        exitCode: result.exitCode,
        timedOut: timedOut,
      );
    }
    if (isGhMissing && _ghFailureMarkers.any(lower.contains)) {
      return CommandResult(
        output: ghMissingHint,
        exitCode: result.exitCode,
        timedOut: timedOut,
      );
    }

    final hasStrongSshSignal = lower.contains('connection closed') ||
        lower.contains('connection reset') ||
        lower.contains('broken pipe') ||
        lower.contains('kex_exchange') ||
        lower.contains('permission denied') ||
        lower.contains('no route to host') ||
        lower.contains('could not resolve') ||
        lower.contains('timed out') ||
        lower.contains('operation timed out') ||
        lower.contains('failed to connect') ||
        lower.contains('ssh:') ||
        lower.contains('exit status 255') ||
        timedOut;
    final shellClosedOnly = lower.contains('shell closed') && !hasStrongSshSignal;
    if (hasStrongSshSignal || (lower.contains('shell closed') && (result.exitCode == 255 || timedOut))) {
      final detail = output.trim();
      final merged = detail.isEmpty || detail == connectionHint
          ? connectionHint
          : '$connectionHint\n\n详情: $detail';
      return CommandResult(
        output: merged,
        exitCode: result.exitCode,
        timedOut: timedOut,
      );
    }
    if (shellClosedOnly) {
      final detail = output.trim();
      final hint = detail.isEmpty
          ? '远端命令执行失败(会话已关闭);若持续出现请确认 Codespace 已启动且网络可用,可执行: gh codespace ssh -c ${codespace}'
          : '$detail\n\n(若持续出现请确认 Codespace 已启动且网络可用,可执行: gh codespace ssh -c ${codespace})';
      return CommandResult(output: hint, exitCode: result.exitCode, timedOut: timedOut);
    }

    if (_ghFailureMarkers.any(lower.contains)) {
      return CommandResult(
        output: ghMissingHint,
        exitCode: result.exitCode,
        timedOut: timedOut,
      );
    }
    return result;
  }
}