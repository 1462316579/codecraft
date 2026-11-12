import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/semantic_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// 「更多选项」弹层的动作。复制已在气泡下方常驻,这里不再重复提供。
enum MessageAction { edit, delete }

/// 消息「更多选项」弹层:编辑 / 删除。
Future<MessageAction?> showMessageActionsSheet(BuildContext context) {
  return showModalBottomSheet<MessageAction>(
    context: context,
    showDragHandle: true,
    backgroundColor: context.semantic.cardSurface,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext);
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.sm),
                child: Text(
                  l10n.chatMoreOptions,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: Spacing.xs),
            _ActionItem(
              icon: LucideIcons.pencil,
              title: l10n.chatActionEdit,
              onTap: () => Navigator.pop(sheetContext, MessageAction.edit),
            ),
            _ActionItem(
              icon: LucideIcons.trash2,
              title: l10n.chatActionDelete,
              isDestructive: true,
              onTap: () => Navigator.pop(sheetContext, MessageAction.delete),
            ),
            const SizedBox(height: Spacing.lg),
          ],
        ),
      );
    },
  );
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.md),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: Spacing.md),
            Text(title, style: theme.textTheme.bodyLarge?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
