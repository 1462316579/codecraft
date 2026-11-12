import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'db/app_database.dart';
import '../core/log/log_store.dart';

/// 存储占用分类。**各分类互斥**,加总即 App 总占用;枚举顺序即界面展示顺序。
///
/// 分类边界按物理目录划定:日志与缓存所在目录不重复计入 [other],
/// 工作区内的聊天附件算在 [workspaces] 里(只作为副标题提示,不单列分类)。
enum StorageCategory {
  chat('聊天记录'),
  workspaces('工作区'),
  aiConfig('AI 配置与产物'),
  checkpoints('检查点'),
  logs('日志'),
  caches('缓存'),
  other('其他数据'),
  apk('应用安装包');

  const StorageCategory(this.label);

  final String label;
}

/// [StorageDetail.key] 的取值:把「哪些明细项可清理」与它们的目录名解耦。
abstract final class StorageDetailKey {
  static const String toolOutput = 'toolOutput';
  static const String visionSessions = 'visionSessions';
}

/// 分类下的一条明细(容器名、项目名、会话标题、子目录名等)。
class StorageDetail {
  const StorageDetail({
    required this.label,
    required this.bytes,
    this.note,
    this.key,
    this.indent = false,
  });

  final String label;
  final int bytes;

  /// 副标题(消息数、附件大小等);纯展示项为 null。
  final String? note;

  /// 稳定标识,供界面按项取值(如按 `toolOutput` 找可清理大小)。
  final String? key;

  /// 是否作为上一层明细的下钻项缩进显示。
  final bool indent;
}

class StorageEntry {
  const StorageEntry({required this.category, required this.bytes, this.details = const []});

  final StorageCategory category;
  final int bytes;
  final List<StorageDetail> details;
}

/// 可清理项:都是能自动重建或仅影响历史回看的临时数据,不含用户内容。
enum CleanupKind {
  caches('缓存文件', '临时文件,删除后会自动重建'),
  logs('运行日志', '应用日志与 AI 请求日志,删除不影响功能'),
  toolOutput('工具输出存档', 'AI 超长工具输出保存到磁盘的副本,删除后旧消息里的输出路径不再可读'),
  visionSessions('识图会话缓存', '识图追问的历史,删除后无法继续追问旧图片');

  const CleanupKind(this.label, this.description);

  final String label;
  final String description;
}

/// 所在存储卷的容量信息(App 私有目录所在卷)。
class DeviceSpace {
  const DeviceSpace({required this.totalBytes, required this.availableBytes});

  final int totalBytes;
  final int availableBytes;
}

/// 字节数转可读文本(对齐上游 formatStorageSize,固定用 `.` 作小数点)。
String formatStorageSize(int bytes) {
  if (bytes >= 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
  if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '$bytes B';
}

/// 配置目录(docs 根)下已知的配置文件,用于「AI 配置与产物」的明细拆分。
const List<String> _configEntries = [
  'skills',
  'codecraft',
  'model_metadata.json',
  'mcp.json',
  'mcp-oauth.json',
  'permissions.json',
  'git-credentials',
];

/// 统计 App 各部分磁盘占用,并清理可安全重建的临时数据。
///
/// 分类之间互斥,加总即总占用。目录归属:
/// - 文档目录:数据库、工作区、配置与 skills、检查点;
/// - files 目录:容器 rootfs 与镜像包(原生侧解压根目录);
/// - 系统临时目录:缓存。
class StorageScanner {
  StorageScanner({
    Future<Directory> Function()? documentsDir,
    Future<Directory> Function()? cacheDir,
    Future<List<Directory>> Function()? logDirs,
    Future<List<int>> Function()? apkSizes,
    AppDatabase? database,
  })  : _documentsDir = documentsDir,
        _cacheDir = cacheDir,
        _logDirs = logDirs,
        _apkSizes = apkSizes,
        _database = database;

  final Future<Directory> Function()? _documentsDir;
  final Future<Directory> Function()? _cacheDir;
  final Future<List<Directory>> Function()? _logDirs;
  final Future<List<int>> Function()? _apkSizes;

  final AppDatabase? _database;

  /// 文档目录(数据库、工作区、配置都在其下)。
  Future<Directory> _docs() async {
    final custom = _documentsDir;
    if (custom != null) return custom();
    return getApplicationDocumentsDirectory();
  }

  /// files 目录(应用支持目录);拿不到时退回文档目录。
  Future<Directory> _files() async => _docs();

  /// 系统缓存目录;测试注入可控路径。
  Future<Directory> _cache() async {
    final custom = _cacheDir;
    if (custom != null) return custom();
    return getTemporaryDirectory();
  }

  /// 逐分类上报统计结果:数据库、缓存这类秒出的先算,容器最后,界面可以边算边填。
  Stream<StorageEntry> scan() async* {
    final docs = await _docs();

    yield await _chatEntry(docs);
    yield await _cacheEntry();
    yield await _logsEntry(docs);
    yield await _apkEntry();
    yield await _checkpointsEntry(docs);
    yield await _otherDataEntry(docs);
    yield await _aiConfigEntry(docs);
    yield await _workspacesEntry(docs);
  }

  /// App 私有目录所在存储卷的容量。
  Future<DeviceSpace> deviceSpace() async {
    try {
      final docs = await _docs();
      final result = await Process.run('df', ['-k', docs.path]);
      final parsed = _parseDf(result.stdout.toString());
      return DeviceSpace(totalBytes: parsed.$1, availableBytes: parsed.$2);
    } catch (_) {
      return const DeviceSpace(totalBytes: 0, availableBytes: 0);
    }
  }

  /// 执行一项清理,返回释放的字节数。
  Future<int> clean(CleanupKind kind) async {
    final docs = await _docs();
    switch (kind) {
      case CleanupKind.caches:
        return await _clearDir(await _cache());
      case CleanupKind.logs:
        var freed = 0;
        for (final dir in await _logDirs_()) {
          freed += await _clearDir(dir);
        }
        return freed;
      case CleanupKind.toolOutput:
        return await _clearDir(Directory(p.join(docs.path, 'codecraft', 'tool-output')));
      case CleanupKind.visionSessions:
        return await _clearDir(Directory(p.join(docs.path, 'codecraft', 'vision-sessions')));
    }
  }

  // ── 各分类 ──────────────────────────────────────────────────────────────

  /// 聊天记录:数据库文件本身(含 WAL/SHM 旁文件),明细列出占用最大的几个会话。
  Future<StorageEntry> _chatEntry(Directory docs) async {
    var bytes = 0;
    final db = File(p.join(docs.path, 'codecraft_flutter.db'));
    bytes += await _fileSize(db);
    for (final suffix in ['-wal', '-shm']) {
      bytes += await _fileSize(File('${db.path}$suffix'));
    }
    return StorageEntry(
      category: StorageCategory.chat,
      bytes: bytes,
      details: await _sessionDetails(),
    );
  }

  /// 占用最大的几个会话(按消息文本长度近似,对齐上游 sessionStorageUsage(5))。
  Future<List<StorageDetail>> _sessionDetails() async {
    final database = _database;
    if (database == null) return const [];
    try {
      final rows = await database.db.rawQuery('''
        SELECT s.title AS title,
               COUNT(m.id) AS messageCount,
               SUM(
                 LENGTH(m.content)
                 + LENGTH(COALESCE(m.reasoning, ''))
                 + LENGTH(COALESCE(m.toolArgs, ''))
                 + LENGTH(COALESCE(m.toolCallsJson, ''))
                 + LENGTH(COALESCE(m.attachmentsJson, ''))
               ) AS bytes
        FROM chat_sessions s
        JOIN agent_messages m ON m.sessionId = s.id
        GROUP BY s.id
        HAVING bytes > 0
        ORDER BY bytes DESC
        LIMIT 5
      ''');
      return [
        for (final row in rows)
          StorageDetail(
            label: (row['title'] as String?)?.trim().isNotEmpty ?? false
                ? row['title']! as String
                : '未命名会话',
            bytes: (row['bytes'] as num?)?.toInt() ?? 0,
            note: '${(row['messageCount'] as num?)?.toInt() ?? 0} 条消息',
          ),
      ];
    } catch (_) {
      // 读库失败时只展示总量,不让整次统计失败。
      return const [];
    }
  }

  /// 容器:`<files>/container/rootfs`(内置)与 `rootfs_<id>`(自定义镜像),
  /// 工作区:按项目列出并标出其中的聊天附件。
  Future<StorageEntry> _workspacesEntry(Directory workspaceRoot) async {
    final details = <StorageDetail>[];
    var total = 0;
    if (await workspaceRoot.exists()) {
      for (final dir in await _listDirs(workspaceRoot)) {
        final size = await _dirSize(dir);
        total += size;
        final attachments = await _dirSize(
          Directory(p.join(dir.path, '.codecraft', 'attachments')),
        );
        details.add(StorageDetail(
          label: p.basename(dir.path),
          bytes: size,
          note: attachments > 0 ? '含附件 ${formatStorageSize(attachments)}' : null,
        ));
      }
      await for (final entity in workspaceRoot.list()) {
        if (entity is File) total += await _fileSize(entity);
      }
    }
    return StorageEntry(
      category: StorageCategory.workspaces,
      bytes: total,
      details: details,
    );
  }

  /// AI 配置与产物:配置目录下的 skills、codecraft 与各配置文件。
  Future<StorageEntry> _aiConfigEntry(Directory docs) async {
    final details = <StorageDetail>[];
    var total = 0;
    for (final name in _configEntries) {
      final entity = _entityAt(docs, name);
      final size = await _dirSize(entity);
      if (size == 0) continue;
      total += size;
      details.add(StorageDetail(
        label: name,
        bytes: size,
        key: switch (name) {
          'tool-output' => StorageDetailKey.toolOutput,
          'vision-sessions' => StorageDetailKey.visionSessions,
          _ => null,
        },
      ));
    }
    details.sort((a, b) => b.bytes.compareTo(a.bytes));
    return StorageEntry(
      category: StorageCategory.aiConfig,
      bytes: total,
      details: details,
    );
  }

  Future<StorageEntry> _checkpointsEntry(Directory docs) async {
    final dir = Directory(p.join(docs.path, 'checkpoints'));
    return StorageEntry(category: StorageCategory.checkpoints, bytes: await _dirSize(dir));
  }

  /// 日志目录:与 FileLogger/AiLogger 落盘位置保持一致(外部私有目录优先)。
  Future<List<Directory>> _logDirs_() async {
    final custom = _logDirs;
    if (custom != null) return custom();
    final base = await resolveLogBaseDir();
    return [
      Directory(p.join(base.path, LogSource.app.dirName)),
      Directory(p.join(base.path, LogSource.ai.dirName)),
    ];
  }

  /// 日志:应用日志(按天文件)+ AI 请求日志(按会话文件)两个目录。
  Future<StorageEntry> _logsEntry(Directory docs) async {
    final dirs = await _logDirs_();
    final app = await _dirSize(dirs[0]);
    final ai = dirs.length > 1 ? await _dirSize(dirs[1]) : 0;
    final details = <StorageDetail>[
      if (app > 0) StorageDetail(label: '应用日志', bytes: app),
      if (ai > 0) StorageDetail(label: 'AI 请求日志', bytes: ai),
    ];
    return StorageEntry(
      category: StorageCategory.logs,
      bytes: app + ai,
      details: details,
    );
  }

  Future<StorageEntry> _cacheEntry() async {
    return StorageEntry(category: StorageCategory.caches, bytes: await _dirSize(await _cache()));
  }

  /// 其他数据:配置目录里未被上述分类覆盖的部分。
  Future<StorageEntry> _otherDataEntry(Directory docs) async {
    const classified = {
      'checkpoints',
      'logs',
      'codecraft_flutter.db',
      'codecraft_flutter.db-wal',
      'codecraft_flutter.db-shm',
      ..._configEntries,
    };
    var total = 0;
    if (await docs.exists()) {
      await for (final entity in docs.list(followLinks: false)) {
        if (classified.contains(p.basename(entity.path))) continue;
        total += await _dirSize(entity);
      }
    }
    return StorageEntry(category: StorageCategory.other, bytes: total);
  }

  /// 应用安装包本体(base APK 与各 split)。
  Future<StorageEntry> _apkEntry() async {
    final sizes = await (_apkSizes?.call()) ?? const <int>[];
    return StorageEntry(
      category: StorageCategory.apk,
      bytes: sizes.fold(0, (sum, size) => sum + size),
    );
  }

  // ── 工具 ────────────────────────────────────────────────────────────────

  FileSystemEntity _entityAt(Directory parent, String name) =>
      Directory(p.join(parent.path, name)).absolute;

  Future<List<Directory>> _listDirs(Directory dir) async {
    final result = <Directory>[];
    if (!await dir.exists()) return result;
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is Directory) result.add(entity);
    }
    result.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    return result;
  }

  Future<int> _fileSize(File file) async {
    try {
      if (!await file.exists()) return 0;
      return await file.length();
    } catch (_) {
      return 0;
    }
  }

  /// 目录占用求和。不跟随符号链接(容器与依赖目录里到处是 symlink,跟随会重复计数甚至成环);
  /// 单个条目读失败一律跳过,不让整次统计失败。
  Future<int> _dirSize(FileSystemEntity target) async {
    try {
      final type = await FileSystemEntity.type(target.path, followLinks: false);
      if (type == FileSystemEntityType.notFound) return 0;
      if (type == FileSystemEntityType.link) return 0;
      if (type == FileSystemEntityType.file) return await File(target.path).length();
      if (type != FileSystemEntityType.directory) return 0;

      var total = 0;
      await for (final entity in Directory(target.path).list(followLinks: false)) {
        final childType = await FileSystemEntity.type(entity.path, followLinks: false);
        if (childType == FileSystemEntityType.file) {
          try {
            total += await File(entity.path).length();
          } catch (_) {
            // 单文件读失败跳过。
          }
        } else if (childType == FileSystemEntityType.directory) {
          total += await _dirSize(entity);
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// 删除目录下所有内容但保留目录本身,返回释放字节数。
  Future<int> _clearDir(Directory dir) async {
    if (!await dir.exists()) return 0;
    var freed = 0;
    await for (final entity in dir.list(followLinks: false)) {
      final size = await _dirSize(entity);
      try {
        await entity.delete(recursive: true);
        freed += size;
      } catch (_) {
        // 删不掉就跳过,不中断整次清理。
      }
    }
    return freed;
  }

  /// 解析 `df -k` 输出:取第 2 行,total 在第 2 列、available 在第 4 列(KB)。
  (int, int) _parseDf(String output) {
    final lines = output.trim().split('\n');
    if (lines.length < 2) return (0, 0);
    final cols = lines[1].trim().split(RegExp(r'\s+'));
    if (cols.length < 4) return (0, 0);
    final total = int.tryParse(cols[1]) ?? 0;
    final available = int.tryParse(cols[3]) ?? 0;
    return (total * 1024, available * 1024);
  }
}