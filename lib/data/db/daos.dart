import 'checkpoint_dao.dart';
import 'package:sqflite/sqflite.dart';

import '../../agent/models/agent_message.dart';
import '../../agent/models/chat_session.dart';
import '../../agent/models/project.dart';
import '../../agent/models/todo_item.dart';
import '../providers/provider_config.dart';
import 'app_database.dart';
import 'llm_call_records.dart';

class SessionDao {
  SessionDao(this._db);

  final AppDatabase _db;

  /// 主会话列表(子代理会话不出现,靠子代理卡片「进入会话」打开)。
  Future<List<ChatSession>> list() async {
    final rows = await _db.db.query(
      'chat_sessions',
      where: 'parentId IS NULL',
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return rows.map(ChatSession.fromMap).toList();
  }

  /// 某个父会话的全部子代理会话(TaskTool list 用)。
  Future<List<ChatSession>> getSubSessionsByParentOnce(String parentId) async {
    final rows = await _db.db.query(
      'chat_sessions',
      where: 'parentId = ?',
      whereArgs: [parentId],
      orderBy: 'updatedAt DESC',
    );
    return rows.map(ChatSession.fromMap).toList();
  }

  /// 某个项目下的会话(侧栏用)。
  Future<List<ChatSession>> listByProject(String projectId) async {
    final rows = await _db.db.query(
      'chat_sessions',
      where: 'projectId = ? AND parentId IS NULL',
      whereArgs: [projectId],
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return rows.map(ChatSession.fromMap).toList();
  }

  Future<ChatSession?> get(String id) async {
    final rows = await _db.db.query('chat_sessions', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : ChatSession.fromMap(rows.first);
  }

  Future<void> upsert(ChatSession session) =>
      _db.db.insert('chat_sessions', session.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> delete(String id) async {
    // 子代理会话随父会话一并删除,避免孤儿。
    final subRows = await _db.db.query(
      'chat_sessions',
      columns: ['id'],
      where: 'parentId = ?',
      whereArgs: [id],
    );
    for (final row in subRows) {
      final subId = row['id'] as String;
      await _db.db.delete('chat_sessions', where: 'id = ?', whereArgs: [subId]);
      await _db.db.delete('agent_messages', where: 'sessionId = ?', whereArgs: [subId]);
      await _db.db.delete('todo_items', where: 'sessionId = ?', whereArgs: [subId]);
      await _db.checkpointDao.deleteForSession(subId);
    }
    await _db.db.delete('chat_sessions', where: 'id = ?', whereArgs: [id]);
    await _db.db.delete('agent_messages', where: 'sessionId = ?', whereArgs: [id]);
    await _db.db.delete('todo_items', where: 'sessionId = ?', whereArgs: [id]);
    // 检查点记录一并删(快照目录由 sessions_controller 负责)。
    await _db.checkpointDao.deleteForSession(id);
  }
}

class ProjectDao {
  ProjectDao(this._db);

  final AppDatabase _db;

  Future<List<Project>> list() async {
    final rows = await _db.db.query('projects', orderBy: 'updatedAt DESC');
    return rows.map(Project.fromMap).toList();
  }

  Future<Project?> get(String id) async {
    final rows = await _db.db.query('projects', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Project.fromMap(rows.first);
  }

  Future<void> upsert(Project project) =>
      _db.db.insert('projects', project.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  /// 删项目时连同其下所有会话(会话自身的消息、待办、检查点由 SessionDao.delete 清理)。
  Future<void> delete(String id) async {
    final sessions = await _db.db.query(
      'chat_sessions',
      where: 'projectId = ?',
      whereArgs: [id],
    );
    for (final row in sessions) {
      final sessionId = row['id'] as String;
      await _db.db.delete('chat_sessions', where: 'id = ?', whereArgs: [sessionId]);
      await _db.db.delete('agent_messages', where: 'sessionId = ?', whereArgs: [sessionId]);
      await _db.db.delete('todo_items', where: 'sessionId = ?', whereArgs: [sessionId]);
      await _db.checkpointDao.deleteForSession(sessionId);
    }
    await _db.db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }
}

class MessageDao {
  MessageDao(this._db);

  final AppDatabase _db;

  /// 按时间升序列出会话消息;[limit] 非空时取**最新的** [limit] 条(仍按升序返回),
  /// 供聊天页分页加载与向上补载更早消息。
  Future<List<AgentMessage>> listBySession(String sessionId, {int? limit}) async {
    final rows = limit == null
        ? await _db.db.query(
            'agent_messages',
            where: 'sessionId = ?',
            whereArgs: [sessionId],
            orderBy: 'timestamp ASC',
          )
        : (await _db.db.rawQuery(
            'SELECT * FROM agent_messages WHERE sessionId = ? '
            'ORDER BY timestamp DESC LIMIT ?',
            [sessionId, limit],
          )).reversed.toList();
    return rows.map(AgentMessage.fromMap).toList();
  }

  Future<int> countBySession(String sessionId) async {
    final rows = await _db.db.rawQuery(
      'SELECT COUNT(*) AS n FROM agent_messages WHERE sessionId = ?',
      [sessionId],
    );
    return (rows.first['n'] as int?) ?? 0;
  }

  Future<void> insert(AgentMessage message) =>
      _db.db.insert('agent_messages', message.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> update(AgentMessage message) => _db.db.update(
        'agent_messages',
        message.toMap(),
        where: 'id = ?',
        whereArgs: [message.id],
      );

  Future<void> delete(String id) =>
      _db.db.delete('agent_messages', where: 'id = ?', whereArgs: [id]);

  /// 删除该时间点及其之后的消息。含等于:目标消息自身属于「被回退掉的那一轮」,一起删。
  Future<void> deleteFromTimestamp(String sessionId, int timestamp) => _db.db.delete(
        'agent_messages',
        where: 'sessionId = ? AND timestamp >= ?',
        whereArgs: [sessionId, timestamp],
      );

  /// 提交一次上下文压缩:head 消息标记为已压缩(回放与渲染跳过),插入 marker 与
  /// 摘要两条新消息。整个操作一个事务,失败则全部回滚(对齐上游 commitCompaction)。
  Future<void> commitCompaction({
    required String sessionId,
    required List<String> headIds,
    required AgentMessage marker,
    required AgentMessage summary,
    required String summaryId,
  }) async {
    await _db.db.transaction((txn) async {
      for (final id in headIds) {
        await txn.rawUpdate(
          'UPDATE agent_messages SET isCompacted = 1, compactedBySummaryId = ? WHERE id = ?',
          [summaryId, id],
        );
      }
      await txn.insert(
        'agent_messages',
        marker.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        'agent_messages',
        summary.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }
}

class ProviderDao {
  ProviderDao(this._db);

  final AppDatabase _db;

  Future<List<ProviderConfig>> list() async {
    final rows = await _db.db.query('providers', orderBy: 'sortOrder ASC');
    return rows
        .map((row) => ProviderConfig.fromJson(row['json'] as String))
        .toList();
  }

  Future<void> upsert(ProviderConfig config, {int? sortOrder}) async {
    final rows =
        await _db.db.query('providers', where: 'id = ?', whereArgs: [config.id], limit: 1);
    final order = sortOrder ??
        (rows.isEmpty
            ? (await _db.db.rawQuery('SELECT MAX(sortOrder) AS m FROM providers')).first['m'] as int?
                ?? -1
            : rows.first['sortOrder'] as int);
    await _db.db.insert(
      'providers',
      {'id': config.id, 'json': config.toJson(), 'sortOrder': order + (rows.isEmpty ? 1 : 0)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) =>
      _db.db.delete('providers', where: 'id = ?', whereArgs: [id]);

  /// 按给定顺序重写排序号(长按拖拽调整后调用)。
  Future<void> reorder(List<String> idsInOrder) async {
    final batch = _db.db.batch();
    for (var index = 0; index < idsInOrder.length; index++) {
      batch.update(
        'providers',
        {'sortOrder': index},
        where: 'id = ?',
        whereArgs: [idsInOrder[index]],
      );
    }
    await batch.commit(noResult: true);
  }
}

class TodoDao {
  TodoDao(this._db);

  final AppDatabase _db;

  Future<List<TodoItem>> listBySession(String sessionId) async {
    final rows = await _db.db.query(
      'todo_items',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: '`order` ASC, priority DESC',
    );
    return rows.map(TodoItem.fromMap).toList();
  }

  /// 快照式替换:先清空会话内全部待办,再写入本次列表。
  Future<void> replaceAll(String sessionId, List<TodoItem> items) async {
    await _db.db.delete('todo_items', where: 'sessionId = ?', whereArgs: [sessionId]);
    for (final item in items) {
      await _db.db.insert('todo_items', item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> deleteBySession(String sessionId) =>
      _db.db.delete('todo_items', where: 'sessionId = ?', whereArgs: [sessionId]);
}

extension AppDatabaseDaos on AppDatabase {
  SessionDao get sessionDao => SessionDao(this);
  ProjectDao get projectDao => ProjectDao(this);
  MessageDao get messageDao => MessageDao(this);
  ProviderDao get providerDao => ProviderDao(this);
  TodoDao get todoDao => TodoDao(this);
  LlmCallRecordDao get llmCallDao => LlmCallRecordDao(db);
}