import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'codespaces_engine.dart';
import 'container/container_engine_provider.dart';
import 'container/command_engine.dart';
import 'workspaces.dart';

/// 命令与终端的执行环境(对齐上游 `ExecutionMode`):本地 PRoot 容器,或某个 GitHub Codespace。
///
/// 只存在内存里(同上游 ExecutionModeHolder 不落盘):codespace 可能已被删除或停机,
/// 持久化一个失效目标只会让下次启动莫名其妙地报错。
sealed class ExecutionTarget {
  const ExecutionTarget();

  /// 界面展示名。
  String get label;

  /// 是否为远程 Codespace(终端页据此提示)。
  bool get isRemote;
}

/// 本地容器(默认)。
class LocalExecutionTarget extends ExecutionTarget {
  const LocalExecutionTarget();

  @override
  String get label => '本地容器';

  @override
  bool get isRemote => false;

  @override
  bool operator ==(Object other) => other is LocalExecutionTarget;

  @override
  int get hashCode => 0;
}

/// 某个 Codespace(命令经本地容器里的 gh 隧道到远端执行)。
class CodespaceExecutionTarget extends ExecutionTarget {
  const CodespaceExecutionTarget({required this.name, this.repository = ''});

  /// Codespace 名(API 里的 `name`)。
  final String name;

  /// 仓库全名(`owner/repo`),仅用于展示。
  final String repository;

  @override
  String get label => repository.trim().isEmpty ? name : repository;

  @override
  bool get isRemote => true;

  @override
  bool operator ==(Object other) =>
      other is CodespaceExecutionTarget && other.name == name && other.repository == repository;

  @override
  int get hashCode => Object.hash(name, repository);
}

final executionTargetProvider =
    NotifierProvider<ExecutionTargetController, ExecutionTarget>(ExecutionTargetController.new);

/// 执行环境选择(内存态)。
class ExecutionTargetController extends Notifier<ExecutionTarget> {
  @override
  ExecutionTarget build() => const LocalExecutionTarget();

  void useLocal() => state = const LocalExecutionTarget();

  void useCodespace(String name, {String repository = ''}) =>
      state = CodespaceExecutionTarget(name: name, repository: repository);
}

/// 跟随当前执行环境的命令引擎:本地容器,或包一层 gh 隧道的 [CodespacesEngine]。
final executionEngineProvider = FutureProvider<CommandEngine>((ref) async {
  final local = await ref.read(containerEngineProvider);
  final target = ref.watch(executionTargetProvider);
  return switch (target) {
    LocalExecutionTarget() => local,
    CodespaceExecutionTarget(:final name) => CodespacesEngine(
        transport: local,
        codespace: name,
        // 命令的 workdir 与文件路径都按工作区根映射到 codespace 的同一位置。
        localRoot: ref.watch(currentWorkspaceProvider).rootPath,
      ),
  };
});