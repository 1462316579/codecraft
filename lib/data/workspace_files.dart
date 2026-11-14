import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../app/current_project.dart';
import '../agent/models/project.dart';
import 'codespaces.dart';
import 'codespaces_controller.dart';
import 'credentials.dart';
import 'codespaces_engine.dart';
import 'container/command_engine.dart';
import 'execution_target.dart';
import 'github_contents_client.dart';
import 'github_contents_workspace_files.dart';
import 'git/git_runner.dart';
import 'workspaces.dart';

/// 目录项（[WorkspaceFiles.listDir] 的结果，字段与宿主 `FileStat` 对齐）。
class DirEntry {
  const DirEntry({
    required this.name,
    required this.isDirectory,
    required this.size,
    required this.modified,
  });

  final String name;
  final bool isDirectory;
  final int size;
  final DateTime modified;
}

/// 搜索命中（[WorkspaceFiles.searchLines] 的结果）。[path] 用调用方的路径坐标系。
class SearchHit {
  const SearchHit({required this.path, required this.line, required this.text});

  final String path;

  /// 行号（从 1 计）。
  final int line;

  final String text;
}

/// 工作区文件操作失败（文件不存在 / 过大 / 远端命令失败）。
class WorkspaceFileException implements Exception {
  const WorkspaceFileException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 工作区文件读写：本地容器里工作区是 bind 挂载，宿主路径与容器内路径一致，直接用 `File` 最快；
/// Codespace 目标下工作区在远端（通常在 `/workspaces/<repo>`），必须经执行引擎读写。
abstract class WorkspaceFiles {
  Future<bool> exists(String path);

  Future<bool> isDirectory(String path);

  /// 文件字节数；文件不存在或读不到时抛异常。
  Future<int> sizeOf(String path);

  /// 写原始字节（逆向工具的十六进制与 dex 回写用）。
  Future<void> writeBytes(String path, Uint8List bytes);

  /// 读全文（文本）；超出实现上限时抛 [WorkspaceFileException]。
  Future<String> readText(String path);

  /// 读原始字节；用于二进制文件（APK 里的 `.dex`/`.so` 等）。
  Future<Uint8List> readBytes(String path);

  Future<void> writeText(String path, String content);

  Future<List<DirEntry>> listDir(String path);

  /// 建目录（已存在时视为成功）。
  Future<void> createDir(String path);

  /// 重命名/移动；目标已存在时由实现决定行为（本地为覆盖）。
  Future<void> rename(String from, String to);

  /// 删除文件或目录（目录递归删除）。
  Future<void> delete(String path, {bool recursive = false});

  /// 复制文件或目录到 [to]（目录递归复制）。
  ///
  /// [overwrite] 为假且目标已存在时抛 [WorkspaceFileException]；
  /// 为真时先删除目标再复制（避免留下旧文件混合）。
  Future<void> copy(String from, String to, {bool overwrite = false});

  /// 移动文件或目录到 [to]；语义与 [copy] 的 [overwrite] 相同,成功后源不再存在。
  Future<void> move(String from, String to, {bool overwrite = false});

  /// 把压缩包 [archivePath] 解到目录 [destDir](不存在则创建),返回写出的文件数。
  ///
  /// 只接受 [supportsArchiveExtraction] 认得的后缀;格式不支持或内容损坏时
  /// 抛 [WorkspaceFileException]。目标目录已存在时由调用方先清空。
  Future<int> extractArchive(String archivePath, String destDir);

  /// 在 [root]（文件或目录）下按行搜索 [pattern]。
  ///
  /// [ignoreCase] 忽略大小写；[fixed] 把 [pattern] 当纯文本（不做正则解释）；
  /// [limit] 为命中上限，达到即停止并交由调用方标记截断。
  Future<List<SearchHit>> searchLines(
    String root,
    String pattern, {
    bool ignoreCase = false,
    bool fixed = false,
    required int limit,
  });
}

/// 宿主文件系统实现（本地容器目标）。
class LocalWorkspaceFiles implements WorkspaceFiles {
  const LocalWorkspaceFiles({this.root});

  /// 二进制读取上限：APK 里的 `.so` 动辄几十 MB，全读进内存没有意义，
  /// 提取字符串时只需要前一段。
  static const int maxBytes = 32 * 1024 * 1024;

  /// 工作区根：搜索时的排除规则按「相对工作区的路径」判断，
  /// 否则工作区自身的路径里出现 `build` 之类的段会让整个搜索被跳过。
  final String? root;

  @override
  Future<bool> exists(String path) async {
    // File.exists() 对已存在的目录返回 false,必须两种都查:
    // 否则解压覆盖确认、新建/重命名/粘贴查重对目录全部失效。
    return await File(path).exists() || await Directory(path).exists();
  }

  @override
  Future<bool> isDirectory(String path) => Directory(path).exists();

  @override
  Future<int> sizeOf(String path) async {
    if (!(await File(path).exists()) && !(await Directory(path).exists())) {
      throw WorkspaceFileException('文件不存在:$path');
    }
    return File(path).length();
  }

  @override
  Future<String> readText(String path) async {
    if (!(await File(path).exists()) && !(await Directory(path).exists())) {
      throw WorkspaceFileException('文件不存在:$path');
    }
    return File(path).readAsString();
  }

  @override
  Future<Uint8List> readBytes(String path) async {
    final file = File(path);
    if (!(await file.exists()) && !(await Directory(file.path).exists())) {
      throw WorkspaceFileException('文件不存在:$path');
    }
    if (await file.length() > maxBytes) {
      throw WorkspaceFileException('文件过大（上限 ${maxBytes ~/ 1024} KB）');
    }
    return file.readAsBytes();
  }

  @override
  Future<void> writeText(String path, String content) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  @override
  Future<void> writeBytes(String path, Uint8List bytes) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  @override
  Future<List<DirEntry>> listDir(String path) async {
    final entries = <DirEntry>[];
    await for (final entity in Directory(path).list(followLinks: false)) {
      final stat = await entity.stat();
      entries.add(DirEntry(
        name: p.basename(entity.path),
        isDirectory: stat.type == FileSystemEntityType.directory,
        size: stat.size,
        modified: stat.modified,
      ));
    }
    return entries;
  }

  @override
  Future<void> createDir(String path) => Directory(path).create(recursive: true);

  @override
  Future<void> rename(String from, String to) async {
    final source = FileSystemEntity.typeSync(from);
    if (source == FileSystemEntityType.directory) {
      await Directory(from).rename(to);
    } else {
      await File(from).rename(to);
    }
  }

  @override
  Future<void> delete(String path, {bool recursive = false}) async {
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: recursive);
    } else if (type != FileSystemEntityType.notFound) {
      await File(path).delete();
    }
  }

  @override
  Future<void> copy(String from, String to, {bool overwrite = false}) async {
    final type = FileSystemEntity.typeSync(from);
    if (type == FileSystemEntityType.notFound) {
      throw const WorkspaceFileException('源文件不存在');
    }
    if (FileSystemEntity.typeSync(to) != FileSystemEntityType.notFound) {
      if (!overwrite) throw const WorkspaceFileException('目标已存在同名项');
      await delete(to, recursive: true);
    }
    if (type == FileSystemEntityType.directory) {
      await _copyDirectory(Directory(from), Directory(to));
    } else {
      await Directory(p.dirname(to)).create(recursive: true);
      await File(from).copy(to);
    }
  }

  @override
  Future<void> move(String from, String to, {bool overwrite = false}) async {
    if (FileSystemEntity.typeSync(to) != FileSystemEntityType.notFound) {
      if (!overwrite) throw const WorkspaceFileException('目标已存在同名项');
      await delete(to, recursive: true);
    }
    try {
      await rename(from, to);
    } on FileSystemException {
      // 跳文件系统/跨设备时 rename 会失败：退化为复制后删源。
      await copy(from, to, overwrite: true);
      await delete(from, recursive: true);
    }
  }

  @override
  Future<int> extractArchive(String archivePath, String destDir) async {
    final suffix = _archiveSuffix(archivePath);
    if (suffix == null) throw const WorkspaceFileException('不支持的压缩格式');
    if (!await File(archivePath).exists()) {
      throw const WorkspaceFileException('压缩包不存在');
    }
    try {
      // gz/bz2/xz/zst 只压缩了单个文件、里面没有目录结构:解出来写成去掉后缀的
      // 同名文件(archive 的 extractFileToDisk 只认 tar 化的这类文件)。
      if (_singleStreamSuffixes.contains(suffix)) {
        final bytes = await File(archivePath).readAsBytes();
        await Directory(destDir).create(recursive: true);
        final target = File(p.join(destDir, archiveTargetName(p.basename(archivePath))));
        await target.writeAsBytes(_decodeSingleStream(suffix, bytes));
        return 1;
      }
      await extractFileToDisk(archivePath, destDir);
      var count = 0;
      await for (final entity in Directory(destDir).list(recursive: true)) {
        if (entity is File) count++;
      }
      return count;
    } catch (error) {
      throw WorkspaceFileException('解压失败:$error');
    }
  }

  /// 递归复制目录（含子目录与文件）。
  static Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entity in source.list(followLinks: false)) {
      final name = p.basename(entity.path);
      final destination = p.join(target.path, name);
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(destination));
      } else if (entity is File) {
        await entity.copy(destination);
      }
    }
  }

  @override
  Future<List<SearchHit>> searchLines(
    String root,
    String pattern, {
    bool ignoreCase = false,
    bool fixed = false,
    required int limit,
  }) async {
    if (pattern.isEmpty) return const [];
    final matcher = RegExp(
      fixed ? RegExp.escape(pattern) : pattern,
      caseSensitive: !ignoreCase,
    );
    final hits = <SearchHit>[];

    void scanFile(File file) {
      if (hits.length >= limit) return;
      List<String> lines;
      try {
        lines = const LineSplitter().convert(file.readAsStringSync());
      } catch (_) {
        // 二进制文件（APK 里的 .dex/.so）按可打印字符串匹配：
        // 逆向项目里要找的类名、URL、错误文案都在这些字符串里。
        try {
          if (file.lengthSync() > LocalWorkspaceFiles.maxBytes) return;
          lines = const LineSplitter()
              .convert(extractPrintableStrings(file.readAsBytesSync()));
        } catch (_) {
          return; // 真的读不了才跳过
        }
      }
      for (var i = 0; i < lines.length; i++) {
        if (hits.length >= limit) return;
        if (matcher.hasMatch(lines[i])) {
          hits.add(SearchHit(path: file.path, line: i + 1, text: lines[i]));
        }
      }
    }

    if (await File(root).exists()) {
      scanFile(File(root));
      return hits;
    }
    await for (final entity in Directory(root).list(recursive: true, followLinks: false)) {
      if (hits.length >= limit) break;
      if (entity is! File) continue;
      if (_shouldSkip(entity.path)) continue;
      scanFile(entity);
    }
    return hits;
  }

  /// 隐藏项与依赖/构建目录不搜（与远端 grep 的 --exclude* 规则保持一致）。
  bool _shouldSkip(String path) {
    final workspaceRoot = root;
    final relative = workspaceRoot == null ? path : p.relative(path, from: workspaceRoot);
    for (final segment in p.split(relative)) {
      if (segment.startsWith('.')) return true;
      if (segment == 'node_modules' || segment == 'build') return true;
    }
    return false;
  }
}

/// Codespace 实现：每次操作经 `gh codespace ssh` 在远端执行。
///
/// 传输一律走 base64：远端 shell 的行尾、编码、二进制内容都不会被中间几层转义破坏。
/// 受限于单次命令输出的限幅（40K 字符），读写都按 [maxChunkBytes] 分块，
/// 块大小取「base64 后仍远低于限幅」的值。
class RemoteWorkspaceFiles implements WorkspaceFiles {
  RemoteWorkspaceFiles({required this.engine});

  /// 同时承担「转发命令」与「本地/远端路径映射」的引擎。
  final CodespacesEngine engine;

  /// 单次命令传输的原始字节数：base64 后约 21KB，远低于命令输出的 40K 限幅。
  static const int maxChunkBytes = 16000;

  /// 可读文件的字节上限：再大就按「文件过大」报错，避免几十次往返。
  static const int maxFileBytes = 512 * 1024;

  @override
  Future<Uint8List> readBytes(String path) async {
    final remote = await remotePath(path);
    final quoted = GitRunner.quote(remote);
    final sizeResult = await _run('stat -c %s $quoted');
    if (sizeResult.exitCode != 0) {
      throw WorkspaceFileException('读取失败：${sizeResult.output.trim()}');
    }
    final size = int.tryParse(sizeResult.output.trim()) ?? 0;
    if (size > maxFileBytes) {
      throw const WorkspaceFileException('文件过大，Codespaces 目标下单次最多读取 512KB');
    }

    final bytes = <int>[];
    var offset = 0;
    while (offset < size) {
      final result = await _run(
        'dd if=$quoted bs=$maxChunkBytes skip=${offset ~/ maxChunkBytes} count=1 2>/dev/null '
        '| base64 | tr -d \"\\\\n\"',
      );
      if (result.exitCode != 0) {
        throw WorkspaceFileException('读取失败：${result.output.trim()}');
      }
      final encoded = result.output.trim();
      if (encoded.isEmpty) break;
      try {
        bytes.addAll(base64.decode(encoded));
      } catch (error) {
        throw WorkspaceFileException('内容解码失败：$error');
      }
      offset += maxChunkBytes;
    }
    return Uint8List.fromList(bytes);
  }

  @override
  Future<int> sizeOf(String path) async {
    final result = await _run('stat -c %s ${GitRunner.quote(await remotePath(path))}');
    if (result.exitCode != 0) {
      throw WorkspaceFileException('读取失败：${result.output.trim()}');
    }
    return int.tryParse(result.output.trim()) ?? 0;
  }

  @override
  Future<String> readText(String path) async => utf8.decode(await readBytes(path));

  Future<String> remotePath(String localPath) async {
    try {
      return await engine.remotePath(localPath);
    } on StateError catch (error) {
      throw WorkspaceFileException(error.message);
    }
  }

  Future<String> localPath(String remotePathValue) => engine.localPath(remotePathValue);

  Future<CommandResult> _run(String script, {Duration? timeout}) => engine.runCommandSync(
        script,
        timeout: timeout ?? const Duration(seconds: 120),
      );

  @override
  Future<bool> exists(String path) async {
    String remote;
    try {
      remote = await remotePath(path);
    } catch (_) {
      remote = await engine.remoteRoot();
    }
    final result = await _run('[ -e ${GitRunner.quote(remote)} ]',
        timeout: const Duration(seconds: 30));
    return result.exitCode == 0;
  }

  @override
  Future<bool> isDirectory(String path) async {
    String remote;
    try {
      remote = await remotePath(path);
    } catch (_) {
      remote = await engine.remoteRoot();
    }
    final result = await _run('[ -d ${GitRunner.quote(remote)} ]',
        timeout: const Duration(seconds: 30));
    return result.exitCode == 0;
  }

  @override
  Future<List<DirEntry>> listDir(String path) async {
    final remote = await remotePath(path);
    final quoted = GitRunner.quote(remote);
    // GNU find 的 -printf 直接给出类型/大小/修改时间/basename，一次往返拿到全部字段，
    // 比 ls 解析稳（文件名里的空格、特殊字符不会被打断）。
    final result = await _run(
      'find $quoted -mindepth 1 -maxdepth 1 -printf "%y|%s|%T@|%f\\n"',
      timeout: const Duration(seconds: 30),
    );
    if (result.exitCode != 0) {
      throw WorkspaceFileException('列出目录失败：${result.output.trim()}');
    }
    final entries = <DirEntry>[];
    for (final line in const LineSplitter().convert(result.output)) {
      if (line.isEmpty) continue;
      final parts = line.split('|');
      if (parts.length != 4) continue;
      final typeChar = parts[0];
      final size = int.tryParse(parts[1]) ?? 0;
      final modifiedEpoch = double.tryParse(parts[2]);
      final modified = modifiedEpoch != null
          ? DateTime.fromMillisecondsSinceEpoch((modifiedEpoch * 1000).round())
          : DateTime.now();
      entries.add(DirEntry(
        name: parts[3],
        isDirectory: typeChar == 'd',
        size: size,
        modified: modified,
      ));
    }
    return entries;
  }

  @override
  Future<void> writeText(String path, String content) async =>
      writeBytes(path, Uint8List.fromList(utf8.encode(content)));

  @override
  Future<void> writeBytes(String path, Uint8List bytes) async {
    final remote = await remotePath(path);
    final createResult = await _run('mkdir -p ${GitRunner.quote(p.dirname(remote))}');
    if (createResult.exitCode != 0) {
      throw WorkspaceFileException('创建目录失败：${createResult.output.trim()}');
    }
    if (bytes.isEmpty) {
      final result = await _run(': > ${GitRunner.quote(remote)}');
      if (result.exitCode != 0) {
        throw WorkspaceFileException('写入失败：${result.output.trim()}');
      }
      return;
    }
    for (var offset = 0; offset < bytes.length; offset += maxChunkBytes) {
      final end = offset + maxChunkBytes < bytes.length ? offset + maxChunkBytes : bytes.length;
      final encoded = base64.encode(bytes.sublist(offset, end));
      final redirection = offset == 0 ? '>' : '>>';
      final result = await _run(
        'printf \"%s\" ${GitRunner.quote(encoded)} | base64 -d $redirection ${GitRunner.quote(remote)}',
      );
      if (result.exitCode != 0) {
        throw WorkspaceFileException('写入失败：${result.output.trim()}');
      }
    }
  }



  @override
  Future<void> createDir(String path) async {
    final remote = await remotePath(path);
    final result = await _run('mkdir -p ${GitRunner.quote(remote)}');
    if (result.exitCode != 0) {
      throw WorkspaceFileException('建目录失败：${result.output.trim()}');
    }
  }

  @override
  Future<void> rename(String from, String to) async {
    final source = await remotePath(from);
    final target = await remotePath(to);
    final result = await _run('mv ${GitRunner.quote(source)} ${GitRunner.quote(target)}');
    if (result.exitCode != 0) {
      throw WorkspaceFileException('重命名失败：${result.output.trim()}');
    }
  }

  @override
  Future<void> delete(String path, {bool recursive = false}) async {
    final remote = await remotePath(path);
    final result = await _run('rm ${recursive ? '-rf' : '-f'} ${GitRunner.quote(remote)}');
    if (result.exitCode != 0) {
      throw WorkspaceFileException('删除失败：${result.output.trim()}');
    }
  }

  @override
  Future<void> copy(String from, String to, {bool overwrite = false}) async {
    final source = await remotePath(from);
    final target = await remotePath(to);
    final guard = overwrite
        ? ''
        : 'if [ -e ${GitRunner.quote(target)} ]; then exit 9; fi\\n';
    final result = await _run('$guard' 'cp -a ${GitRunner.quote(source)} ${GitRunner.quote(target)}');
    if (result.exitCode == 9) throw const WorkspaceFileException('目标已存在同名项');
    if (result.exitCode != 0) {
      throw WorkspaceFileException('复制失败：${result.output.trim()}');
    }
  }

  @override
  Future<void> move(String from, String to, {bool overwrite = false}) async {
    final source = await remotePath(from);
    final target = await remotePath(to);
    final guard = overwrite
        ? ''
        : 'if [ -e ${GitRunner.quote(target)} ]; then exit 9; fi\\n';
    final result = await _run('$guard' 'mv ${GitRunner.quote(source)} ${GitRunner.quote(target)}');
    if (result.exitCode == 9) throw const WorkspaceFileException('目标已存在同名项');
    if (result.exitCode != 0) {
      throw WorkspaceFileException('移动失败：${result.output.trim()}');
    }
  }

  @override
  Future<int> extractArchive(String archivePath, String destDir) async {
    final suffix = _archiveSuffix(archivePath);
    if (suffix == null) throw const WorkspaceFileException('不支持的压缩格式');
    final remote = await remotePath(archivePath);
    final dest = await remotePath(destDir);
    final destQuoted = GitRunner.quote(dest);
    final extract = _remoteExtractCommand(suffix, remote, dest);
    final result = await _run(
      'mkdir -p $destQuoted\n$extract',
      timeout: const Duration(minutes: 10),
    );
    if (result.exitCode != 0) {
      throw WorkspaceFileException('解压失败:${result.output.trim()}');
    }
    final counted = await _run('find $destQuoted -mindepth 1 -type f | wc -l');
    return int.tryParse(counted.output.trim()) ?? 0;
  }

  @override
  Future<List<SearchHit>> searchLines(
    String root,
    String pattern, {
    bool ignoreCase = false,
    bool fixed = false,
    required int limit,
  }) async {
    if (pattern.isEmpty) return const [];
    final remote = await remotePath(root);
    final remoteRootPath = await engine.remoteRoot();
    final args = <String>[
      'grep',
      '-r',
      '-n',
      '-I',
      if (ignoreCase) '-i',
      fixed ? '-F' : '-E',
      '--exclude-dir=.git',
      '--exclude-dir=node_modules',
      '--exclude-dir=build',
      '--exclude=.*',
      '--exclude-dir=.*',
      '-e',
      pattern,
      remote,
    ];
    final result = await _run('${args.map(GitRunner.quote).join(' ')} | head -n $limit');
    final hits = <SearchHit>[];
    for (final line in const LineSplitter().convert(result.output)) {
      if (line.trim().isEmpty) continue;
      final firstColon = line.indexOf(':');
      if (firstColon <= 0) continue;
      final secondColon = line.indexOf(':', firstColon + 1);
      if (secondColon <= firstColon) continue;
      final lineNumber = int.tryParse(line.substring(firstColon + 1, secondColon));
      if (lineNumber == null) continue;
      final hitPath = line.substring(0, firstColon);
      hits.add(SearchHit(
        path: hitPath.startsWith('$remoteRootPath/') ? await localPath(hitPath) : hitPath,
        line: lineNumber,
        text: line.substring(secondColon + 1),
      ));
    }
    return hits;
  }
}

final workspaceFilesProvider = FutureProvider<WorkspaceFiles>((ref) async {
  final target = ref.watch(executionTargetProvider);
  final localRoot = ref.watch(currentWorkspaceProvider).rootPath;
  // GitHub Codespaces 仅编程项目使用:写作与逆向项目强制走本地容器。
  final project = ref.watch(currentProjectProvider);
  if (project != null && project.kind != ProjectKind.coding) {
    return LocalWorkspaceFiles(root: localRoot);
  }
  if (!target.isRemote) return LocalWorkspaceFiles(root: localRoot);
  final engine = await ref.watch(executionEngineProvider.future);
  if (engine is! CodespacesEngine) return LocalWorkspaceFiles(root: localRoot);

  // 尝试使用 GitHub Contents API（无需 SSH/gh CLI）
  // 如果 Codespace 有未提交的改动，Contents API 只能看到 committed 状态，
  // 因此优先使用 SSH，失败时回退到 Contents API
  try {
    // 检查 gh 是否可用（SSH 通道）
    final ghCheck = await engine.transport.runCommandSync(
      'command -v gh >/dev/null 2>&1 && echo ok',
      timeout: const Duration(seconds: 10),
    );
    if (ghCheck.output.trim() == 'ok') {
      return RemoteWorkspaceFiles(engine: engine);
    }
  } catch (_) {}

  // gh 不可用，尝试 GitHub Contents API
  final token = await codespacesTokenFrom(ref.read(credentialStoreProvider));
  if (token.isNotEmpty) {
    // 从 Codespace 名称推断 owner/repo
    // Codespace name format: <owner>-<repo>-<hash> or just use the repository field
    final csState = ref.read(codespacesProvider);
    final cs = csState.codespaces.where((c) => c.name == (target as CodespaceExecutionTarget).name).firstOrNull;
    if (cs != null && cs.repository.isNotEmpty) {
      final parts = cs.repository.split('/');
      if (parts.length == 2) {
        final client = GitHubContentsClient(
          token: token,
          owner: parts[0],
          repo: parts[1],
          ref: cs.gitRef.isNotEmpty ? cs.gitRef : null,
        );
        return GitHubContentsWorkspaceFiles(
          client: client,
          repoRoot: localRoot,
        );
      }
    }
  }

  // 最终回退：SSH
  return RemoteWorkspaceFiles(engine: engine);
});

/// 解压支持的压缩包后缀:按此顺序匹配,`.tar.gz` 这类双段不会被误认成 `.gz`。
const List<String> _extractableArchiveSuffixes = [
  '.tar.gz', '.tar.bz2', '.tar.xz', '.tar.zst', '.tar.zstd',
  '.tgz', '.tbz2', '.tbz', '.txz', '.tzst',
  '.zip', '.jar', '.war', '.ear', '.apk', '.apks', '.xapk', '.aab', '.xpi', '.ipa',
  '.tar',
  '.gz', '.bz2', '.xz', '.zst', '.zstd',
];

/// 只压缩了单个文件的流格式(里面没有目录结构)。
const Set<String> _singleStreamSuffixes = {'.gz', '.bz2', '.xz', '.zst', '.zstd'};

/// zip 容器族(jar/war/apk/aab 等只是换了个后缀)。
const Set<String> _zipSuffixes = {
  '.zip', '.jar', '.war', '.ear', '.apk', '.apks', '.xapk', '.aab', '.xpi', '.ipa',
};

String? _archiveSuffix(String path) {
  final lower = path.toLowerCase();
  for (final suffix in _extractableArchiveSuffixes) {
    if (lower.length > suffix.length && lower.endsWith(suffix)) return suffix;
  }
  return null;
}

/// 该路径能否被内置解压([WorkspaceFiles.extractArchive])。文件树据此决定是否
/// 给出「解压」入口,不支持的格式(7z、rar 等)不显示菜单项。
bool supportsArchiveExtraction(String path) => _archiveSuffix(path) != null;

/// 解压目标文件夹的默认名:去掉压缩后缀(`a.tar.gz` → `a`)。
String archiveTargetName(String name) {
  final suffix = _archiveSuffix(name);
  return suffix == null ? name : name.substring(0, name.length - suffix.length);
}

Uint8List _decodeSingleStream(String suffix, Uint8List bytes) => switch (suffix) {
      '.gz' => Uint8List.fromList(GZipDecoder().decodeBytes(bytes)),
      '.bz2' => Uint8List.fromList(BZip2Decoder().decodeBytes(bytes)),
      '.xz' => Uint8List.fromList(XZDecoder().decodeBytes(bytes)),
      _ => throw UnsupportedError('不支持的压缩格式: $suffix'),
    };

/// 远端解压命令(依赖 Codespace 上常见的 unzip/tar/gzip/bzip2/xz)。
String _remoteExtractCommand(String suffix, String archivePath, String destDir) {
  if (_singleStreamSuffixes.contains(suffix)) {
    final tool = switch (suffix) {
      '.gz' => 'gzip',
      '.bz2' => 'bzip2',
      '.xz' => 'xz',
      _ => 'zstd',
    };
    final target = p.posix.join(destDir, archiveTargetName(p.posix.basename(archivePath)));
    return '$tool -dc ${GitRunner.quote(archivePath)} > ${GitRunner.quote(target)}';
  }
  if (_zipSuffixes.contains(suffix)) {
    return 'unzip -oq ${GitRunner.quote(archivePath)} -d ${GitRunner.quote(destDir)}';
  }
  return 'tar -xf ${GitRunner.quote(archivePath)} -C ${GitRunner.quote(destDir)}';
}

bool looksBinary(Uint8List bytes) {
  if (bytes.contains(0)) return true;
  try {
    utf8.decode(bytes);
    return false;
  } on FormatException {
    return true;
  }
}

String extractPrintableStrings(Uint8List bytes, {int minLength = 4}) {
  final buffer = StringBuffer();
  final run = StringBuffer();
  void flush() {
    if (run.length >= minLength) {
      if (buffer.isNotEmpty) buffer.write('\\n');
      buffer.write(run.toString());
    }
    run.clear();
  }

  for (final byte in bytes) {
    if (byte == 0x09 || (byte >= 0x20 && byte <= 0x7E)) {
      run.writeCharCode(byte);
    } else {
      flush();
    }
  }
  flush();
  return buffer.toString();
}