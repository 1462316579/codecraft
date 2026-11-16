import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

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

/// 工作区文件读写：本地容器里工作区是 bind 挂载，宿主路径与容器内路径一致，直接用 `File` 最快。
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

final workspaceFilesProvider = FutureProvider<WorkspaceFiles>((ref) async {
  final root = ref.watch(currentWorkspaceProvider).rootPath;
  return LocalWorkspaceFiles(root: root);
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