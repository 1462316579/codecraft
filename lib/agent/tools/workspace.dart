import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 当前工作区目录;main() 中 override 为已打开的实例,测试可指向临时目录。
final workspaceProvider = Provider<Workspace>((ref) => throw StateError('workspaceProvider 需在 ProviderScope.overrides 中注入'));

/// 应用配置目录:全局技能与全局配置的根,取应用私有目录本身。
final configDirProvider = Provider<String>(
  (ref) => ref.watch(workspaceProvider).rootPath,
);

/// 打开(必要时创建)应用私有目录作为工作区根,文件直接落在目录下。
Future<Workspace> openWorkspace() async {
  final docs = await getApplicationDocumentsDirectory();
  final root = Directory(docs.path);
  if (!await root.exists()) {
    await root.create(recursive: true);
  }
  return Workspace(root.path);
}

/// 工作区根:应用私有目录本身。
///
/// 路径解析规则:
/// - 绝对路径(`/...`)直接规范化后返回;
/// - 相对路径按工作区根解析,不允许越界 `..`;
/// - 不再支持 `~/workspace/...` 等逻辑前缀。
class Workspace {
  Workspace(this.rootPath);

  final String rootPath;

  /// 把模型给的路径解析为可访问的绝对路径。
  String resolve(String input) {
    var path = input.trim();
    if (path.isEmpty) {
      throw const ToolPathException('路径为空');
    }

    // 绝对路径:直接规范化后返回。
    if (path.startsWith('/')) {
      return p.normalize(path);
    }

    // 相对路径按工作区根解析,不允许越界。
    final resolved = p.normalize(p.join(rootPath, path));
    if (resolved != rootPath && !resolved.startsWith('$rootPath${p.separator}')) {
      throw ToolPathException('路径越出工作区:$input');
    }
    return resolved;
  }

  /// 工作区绝对路径原样返回。
  String display(String absolutePath) => p.normalize(absolutePath);
}

class ToolPathException implements Exception {
  const ToolPathException(this.message);

  final String message;

  @override
  String toString() => message;
}
