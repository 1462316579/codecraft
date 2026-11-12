import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/workspaces.dart';
import '../data/db/checkpoint_dao.dart';
import '../data/workspace_files.dart';
import 'file_version_registry.dart';
import 'tools/workspace.dart' show configDirProvider;

/// 一次代码回滚的结果。
///
/// [skipped] 是「快照之后存在本会话未见过的改动」而**跳过**的文件(展示用路径)。
/// 调用方必须把它展示给用户——静默跳过等于把数据丢失换成无声的失败。
class CheckpointRestoreResult {
  const CheckpointRestoreResult({required this.restored, required this.skipped});

  final int restored;
  final List<String> skipped;

  static const empty = CheckpointRestoreResult(restored: 0, skipped: []);
}

/// 检查点管理(对齐上游 CheckpointManager):在工具改文件前拍快照,支持按检查点回滚工作区。
///
/// 快照存放于 `<根目录>/checkpoints/<sessionId>/<checkpointId>/`,数据库只记元信息。
class CheckpointManager {
  CheckpointManager({
    required AppDatabase database,
    required Directory checkpointRoot,
    required Future<WorkspaceFiles> Function() files,
    FileVersionRegistry? versions,
    Future<String> Function()? workspaceRoot,
  })  : _db = database,
        _root = checkpointRoot,
        _files = files,
        _versions = versions ?? FileVersionRegistry(),
        _workspaceRoot = workspaceRoot;

  final AppDatabase _db;
  final Directory _root;
  final Future<WorkspaceFiles> Function() _files;
  final FileVersionRegistry _versions;

  /// 工作区根(用于把绝对路径折算成展示/记录用的相对路径)。
  /// 必须与实际记录版本时用的 key 保持同一基准,否则回滚的并发判定会因 key 不匹配而失效。
  final Future<String> Function()? _workspaceRoot;

  /// 活动检查点按会话隔离:多个会话会并行跑,用单一字段会被后创建的会话覆盖,
  /// 导致文件快照挂到别的会话名下,那个会话一撤销就会把本会话刚写好的文件还原/删除。
  final Map<String, String> _active = {};

  FileVersionRegistry get versions => _versions;

  /// 用户发出新消息时调用,创建检查点节点并设为该会话的活动检查点。
  Future<Checkpoint> createCheckpoint({
    required String sessionId,
    required String userMessageId,
    required String prompt,
  }) async {
    final snippet = prompt.length > 60 ? '${prompt.substring(0, 60)}...' : prompt;
    final checkpoint = Checkpoint(
      id: newCheckpointId(),
      sessionId: sessionId,
      userMessageId: userMessageId,
      promptSnippet: snippet,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _db.checkpointDao.insertCheckpoint(checkpoint);
    _active[sessionId] = checkpoint.id;
    return checkpoint;
  }

  void setActiveCheckpoint(String sessionId, String? checkpointId) {
    if (checkpointId == null) {
      _active.remove(sessionId);
    } else {
      _active[sessionId] = checkpointId;
    }
  }

  /// 工具(writeFile/editFile)将要修改或新建文件前调用。
  /// 同一检查点内对同一文件只保留最原始的一次快照。
  Future<void> beforeFileModified(String sessionId, String filePath) async {
    final checkpointId = _active[sessionId];
    if (checkpointId == null) return;
    if (await _db.checkpointDao.countSnapshot(checkpointId, filePath) > 0) return;

    final files = await _files();
    final exists = await files.exists(filePath);
    final changeType = exists ? 'MODIFY' : 'CREATE';

    final dir = Directory(p.join(_root.path, sessionId, checkpointId));
    await dir.create(recursive: true);
    final snapshotName = '${newCheckpointId()}_${p.basename(filePath)}';
    final snapshotFile = File(p.join(dir.path, snapshotName));

    // 指纹只是锦上添花:算不出来(文件过大、IO 异常)就留 null,
    // 回滚时按「未知版本」放行,不能因为它拿不到就让快照本身失败。
    String? fingerprint;
    if (exists) {
      final original = await files.readText(filePath);
      await snapshotFile.writeAsString(original);
      fingerprint = FileVersionRegistry.fingerprintOf(original);
    } else {
      await snapshotFile.writeAsString(''); // CREATE 的空占位
    }

    await _db.checkpointDao.insertFileSnapshot(CheckpointFileSnapshot(
      id: newCheckpointId(),
      checkpointId: checkpointId,
      filePath: filePath,
      snapshotRelativePath: p.join(sessionId, checkpointId, snapshotName),
      changeType: changeType,
      fingerprint: fingerprint,
    ));
  }

  /// 把工作区回滚到指定检查点的初始状态:收集目标及其之后的全部检查点,倒序还原。
  ///
  /// 并发保护的判定(详见 [FileVersionRegistry]):
  /// | 快照类型 | 条件 | 行为 |
  /// | --- | --- | --- |
  /// | MODIFY | 当前指纹 == 本会话记录的指纹,或本会话无记录 | 写回快照内容 |
  /// | MODIFY | 当前指纹 ≠ 本会话记录的指纹 | 存在本会话未见过的改动,跳过 |
  /// | MODIFY | 文件已被删除 | 按快照恢复 |
  /// | CREATE | 恒成立 | 删除该文件 |
  Future<CheckpointRestoreResult> restoreCodeToCheckpoint(
    String sessionId,
    String targetCheckpointId,
  ) async {
    final all = await _db.checkpointDao.listForSession(sessionId);
    final targetIndex = all.indexWhere((item) => item.id == targetCheckpointId);
    if (targetIndex == -1) return CheckpointRestoreResult.empty;

    final files = await _files();
    var restored = 0;
    final skipped = <String>[];

    for (final checkpoint in all.sublist(targetIndex).reversed) {
      final snapshots = await _db.checkpointDao.snapshotsFor(checkpoint.id);
      for (final snapshot in snapshots) {
        final snapshotFile = File(p.join(_root.path, snapshot.snapshotRelativePath));
        final displayPath = await _displayPath(snapshot.filePath);

        if (snapshot.isCreate) {
          // 创建快照意味着「这个文件是本会话新建的」,常规回滚就是删掉它。
          if (await files.exists(snapshot.filePath)) {
            await files.delete(snapshot.filePath);
            _versions.forget(sessionId, displayPath);
            restored++;
          }
          continue;
        }

        if (!await snapshotFile.exists()) continue;

        String? currentFingerprint;
        if (await files.exists(snapshot.filePath)) {
          currentFingerprint = FileVersionRegistry.fingerprintOf(
            await files.readText(snapshot.filePath),
          );
        }
        final knownFingerprint = _versions.get(sessionId, displayPath);
        if (currentFingerprint != null &&
            knownFingerprint != null &&
            currentFingerprint != knownFingerprint) {
          skipped.add(displayPath);
          continue;
        }

        await files.writeText(snapshot.filePath, await snapshotFile.readAsString());
        // 回滚是一次「外部写入」:所有会话手上的版本都过期了。
        final written = FileVersionRegistry.fingerprintOf(
          await files.readText(snapshot.filePath),
        );
        if (written != null) _versions.recordExternal(displayPath, written);
        restored++;
      }
    }
    return CheckpointRestoreResult(restored: restored, skipped: skipped);
  }

  /// 删除会话关联的全部检查点记录与快照目录。
  Future<void> clearSessionCheckpoints(String sessionId) async {
    _active.remove(sessionId);
    _versions.clearSession(sessionId);
    await _db.checkpointDao.deleteForSession(sessionId);
    final dir = Directory(p.join(_root.path, sessionId));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// 版本登记的 key:相对工作区根的路径(拿不到工作区根时退化为绝对路径)。
  ///
  /// 快照与版本记录必须用同一个 key,否则「本会话记录的版本」永远查不到,
  /// 并发判定会把外部改动也放行——静默覆盖别人的修改。
  Future<String> _displayPath(String filePath) async {
    final root = await _workspaceRoot?.call();
    if (root == null || root.isEmpty) return filePath;
    if (!filePath.startsWith(root)) return filePath;
    final relative = filePath.substring(root.length);
    return relative.startsWith(p.separator) ? relative.substring(1) : relative;
  }
}

/// 检查点 id(与快照文件名共用,无需额外的 uuid 依赖)。
String newCheckpointId() =>
    '${DateTime.now().microsecondsSinceEpoch}-${_counter++}';

int _counter = 0;

/// 检查点存储根目录:`<配置目录>/checkpoints`(与工作区同级,不污染工作区内容)。
final checkpointManagerProvider = FutureProvider<CheckpointManager>((ref) async {
  final database = ref.watch(databaseProvider);
  final root = Directory(p.join(ref.watch(configDirProvider), 'checkpoints'));
  if (!await root.exists()) await root.create(recursive: true);
  return CheckpointManager(
    database: database,
    checkpointRoot: root,
    files: () => ref.read(workspaceFilesProvider.future),
    workspaceRoot: () async => ref.read(currentWorkspaceProvider).rootPath,
  );
});

/// 回退三选项(对齐上游 RewindOption)。
enum RewindOption {
  /// 同时还原代码 + 删除其后会话,并把提问回填输入框。
  codeAndConversation,

  /// 只删除其后会话,并把提问回填输入框。
  conversation,

  /// 只还原代码,会话不动。
  code,
}
