import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'file_logger.dart';

/// 日志来源(查看页按来源分组/标注)。
enum LogSource {
  app('应用日志', 'logs'),
  ai('AI 请求日志', 'ai-logs');

  const LogSource(this.label, this.dirName);

  final String label;
  final String dirName;
}

/// 一个日志文件(查看页列表项)。
class LogFileInfo {
  const LogFileInfo({
    required this.source,
    required this.name,
    required this.path,
    required this.bytes,
    required this.modified,
  });

  final LogSource source;
  final String name;
  final String path;
  final int bytes;
  final DateTime modified;
}

/// 日志文件的列举/读取/清理(查看页与存储清理共用)。
class LogStore {
  LogStore({required this.logsDir, required this.aiLogsDir});

  final Directory logsDir;
  final Directory aiLogsDir;

  Directory dirFor(LogSource source) =>
      source == LogSource.app ? logsDir : aiLogsDir;

  /// 列出全部日志文件(含 AI 会话日志与其归档),按修改时间从新到旧。
  List<LogFileInfo> listFiles() {
    final files = <LogFileInfo>[];
    for (final source in LogSource.values) {
      final dir = dirFor(source);
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync()) {
        if (entity is! File) continue;
        final stat = entity.statSync();
        files.add(LogFileInfo(
          source: source,
          name: p.basename(entity.path),
          path: entity.path,
          bytes: stat.size,
          modified: stat.modified,
        ));
      }
    }
    files.sort((a, b) => b.modified.compareTo(a.modified));
    return files;
  }

  /// 应用日志文件(logs 目录下 log- 开头,按文件名即日期升序)——日志查看页用,对齐上游 FileLogger.listLogFiles。
  List<LogFileInfo> listAppLogFiles() {
    if (!logsDir.existsSync()) return const [];
    final files = <LogFileInfo>[];
    for (final entity in logsDir.listSync()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (!name.startsWith('log-')) continue;
      final stat = entity.statSync();
      files.add(LogFileInfo(
        source: LogSource.app,
        name: name,
        path: entity.path,
        bytes: stat.size,
        modified: stat.modified,
      ));
    }
    files.sort((a, b) => a.name.compareTo(b.name));
    return files;
  }

  /// 全部日志占用的字节数(存储清理页展示)。
  int totalBytes() {
    var total = 0;
    for (final file in listFiles()) {
      total += file.bytes;
    }
    return total;
  }

  Future<String> read(LogFileInfo info) => File(info.path).readAsString();

  /// 删除全部日志文件,返回释放的字节数。
  Future<int> deleteAll() async {
    var freed = 0;
    for (final source in LogSource.values) {
      final dir = dirFor(source);
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync()) {
        if (entity is! File) continue;
        try {
          freed += entity.lengthSync();
          await entity.delete();
        } catch (_) {}
      }
    }
    return freed;
  }
}

/// 日志等级在 SharedPreferences 里的键(设置页写入、启动时读回)。
const String logLevelPrefKey = 'logLevel';

/// 日志根目录:优先外部私有目录(可用文件管理器直接查看),不可用时回退应用文档目录。
///
/// 与上游 `FileLogger.init` 的取向一致——日志的价值之一是「没有 adb 也能拿到」。
Future<Directory> resolveLogBaseDir() async {
  try {
    final external = await getExternalStorageDirectory();
    if (external != null) return external;
  } catch (_) {
    // 外部目录不可用(无存储权限等)时回退内部目录。
  }
  try {
    return await getApplicationDocumentsDirectory();
  } catch (_) {
    // 平台通道也不可用(单元测试等):退到临时目录,日志降级但不影响调用方。
    return Directory.systemTemp;
  }
}

final logBaseDirProvider = FutureProvider<Directory>((ref) => resolveLogBaseDir());

final logStoreProvider = FutureProvider<LogStore>((ref) async {
  final base = await ref.watch(logBaseDirProvider.future);
  return LogStore(
    logsDir: Directory(p.join(base.path, LogSource.app.dirName)),
    aiLogsDir: Directory(p.join(base.path, LogSource.ai.dirName)),
  );
});

/// 文件日志实例(初始化后可用;供 main 在启动时装配)。
final fileLoggerProvider = FutureProvider<FileLogger>((ref) async {
  final store = await ref.watch(logStoreProvider.future);
  return FileLogger(dir: store.logsDir);
});