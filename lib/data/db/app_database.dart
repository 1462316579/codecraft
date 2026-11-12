import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// 应用数据库:七张表(chat_sessions / agent_messages / providers / todo_items / llm_call_records /
/// checkpoints / checkpoint_file_snapshots)。
/// 表结构与字段对齐原仓库 Room entity 的子集,见各模型类的 toMap/fromMap。
class AppDatabase {
  AppDatabase(this.db);

  final Database db;

  static const int schemaVersion = 9;

  static Future<AppDatabase> open({String? path, bool inMemory = false}) async {
    final dbPath = inMemory
        ? inMemoryDatabasePath
        : (path ??
            p.join((await getApplicationDocumentsDirectory()).path, 'codecraft_flutter.db'));
    final db = await openDatabase(
      dbPath,
      version: schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return AppDatabase(db);
  }

  Future<void> close() => db.close();

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
CREATE TABLE chat_sessions (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
  mode TEXT NOT NULL,
  reasoningEffort TEXT NOT NULL,
  providerId TEXT,
  model TEXT,
  totalInputTokens INTEGER NOT NULL DEFAULT 0,
  totalOutputTokens INTEGER NOT NULL DEFAULT 0,
  lastInputTokens INTEGER NOT NULL DEFAULT 0,
  isPinned INTEGER NOT NULL DEFAULT 0,
  projectId TEXT,
  parentId TEXT,
  subagentType TEXT
)''');

    await db.execute('''
CREATE TABLE agent_messages (
  id TEXT PRIMARY KEY,
  sessionId TEXT NOT NULL,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  toolCallsJson TEXT,
  toolCallId TEXT,
  toolName TEXT,
  toolArgs TEXT,
  isError INTEGER NOT NULL DEFAULT 0,
  reasoning TEXT,
  signature TEXT,
  attachmentsJson TEXT,
  isCompacted INTEGER NOT NULL DEFAULT 0,
  isContextSummary INTEGER NOT NULL DEFAULT 0,
  isCompactionMarker INTEGER NOT NULL DEFAULT 0,
  inputTokens INTEGER NOT NULL DEFAULT 0,
  outputTokens INTEGER NOT NULL DEFAULT 0,
  cachedInputTokens INTEGER NOT NULL DEFAULT 0,
  thinkingBlocksJson TEXT,
  isContextExcluded INTEGER NOT NULL DEFAULT 0,
  compactedBySummaryId TEXT
)''');
    await db.execute('CREATE INDEX idx_messages_session ON agent_messages(sessionId)');

    await db.execute('''
CREATE TABLE providers (
  id TEXT PRIMARY KEY,
  json TEXT NOT NULL,
  sortOrder INTEGER NOT NULL DEFAULT 0
)''');

    await _createTodoItems(db);
    await _createLlmCallRecords(db);
    await _createCheckpoints(db);
    await _createProjects(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createTodoItems(db);
    }
    if (oldVersion < 3) {
      await _createLlmCallRecords(db);
    }
    if (oldVersion < 4) {
      await _createCheckpoints(db);
    }
    if (oldVersion < 5) {
      await _createProjects(db);
      await db.execute('ALTER TABLE chat_sessions ADD COLUMN projectId TEXT');
      await _adoptLegacySessions(db);
    }
    if (oldVersion < 6) {
      await _addProjectAppColumns(db);
    }
    if (oldVersion < 7) {
      await _addColumnIfMissing(db, 'projects', 'appApkPath', 'TEXT');
    }
    if (oldVersion < 8) {
      await _addColumnIfMissing(db, 'projects', 'appApkPaths', 'TEXT');
    }
    if (oldVersion < 9) {
      // 子代理系统:父会话 id 与子会话类型标识(子代理会话不出现在主列表)。
      await _addColumnIfMissing(db, 'chat_sessions', 'parentId', 'TEXT');
      await _addColumnIfMissing(db, 'chat_sessions', 'subagentType', 'TEXT');
    }
  }

  /// v5 → v6:「应用逆向」项目的目标应用信息。
  ///
  /// 只对逆向项目有值;编程 / 写作项目这五列为 NULL。
  static Future<void> _addProjectAppColumns(Database db) async {
    const columns = {
      'kind': "TEXT NOT NULL DEFAULT 'coding'",
      'appPackage': 'TEXT',
      'appName': 'TEXT',
      'appVersionName': 'TEXT',
      'appVersionCode': 'INTEGER',
      'appIcon': 'BLOB',
    };
    final existing = await db.rawQuery('PRAGMA table_info(projects)');
    final names = existing.map((row) => row['name'] as String).toSet();
    for (final entry in columns.entries) {
      if (names.contains(entry.key)) continue;
      await db.execute('ALTER TABLE projects ADD COLUMN ${entry.key} ${entry.value}');
    }
  }

  /// 单列补加:用于版本升级时给已有表补列,已存在则跳过。
  static Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    final existing = await db.rawQuery('PRAGMA table_info($table)');
    final names = existing.map((row) => row['name'] as String).toSet();
    if (names.contains(column)) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
  }

  /// 项目与会话的归属表。
  ///
  /// 「项目」是一个可命名的容器(编程 / 写作),下挂多条会话;
  /// 会话本身不再等同于项目——新建会话只在本项目内加一条,不会凭空多出一个项目。
  static Future<void> _createProjects(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS projects (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  mode TEXT NOT NULL,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
  kind TEXT NOT NULL DEFAULT 'coding',
  appPackage TEXT,
  appName TEXT,
  appVersionName TEXT,
  appVersionCode INTEGER,
  appIcon BLOB,
  appApkPath TEXT,
  appApkPaths TEXT
)''');
  }

  /// v4 → v5 迁移:老数据里每条会话本身就是一个「项目」。
  ///
  /// 给每条旧会话各建一个同名项目并挂上去,这样升级后用户看到的结构与之前一致,
  /// 不会把多轮对话合并进同一个项目,也不会丢任何会话。
  static Future<void> _adoptLegacySessions(Database db) async {
    final rows = await db.query('chat_sessions', where: 'projectId IS NULL');
    for (final row in rows) {
      final sessionId = row['id'] as String;
      final title = (row['title'] as String?) ?? '';
      final mode = (row['mode'] as String?) ?? 'build';
      final createdAt = (row['createdAt'] as int?) ?? 0;
      final updatedAt = (row['updatedAt'] as int?) ?? createdAt;
      final projectId = 'p-$sessionId';
      await db.insert('projects', {
        'id': projectId,
        'name': title.trim().isEmpty ? 'Untitled' : title,
        'mode': mode,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.update(
        'chat_sessions',
        {'projectId': projectId},
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    }
  }

  /// 检查点与文件快照(对齐上游 CheckpointEntity / CheckpointFileSnapshotEntity)。
  /// 用于把工作区文件回滚到某条用户消息发出前的状态。
  static Future<void> _createCheckpoints(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS checkpoints (
  id TEXT PRIMARY KEY,
  sessionId TEXT NOT NULL,
  userMessageId TEXT NOT NULL,
  promptSnippet TEXT NOT NULL,
  createdAt INTEGER NOT NULL
)''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_checkpoints_session '
      'ON checkpoints(sessionId, createdAt)',
    );
    await db.execute('''
CREATE TABLE IF NOT EXISTS checkpoint_file_snapshots (
  id TEXT PRIMARY KEY,
  checkpointId TEXT NOT NULL,
  filePath TEXT NOT NULL,
  snapshotRelativePath TEXT NOT NULL,
  changeType TEXT NOT NULL,
  fingerprint TEXT
)''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_snapshots_checkpoint '
      'ON checkpoint_file_snapshots(checkpointId)',
    );
  }

  /// LLM 调用记录(对齐上游 LlmCallRecordEntity / llm_call_records 表):Token 统计页的数据源。
  static Future<void> _createLlmCallRecords(Database db) async {
    await db.execute('''
CREATE TABLE llm_call_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sessionId TEXT,
  providerId TEXT,
  model TEXT,
  reasoningEffort TEXT,
  kind TEXT NOT NULL DEFAULT 'chat',
  inputTokens INTEGER NOT NULL DEFAULT 0,
  outputTokens INTEGER NOT NULL DEFAULT 0,
  cachedInputTokens INTEGER NOT NULL DEFAULT 0,
  cacheCreationTokens INTEGER NOT NULL DEFAULT 0,
  ttfbMillis INTEGER,
  durationMillis INTEGER,
  status TEXT NOT NULL DEFAULT 'success',
  errorMessage TEXT,
  stopReason TEXT,
  retryCount INTEGER NOT NULL DEFAULT 0,
  createdAt INTEGER NOT NULL
)''');
    await db.execute('CREATE INDEX idx_llm_calls_created ON llm_call_records(createdAt)');
    await db.execute(
      'CREATE INDEX index_llm_call_records_provider_model '
      'ON llm_call_records(providerId, model)',
    );
  }

  /// 会话待办清单(对齐上游 todo_items 表)。
  static Future<void> _createTodoItems(Database db) async {
    await db.execute('''
CREATE TABLE todo_items (
  id TEXT PRIMARY KEY,
  sessionId TEXT NOT NULL,
  subject TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'PENDING',
  priority INTEGER NOT NULL DEFAULT 0,
  `order` INTEGER NOT NULL DEFAULT 0,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL
)''');
    await db.execute('CREATE INDEX idx_todos_session ON todo_items(sessionId)');
  }
}

/// 在 main() 中 override 为已打开的实例。
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw StateError('databaseProvider 需在 ProviderScope.overrides 中注入'),
);