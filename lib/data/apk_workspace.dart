import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/models/project.dart';
import '../agent/tools/workspace.dart';
import 'apk_files.dart';
import 'workspaces.dart';

/// 逆向项目的工作区:把目标 APK 解压出来,作为该项目的工作目录。
///
/// 解压是幂等的——目录里已有内容就直接复用,重复进入项目不会重复解包。
class ApkWorkspace {
  ApkWorkspace(this._ref);

  final Ref _ref;

  /// 进行中的解包任务(按项目):打开项目时自动解一次,用户可能又点了按钮,
  /// 两边并发写同一个目录会互相踩。这里让后来者等同一次结果。
  final Map<String, Future<String>> _running = {};

  /// 确保 [project] 的 APK 已解压,返回工作区目录。
  ///
  /// [force] 为 true 时先清空旧内容再解压(APK 更新后用)。
  Future<String> ensureExtracted(Project project, {bool force = false}) {
    final running = _running[project.id];
    if (running != null) return running;
    final task = _ensure(project, force: force).whenComplete(() {
      _running.remove(project.id);
    });
    _running[project.id] = task;
    return task;
  }

  Future<String> _ensure(Project project, {required bool force}) async {
    final apkPaths = project.apkPathsToExtract;
    if (apkPaths.isEmpty) {
      throw const ApkWorkspaceException('拿不到这个应用的安装包路径');
    }
    final dir = apkWorkspaceDir(_ref.read(workspaceProvider).rootPath, project.id);
    final target = Directory(dir);

    if (force && await target.exists()) {
      await target.delete(recursive: true);
    }
    if (await target.exists() && await _hasEntries(target)) {
      return dir;
    }
    await ApkFiles.extract(apkPaths, dir);
    return dir;
  }

  Future<bool> _hasEntries(Directory dir) async {
    await for (final entity in dir.list()) {
      entity.path;
      return true;
    }
    return false;
  }
}

class ApkWorkspaceException implements Exception {
  const ApkWorkspaceException(this.message);

  final String message;

  @override
  String toString() => message;
}

final apkWorkspaceProvider = Provider<ApkWorkspace>((ref) => ApkWorkspace(ref));

/// 某个逆向项目的工作区是否已就绪(目录里已有解压内容)。
///
/// 文件面板据此决定是显示进度还是直接列目录。
final apkWorkspaceReadyProvider = FutureProvider.family<bool, String>((ref, projectId) async {
  final dir = apkWorkspaceDir(ref.watch(workspaceProvider).rootPath, projectId);
  final target = Directory(dir);
  if (!await target.exists()) return false;
  await for (final _ in target.list()) {
    return true;
  }
  return false;
});
