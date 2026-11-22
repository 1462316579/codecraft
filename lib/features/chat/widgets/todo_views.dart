import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../agent/models/todo_item.dart';
import '../../../core/icons/iconfont.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/todos.dart';
import '../../../g11n/app_globalizations.dart';

/// 位于输入框上方的待办任务常驻面板(对齐上游 TodoDashboardBar):
/// 仅在当前会话有待办项时显示;折叠为单行摘要,展开可看完整列表。
class TodoDashboardBar extends ConsumerStatefulWidget {
  const TodoDashboardBar({
    super.key,
    required this.sessionId,
    this.forceCollapse = false,
  });

  final String sessionId;

  /// 授权弹层等叠加时强制收起(上游 forceCollapse)。
  final bool forceCollapse;

  @override
  ConsumerState<TodoDashboardBar> createState() => _TodoDashboardBarState();
}

class _TodoDashboardBarState extends ConsumerState<TodoDashboardBar> {
  bool _expanded = false;

  @override
  void didUpdateWidget(TodoDashboardBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 展开状态按会话隔离记忆,新会话默认收起(对齐上游 rememberSaveable(sessionId))。
    if (oldWidget.sessionId != widget.sessionId) _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final items =
        ref.watch(sessionTodosProvider(widget.sessionId)).valueOrNull ?? const <TodoItem>[];
    if (items.isEmpty) return const SizedBox.shrink();

    final g11n = AppGlobalizations.of(context);
    final theme = Theme.of(context);
    final expanded = _expanded && !widget.forceCollapse;
    final completed = items.where((item) => item.status == TodoStatus.completed).length;
    final allDone = completed == items.length;
    TodoItem? inProgress;
    for (final item in items) {
      if (item.status == TodoStatus.inProgress) {
        inProgress = item;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xs),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(width: 1, color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(Radii.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Iconfont.checkSquare, size: 15, color: theme.colorScheme.primary),
                    const SizedBox(width: Spacing.xs),
                    Text(
                      g11n.todoDashboardTitle,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: allDone
                            ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.6)
                            : theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(Radii.xs),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        allDone
                            ? g11n.todoDashboardAllDone
                            : g11n.todoDashboardProgress(completed, items.length),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    if (!expanded && inProgress != null) ...[
                      const SizedBox(width: Spacing.xs),
                      Expanded(
                        child: Text(
                          inProgress.subject,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    Icon(
                      expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: !expanded
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: Spacing.xs),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var index = 0; index < items.length; index++) ...[
                                if (index > 0) const SizedBox(height: 4),
                                TodoItemRow(item: items[index].toSnapshotItem()),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 待办列表结构化卡片(工具结果里的 todo 快照)。
class TodoCard extends StatelessWidget {
  const TodoCard({super.key, required this.items});

  final List<TodoSnapshotItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const SizedBox(height: 2),
          TodoItemRow(item: items[index]),
        ],
      ],
    );
  }
}

/// 单条待办项行:状态图标 + 标题 + 状态标签(对齐上游 TodoItemRow)。
class TodoItemRow extends StatelessWidget {
  const TodoItemRow({super.key, required this.item});

  final TodoSnapshotItem item;

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final isCompleted = item.status == TodoStatus.completed;
    final isInProgress = item.status == TodoStatus.inProgress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (isCompleted)
              Icon(
                Iconfont.check,
                size: 16,
                color: semantic.diffAdd,
                semanticLabel: g11n.todoCompleted,
              )
            else if (isInProgress)
              const _PulsingDot()
            else
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(width: 1.5, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                item.subject,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isCompleted
                      ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                      : theme.colorScheme.onSurface,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isInProgress) ...[
              const SizedBox(width: Spacing.xs),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(Radii.xs),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                child: Text(
                  g11n.todoInProgress,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
            ],
          ],
        ),
        if (item.description.isNotEmpty && !isCompleted) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              item.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

/// 进行中待办的状态点:8dp 圆点,透明度 1→0.3 往复(上游 650ms 呼吸)。
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.3).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}