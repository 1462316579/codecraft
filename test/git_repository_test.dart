import 'package:codecraft/agent/models/git_models.dart';
import 'package:codecraft/data/container/command_engine.dart';
import 'package:codecraft/data/git/container_git.dart';
import 'package:codecraft/data/git/git_graph_models.dart';
import 'package:codecraft/data/git/git_runner.dart';
import 'package:flutter_test/flutter_test.dart';

/// 输出固定的假命令引擎:所有 git 命令返回同一段 [output],退出码 [exitCode]。
///
/// `status()` 会额外探测 MERGE_HEAD 判断合并状态,该探测必须返回空,否则被误判为合并中。
class _FakeEngine implements CommandEngine {
  _FakeEngine(this.output, {this.exitCode = 0});

  final String output;
  final int exitCode;
  final List<String> commands = [];

  @override
  Future<CommandResult> runCommandSync(
    String command, {
    String? workdir,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    commands.add(command);
    if (command.contains('MERGE_HEAD')) {
      return const CommandResult(output: '', exitCode: 0);
    }
    return CommandResult(output: output, exitCode: exitCode);
  }

  @override
  Future<bool> isReady() async => true;

  @override
  Future<String?> notReadyHint() async => null;

  @override
  Future<TerminalProcess> openTerminal({String? command, int cols = 80, int rows = 24, String? workdir}) =>
      throw UnimplementedError();

  @override
  Stream<Object> runCommandStream(
    String command, {
    String? workdir,
    Duration timeout = const Duration(seconds: 120),
  }) =>
      const Stream.empty();
}

/// [ContainerGit] 的输出解析逻辑(用假引擎喂真实 git 输出)。
///
/// 所有用例的输出均按真实 git 命令输出构造(porcelain / for-each-ref / diff-tree /
/// ls-files / log),聚焦解析:中文路径不转义、分支跟踪信息、refs 组装、分页与合并状态。
void main() {
  const workPath = '/root/workspace';

  ContainerGit repoWith(String output, {int exitCode = 0}) {
    final engine = _FakeEngine(output, exitCode: exitCode);
    return ContainerGit(GitRunner(() async => engine));
  }

  // ── status():porcelain v1 -b 解析 ───────────────────────────

  group('status', () {
    test('解析分支跟踪信息与三组改动', () async {
      final repo = repoWith(
        '## feature/foo...origin/feature/foo [ahead 2, behind 3]\n'
        ' M src/Main.kt\n'
        'A  src/New.kt\n'
        '?? untracked/文件.txt',
      );
      final status = await repo.status(workPath);
      expect(status.branch, 'feature/foo');
      expect(status.ahead, 2);
      expect(status.behind, 3);
      expect(status.upstream, 'origin/feature/foo');
      expect(status.isDetached, isFalse);
      expect(status.staged, [
        const GitFileChange(path: 'src/New.kt', statusCode: 'A', staged: true),
      ]);
      expect(status.unstaged, [
        const GitFileChange(path: 'src/Main.kt', statusCode: 'M', staged: false),
      ]);
      expect(status.untracked, ['untracked/文件.txt']);
      expect(status.hasChanges, isTrue);
    });

    test('无上游时 upstream 为 null 且领先落后为 0', () async {
      final status = await repoWith('## main').status(workPath);
      expect(status.branch, 'main');
      expect(status.upstream, isNull);
      expect(status.ahead, 0);
      expect(status.behind, 0);
      expect(status.hasChanges, isFalse);
    });

    test('分离头指针时分支名为 HEAD', () async {
      final status = await repoWith('## HEAD (no branch)').status(workPath);
      expect(status.isDetached, isTrue);
      expect(status.branch, 'HEAD');
    });

    test('中文路径原样保留(core.quotepath=false)', () async {
      final status = await repoWith(
        ' M 中文目录/文件.txt\n?? 中文未跟踪.txt\nA  新建/目录/测试.txt',
      ).status(workPath);
      expect(status.unstaged, [
        const GitFileChange(path: '中文目录/文件.txt', statusCode: 'M', staged: false),
      ]);
      expect(status.untracked, ['中文未跟踪.txt']);
      expect(status.staged, [
        const GitFileChange(path: '新建/目录/测试.txt', statusCode: 'A', staged: true),
      ]);
    });

    test('重命名取箭头后的新路径', () async {
      final status = await repoWith('R  old.txt -> 新目录/新名.txt').status(workPath);
      expect(status.staged, [
        const GitFileChange(path: '新目录/新名.txt', statusCode: 'R', staged: true),
      ]);
      expect(status.unstaged, isEmpty);
    });

    test('X/Y 两列都改动时同时进已暂存与已修改', () async {
      final status = await repoWith('MM app/src/X.kt').status(workPath);
      expect(status.staged, [
        const GitFileChange(path: 'app/src/X.kt', statusCode: 'M', staged: true),
      ]);
      expect(status.unstaged, [
        const GitFileChange(path: 'app/src/X.kt', statusCode: 'M', staged: false),
      ]);
    });

    test('带引号路径会被还原', () async {
      final status = await repoWith(' M "a b.txt"').status(workPath);
      expect(status.unstaged, [
        const GitFileChange(path: 'a b.txt', statusCode: 'M', staged: false),
      ]);
    });

    test('冲突行进 conflicted 且判定为合并中', () async {
      final status = await repoWith('UU app/src/X.kt').status(workPath);
      expect(status.conflicted, hasLength(1));
      expect(status.isMerging, isTrue);
    });
  });

  // ── loadAllRefs():for-each-ref 解析 ────────────────────────

  group('loadAllRefs', () {
    test('解析本地分支、远程分支与标签,并组装 refsByCommit', () async {
      final repo = repoWith(
        'main\u001f7f2a1b3c4d5e\u001f*\u001frefs/heads/main\u001forigin/main\u001f[ahead 1, behind 2]\n'
        'feature\u001f9a8b7c6d5e4f\u001f\u001frefs/heads/feature\u001f\u001f\n'
        'origin/feature\u001f3c2d1e0f9a8b\u001f\u001frefs/remotes/origin/feature\u001f\u001f\n'
        'v1.0\u001f7f2a1b3c4d5e\u001f\u001frefs/tags/v1.0\u001f\u001f',
      );
      final refs = await repo.loadAllRefs(workPath);

      expect(refs.branches.map((b) => b.name), ['main', 'feature', 'origin/feature']);
      final main = refs.branches.first;
      expect(main.current, isTrue);
      expect(main.remote, isFalse);
      expect(main.upstream, 'origin/main');
      expect(main.ahead, 1);
      expect(main.behind, 2);
      expect(refs.branches[2].remote, isTrue);

      expect(refs.tags.map((t) => t.name), ['v1.0']);
      expect(refs.tags.single.commitHash, '7f2a1b3');

      // 同一 hash 上的本地分支与标签都保留,HEAD 标记只落在本地分支。
      final onHash = refs.refsByCommit['7f2a1b3c4d5e']!;
      expect(onHash.map((r) => r.name), ['main', 'v1.0']);
      expect(onHash.first.isBranch, isTrue);
      expect(onHash.first.isCurrent, isTrue);
      expect(onHash.last.isBranch, isFalse);
      expect(
        refs.refsByCommit['3c2d1e0f9a8b']!.single.isRemote,
        isTrue,
      );
    });

    test('标签按 refname 升序输出后反转为倒序', () async {
      final refs = await repoWith(
        'v0.9\u001f1a2b3c4d5e6f\u001f\u001frefs/tags/v0.9\u001f\u001f\n'
        'v1.0\u001f7f2a1b3c4d5e\u001f\u001frefs/tags/v1.0\u001f\u001f',
      ).loadAllRefs(workPath);
      expect(refs.tags.map((t) => t.name), ['v1.0', 'v0.9']);
      expect(refs.tags.first.commitHash, '7f2a1b3');
    });

    test('空输出返回空结果', () async {
      final refs = await repoWith('').loadAllRefs(workPath);
      expect(refs.branches, isEmpty);
      expect(refs.tags, isEmpty);
      expect(refs.refsByCommit, isEmpty);
    });

    test('fatal 输出返回空结果', () async {
      final refs = await repoWith('fatal: Not a git repository').loadAllRefs(workPath);
      expect(refs.branches, isEmpty);
      expect(refs.tags, isEmpty);
      expect(refs.refsByCommit, isEmpty);
    });

    test('branches() 复用 loadAllRefs', () async {
      final branches = await repoWith(
        'main\u001f7f2a1b3c4d5e\u001f*\u001frefs/heads/main\u001f\u001f\n'
        'origin/main\u001f7f2a1b3c4d5e\u001f\u001frefs/remotes/origin/main\u001f\u001f',
      ).branches(workPath);
      expect(branches.map((b) => b.name), ['main', 'origin/main']);
    });

    test('localRefsOnly 只取本地分支', () async {
      final refs = await repoWith(
        'main\u001f7f2a1b3c4d5e\u001f*\u001frefs/heads/main\n'
        'dev\u001f9a8b7c6d5e4f\u001f\u001frefs/heads/dev',
      ).localRefsOnly(workPath);
      expect(refs.keys, containsAll(['7f2a1b3c4d5e', '9a8b7c6d5e4f']));
      expect(refs['7f2a1b3c4d5e']!.single.isCurrent, isTrue);
      expect(refs['9a8b7c6d5e4f']!.single.isCurrent, isFalse);
    });
  });

  // ── log():%x1f 分隔解析 ────────────────────────────────────

  group('log', () {
    test('解析各字段', () async {
      final commits = await repoWith(
        'a1b2c3d4\u001fa1b2c3\u001fAlice\u001f2 days ago\u001ffix: 问题\u001f\u001f\n'
        'e5f6a7b8\u001fe5f6a7\u001fBob\u001f3 days ago\u001ffeat: 新功能\u001f\u001f',
      ).log(workPath);
      expect(commits, hasLength(2));
      expect(commits.first.hash, 'a1b2c3d4');
      expect(commits.first.author, 'Alice');
      expect(commits.first.date, '2 days ago');
      expect(commits.first.message, 'fix: 问题');
      expect(commits.last.message, 'feat: 新功能');
    });

    test('提交信息含竖线时完整保留', () async {
      final commits = await repoWith(
        'a1b2c3d4\u001fa1b2c3\u001fAlice\u001f2 days ago\u001ffix: merge | conflict\u001f\u001f',
      ).log(workPath);
      expect(commits.single.message, 'fix: merge | conflict');
    });

    test('解析父提交与正文', () async {
      final commits = await repoWith(
        'a1b2c3d4\u001fa1b2c3\u001fAlice\u001f2 days ago\u001fmerge\u001fp1 p2\u001f正文行',
      ).log(workPath);
      expect(commits.single.parents, ['p1', 'p2']);
      expect(commits.single.isMerge, isTrue);
      expect(commits.single.body, '正文行');
    });

    test('空输出返回空', () async {
      expect(await repoWith('').log(workPath), isEmpty);
    });

    test('fatal 输出返回空', () async {
      expect(
        await repoWith("fatal: your current branch 'main' does not have any commits yet")
            .log(workPath),
        isEmpty,
      );
    });

    test('字段不足的行整行丢弃', () async {
      expect(
        await repoWith('a1b2c3d4\u001fa1b2c3\u001fAlice\u001f2 days ago').log(workPath),
        isEmpty,
      );
    });
  });

  // ── commitFiles():diff-tree --name-status 解析 ─────────────

  group('commitFiles', () {
    test('解析 name-status 四行', () async {
      final files = await repoWith(
        'M\tapp/src/Main.kt\n'
        'A\tapp/src/New.kt\n'
        'D\tapp/src/Old.kt\n'
        'A\t中文/文件.txt',
      ).commitFiles(workPath, 'a1b2c3d4');
      expect(files.map((f) => f.path), [
        'app/src/Main.kt',
        'app/src/New.kt',
        'app/src/Old.kt',
        '中文/文件.txt',
      ]);
      expect(files.map((f) => f.statusCode), ['M', 'A', 'D', 'A']);
      expect(files.every((f) => !f.staged), isTrue);
    });

    test('带引号路径会被还原', () async {
      final files = await repoWith('M\t"a b.txt"').commitFiles(workPath, 'a1b2c3d4');
      expect(files.single.path, 'a b.txt');
    });

    test('无 tab 的行跳过,返回空', () async {
      final files = await repoWith(
        "fatal: ambiguous argument 'x': unknown revision or path not in the working tree.\n",
      ).commitFiles(workPath, 'badhash');
      expect(files, isEmpty);
    });
  });

  // ── untrackedFilesIn():ls-files --others 解析 ──────────────

  group('untrackedFilesIn', () {
    test('按行解析并跳过空行', () async {
      final files = await repoWith(
        'newDir/1.txt\nnewDir/2.txt\n中文/新文件.txt\n\n',
      ).untrackedFilesIn(workPath, 'newDir');
      expect(files, ['newDir/1.txt', 'newDir/2.txt', '中文/新文件.txt']);
    });

    test('空输出或 fatal 输出返回空', () async {
      expect(await repoWith('').untrackedFilesIn(workPath, 'dir'), isEmpty);
      expect(
        await repoWith('fatal: not a git repository').untrackedFilesIn(workPath, 'dir'),
        isEmpty,
      );
    });
  });

  // ── graph():提交图与分页 ──────────────────────────────────

  group('graph', () {
    test('空输出返回空图', () async {
      final graph = await repoWith('').graph(workPath);
      expect(graph.commits, isEmpty);
      expect(graph.hasMore, isFalse);
    });

    test('解析提交并保留 refs 标注', () async {
      final graph = await repoWith(
        'h1\u001fh1short\u001fAlice\u001fnow\u001ffirst\u001f\u001f',
      ).graph(workPath, refs: {
        'h1': [
          const GitGraphRef(name: 'main', isBranch: true, isCurrent: true, isRemote: false),
        ],
      });
      expect(graph.commits, hasLength(1));
      expect(graph.commits.first.message, 'first');
      expect(graph.refs['h1']!.single.name, 'main');
    });

    test('满批时 hasMore 为真,不足一批时为假', () async {
      final full = List.generate(
        3,
        (i) => 'h$i\u001fh${i}s\u001fA\u001fnow\u001fmsg$i\u001f\u001f',
      ).join('\n');
      final fullGraph = await repoWith(full).graph(workPath, limit: 3);
      expect(fullGraph.hasMore, isTrue);

      final partialGraph = await repoWith(full).graph(workPath, limit: 10);
      expect(partialGraph.hasMore, isFalse);
    });
  });

  // ── 命令拼装:路径与参数的 shell 转义 ──────────────────────

  group('命令拼装', () {
    test('参数按单引号包裹,内部单引号写成转义形式', () {
      expect(GitRunner.quote('simple'), "'simple'");
      expect(GitRunner.quote("a'b"), r"'a'\''b'");
      expect(GitRunner.quote('中文 路径'), "'中文 路径'");
    });

    test('统一带 core.quotepath=false', () {
      final runner = GitRunner(() async => _FakeEngine(''));
      expect(
        runner.buildCommand(['status', '--porcelain=v1']),
        "'git' '-c' 'core.quotepath=false' 'status' '--porcelain=v1'",
      );
    });

    test('非零退出码抛 GitException 且取 fatal 行', () async {
      final runner = GitRunner(() async => _FakeEngine(
            'some noise\nfatal: not a git repository\nmore noise',
            exitCode: 128,
          ));
      await expectLater(
        runner.checked(workPath, ['status']),
        throwsA(isA<GitException>().having(
          (e) => e.message,
          'message',
          'fatal: not a git repository',
        )),
      );
    });
  });
}