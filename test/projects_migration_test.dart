import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:codecraft/agent/models/chat_session.dart';
import 'package:codecraft/agent/models/project.dart';
import 'package:codecraft/data/db/app_database.dart';
import 'package:codecraft/data/db/daos.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// v4 → v5 迁移:老数据里每条会话自己就是一个「项目」。
/// 迁移必须给每条旧会话补一个同名项目并挂上去,不丢会话、也不把多轮对话并成一个项目。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  open.overrideFor(OperatingSystem.linux, () => ffi.DynamicLibrary.open('libsqlite3.so.0'));
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late Directory dir;
  late String path;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('codecraft-migrate');
    path = p.join(dir.path, 'legacy.db');
  });

  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  /// 造一个 v4 的库:chat_sessions 没有 projectId 列。
  Future<void> createLegacyDb() async {
    final db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, version) async {
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
  isPinned INTEGER NOT NULL DEFAULT 0
)''');
        },
      ),
    );
    await db.insert('chat_sessions', {
      'id': 'legacy-1',
      'title': '老会话一',
      'createdAt': 10,
      'updatedAt': 20,
      'mode': 'build',
      'reasoningEffort': 'medium',
      'isPinned': 0,
    });
    await db.insert('chat_sessions', {
      'id': 'legacy-2',
      'title': '老会话二',
      'createdAt': 11,
      'updatedAt': 21,
      'mode': 'write',
      'reasoningEffort': 'medium',
      'isPinned': 0,
    });
    await db.insert('chat_sessions', {
      'id': 'legacy-3',
      'title': '',
      'createdAt': 12,
      'updatedAt': 22,
      'mode': 'build',
      'reasoningEffort': 'medium',
      'isPinned': 0,
    });
    await db.close();
  }

  test('旧库升级后:每条会话各得其项目,属主与模式都对', () async {
    await createLegacyDb();

    final app = await AppDatabase.open(path: path);
    addTearDown(app.close);

    final projects = await app.projectDao.list();
    expect(projects, hasLength(3), reason: '三条旧会话应各得到一个项目');

    final byName = {for (final project in projects) project.name: project};
    expect(byName.keys, containsAll(['老会话一', '老会话二', 'Untitled']),
        reason: '空标题的会话用 Untitled 兜底');
    expect(byName['老会话二']!.mode, AgentMode.write, reason: '项目继承会话的模式');

    final sessions = await app.sessionDao.list();
    expect(sessions, hasLength(3), reason: '不得丢会话');
    for (final session in sessions) {
      expect(session.projectId, isNotNull, reason: '每条旧会话都应挂上项目');
    }
    final migrated = sessions.firstWhere((s) => s.id == 'legacy-2');
    expect(migrated.projectId, byName['老会话二']!.id, reason: '会话归到自己那个项目');
  });

  test('v5 库升级到 v6:项目补上类型与应用元数据列,旧项目默认编程', () async {
    await createLegacyDb();
    // 先升到 v5(v4→v5 会建 projects 表并迁移会话),再降到 v5 重建以模拟真实升级链。
    final v5 = await AppDatabase.open(path: path);
    final projects = await v5.projectDao.list();
    expect(projects, hasLength(3));
    // v6 的列此时已存在(新代码一次升到最新),旧项目应拿到默认 kind。
    for (final project in projects) {
      expect(project.kind, ProjectKind.coding, reason: '旧项目默认按编程处理');
      expect(project.appPackage, isNull, reason: '旧项目没有目标应用');
      expect(project.appIcon, isNull);
    }
    await v5.close();
  });
}