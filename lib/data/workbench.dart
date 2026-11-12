import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/browser/browser_page.dart';
import '../l10n/app_localizations.dart';
import 'editor_target.dart';
import '../features/editor/editor_page.dart';
import '../features/git/git_page.dart';
import '../features/terminal/terminal_page.dart';

/// 工作台右栏内容类型(对照上游 `WorkbenchPaneKind`)。
enum WorkbenchPaneKind { none, editor, terminal, git, browser }

/// 工作台状态:右栏类型 + 左右分栏比例(上游 `paneKind` / `paneSplit`)。
class WorkbenchState {
  const WorkbenchState({this.kind = WorkbenchPaneKind.none, this.split = defaultSplit});

  /// 默认左右各半(上游 DEFAULT_PANE_SPLIT = 0.5f)。
  static const double defaultSplit = 0.5;

  final WorkbenchPaneKind kind;
  final double split;

  bool get open => kind != WorkbenchPaneKind.none;

  WorkbenchState copyWith({WorkbenchPaneKind? kind, double? split}) =>
      WorkbenchState(
        kind: kind ?? this.kind,
        split: (split ?? this.split).clamp(0.25, 0.75),
      );
}

/// 工作台控制器(对齐上游 `openWorkbench`):点同一类型再次收起。
class WorkbenchController extends Notifier<WorkbenchState> {
  @override
  WorkbenchState build() => const WorkbenchState();

  void open(WorkbenchPaneKind kind) {
    state = state.copyWith(
      kind: state.kind == kind ? WorkbenchPaneKind.none : kind,
    );
  }

  void close() => state = state.copyWith(kind: WorkbenchPaneKind.none);

  void setSplit(double split) => state = state.copyWith(split: split);
}

final workbenchProvider =
    NotifierProvider<WorkbenchController, WorkbenchState>(WorkbenchController.new);

/// 打开右栏或跳转整屏路由(对齐上游 openWorkbench 的宽窄分支)。
void openWorkbench(
  BuildContext context,
  WidgetRef ref,
  WorkbenchPaneKind kind,
  bool wide,
) {
  if (wide) {
    ref.read(workbenchProvider.notifier).open(kind);
    return;
  }
  switch (kind) {
    case WorkbenchPaneKind.terminal:
      context.push('/terminal');
    case WorkbenchPaneKind.browser:
      context.push('/browser');
    case WorkbenchPaneKind.git:
      context.push('/git');
    case WorkbenchPaneKind.editor:
      // 窄屏没有右栏,直接跳整屏编辑器;目标由调用方先写入 editorTargetProvider。
      final target = ref.read(editorTargetProvider);
      if (target == null) {
        context.push('/chat');
      } else {
        context.push(
          '/editor?path=${Uri.encodeQueryComponent(target.path)}'
          '${target.line == null ? '' : '&line=${target.line}'}',
        );
      }
    default:
      context.push('/chat');
  }
}

/// 右栏内容(对齐上游 `WorkbenchPaneContent`)。
class WorkbenchPaneContent extends ConsumerWidget {
  const WorkbenchPaneContent({super.key, required this.kind});

  final WorkbenchPaneKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (kind) {
        WorkbenchPaneKind.browser => const BrowserPage(embedded: true),
        WorkbenchPaneKind.terminal => const TerminalPage(),
        WorkbenchPaneKind.git => const GitPage(embedded: true),
        WorkbenchPaneKind.editor => _EditorPane(),
        _ => const SizedBox.shrink(),
      };
}

/// 右栏外壳:顶部分隔线 + 内容。
class WorkbenchPane extends StatelessWidget {
  const WorkbenchPane({super.key, required this.kind});

  final WorkbenchPaneKind kind;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const Divider(height: 1),
          Expanded(child: WorkbenchPaneContent(kind: kind)),
        ],
      );
}

/// 编辑器栏:还没有打开目标时给一句引导,避免出现空白面板。
class _EditorPane extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(editorTargetProvider);
    if (target == null) {
      return Center(
        child: Text(
          AppLocalizations.of(context).editorNoFile,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }
    return EditorPage(
      path: target.path,
      line: target.line,
      embedded: true,
      // 右栏的关闭键收回右栏,而不是退出聊天页。
      onNavigateBack: () => ref.read(workbenchProvider.notifier).close(),
    );
  }
}
