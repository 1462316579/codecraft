import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../agent/models/project.dart';
import '../agent/tools/workspace.dart';
import '../app/current_project.dart';
import 'container/external_storage.dart';
import 'novel_project.dart';

/// 工作区来源:容器内沙盒、手机外部存储。
enum WorkspaceKind { internal, external }

/// 一个工作区:名称 + 目录路径 + 来源 + 归属项目(可选)。
class WorkspaceInfo {
  const WorkspaceInfo({
    required this.name,
    required this.path,
    this.kind = WorkspaceKind.internal,
    this.projectId,
  });

  final String name;
  final String path;
  final WorkspaceKind kind;
  final String? projectId;

  bool get isExternal => kind == WorkspaceKind.external;
}

/// 写作模式的默认外部目录(位于主存储根下)。
const String writingWorkspaceName = 'AI小说';

class WorkspacesState {
  const WorkspacesState({required this.workspaces});

  final List<WorkspaceInfo> workspaces;
}

/// 当前工作区:按项目类型与执行环境派生,不保存「当前选中哪个」这类可变状态。
///
/// 项目决定模式,模式决定目录:
/// - 编程 + 本地容器: 容器根/`<项目名>`(按项目隔离,不再共享)
/// - 写作: 外部存储 `/storage/emulated/0/AI小说/<小说名>`
/// - 逆向: 容器根/`apk-<项目 id>`
/// - 无当前项目: 容器根目录
final currentWorkspaceProvider = Provider<Workspace>((ref) {
  final project = ref.watch(currentProjectProvider);
  if (project == null) {
    return Workspace(ref.watch(workspaceProvider).rootPath);
  }

  switch (project.kind) {
    case ProjectKind.reverse:
      return Workspace(apkWorkspaceDir(ref.watch(workspaceProvider).rootPath, project.id));
    case ProjectKind.writing:
      // 每部小说一个目录:外部存储 AI小说/<小说名>。
      final workspaces = ref.watch(workspacesProvider).valueOrNull?.workspaces;
      final external = workspaces?.where((w) => w.isExternal).firstOrNull;
      if (external != null) {
        return Workspace(writingProjectDir(external.path, project.name));
      }
      return Workspace(ref.watch(workspaceProvider).rootPath);
    case ProjectKind.coding:
      // 容器内按项目隔离:直接位于容器根下,不加 workspace 前缀
      return Workspace(p.join(ref.watch(workspaceProvider).rootPath, project.name));
  }
});

/// 当前工作区的只读元信息(用于 UI 标签显示)。
final currentWorkspaceInfoProvider = Provider<WorkspaceInfo?>((ref) {
  final project = ref.watch(currentProjectProvider);
  if (project == null) return null;

  WorkspaceInfo? info;
  switch (project.kind) {
    case ProjectKind.reverse:
      info = WorkspaceInfo(
        name: '逆向: ${project.name}',
        path: apkWorkspaceDir(ref.watch(workspaceProvider).rootPath, project.id),
        kind: WorkspaceKind.internal,
        projectId: project.id,
      );
    case ProjectKind.writing:
      final workspaces = ref.watch(workspacesProvider).valueOrNull?.workspaces;
      final external = workspaces?.where((w) => w.isExternal).firstOrNull;
      if (external != null) {
        info = WorkspaceInfo(
          name: project.name,
          path: writingProjectDir(external.path, project.name),
          kind: WorkspaceKind.external,
          projectId: project.id,
        );
      }
    case ProjectKind.coding:
      info = WorkspaceInfo(
        name: project.name,
        path: p.join(ref.watch(workspaceProvider).rootPath, project.name),
        kind: WorkspaceKind.internal,
        projectId: project.id,
      );
  }
  return info;
});

/// 逆向项目的工作区目录:按项目 id 隔离,直接位于容器根目录下,不加 workspace 前缀。
String apkWorkspaceDir(String sandboxRoot, String projectId) =>
    p.join(sandboxRoot, 'apk-$projectId');

/// 写作项目的工作区目录:外部存储的 AI小说 根下按小说名隔离。
String writingProjectDir(String externalRoot, String title) =>
    p.join(externalRoot, NovelScaffold.dirName(title));

/// 工作区列表(供文件树等 UI 列举可用的工作区根目录):internal + external。
final workspacesProvider =
    AsyncNotifierProvider<WorkspacesNotifier, WorkspacesState>(WorkspacesNotifier.new);

class WorkspacesNotifier extends AsyncNotifier<WorkspacesState> {
  String get _internalRoot => ref.read(workspaceProvider).rootPath;

  @override
  Future<WorkspacesState> build() async {
    final workspaces = <WorkspaceInfo>[
      WorkspaceInfo(
        name: '容器',
        path: _internalRoot,
        kind: WorkspaceKind.internal,
      ),
    ];

    // 外部写作目录尽力创建:首次使用写作项目时它还不存在,不建就会一进去就报错。
    // 没有存储权限时创建会失败,此时不阻塞——文件面板会给出授权提示。
    final externalPath = p.join(await ExternalStorage.primaryRoot(), writingWorkspaceName);
    try {
      final external = Directory(externalPath);
      if (!await external.exists()) await external.create(recursive: true);
    } catch (_) {
      // 权限不足等情况:留给文件面板提示,不影响工作区本身可用。
    }
    workspaces.add(
      WorkspaceInfo(
        name: writingWorkspaceName,
        path: externalPath,
        kind: WorkspaceKind.external,
      ),
    );

    return WorkspacesState(workspaces: workspaces);
  }
}
