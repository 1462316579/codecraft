import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 编辑器当前打开的文件(工作台右栏在宽屏下据此渲染编辑器)。
class EditorTarget {
  const EditorTarget({required this.path, this.line});

  /// 容器内绝对路径。
  final String path;

  /// 需要跳转的行号(1 起),null 表示从首行开始。
  final int? line;

  @override
  bool operator ==(Object other) =>
      other is EditorTarget && other.path == path && other.line == line;

  @override
  int get hashCode => Object.hash(path, line);
}

/// 最近一次「在编辑器中打开」的目标;为 null 时工作台编辑器栏显示空态。
final editorTargetProvider =
    NotifierProvider<EditorTargetController, EditorTarget?>(EditorTargetController.new);

class EditorTargetController extends Notifier<EditorTarget?> {
  @override
  EditorTarget? build() => null;

  void open(String path, {int? line}) => state = EditorTarget(path: path, line: line);

  void clear() => state = null;
}