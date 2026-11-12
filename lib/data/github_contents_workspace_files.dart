import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'github_contents_client.dart';
import 'workspace_files.dart';

/// 基于 GitHub Contents API 的 WorkspaceFiles 实现。
///
/// 优势：不依赖 SSH/gh CLI，纯 HTTP 调用，Flutter 原生支持。
/// 限制：Contents API 只能看到 Git 提交状态，无法反映 Codespace 内未提交的改动。
/// 适用于：文件浏览、读取已提交文件、创建/更新文件（自动创建 commit）。
class GitHubContentsWorkspaceFiles implements WorkspaceFiles {
  GitHubContentsWorkspaceFiles({
    required this.client,
    this.repoRoot = '',
  });

  final GitHubContentsClient client;
  final String repoRoot;

  /// 将本地路径映射为仓库路径。
  String _toRepoPath(String localPath) {
    var path = localPath;
    // Remove repo root prefix if present
    if (repoRoot.isNotEmpty && path.startsWith(repoRoot)) {
      path = path.substring(repoRoot.length);
    }
    // Normalize: remove leading slash
    if (path.startsWith('/')) path = path.substring(1);
    return path;
  }

  /// 将仓库路径映射为本地路径。
  String _toLocalPath(String repoPath) {
    if (repoRoot.isEmpty) return '/$repoPath';
    return '$repoRoot/$repoPath';
  }

  @override
  Future<bool> exists(String path) async {
    final repoPath = _toRepoPath(path);
    if (repoPath.isEmpty) return true; // root always exists
    return client.exists(repoPath);
  }

  @override
  Future<bool> isDirectory(String path) async {
    final repoPath = _toRepoPath(path);
    if (repoPath.isEmpty) return true; // root
    return client.isDirectory(repoPath);
  }

  @override
  Future<int> sizeOf(String path) async {
    final repoPath = _toRepoPath(path);
    if (repoPath.isEmpty) return 0;
    final entries = await client.listDir(p.dirname(repoPath));
    final name = p.basename(repoPath);
    for (final entry in entries) {
      if (entry.name == name) return entry.size;
    }
    throw WorkspaceFileException('文件不存在: $path');
  }

  @override
  Future<String> readText(String path) async {
    final repoPath = _toRepoPath(path);
    if (repoPath.isEmpty) throw const WorkspaceFileException('无法读取目录');
    return client.readFile(repoPath);
  }

  @override
  Future<Uint8List> readBytes(String path) async {
    final repoPath = _toRepoPath(path);
    if (repoPath.isEmpty) throw const WorkspaceFileException('无法读取目录');
    final bytes = await client.readBytes(repoPath);
    return Uint8List.fromList(bytes);
  }

  @override
  Future<void> writeText(String path, String content) async {
    final repoPath = _toRepoPath(path);
    if (repoPath.isEmpty) throw const WorkspaceFileException('无法写入目录');
    final sha = await client.getFileSha(repoPath);
    await client.writeFile(repoPath, content, sha: sha);
  }

  @override
  Future<void> writeBytes(String path, Uint8List bytes) async {
    await writeText(path, utf8.decode(bytes));
  }

  @override
  Future<List<DirEntry>> listDir(String path) async {
    final repoPath = _toRepoPath(path);
    final entries = await client.listDir(repoPath);
    return [
      for (final entry in entries)
        DirEntry(
          name: entry.name,
          isDirectory: entry.isDir,
          size: entry.size,
          modified: DateTime.now(),
        ),
    ];
  }

  @override
  Future<void> createDir(String path) async {
    // Contents API doesn't have a direct "create directory" - directories are
    // created implicitly when files are added. Create a .gitkeep file.
    final repoPath = _toRepoPath(path);
    if (repoPath.isEmpty) return;
    final gitkeepPath = '$repoPath/.gitkeep';
    final exists = await client.exists(gitkeepPath);
    if (!exists) {
      await client.writeFile(gitkeepPath, '', message: 'Create directory $repoPath');
    }
  }

  @override
  Future<void> rename(String from, String to) async {
    // Contents API doesn't support rename directly.
    // Read from old path, write to new path, then delete old.
    final content = await readText(from);
    await writeText(to, content);
    await delete(from);
  }

  @override
  Future<void> delete(String path, {bool recursive = false}) async {
    final repoPath = _toRepoPath(path);
    if (repoPath.isEmpty) throw const WorkspaceFileException('无法删除根目录');
    final sha = await client.getFileSha(repoPath);
    if (sha == null) throw WorkspaceFileException('文件不存在: $path');
    await client.deleteFile(repoPath, sha);
  }


  @override
  Future<void> copy(String from, String to, {bool overwrite = false}) async {
    final content = await readText(from);
    if (!overwrite && await exists(to)) {
      throw const WorkspaceFileException('目标已存在');
    }
    await writeText(to, content);
  }

  @override
  Future<void> move(String from, String to, {bool overwrite = false}) async {
    await copy(from, to, overwrite: overwrite);
    await delete(from);
  }

  @override
  Future<int> extractArchive(String archivePath, String destDir) async {
    throw const WorkspaceFileException('Contents API 不支持解压操作，请使用 SSH 连接');
  }

  @override
  Future<List<SearchHit>> searchLines(
    String root,
    String pattern, {
    bool ignoreCase = false,
    bool fixed = false,
    required int limit,
  }) async {
    throw const WorkspaceFileException('Contents API 不支持搜索操作，请使用 SSH 连接');
  }
}
