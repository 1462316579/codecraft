import 'package:flutter/material.dart';

import '../../../agent/checkpoint_manager.dart';
import '../../../core/icons/iconfont.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../g11n/app_globalizations.dart';

/// 回退选项弹层(对齐上游 RewindOptionsBottomSheet):三选一 + 目标提示词摘要。
Future<RewindOption?> showRewindOptionsSheet(
  BuildContext context, {
  required String promptSnippet,
}) {
  return showModalBottomSheet<RewindOption>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: context.semantic.cardSurface,
    builder: (sheetContext) {
      final g11n = AppGlobalizations.of(sheetContext);
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                g11n.checkpointRewindTitle,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (promptSnippet.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  g11n.checkpointTargetPrompt(promptSnippet),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: Spacing.md),
              _OptionRow(
                icon: Iconfont.rotateCcw,
                title: g11n.checkpointRestoreCodeAndConversation,
                description: g11n.checkpointRestoreCodeAndConversationDesc,
                onTap: () => Navigator.pop(sheetContext, RewindOption.codeAndConversation),
              ),
              _OptionRow(
                icon: Iconfont.messageSquare,
                title: g11n.checkpointRestoreConversation,
                description: g11n.checkpointRestoreConversationDesc,
                onTap: () => Navigator.pop(sheetContext, RewindOption.conversation),
              ),
              _OptionRow(
                icon: Iconfont.fileText,
                title: g11n.checkpointRestoreCode,
                description: g11n.checkpointRestoreCodeDesc,
                onTap: () => Navigator.pop(sheetContext, RewindOption.code),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.mdLarge),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xs, vertical: Spacing.sm),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
