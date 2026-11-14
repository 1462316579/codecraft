import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../agent/models/git_models.dart';
import '../execution_target.dart';
import 'git_graph_builder.dart';
import 'git_graph_models.dart';
import 'git_runner.dart';
import '../container/command_engine.dart';

/// 解码 git 的 C 风格路径转义(形如 `"a\346\226\207"`):八进制字节按 UTF-8 还原。
///
/// porcelain v1 / ls-files / diff-tree 对含引号、反斜杠、空格或控制字符的路径会整体加引号并做
/// C 风格转义;未加引号的普通路径原样返回。八进制转义是**逐字节**的:一个汉字三个字节会转成
/// 三段 `\NNN`,逐段取字符只能得到三个 Latin-1 字符(即乱码),故连续的 `\NNN` 先攒成字节序列
/// 再整体按 UTF-8 解码。
String unquoteGitPath(String raw) {
  if (!raw.startsWith('"')) return raw;
  final inner = raw.length >= 2 && raw.endsWith('"')
      ? raw.substring(1, raw.length - 1)
      : raw.substring(1);
  final buffer = StringBuffer();
  var index = 0;
  while (index < inner.length) {
    final char = inner[index];
    if (char != r'\' || index + 1 >= inner.length) {
      buffer.write(char);
      index += 1;
      continue;
    }
    if (_isOctal(inner[index + 1])) {
      final bytes = <int>[];
      while (index + 1 < inner.length &&
          inner[index] == r'\' &&
          _isOctal(inner[index + 1])) {
        final end = index + 4 > inner.length ? inner.length : index + 4;
        final chunk = inner
            .substring(index + 1, end)
            .split('')
            .takeWhile(_isOctal)
            .join();
        if (chunk.length != 3) break;
        bytes.add(int.parse(chunk, radix: 8));
        index += 4;
      }
      if (bytes.isEmpty) {
        buffer.write(char);
        index += 1;
      } else {
        buffer.write(utf8.decode(bytes, allowMalformed: true));
      }
      continue;
    }
    final decoded = switch (inner[index + 1]) {
      'a' => '\u0007',
      'b' => '\b',
      'f' => '\u000C',
      'n' => '\n',
      'r' => '\r',
      't' => '\t',
      'v' => '\u000B',
      '"' => '"',
      r'\' => r'\',
      _ => null,
    };
    if (decoded == null) {
      buffer.write(char);
      index += 1;
    } else {
      buffer.write(decoded);
      index += 2;
    }
  }
  return buffer.toString();
}

bool _isOctal(String char) =>
    char.codeUnitAt(0) >= 0x30 && char.codeUnitAt(0) <= 0x37;

/// 取短哈希(对齐上游 `take(7)`):不足 7 位时原样返回,不越界。
String shortHash(String hash) => hash.length <= 7 ? hash : hash.substring(0, 7);

/// 一次 `for-each-ref` 得到的全部引用切面(对齐上游 AllRefs)。
class GitAllRefs {
  const GitAllRefs({
    this.branches = const [],
    this.tags = const [],
    this.refsByCommit = const {},
  });

  final List<GitBranch> branches;
  final List<GitTag> tags;
  final Map<String, List<GitGraphRef>> refsByCommit;
}

/// 容器内真实 git(对齐上游 `GitRepository`):命令经 [GitRunner] 交给容器的 `/bin/sh -c`,
/// cwd 为仓库路径。凭据由容器内 `.gitconfig` 的 credential helper 处理。
class ContainerGit {
  ContainerGit(this._runner);

  final GitRunner _runner;

  /// 容器未就绪时的引导文案;就绪返回 null。
  Future<String?> notReadyHint() async => null;

  /// 运行任意 shell 命令(如 `gh api user`),返回聚合输出与退出码。
  Future<CommandResult> runShell(String path, String command, {Duration? timeout}) async =>
      _runner.runShell(path, command, timeout: timeout);

  /// 指定路径是否处于 git 工作树内(`rev-parse --is-inside-work-tree`)。
  Future<bool> isRepository(String path) async {
    final result = await _runner.run(path, ['rev-parse', '--is-inside-work-tree']);
    return result.exitCode == 0 && result.output.trim() == 'true';
  }

  /// 工作区根与一层直接子目录里的 git 仓库:根优先,子目录按名称排序。
  Future<List<String>> discoverRepos(String root) async {
    final repos = <String>[];
    if (await isRepository(root)) repos.add(root);
    for (final name in listSubdirectories(root)) {
      final path = p.join(root, name);
      if (await isRepository(path)) repos.add(path);
    }
    return repos;
  }

  /// 一层直接子目录名(忽略隐藏目录),按名称排序。
  List<String> listSubdirectories(String root) {
    final dir = Directory(root);
    if (!dir.existsSync()) return const [];
    final names = <String>[];
    for (final entity in dir.listSync()) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (name.startsWith('.')) continue;
      names.add(name);
    }
    names.sort();
    return names;
  }

  /// 初始化仓库:优先 `init -b main`,老版本 git 不支持 `-b` 时降级并手动把 HEAD 指向 main。
  Future<void> init(String path) async {
    final result = await _runner.run(path, ['init', '-b', 'main']);
    if (result.exitCode == 0) return;
    await _runner.checked(path, ['init']);
    await _runner.run(path, ['symbolic-ref', 'HEAD', 'refs/heads/main']);
  }

  /// 克隆远程仓库到工作区根目录(`git clone <url> .`);超时 10 分钟。
  Future<void> clone(String path, String url) async {
    await _runner.checked(
      path,
      ['clone', url.trim(), '.'],
      timeout: const Duration(minutes: 10),
    );
  }

  /// 是否配置了至少一个远端(`git remote` 输出非空)。
  Future<bool> hasRemote(String path) async {
    final result = await _runner.run(path, ['remote']);
    return result.exitCode == 0 && result.output.trim().isNotEmpty;
  }

  /// `git status --porcelain=v1 -b` 的聚合视图(解析口径与上游一致)。
  Future<GitStatus> status(String path) async {
    final raw = await _runner.checked(path, ['status', '--porcelain=v1', '-b']);
    final lines = raw.split('\n').map((line) => line.endsWith('\r')
        ? line.substring(0, line.length - 1)
        : line);

    var branch = '(unknown)';
    String? upstream;
    var isDetached = false;
    var ahead = 0;
    var behind = 0;
    final staged = <GitFileChange>[];
    final unstaged = <GitFileChange>[];
    final untracked = <String>[];
    final conflicted = <GitFileChange>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      if (line.startsWith('## ')) {
        final header = line.substring(3);
        isDetached = header.startsWith('HEAD (no branch)');
        final tracking = header.split(' [').first;
        if (isDetached) {
          branch = 'HEAD';
        } else {
          final name = tracking.split('...').first;
          branch = name.trim().isEmpty ? tracking : name;
          final after = tracking.contains('...') ? tracking.split('...')[1] : '';
          upstream = after.trim().isEmpty ? null : after.trim();
        }
        if (header.contains(' [')) {
          var bracket = header.split(' [').last;
          if (bracket.endsWith(']')) bracket = bracket.substring(0, bracket.length - 1);
          for (final token in bracket.split(',')) {
            final text = token.trim();
            final count = int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            if (text.startsWith('ahead')) {
              ahead = count;
            } else if (text.startsWith('behind')) {
              behind = count;
            }
          }
        }
        continue;
      }
      if (line.length < 3) continue;
      final x = line[0];
      final y = line[1];
      final rawPath = line.substring(3);
      final path = unquoteGitPath(
        (rawPath.contains(' -> ') ? rawPath.split(' -> ').last : rawPath).trim(),
      );

      if (x == '?' && y == '?') {
        untracked.add(path);
        continue;
      }
      final isConflict =
          x == 'U' || y == 'U' || (x == 'A' && y == 'A') || (x == 'D' && y == 'D');
      if (isConflict) {
        conflicted.add(GitFileChange(path: path, statusCode: '$x$y', staged: false));
        continue;
      }
      if (x != ' ' && x != '?') {
        staged.add(GitFileChange(path: path, statusCode: x, staged: true));
      }
      if (y != ' ' && y != '?') {
        unstaged.add(GitFileChange(path: path, statusCode: y, staged: false));
      }
    }
    final isMerging = await hasMergeHead(path) || conflicted.isNotEmpty;
    return GitStatus(
      branch: branch,
      ahead: ahead,
      behind: behind,
      staged: staged,
      unstaged: unstaged,
      untracked: untracked,
      conflicted: conflicted,
      isMerging: isMerging,
      upstream: upstream,
      isDetached: isDetached,
    );
  }

  /// 是否存在未完成的合并(`MERGE_HEAD`)。
  Future<bool> hasMergeHead(String path) async {
    final result = await _runner.run(path, ['rev-parse', '-q', '--verify', 'MERGE_HEAD']);
    if (result.exitCode != 0) return false;
    final output = result.output.trim();
    return output.isNotEmpty && !output.startsWith('fatal');
  }

  /// 提交列表(对齐上游 log + 图接口的字段):`%H %h %an %ar %s %P %b`,
  /// `%ar` 是 git 的英文相对时间;`%P` 用于判定合并提交,`%b` 供详情弹层展示(只取首行)。
  ///
  /// 注意：`%b`(提交正文)可能包含多行，按 `\n` 分割后会把 body 的多行拆开。
  /// 这里按 40 位 SHA-1 哈希作为提交边界重新组合，避免多行 body 被误拆导致提交丢失。
  Future<List<GitCommit>> log(String path, {int skip = 0, int limit = 100}) async {
    final args = <String>[
      'log',
      '--pretty=format:%H%x1f%h%x1f%an%x1f%ar%x1f%s%x1f%P%x1f%b',
    ];
    if (skip > 0) args.addAll(['--skip', '$skip']);
    args.addAll(['-n', '$limit']);
    final result = await _runner.run(path, args);
    final raw = result.output;
    if (raw.trim().isEmpty || raw.startsWith('fatal:')) return const [];
    final sha1Boundary = RegExp(r'^[0-9a-f]{40}\x1f');
    final commits = <GitCommit>[];
    final lines = raw.split('\n');
    var i = 0;
    while (i < lines.length) {
      final line = lines[i].endsWith('\r') ? lines[i].substring(0, lines[i].length - 1) : lines[i];
      if (!sha1Boundary.hasMatch(line)) {
        i++;
        continue;
      }
      final parts = line.split('\u001f');
      if (parts.length < 6) {
        i++;
        continue;
      }
      var body = parts.length > 6 ? parts[6] : '';
      i++;
      while (i < lines.length) {
        final nextLine = lines[i].endsWith('\r') ? lines[i].substring(0, lines[i].length - 1) : lines[i];
        if (sha1Boundary.hasMatch(nextLine)) break;
        body = body.isEmpty ? nextLine : '$body\n$nextLine';
        i++;
      }
      commits.add(GitCommit(
        hash: parts[0],
        author: parts[2],
        date: parts[3],
        message: parts[4],
        parents: parts[5].split(' ').where((hash) => hash.trim().isNotEmpty).toList(),
        body: body.trim(),
      ));
    }
    return commits;
  }

  /// 分支列表(本地 + 远程),当前分支高亮。
  Future<List<GitBranch>> branches(String path) async =>
      (await loadAllRefs(path)).branches;

  /// 标签列表(名称 + 指向提交的短哈希)。
  Future<List<GitTag>> tags(String path) async => (await loadAllRefs(path)).tags;

  /// 一次 `for-each-ref` 拿全部分支/标签及其指向的提交与是否 HEAD(对齐上游 loadAllRefs)。
  Future<GitAllRefs> loadAllRefs(String path) async {
    final result = await _runner.run(path, [
      'for-each-ref',
      '--format=%(refname:short)\u001f%(objectname)\u001f%(HEAD)\u001f%(refname)\u001f%(upstream:short)\u001f%(upstream:track)',
      'refs/heads',
      'refs/remotes',
      'refs/tags',
    ]);
    final raw = result.output;
    if (raw.trim().isEmpty || raw.startsWith('fatal:')) return const GitAllRefs();

    final branches = <GitBranch>[];
    final tags = <GitTag>[];
    final refsByCommit = <String, List<GitGraphRef>>{};
    for (final line in raw.split('\n')) {
      final trimmed = (line.endsWith('\r')
              ? line.substring(0, line.length - 1)
              : line)
          .trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split('\u001f');
      if (parts.length < 4) continue;
      final name = parts[0];
      final hash = parts[1];
      final isHead = parts[2].trim() == '*';
      final refname = parts[3];
      final upstreamRaw = parts.length > 4 ? parts[4] : '';
      final upstream = upstreamRaw.trim().isEmpty ? null : upstreamRaw;
      final track = parts.length > 5 ? parts[5] : '';
      final ahead = int.tryParse(
              RegExp(r'ahead (\d+)').firstMatch(track)?.group(1) ?? '') ??
          0;
      final behind = int.tryParse(
              RegExp(r'behind (\d+)').firstMatch(track)?.group(1) ?? '') ??
          0;
      final isRemote = refname.startsWith('refs/remotes');
      final isBranch = refname.startsWith('refs/heads') || isRemote;
      refsByCommit.putIfAbsent(hash, () => <GitGraphRef>[]).add(GitGraphRef(
            name: name,
            isBranch: isBranch,
            isCurrent: isHead && !isRemote,
            isRemote: isRemote,
          ));
      if (isBranch) {
        branches.add(GitBranch(
          name: name,
          current: isHead && !isRemote,
          remote: isRemote,
          upstream: upstream,
          ahead: ahead,
          behind: behind,
        ));
      } else {
        tags.add(GitTag(name: name, commitHash: shortHash(hash)));
      }
    }
    // for-each-ref 默认按 refname 排序;标签倒序与上游 listTags 行为对齐。
    return GitAllRefs(
      branches: branches,
      tags: tags.reversed.toList(),
      refsByCommit: refsByCommit,
    );
  }

  /// 创建分支(对齐上游 createBranch):`checkout=true` 时 `git checkout -b`,否则 `git branch`;
  /// [startPoint] 为空则从当前 HEAD 起。
  Future<void> createBranch(
    String path,
    String name, {
    String? startPoint,
    bool checkout = false,
  }) async {
    final base = (startPoint == null || startPoint.trim().isEmpty)
        ? <String>[]
        : <String>[startPoint];
    await _runner.checked(
      path,
      checkout ? ['checkout', '-b', name, ...base] : ['branch', name, ...base],
    );
  }

  /// 打标签(对齐上游 createTag):`git tag <name> [hash]`。
  Future<void> createTag(String path, String name, {String? commitHash}) async {
    if (commitHash == null || commitHash.trim().isEmpty) {
      await _runner.checked(path, ['tag', name]);
    } else {
      await _runner.checked(path, ['tag', name, commitHash]);
    }
  }

  /// 重置当前分支到指定提交(对齐上游 resetToCommit):`git reset --<mode> <hash>`。
  Future<void> resetToCommit(String path, String commitHash, {String mode = 'mixed'}) async {
    await _runner.checked(path, ['reset', '--$mode', commitHash]);
  }

  /// 某次提交对某个文件的差异原文(`git show`,根提交也能出本文)。
  /// 提交署名(`user.name` / `user.email`,local 优先、git 自行回落到 global/system)。
  Future<GitIdentity> identity(String path) async => GitIdentity(
        name: await _configGet(path, 'user.name'),
        email: await _configGet(path, 'user.email'),
      );

  Future<String> _configGet(String path, String key) async {
    final result = await _runner.run(path, ['config', '--get', key]);
    return result.exitCode == 0 ? result.output.trim() : '';
  }

  /// 某次提交改动的文件清单(对齐上游 commitFiles):`--root` 兼容无父的根提交,
  /// `--no-renames` 让重命名退化为「删除旧 + 新增新」,状态码取首字符即可。
  Future<List<GitFileChange>> commitFiles(String path, String hash) async {
    final result = await _runner.run(path, [
      'diff-tree',
      '--no-commit-id',
      '-r',
      '--root',
      '--name-status',
      '--no-renames',
      hash,
    ]);
    final raw = result.output;
    if (raw.trim().isEmpty || raw.startsWith('fatal:')) return const [];
    final files = <GitFileChange>[];
    for (final line in raw.split('\n')) {
      final trimmed = (line.endsWith('\r')
              ? line.substring(0, line.length - 1)
              : line)
          .trim();
      final tab = trimmed.indexOf('\t');
      if (trimmed.isEmpty || tab < 0) continue;
      files.add(GitFileChange(
        path: unquoteGitPath(trimmed.substring(tab + 1).trim()),
        statusCode: trimmed.substring(0, tab).trim(),
        staged: false,
      ));
    }
    return files;
  }

  // ── 提交图(对齐上游 graph / graphAppend / localRefsOnly)──

  /// 仅本地分支的 refs-by-commit 映射(无标签、无远程)。
  Future<Map<String, List<GitGraphRef>>> localRefsOnly(String path) async {
    final result = await _runner.run(path, [
      'for-each-ref',
      '--format=%(refname:short)\u001f%(objectname)\u001f%(HEAD)\u001f%(refname)',
      'refs/heads',
    ]);
    final raw = result.output;
    if (raw.trim().isEmpty || raw.startsWith('fatal:')) return const {};
    final refs = <String, List<GitGraphRef>>{};
    for (final line in raw.split('\n')) {
      final trimmed = _stripCr(line).trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split('\u001f');
      if (parts.length < 4) continue;
      refs.putIfAbsent(parts[1], () => []).add(GitGraphRef(
            name: parts[0],
            isBranch: true,
            isCurrent: parts[2].trim() == '*',
            isRemote: false,
          ));
    }
    return refs;
  }

  /// 首批拉取提交图(上游 `graph`)。
  Future<GitGraph> graph(
    String path, {
    int limit = GitRunner.graphPageSize,
    Map<String, List<GitGraphRef>> refs = const {},
  }) =>
      graphAppend(path, existingCommits: const [], refs: refs, limit: limit);

  /// 分页追加提交:用 `--skip` 取下一页,与已有提交去重后整体重算泳道布局。
  Future<GitGraph> graphAppend(
    String path, {
    List<GraphCommit> existingCommits = const [],
    Map<String, List<GitGraphRef>> refs = const {},
    int limit = GitRunner.graphPageSize,
  }) async {
    final result = await _runner.run(path, [
      'log',
      '--pretty=format:%H%x1f%h%x1f%an%x1f%ar%x1f%s%x1f%P%x1f%b',
      '--skip',
      '${existingCommits.length}',
      '-n',
      '$limit',
    ]);
    final raw = result.output;
    if (raw.trim().isEmpty || raw.startsWith('fatal:')) {
      return existingCommits.isEmpty
          ? GitGraph.empty
          : GitGraphBuilder.buildGraph(existingCommits, refs, hasMore: false);
    }
    final newCommits = GitGraphBuilder.parseGraphCommits(raw);
    if (newCommits.isEmpty && existingCommits.isEmpty) return GitGraph.empty;
    final existingHashes = existingCommits.map((commit) => commit.hash).toSet();
    final merged = [
      ...existingCommits,
      ...newCommits.where((commit) => !existingHashes.contains(commit.hash)),
    ];
    return GitGraphBuilder.buildGraph(merged, refs, hasMore: newCommits.length >= limit);
  }

  // ── 暂存 / 提交 / 回退 ──

  Future<void> stage(String path, String filePath) async =>
      _runner.checked(path, ['add', '--', filePath]);

  Future<void> unstage(String path, String filePath) async =>
      _runner.checked(path, ['reset', 'HEAD', '--', filePath]);

  Future<void> stageAll(String path) async => _runner.checked(path, ['add', '-A']);

  Future<void> unstageAll(String path) async => _runner.checked(path, ['reset']);

  Future<void> commit(String path, String message, {bool amend = false}) async {
    if (amend) {
      await _runner.checked(path, ['commit', '--amend', '-m', message]);
    } else {
      await _runner.checked(path, ['commit', '-m', message]);
    }
  }

  /// 供 AI 生成提交信息的差异文本:优先暂存区,为空则取工作区。
  Future<String> diffForCommitMessage(String path) async {
    final staged = await _runner.run(path, ['diff', '--cached', '--no-color', '--no-ext-diff']);
    if (staged.output.trim().isNotEmpty && !staged.output.startsWith('fatal:')) {
      return staged.output;
    }
    final worktree = await _runner.run(path, ['diff', '--no-color', '--no-ext-diff']);
    return worktree.output.startsWith('fatal:') ? '' : worktree.output;
  }

  /// 回退单个文件的未暂存改动(被删除的文件由此重新出现)。
  Future<void> revertWorktree(String path, String filePath) async =>
      _runner.checked(path, ['checkout', '--', filePath]);

  /// 回退单个文件的全部改动(已暂存 + 未暂存)到上次提交;无 HEAD 时只能退回未跟踪。
  Future<void> revertToHead(String path, String filePath) async {
    if (!await hasHead(path)) {
      await _runner.checked(path, ['rm', '-q', '--cached', '--', filePath]);
      return;
    }
    await _runner.checked(path, ['reset', '-q', 'HEAD', '--', filePath]);
    if (await _existsInHead(path, filePath)) {
      await _runner.checked(path, ['checkout', '--', filePath]);
    }
  }

  /// 回退全部未暂存改动(pathspec `:/` 指仓库根,已暂存内容不受影响)。
  Future<void> revertAllWorktree(String path) async =>
      _runner.checked(path, ['checkout', '--', ':/']);

  /// 删除未跟踪的文件或目录(不带 `-x`,被忽略的文件保持不动)。
  Future<void> deleteUntracked(String path, String target) async =>
      _runner.checked(path, ['clean', '-f', '-d', '--', target]);

  /// 某个未跟踪目录下的未跟踪文件清单(`git status` 默认把新目录折叠成一行)。
  Future<List<String>> untrackedFilesIn(String path, String dir) async {
    final result = await _runner.run(
      path,
      ['ls-files', '--others', '--exclude-standard', '--', dir],
    );
    final raw = result.output;
    if (raw.trim().isEmpty || raw.startsWith('fatal:')) return const [];
    return [
      for (final line in raw.split('\n'))
        if (_stripCr(line).trim().isNotEmpty) unquoteGitPath(_stripCr(line).trim()),
    ];
  }

  /// 仓库是否已有提交(HEAD 可解析);空仓库里 `reset HEAD` / `ls-tree HEAD` 都会失败。
  Future<bool> hasHead(String path) async {
    final result = await _runner.run(path, ['rev-parse', '--verify', 'HEAD']);
    final output = result.output.trim();
    return output.isNotEmpty && !output.startsWith('fatal');
  }

  Future<bool> _existsInHead(String path, String filePath) async {
    final result = await _runner.run(path, ['ls-tree', 'HEAD', '--', filePath]);
    final output = result.output.trim();
    return output.isNotEmpty && !output.startsWith('fatal');
  }

  // ── 远程操作 ──

  Future<void> pull(String path) async =>
      _runner.checked(path, ['pull'], timeout: const Duration(minutes: 10));

  /// 有上游则 `push`;无上游时自动 `--set-upstream <remote> <branch>` 首推建关联。
  Future<void> push(String path) async {
    if (await _hasUpstream(path)) {
      await _runner.checked(path, ['push'], timeout: const Duration(minutes: 10));
      return;
    }
    final remoteResult = await _runner.run(path, ['remote']);
    final remote = remoteResult.output
        .split('\n')
        .map(_stripCr)
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    if (remote.isEmpty) throw const GitException('未配置远程仓库');
    final branchResult = await _runner.run(path, ['rev-parse', '--abbrev-ref', 'HEAD']);
    final branch = _stripCr(branchResult.output).trim();
    if (branch.isEmpty || branch == 'HEAD') {
      throw const GitException('无法确定当前分支(处于 detached HEAD)');
    }
    await _runner.checked(
      path,
      ['push', '--set-upstream', remote, branch],
      timeout: const Duration(minutes: 10),
    );
  }

  /// 当前是否为 master 分支的首次推送(供 UI 询问是否重命名为 main)。
  Future<bool> isFirstPushOfMaster(String path) async {
    if (await _hasUpstream(path)) return false;
    final result = await _runner.run(path, ['rev-parse', '--abbrev-ref', 'HEAD']);
    return _stripCr(result.output).trim() == 'master';
  }

  Future<void> renameMasterToMainAndPush(String path) async {
    await renameBranch(path, 'master', 'main');
    await push(path);
  }

  Future<bool> _hasUpstream(String path) async {
    final result = await _runner.run(path, ['rev-parse', '--abbrev-ref', '@{upstream}']);
    final output = _stripCr(result.output).trim();
    return output.isNotEmpty && output != 'HEAD' && !output.startsWith('fatal');
  }

  // ── 分支 / 标签写操作 ──

  Future<void> deleteBranch(String path, String name) async =>
      _runner.checked(path, ['branch', '-d', name]);

  Future<void> renameBranch(String path, String oldName, String newName) async =>
      _runner.checked(path, ['branch', '-m', oldName, newName]);

  /// 删除远程分支:ref 形如 `origin/feature`,无 remote 前缀时按 `origin` 兜底。
  Future<void> deleteRemoteBranch(String path, String ref) async {
    final slash = ref.indexOf('/');
    final remote = slash < 0 ? 'origin' : ref.substring(0, slash);
    final branch = slash < 0 ? ref : ref.substring(slash + 1);
    await _runner.checked(path, ['push', remote, '--delete', branch]);
  }

  Future<void> deleteTag(String path, String name) async =>
      _runner.checked(path, ['tag', '-d', name]);

  /// 切换分支/标签:远程分支会创建本地跟踪分支并去掉远程前缀。
  Future<void> checkout(String path, String branch, {bool isRemote = false}) async {
    if (isRemote) {
      final slash = branch.indexOf('/');
      final localName = slash < 0 ? branch : branch.substring(slash + 1);
      await _runner.checked(path, ['checkout', '-b', localName, '--track', branch]);
    } else {
      await _runner.checked(path, ['checkout', branch]);
    }
  }

  Future<void> mergeBranch(String path, String branch, {bool noFf = false}) async {
    if (noFf) {
      await _runner.checked(path, ['merge', '--no-ff', branch]);
    } else {
      await _runner.checked(path, ['merge', branch]);
    }
  }

  Future<void> abortMerge(String path) async => _runner.checked(path, ['merge', '--abort']);

  // ── 储藏 ──

  Future<List<GitStash>> stashList(String path) async {
    final result = await _runner.run(path, [
      'stash',
      'list',
      '--pretty=format:%gd%x1f%s%x1f%ar',
    ]);
    final raw = result.output;
    if (raw.trim().isEmpty || raw.startsWith('fatal:')) return const [];
    final stashes = <GitStash>[];
    for (final line in raw.split('\n')) {
      final trimmed = _stripCr(line).trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split('\u001f');
      if (parts.length < 3) continue;
      stashes.add(GitStash(
        index: parts[0],
        message: parts[1],
        date: parts[2],
      ));
    }
    return stashes;
  }

  Future<void> stashSave(
    String path, {
    String? message,
    bool includeUntracked = false,
  }) async {
    final args = <String>['stash', 'push'];
    if (includeUntracked) args.add('-u');
    if (message != null && message.trim().isNotEmpty) {
      args.addAll(['-m', message.trim()]);
    }
    await _runner.checked(path, args);
  }

  Future<void> stashPop(String path, {String index = 'stash@{0}'}) async =>
      _runner.checked(path, ['stash', 'pop', index]);

  Future<void> stashApply(String path, {String index = 'stash@{0}'}) async =>
      _runner.checked(path, ['stash', 'apply', index]);

  Future<void> stashDrop(String path, {String index = 'stash@{0}'}) async =>
      _runner.checked(path, ['stash', 'drop', index]);

  Future<void> stashClear(String path) async => _runner.checked(path, ['stash', 'clear']);

  // ── 署名与仓库地址 ──

  /// 写提交署名:工作区已有项目级署名则写 local,否则写 global(容器持久挂载的 .gitconfig)。
  Future<void> setUserIdentity(String path, String name, String email) async {
    if (name.trim().isNotEmpty) {
      final scope = await _hasLocalConfig(path, 'user.name') ? '--local' : '--global';
      await _runner.checked(path, ['config', scope, 'user.name', name]);
    }
    if (email.trim().isNotEmpty) {
      final scope = await _hasLocalConfig(path, 'user.email') ? '--local' : '--global';
      await _runner.checked(path, ['config', scope, 'user.email', email]);
    }
  }

  Future<bool> _hasLocalConfig(String path, String key) async {
    final result = await _runner.run(path, ['config', '--local', '--get', key]);
    return result.output.trim().isNotEmpty;
  }

  Future<String> getUserName(String path) async =>
      _stripCr((await _runner.run(path, ['config', '--get', 'user.name'])).output).trim();

  Future<String> getUserEmail(String path) async =>
      _stripCr((await _runner.run(path, ['config', '--get', 'user.email'])).output).trim();

  /// 写 remote.origin.url:始终写 `--local`(绝不写 global,否则污染后续 clone),
  /// 并顺手清掉 global 可能残留的同名配置。
  Future<void> setRepoUrl(String path, String url) async {
    if (url.trim().isNotEmpty) {
      await _runner.checked(path, ['config', '--local', 'remote.origin.url', url]);
    } else {
      await _runner.run(path, ['config', '--local', '--unset', 'remote.origin.url']);
    }
    await _runner.run(path, ['config', '--global', '--unset', 'remote.origin.url']);
  }

  Future<String> getRepoUrl(String path) async =>
      _stripCr((await _runner.run(path, ['config', '--get', 'remote.origin.url'])).output)
          .trim();

  // ── 文件内容(差异对比用)──

  /// 指定 ref 下文件的完整内容;该 ref 无此文件时返回空串(上层按全增/全删呈现)。
  Future<String> showFileContent(String path, String ref, String filePath) async {
    if (await _refBlobSize(path, '$ref:$filePath') > GitRunner.maxDiffFileBytes) {
      throw const GitOutputTooLargeException();
    }
    final result = await _runner.run(path, ['show', '$ref:$filePath']);
    final output = result.output;
    return output.startsWith('fatal:') || output.startsWith('error:') ? '' : output;
  }

  /// 暂存区文件内容(index);尚未暂存时返回空串。
  Future<String> indexFileContent(String path, String filePath) async {
    if (await _refBlobSize(path, ':$filePath') > GitRunner.maxDiffFileBytes) {
      throw const GitOutputTooLargeException();
    }
    final result = await _runner.run(path, ['show', ':$filePath']);
    final output = result.output;
    return output.startsWith('fatal:') || output.startsWith('error:') ? '' : output;
  }

  /// 工作区当前文件内容(工作区在宿主目录,直接读文件最快)。
  Future<String> worktreeFileContent(String path, String filePath) async {
    final file = File(p.join(path, filePath));
    if (file.existsSync()) {
      if (file.lengthSync() > GitRunner.maxDiffFileBytes) throw const GitOutputTooLargeException();
      return file.readAsStringSync();
    }
    final result = await _runner.runShell(path, 'cat -- ${GitRunner.quote(filePath)}');
    return result.exitCode == 0 ? result.output : '';
  }

  Future<int> _refBlobSize(String path, String spec) async {
    final result = await _runner.run(path, ['cat-file', '-s', spec]);
    return int.tryParse(result.output.trim()) ?? 0;
  }

  /// 把忽略规则追加到工作区 `.gitignore`(已存在则不重复追加)。
  Future<String> addToGitignore(String path, String pattern) async {
    final normalized = pattern.trim();
    if (normalized.isEmpty) return '';
    final quoted = GitRunner.quote(normalized);
    final check = await _runner.runShell(path, 'grep -F -x -- $quoted .gitignore');
    if (check.exitCode == 0) return normalized;
    final append = await _runner.runShell(path, "printf '%s\\n' $quoted >> .gitignore");
    if (append.exitCode != 0) {
      throw GitException(append.output.trim().isEmpty ? '写入 .gitignore 失败' : append.output);
    }
    return normalized;
  }

  static String _stripCr(String line) =>
      line.endsWith('\r') ? line.substring(0, line.length - 1) : line;
}

/// git 服务:懒取执行引擎(本地容器或 Codespace),供 Git 页在容器就绪前即可构建。
///
/// 目标是 Codespace 时每条 git 命令都会新起一次 `gh codespace ssh`,
/// 单次操作因此比本地慢数秒——换来的是 Git 页与终端/工具操作的是同一个环境。
final containerGitProvider = Provider<ContainerGit>(
  (ref) => ContainerGit(
    GitRunner(() => ref.read(executionEngineProvider.future)),
  ),
);