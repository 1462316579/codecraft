import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

/// 一个检查点:对应某条用户消息发出前的状态(对齐上游 CheckpointEntity)。
class Checkpoint {
  const Checkpoint({
    required this.id,
    required this.sessionId,
    required this.userMessageId,
    required this.promptSnippet,
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final String userMessageId;

  /// 触发该检查点的用户提示词前 60 字,回退弹层里展示「回退到:……」。
  final String promptSnippet;
  final int createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'sessionId': sessionId,
        'userMessageId': userMessageId,
        'promptSnippet': promptSnippet,
        'createdAt': createdAt,
      };

  static Checkpoint fromMap(Map<String, Object?> map) => Checkpoint(
        id: map['id'] as String,
        sessionId: map['sessionId'] as String,
        userMessageId: map['userMessageId'] as String,
        promptSnippet: map['promptSnippet'] as String,
        createdAt: map['createdAt'] as int,
      );
}

/// 单个文件在某个检查点里的原始状态(对齐上游 CheckpointFileSnapshotEntity)。
///
/// [changeType] 为 `MODIFY`(快照时文件已存在,[snapshotRelativePath] 存原内容)
/// 或 `CREATE`(快照时文件不存在,回滚时删除它)。
class CheckpointFileSnapshot {
  const CheckpointFileSnapshot({
    required this.id,
    required this.checkpointId,
    required this.filePath,
    required this.snapshotRelativePath,
    required this.changeType,
    this.fingerprint,
  });

  final String id;
  final String checkpointId;

  /// 文件的绝对路径(AI 视角的路径,回滚时直接写回这里)。
  final String filePath;

  /// 快照内容相对 `<documents>/checkpoints/` 的路径。
  final String snapshotRelativePath;

  /// `MODIFY` 或 `CREATE`。
  final String changeType;

  /// 拍摄时的内容指纹;CREATE 时必为 null(文件尚不存在)。
  final String? fingerprint;

  bool get isCreate => changeType == 'CREATE';

  Map<String, Object?> toMap() => {
        'id': id,
        'checkpointId': checkpointId,
        'filePath': filePath,
        'snapshotRelativePath': snapshotRelativePath,
        'changeType': changeType,
        'fingerprint': fingerprint,
      };

  static CheckpointFileSnapshot fromMap(Map<String, Object?> map) => CheckpointFileSnapshot(
        id: map['id'] as String,
        checkpointId: map['checkpointId'] as String,
        filePath: map['filePath'] as String,
        snapshotRelativePath: map['snapshotRelativePath'] as String,
        changeType: map['changeType'] as String,
        fingerprint: map['fingerprint'] as String?,
      );
}

/// 检查点与文件快照的读写(对齐上游 CheckpointDao)。
class CheckpointDao {
  CheckpointDao(this._db);

  final AppDatabase _db;

  Future<void> insertCheckpoint(Checkpoint checkpoint) => _db.db.insert(
        'checkpoints',
        checkpoint.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  /// 按创建时间升序取会话的全部检查点:回滚时据此确定「目标及其之后」的范围。
  Future<List<Checkpoint>> listForSession(String sessionId) async {
    final rows = await _db.db.query(
      'checkpoints',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'createdAt ASC',
    );
    return rows.map(Checkpoint.fromMap).toList();
  }

  Future<Checkpoint?> findByMessage(String sessionId, String userMessageId) async {
    final rows = await _db.db.query(
      'checkpoints',
      where: 'sessionId = ? AND userMessageId = ?',
      whereArgs: [sessionId, userMessageId],
      limit: 1,
    );
    return rows.isEmpty ? null : Checkpoint.fromMap(rows.first);
  }

  /// 同一检查点内对同一文件只保留最原始的一次快照,重复拍摄前先查重。
  Future<int> countSnapshot(String checkpointId, String filePath) async {
    final rows = await _db.db.query(
      'checkpoint_file_snapshots',
      columns: ['id'],
      where: 'checkpointId = ? AND filePath = ?',
      whereArgs: [checkpointId, filePath],
      limit: 1,
    );
    return rows.length;
  }

  Future<void> insertFileSnapshot(CheckpointFileSnapshot snapshot) => _db.db.insert(
        'checkpoint_file_snapshots',
        snapshot.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<List<CheckpointFileSnapshot>> snapshotsFor(String checkpointId) async {
    final rows = await _db.db.query(
      'checkpoint_file_snapshots',
      where: 'checkpointId = ?',
      whereArgs: [checkpointId],
    );
    return rows.map(CheckpointFileSnapshot.fromMap).toList();
  }

  Future<void> deleteForSession(String sessionId) async {
    final batch = _db.db.batch();
    batch.rawDelete(
      'DELETE FROM checkpoint_file_snapshots WHERE checkpointId IN '
      '(SELECT id FROM checkpoints WHERE sessionId = ?)',
      [sessionId],
    );
    batch.delete('checkpoints', where: 'sessionId = ?', whereArgs: [sessionId]);
    await batch.commit(noResult: true);
  }
}

extension CheckpointDaoAccess on AppDatabase {
  CheckpointDao get checkpointDao => CheckpointDao(this);
}
