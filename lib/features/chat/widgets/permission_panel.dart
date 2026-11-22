import 'package:flutter/material.dart';

import '../../../core/icons/iconfont.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/permissions.dart';
import '../../../g11n/app_globalizations.dart';
import '../../../agent/models/agent_ui_state.dart';

/// 工具授权卡(对齐上游 ToolPermissionPanel):
/// 标题 + 工具名 pill + 折叠箭头;展开后是摘要与等宽详情、记忆说明行,
/// 以及三选一按钮:拒绝 / 始终允许(不可记忆时禁用并说明原因)/ 允许。
class PermissionPanel extends StatefulWidget {
  const PermissionPanel({
    super.key,
    required this.permission,
    required this.onChoice,
  });

  final PendingPermission permission;
  final ValueChanged<PermissionChoice> onChoice;

  @override
  State<PermissionPanel> createState() => _PermissionPanelState();
}

class _PermissionPanelState extends State<PermissionPanel> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final permission = widget.permission;
    final canRemember = permission.rememberablePatterns.isNotEmpty;
    final rememberLabel = !canRemember
        ? (permission.rememberDisabledReason ?? g11n.chatPermSingleUseDesc)
        : permission.rememberablePatterns.length == 1 &&
                permission.rememberablePatterns.first == PermissionRule.wholeTool
            ? g11n.chatPermAlwaysToolDesc
            : '${g11n.chatPermAlwaysPrefix}${permission.rememberablePatterns.join('、')}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Iconfont.shield, size: 15, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          permission.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(Radii.xs),
                        ),
                        child: Text(
                          permission.toolName,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18,
                  color: semantic.subtleText,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: Spacing.sm),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(Radii.sm),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        permission.summary,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurface),
                      ),
                      if (permission.details.trim().isNotEmpty) ...[
                        const SizedBox(height: Spacing.xs),
                        Text(
                          permission.details,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: semantic.subtleText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              rememberLabel,
              style: theme.textTheme.labelSmall?.copyWith(color: semantic.subtleText),
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    text: g11n.chatPermDeny,
                    onPressed: () => widget.onChoice(PermissionChoice.reject),
                    foreground: theme.colorScheme.error,
                    background: theme.colorScheme.errorContainer,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: _ActionButton(
                    text: g11n.chatPermAlwaysAllow,
                    onPressed: canRemember
                        ? () => widget.onChoice(PermissionChoice.always)
                        : null,
                    foreground: theme.colorScheme.onSurface,
                    background: semantic.mutedSurface,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: _ActionButton(
                    text: g11n.allow,
                    onPressed: () => widget.onChoice(PermissionChoice.once),
                    foreground: Colors.white,
                    background: semantic.success,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.text,
    required this.onPressed,
    required this.foreground,
    required this.background,
  });

  final String text;
  final VoidCallback? onPressed;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withValues(alpha: 0.5),
        disabledForegroundColor: foreground.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}