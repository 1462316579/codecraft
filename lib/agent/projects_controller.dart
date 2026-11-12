import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/util/ids.dart';
import '../data/db/app_database.dart';
import '../data/db/daos.dart';
import 'models/chat_session.dart';
import 'models/project.dart';

final projectsProvider =
    AsyncNotifierProvider<ProjectsNotifier, List<Project>>(ProjectsNotifier.new);

/// 按 id 读取单个项目;依赖 [projectsProvider] 以便列表变更后自动刷新。
final projectByIdProvider = FutureProvider.family<Project?, String>((ref, id) async {
  await ref.watch(projectsProvider.future);
  return ref.read(databaseProvider).projectDao.get(id);
});

class ProjectsNotifier extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() => ref.watch(databaseProvider).projectDao.list();

  /// 新建项目(项目页右上角加号)。名称可重复,不做唯一约束。
  Future<Project> create({
    required String name,
    AgentMode mode = AgentMode.build,
    ProjectKind kind = ProjectKind.coding,
    String? appPackage,
    String? appName,
    String? appVersionName,
    int? appVersionCode,
    Uint8List? appIcon,
    String? appApkPath,
    List<String> appApkPaths = const [],
  }) async {
    final now = nowMs();
    final project = Project(
      id: newId(),
      name: name,
      createdAt: now,
      updatedAt: now,
      mode: mode,
      kind: kind,
      appPackage: appPackage,
      appName: appName,
      appVersionName: appVersionName,
      appVersionCode: appVersionCode,
      appIcon: appIcon,
      appApkPath: appApkPath,
      appApkPaths: appApkPaths,
    );
    await ref.read(databaseProvider).projectDao.upsert(project);
    ref.invalidateSelf();
    await future;
    return project;
  }

  Future<void> rename(String id, String name) =>
      _mutate(id, (p) => p.copyWith(name: name));

  /// 删项目:连同其下所有会话一起删(DAO 负责级联)。
  Future<void> remove(String id) async {
    await ref.read(databaseProvider).projectDao.delete(id);
    ref.invalidateSelf();
    await future;
  }

  /// 会话变动后把项目的更新时间顶上去,让项目列表按最近活跃排序。
  Future<void> touch(String id) => _mutate(id, (p) => p);

  Future<void> _mutate(String id, Project Function(Project) transform) async {
    final dao = ref.read(databaseProvider).projectDao;
    final project = await dao.get(id);
    if (project == null) return;
    await dao.upsert(transform(project).copyWith(updatedAt: nowMs()));
    ref.invalidateSelf();
    await future;
  }
}