import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'checkpoint_manager.dart';

import '../core/util/ids.dart';
import '../data/db/app_database.dart';
import '../data/db/daos.dart';
import 'models/chat_session.dart';

final sessionsProvider =
    AsyncNotifierProvider<SessionsNotifier, List<ChatSession>>(SessionsNotifier.new);

/// 按 id 读取单个会话;依赖 [sessionsProvider] 以便列表变更后自动刷新。
final sessionByIdProvider = FutureProvider.family<ChatSession?, String>((ref, id) async {
  await ref.watch(sessionsProvider.future);
  return ref.read(databaseProvider).sessionDao.get(id);
});

class SessionsNotifier extends AsyncNotifier<List<ChatSession>> {
  @override
  Future<List<ChatSession>> build() => ref.watch(databaseProvider).sessionDao.list();

  /// 新建会话;有可用供应商时默认选中第一个。
  ///
  /// [projectId] 为所属项目。只有项目页「新建项目」才建项目,
  /// 聊天页加号走这里,只在本项目内加一条会话。
  Future<ChatSession> create({
    AgentMode mode = AgentMode.build,
    String? projectId,
  }) async {
    final now = nowMs();
    final session = ChatSession(
      id: newId(),
      title: '',
      createdAt: now,
      updatedAt: now,
      providerId: null,
      model: '',
      mode: mode,
      projectId: projectId,
    );
    await ref.read(databaseProvider).sessionDao.upsert(session);
    ref.invalidateSelf();
    await future;
    return session;
  }


  Future<void> rename(String id, String title) => _mutate(id, (s) => s.copyWith(title: title));

  Future<void> togglePin(String id) => _mutate(id, (s) => s.copyWith(isPinned: !s.isPinned));

  Future<void> upsert(ChatSession session) async {
    await ref.read(databaseProvider).sessionDao.upsert(session);
    ref.invalidateSelf();
    await future;
  }

  Future<void> remove(String id) async {
    await ref.read(databaseProvider).sessionDao.delete(id);
    await _clearCheckpointFiles([id]);
    ref.invalidateSelf();
    await future;
  }

  /// 批量删除(多选模式用):一次刷新手,避免逐条 invalidate 引起列表闪动。
  Future<void> removeMany(Iterable<String> ids) async {
    final dao = ref.read(databaseProvider).sessionDao;
    for (final id in ids) {
      await dao.delete(id);
    }
    await _clearCheckpointFiles(ids);
    ref.invalidateSelf();
    await future;
  }

  /// 删掉会话的快照目录。记录已随 sessionDao.delete 删掉,这里只清磁盘文件;
  /// 失败不影响会话删除本身(残留目录只是占空间)。
  Future<void> _clearCheckpointFiles(Iterable<String> ids) async {
    try {
      final manager = await ref.read(checkpointManagerProvider.future);
      for (final id in ids) {
        await manager.clearSessionCheckpoints(id);
      }
    } catch (_) {}
  }

  Future<void> _mutate(String id, ChatSession Function(ChatSession) transform) async {
    final dao = ref.read(databaseProvider).sessionDao;
    final session = await dao.get(id);
    if (session == null) return;
    await dao.upsert(transform(session).copyWith(updatedAt: nowMs()));
    ref.invalidateSelf();
    await future;
  }
}