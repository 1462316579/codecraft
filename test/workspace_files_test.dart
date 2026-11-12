import 'dart:convert';
import 'dart:io';

import 'package:codecraft/agent/tools/explorer_tools.dart';
import 'package:codecraft/agent/tools/file_tools.dart';
import 'package:codecraft/agent/tools/tool.dart';
import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/data/codespaces_engine.dart';
import 'package:codecraft/data/git/container_git.dart';
import 'package:codecraft/data/git/git_runner.dart';
import 'package:codecraft/data/container/command_engine.dart';
import 'package:codecraft/data/workspace_files.dart';
import 'package:flutter_test/flutter_test.dart';

/// 用「本机临时目录」冒充 codespace:把引擎收到的命令真正交给本机 sh 执行,
/// 并把输出按容器引擎的 40K 限幅截断(head 20000 + tail 20000)。
///
/// 这样分块读取、base64 编解码、find/stat 解析这些逻辑都被真实执行到;
/// 若分块大小写错导致被限幅,解码会失败,测试即会暴露。
class _FakeRemoteEngine extends CommandEngine {
  _FakeRemoteEngine(this.pwd, {this.binDir});

  /// 存放假 gh 的目录(加入 PATH),让 `gh codespace ssh` 转发能落到本机 sh。
  final String? binDir;

  /// 远端工作目录(即 fake codespace 的默认 cwd)。
  final String pwd;

  final List<String> scripts = [];

  /// 与 LinuxContainerEngine 的 BoundedOutput 保持一致的限幅。
  static const int _headLimit = 20000;
  static const int _tailLimit = 20000;

  /// 仅用于识别简单单引号包裹的整条命令;多段引号的命令原样返回以避免破坏。
  static String _unquoteSimple(String command) {
    if (!command.startsWith("'")) return command;
    // 只有「整个字符串是一个单引号 token」时才剥壳。
    if (command.indexOf("'", 1) == command.length - 1) {
      return command.substring(1, command.length - 1);
    }
    return command;
  }

  String _cap(String text) {
    if (text.length <= _headLimit + _tailLimit) return text;
    final dropped = text.length - _headLimit - _tailLimit;
    return '${text.substring(0, _headLimit)}\n…(省略 $dropped 字符)…\n'
        '${text.substring(text.length - _tailLimit)}';
  }

  /// 远端探测 pwd:兼容旧的裸 `pwd`与新的 gh 转发形式。
  bool _isPwdProbe(String script) {
    if (script.trim() == 'pwd') return true;
    if (script.contains('codespace ssh') &&
        (script.contains("-- sh -c 'pwd'") || script.contains('-- sh -c pwd'))) {
      return true;
    }
    return false;
  }

  /// 从 gh 转发命令里取出被单引号包着的远端 payload(最后一层 sh -c '...')。
  String? _extractRemotePayload(String script) {
    // 形如: gh codespace ssh -c 'cs' -- sh -c 'payload' 2>&1
    final marker = "-- sh -c '";
    final start = script.lastIndexOf(marker);
    if (start < 0) return null;
    var payload = script.substring(start + marker.length);
    // 尾部可能有 ' 2>&1 或 '。剩下未配对引号时，把最后一个 ' 后面的都当后缀剥掉。
    final end = payload.lastIndexOf("'");
    if (end >= 0) payload = payload.substring(0, end);
    // payload 内部的引号以 '\'' 形式转义(与真实 ssh 的单引号传递一致),
    // 还原成字面量后交给本机 sh,否则含路径引号的命令(如 [ -e '...' ])会被解析坏。
    return payload.replaceAll("'\\''", "'");
  }

  @override
  Future<CommandResult> runCommandSync(
    String command, {
    String? workdir,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    final script = _unquoteSimple(command);
    scripts.add(script);
    if (_isPwdProbe(script) || _isPwdProbe(command)) {
      return CommandResult(output: '$pwd\n', exitCode: 0);
    }
    // gh 转发的远端命令:取出 payload,把它当成在 codespace(cwd=远端目录)里执行。
    // 探测链(echo 1/git rev-parse/echo $CODESPACE_REPO_ROOT/pwd)与真实远端命令
    // (printf <b64> | base64 -d | sh)都在这条路径上,统一落到本机 sh + 锁定 cwd。
    final payload = _extractRemotePayload(script) ?? _extractRemotePayload(command);
    if (payload != null) {
      // 远端 cwd 里的相对命令(如 git rev-parse)不能跑到本机仓库里去;
      // 注入 CODESPACE_REPO_ROOT 模拟真实 Codespace 的环境变量(探测链优先级 2)。
      final env = <String, String>{
        if (binDir != null) 'PATH': '$binDir:${Platform.environment['PATH'] ?? ''}',
        'CODESPACE_REPO_ROOT': pwd,
      };
      final result = await Process.run(
        'sh',
        ['-c', payload],
        environment: env,
        workingDirectory: pwd,
      );
      return CommandResult(
        output: _cap(result.stdout.toString()),
        exitCode: result.exitCode,
      );
    }
    final result = await Process.run(
      'sh',
      ['-c', script],
      environment: binDir == null
          ? null
          : {'PATH': '$binDir:${Platform.environment['PATH'] ?? ''}'},
    );
    return CommandResult(
      output: _cap(result.stdout.toString()),
      exitCode: result.exitCode,
    );
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

void main() {
  late Directory remote;
  late Directory local;
  late _FakeRemoteEngine transport;
  late CodespacesEngine engine;
  late RemoteWorkspaceFiles files;

  late Directory bin;

  setUp(() {
    remote = Directory.systemTemp.createTempSync('cs-remote');
    local = Directory.systemTemp.createTempSync('cs-local');
    // 假 gh:跳过 `codespace ssh -c NAME --`,其余参数在本机原样执行。
    bin = Directory.systemTemp.createTempSync('cs-bin');
    final gh = File('${bin.path}/gh')
      ..writeAsStringSync('#!/bin/sh\n'
          'while [ \$# -gt 0 ] && [ "\$1" != "--" ]; do shift; done\n'
          '[ "\$1" = "--" ] && shift\n'
          'exec "\$@"\n');
    Process.runSync('chmod', ['755', gh.path]);
    transport = _FakeRemoteEngine(remote.path, binDir: bin.path);
    engine = CodespacesEngine(
      transport: transport,
      codespace: 'cs',
      localRoot: local.path,
      // 测试环境用假 gh(在 PATH 中),避免依赖真实的 gh-codespaces.sh。
      ghHelper: 'gh',
    );
    files = RemoteWorkspaceFiles(engine: engine);
  });

  tearDown(() {
    remote.deleteSync(recursive: true);
    local.deleteSync(recursive: true);
    bin.deleteSync(recursive: true);
  });

  String remoteFile(String relative) => '${remote.path}/$relative';
  String localFile(String relative) => '${local.path}/$relative';

  group('路径映射', () {
    test('工作区根换成远端根,其余结构不变', () async {
      expect(await files.remotePath(local.path), remote.path);
      expect(
        await files.remotePath(localFile('app/src/main.dart')),
        remoteFile('app/src/main.dart'),
      );
    });

    test('远端根只探测一次(探测链不重复执行)', () async {
      await files.remotePath(localFile('a.txt'));
      await files.remotePath(localFile('b.txt'));
      await files.remotePath(localFile('c.txt'));
      // 探测链以 gh 转发(echo __codecraft_ok__/git rev-parse/echo $CODESPACE_REPO_ROOT)的形式发出;
      // 首次解析后缓存,后续映射只发 [ -e ... ] 存在性探测,不再重跑探测链。
      final probes = transport.scripts
          .where((s) => s.contains('echo __codecraft_ok__') || s.contains('git rev-parse'))
          .length;
      expect(probes, 1);
    });

    test('工作区外的路径直接拒绝', () async {
      expect(
        () => files.remotePath('/etc/passwd'),
        throwsA(isA<WorkspaceFileException>()),
      );
    });
  });

  group('workdir 映射与 git 转发', () {
    test('workdir 按工作区根映射到远端,并真的 cd 过去', () async {
      Directory(remoteFile('sub')).createSync();
      final result = await engine.runCommandSync('pwd', workdir: localFile('sub'));
      expect(result.output.trim(), remoteFile('sub'));
    });

    test('workdir 就是工作区根时映射到远端工作区根', () async {
      final result = await engine.runCommandSync('pwd', workdir: local.path);
      expect(result.output.trim(), remote.path);
    });

    test('工作区外的 workdir 直接报错,不默默跑在默认目录', () async {
      expect(
        () => engine.runCommandSync('pwd', workdir: '/etc'),
        throwsA(isA<StateError>()),
      );
    });

    test('git 命令在 codespace 的仓库里真的执行(ContainerGit 端到端)', () async {
      // 远端放一个真 git 仓库(含一次提交),本地路径映射过去后由 ContainerGit 走 gh 转发执行。
      final repo = Directory(remoteFile('repo'))..createSync();
      Process.runSync('git', ['init', '-q', '-b', 'main', repo.path]);
      File('${repo.path}/a.txt').writeAsStringSync('hello\n');
      Process.runSync('git', ['-C', repo.path, 'add', 'a.txt']);
      Process.runSync('git', [
        '-C', repo.path,
        '-c', 'user.name=T', '-c', 'user.email=t@example.com',
        'commit', '-q', '-m', 'init',
      ]);

      final cgit = ContainerGit(GitRunner(() async => engine));
      expect(await cgit.isRepository(localFile('repo')), isTrue);

      final status = await cgit.status(localFile('repo'));
      expect(status.branch, 'main');
      expect(status.staged, isEmpty);
      expect(status.unstaged, isEmpty);

      File('${repo.path}/new.txt').writeAsStringSync('x\n');
      final after = await cgit.status(localFile('repo'));
      expect(after.untracked, contains('new.txt'));

      await cgit.setUserIdentity(localFile('repo'), 'Tester', 't@example.com');
      expect(await cgit.getUserName(localFile('repo')), 'Tester');

      final refs = await cgit.loadAllRefs(localFile('repo'));
      expect(refs.branches.map((b) => b.name), contains('main'));
    });

    test('空仓库的分支名沿用上游行为(显示 git 原始 header 剩余部分)', () async {
      final repo = Directory(remoteFile('empty-repo'))..createSync();
      Process.runSync('git', ['init', '-q', '-b', 'main', repo.path]);
      final cgit = ContainerGit(GitRunner(() async => engine));
      // git status --porcelain=v1 -b 在无提交时输出 `## No commits yet on main`,
      // 上游解析同样取冒号后的整段,故此处与上游保持一致而不是自作主张改写。
      expect((await cgit.status(localFile('empty-repo'))).branch, 'No commits yet on main');
    });

    test('非仓库目录判定为 false(git 的报错经由转发原样回来)', () async {
      Directory(remoteFile('plain')).createSync();
      final cgit = ContainerGit(GitRunner(() async => engine));
      expect(await cgit.isRepository(localFile('plain')), isFalse);
    });
  });

  group('远端读', () {
    test('小文件原样读回(含中文与空行)', () async {
      File(remoteFile('a.txt')).writeAsStringSync('第一行\n\n第三行 ok');
      expect(await files.readText(localFile('a.txt')), '第一行\n\n第三行 ok');
    });

    test('超过单块上限的文件分块读回,内容完全一致', () async {
      // 每块 16000 字节,这里远超两块——单块读会被 40K 限幅截断。
      final content = List.generate(4000, (i) => 'line-${i.toString().padLeft(5, '0')}-中文填充')
          .join('\n');
      expect(utf8.encode(content).length, greaterThan(RemoteWorkspaceFiles.maxChunkBytes * 2));
      File(remoteFile('big.txt')).writeAsBytesSync(utf8.encode(content));

      final read = await files.readText(localFile('big.txt'));
      expect(read, content);
    });

    test('空文件读回空串', () async {
      File(remoteFile('empty.txt')).writeAsStringSync('');
      expect(await files.readText(localFile('empty.txt')), '');
    });

    test('超过 512KB 直接报「文件过大」,不做几十次往返', () async {
      File(remoteFile('huge.bin'))
          .writeAsBytesSync(List.filled(RemoteWorkspaceFiles.maxFileBytes + 1, 0x61));
      expect(
        () => files.readText(localFile('huge.bin')),
        throwsA(isA<WorkspaceFileException>()),
      );
    });

    test('文件不存在时报错', () async {
      expect(
        () => files.readText(localFile('nope.txt')),
        throwsA(isA<WorkspaceFileException>()),
      );
    });
  });

  group('远端写', () {
    test('自动创建父目录,内容逐字节一致', () async {
      const content = 'a\n中文内容\n\t缩进\n无尾换行';
      await files.writeText(localFile('deep/nested/x.txt'), content);
      expect(File(remoteFile('deep/nested/x.txt')).readAsStringSync(), content);
    });

    test('大内容分块写入,既不截断也不重复', () async {
      final content = List.generate(3000, (i) => 'row-$i-填充填充填充').join('\n');
      expect(utf8.encode(content).length, greaterThan(RemoteWorkspaceFiles.maxChunkBytes * 2));
      await files.writeText(localFile('out.txt'), content);
      expect(File(remoteFile('out.txt')).readAsStringSync(), content);
    });

    test('写空内容得到空文件', () async {
      File(remoteFile('z.txt')).writeAsStringSync('旧内容');
      await files.writeText(localFile('z.txt'), '');
      expect(File(remoteFile('z.txt')).readAsStringSync(), '');
    });

    test('读改写往返后与预期一致(editFile 的基础)', () async {
      await files.writeText(localFile('r.txt'), 'abc');
      final content = await files.readText(localFile('r.txt'));
      await files.writeText(localFile('r.txt'), content.replaceFirst('b', 'B'));
      expect(File(remoteFile('r.txt')).readAsStringSync(), 'aBc');
    });
  });

  group('远端存在性与列目录', () {
    test('exists / isDirectory 区分文件与目录', () async {
      Directory(remoteFile('dir')).createSync();
      File(remoteFile('dir/f.txt')).writeAsStringSync('x');
      expect(await files.exists(localFile('dir/f.txt')), isTrue);
      expect(await files.exists(localFile('dir/missing')), isFalse);
      expect(await files.isDirectory(localFile('dir')), isTrue);
      expect(await files.isDirectory(localFile('dir/f.txt')), isFalse);
    });

    test('列目录带出类型、大小与时间,文件名含空格也能解析', () async {
      Directory(remoteFile('sub')).createSync();
      File(remoteFile('a b.txt')).writeAsStringSync('12345');
      final entries = await files.listDir(local.path);
      final byName = {for (final e in entries) e.name: e};

      expect(byName.keys, containsAll(['a b.txt', 'sub']));
      expect(byName['a b.txt']!.isDirectory, isFalse);
      expect(byName['a b.txt']!.size, 5);
      expect(byName['sub']!.isDirectory, isTrue);
      expect(byName['a b.txt']!.modified.year, greaterThan(2000));
    });

    test('空目录返回空列表', () async {
      expect(await files.listDir(local.path), isEmpty);
    });
  });

  group('文件工具走远端后端', () {
    late Workspace workspace;
    late ReadFileTool readTool;
    late WriteFileTool writeTool;
    late EditFileTool editTool;
    late ListTool listTool;

    setUp(() {
      workspace = Workspace(local.path);
      Future<WorkspaceFiles> supplier() async => files;
      readTool = ReadFileTool(workspace, supplier);
      writeTool = WriteFileTool(workspace, supplier);
      editTool = EditFileTool(workspace, supplier);
      listTool = ListTool(workspace, supplier);
    });

    test('readFile 分段读数与总行数正确', () async {
      Directory(remoteFile('src')).createSync();
      File(remoteFile('src/main.dart')).writeAsStringSync(
        List.generate(120, (i) => 'line $i').join('\n'),
      );
      final result = await readTool.execute({
        'path': '~/workspace/src/main.dart',
        'start_line': 5,
        'end_line': 7,
      });
      final data = (result as ToolSuccess).data as Map;
      expect(data['content'], 'line 4\nline 5\nline 6');
      expect(data['start_line'], 5);
      expect(data['end_line'], 7);
      expect(data['total_lines'], 120);
      expect(data['path'], '~/workspace/src/main.dart');
    });

    test('writeFile 写远端并报告创建状态', () async {
      final created = await writeTool.execute({
        'path': '~/workspace/new/created.txt',
        'content': 'hello 远端',
      });
      expect(((created as ToolSuccess).data as Map)['created'], isTrue);
      expect(File(remoteFile('new/created.txt')).readAsStringSync(), 'hello 远端');

      final again = await writeTool.execute({
        'path': '~/workspace/new/created.txt',
        'content': 'hello 远端',
      });
      expect(((again as ToolSuccess).data as Map)['created'], isFalse);
    });

    test('editFile 在远端整批生效', () async {
      File(remoteFile('e.txt')).writeAsStringSync('alpha\nbeta\ngamma\n');
      final result = await editTool.execute({
        'path': '~/workspace/e.txt',
        'edits': [
          {'old_string': 'alpha', 'new_string': 'ALPHA'},
          {'old_string': 'gamma', 'new_string': 'GAMMA'},
        ],
      });
      expect(((result as ToolSuccess).data as Map)['replacements'], 2);
      expect(File(remoteFile('e.txt')).readAsStringSync(), 'ALPHA\nbeta\nGAMMA\n');
    });

    test('editFile 匹配失败时不改动远端文件', () async {
      File(remoteFile('e2.txt')).writeAsStringSync('keep\n');
      final result = await editTool.execute({
        'path': '~/workspace/e2.txt',
        'edits': [
          {'old_string': 'not-there', 'new_string': 'x'},
        ],
      });
      expect(result, isA<ToolError>());
      expect((result as ToolError).code, 'NO_MATCH');
      expect(File(remoteFile('e2.txt')).readAsStringSync(), 'keep\n');
    });

    test('list 工具经远端后端列出目录', () async {
      Directory(remoteFile('app')).createSync();
      File(remoteFile('app/main.dart')).writeAsStringSync('void main() {}');
      final result = await listTool.execute({'args': '-la ~/workspace/app'});
      final output = ((result as ToolSuccess).data as Map)['output'] as String;
      expect(output, contains('main.dart'));
      expect(output, contains('d'));
    });

    test('search 走远端 grep:带行号、路径映射回 ~/workspace 写法', () async {
      Directory(remoteFile('lib')).createSync();
      File(remoteFile('lib/a.dart'))
          .writeAsStringSync('void main() {}\n// 其他\nvoid main2() {}');
      final searchTool = SearchTool(workspace, () async => files);
      final result = await searchTool.execute({'args': '-n "void main" ~/workspace'}) as ToolSuccess;
      final output = (result.data as Map)['output'] as String;
      expect(output, contains('~/workspace/lib/a.dart:1: void main() {}'));
      expect(output, contains('~/workspace/lib/a.dart:3: void main2() {}'));
      expect(output, isNot(contains('其他')));
    });

    test('search -i 忽略大小写,-F 按纯文本匹配', () async {
      File(remoteFile('c.txt')).writeAsStringSync('Needle here\nother\n');
      final searchTool = SearchTool(workspace, () async => files);

      final insensitive =
          await searchTool.execute({'args': '-i -n "needle" ~/workspace'}) as ToolSuccess;
      expect((insensitive.data as Map)['matches'], 1);

      final exact = await searchTool.execute({'args': '-n "needle" ~/workspace'}) as ToolSuccess;
      expect((exact.data as Map)['matches'], 0);

      File(remoteFile('p.txt')).writeAsStringSync('a.b\na_b\n');
      final fixed = await searchTool.execute({'args': '-F -n "a.b" ~/workspace'}) as ToolSuccess;
      expect((fixed.data as Map)['output'] as String, contains('~/workspace/p.txt:1: a.b'));
      expect((fixed.data as Map)['output'] as String, isNot(contains('a_b')));
    });

    test('search 跳过隐藏项与 .git / node_modules / build', () async {
      Directory(remoteFile('.git')).createSync();
      File(remoteFile('.git/config')).writeAsStringSync('needle\n');
      Directory(remoteFile('node_modules')).createSync();
      File(remoteFile('node_modules/x.js')).writeAsStringSync('needle\n');
      Directory(remoteFile('build')).createSync();
      File(remoteFile('build/out.txt')).writeAsStringSync('needle\n');
      File(remoteFile('.hidden')).writeAsStringSync('needle\n');
      File(remoteFile('kept.txt')).writeAsStringSync('needle\n');

      final searchTool = SearchTool(workspace, () async => files);
      final result = await searchTool.execute({'args': '-n "needle" ~/workspace'}) as ToolSuccess;
      final output = (result.data as Map)['output'] as String;
      expect(output, contains('kept.txt'));
      expect(output, isNot(contains('.git/config')));
      expect(output, isNot(contains('node_modules')));
      expect(output, isNot(contains('build/out.txt')));
      expect(output, isNot(contains('.hidden')));
    });

    test('search 命中数达到限值即标记截断', () async {
      File(remoteFile('many.txt'))
          .writeAsStringSync(List.generate(30, (i) => 'hit $i').join('\n'));
      final searchTool = SearchTool(workspace, () async => files);
      final result =
          await searchTool.execute({'args': '-n "hit" ~/workspace | head -n 5'}) as ToolSuccess;
      final data = result.data as Map;
      expect(data['matches'], 5);
      expect(data['truncated'], isTrue);
    });

    test('search 路径不存在时报 NOT_FOUND', () async {
      final searchTool = SearchTool(workspace, () async => files);
      final result = await searchTool.execute({'args': '-n "x" ~/workspace/no-such-dir'});
      expect(result, isA<ToolError>());
      expect((result as ToolError).code, 'NOT_FOUND');
    });
  });

  group('本地搜索', () {
    test('逐行匹配并跳过隐藏项与依赖/构建目录', () async {
      final root = Directory.systemTemp.createTempSync('local-search');
      addTearDown(() => root.deleteSync(recursive: true));
      final backend = LocalWorkspaceFiles(root: root.path);

      File('${root.path}/kept.txt').writeAsStringSync('needle\n');
      File('${root.path}/.hidden').writeAsStringSync('needle\n');
      Directory('${root.path}/node_modules').createSync();
      File('${root.path}/node_modules/a.js').writeAsStringSync('needle\n');

      final hits = await backend.searchLines(root.path, 'needle', limit: 50);
      expect(hits.map((h) => h.path), ['${root.path}/kept.txt']);
      expect(hits.single.line, 1);
      expect(hits.single.text, 'needle');
    });

    test('工作区自身的路径里有 build 段时不至于把整个搜索跳过', () async {
      // 排除规则按「相对工作区的路径」判断,否则路径里出现 build 会全被跳过。
      final outer = Directory.systemTemp.createTempSync('local-build');
      addTearDown(() => outer.deleteSync(recursive: true));
      final root = Directory('${outer.path}/build')..createSync();
      File('${root.path}/k.txt').writeAsStringSync('needle\n');

      final withRoot = await LocalWorkspaceFiles(root: root.path)
          .searchLines(root.path, 'needle', limit: 50);
      expect(withRoot, hasLength(1));

      final withoutRoot = await const LocalWorkspaceFiles()
          .searchLines(root.path, 'needle', limit: 50);
      expect(withoutRoot, isEmpty);
    });

    test('大小写与固定串匹配', () async {
      final root = Directory.systemTemp.createTempSync('local-case');
      addTearDown(() => root.deleteSync(recursive: true));
      File('${root.path}/c.txt').writeAsStringSync('Needle\na.b\n');
      final backend = LocalWorkspaceFiles(root: root.path);

      expect(await backend.searchLines(root.path, 'needle', limit: 10), isEmpty);
      expect(
        await backend.searchLines(root.path, 'needle', ignoreCase: true, limit: 10),
        hasLength(1),
      );
      expect(await backend.searchLines(root.path, 'a.b', fixed: true, limit: 10), hasLength(1));
    });
  });

  group('本地后端', () {
    test('与远端后端语义一致(读/写/列目录)', () async {
      const localBackend = LocalWorkspaceFiles();
      final dir = Directory.systemTemp.createTempSync('local-fs');
      addTearDown(() => dir.deleteSync(recursive: true));

      await localBackend.writeText('${dir.path}/a/b.txt', '内容\n');
      expect(await localBackend.exists('${dir.path}/a/b.txt'), isTrue);
      expect(await localBackend.exists('${dir.path}/a/missing'), isFalse);
      expect(await localBackend.isDirectory('${dir.path}/a'), isTrue);
      expect(await localBackend.readText('${dir.path}/a/b.txt'), '内容\n');
      final entries = await localBackend.listDir(dir.path);
      expect(entries.map((e) => e.name), ['a']);
      expect(entries.single.isDirectory, isTrue);
    });

    test('sizeOf 返回字节数,文件不存在时抛异常', () async {
      const backend = LocalWorkspaceFiles();
      final dir = Directory.systemTemp.createTempSync('local-size');
      addTearDown(() => dir.deleteSync(recursive: true));

      await backend.writeText('${dir.path}/a.txt', '天玄大陆');
      // 中文按 UTF-8 算 4 个字符 12 字节。
      expect(await backend.sizeOf('${dir.path}/a.txt'), 12);
      await expectLater(
        backend.sizeOf('${dir.path}/missing.txt'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('工作区之外的绝对路径也能读写(写作项目的宿主目录)', () async {
      // 写作项目的工作区是手机上的普通目录,不经容器:编辑器与工具都直接走
      // 宿主 File API,路径不在任何「沙盒根」下也得能读写。
      const backend = LocalWorkspaceFiles();
      final dir = Directory.systemTemp.createTempSync('outside-workspace');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}/1.txt';

      await backend.writeText(path, '第一段\n');
      expect(await backend.readText(path), '第一段\n');
      expect(await backend.sizeOf(path), 10);
      expect(looksBinary(await backend.readBytes(path)), isFalse);
    });
  });
}