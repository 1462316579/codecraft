import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../agent/models/git_models.dart';
import '../../../core/theme/git_colors.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/settings_group.dart';

/// 状态码徽标:32×20 胶囊,背景取自 [GitStatusColors],前景按背景亮度自适应。
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final background = GitStatusColors.background(code);
    final foreground = GitStatusColors.foreground(background);
    return Container(
      width: 32,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        code.length > 2 ? code.substring(0, 2) : code,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontFamily: 'monospace',
              color: foreground,
            ),
      ),
    );
  }
}

/// 分组小标题(左对齐、subtleText、13sp),右侧可带操作。
class GitSectionHeader extends StatelessWidget {
  const GitSectionHeader({super.key, required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.lg, Spacing.sm, Spacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: context.semantic.subtleText,
                  ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// 统计小卡:大数字(等宽)+ 小标签。
class StatusMetric extends StatelessWidget {
  const StatusMetric({
    super.key,
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: context.semantic.mutedSurface,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            maxLines: 1,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontFamily: 'monospace',
                ),
          ),
          Text(
            label,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// 次级操作按钮:柔和背景微卡片按钮,40dp 高、12dp 圆角。
class GitActionButton extends StatelessWidget {
  const GitActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final background = enabled
        ? semantic.buttonMutedBg
        : semantic.mutedSurface.withValues(alpha: 0.5);
    final foreground = enabled
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.40);
    return SizedBox(
      height: 40,
      child: FilledButton.tonal(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background,
          disabledForegroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.mdLarge)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15),
            const SizedBox(width: Spacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: foreground,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 懒加载列表里的分组行:多行拼成一张卡片——首/末行保留圆角、中间行直角,非首行顶部补分隔线。
class FileGroupRow extends StatelessWidget {
  const FileGroupRow({
    super.key,
    required this.index,
    required this.count,
    required this.child,
  });

  final int index;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(Radii.lg);
    final shape = count <= 1
        ? BorderRadius.all(radius)
        : index == 0
            ? BorderRadius.vertical(top: radius)
            : index == count - 1
                ? BorderRadius.vertical(bottom: radius)
                : BorderRadius.zero;
    return Container(
      decoration: BoxDecoration(
        color: context.semantic.cardSurface,
        borderRadius: shape,
      ),
      child: Column(
        children: [
          if (index > 0) const SettingsDivider(),
          child,
        ],
      ),
    );
  }
}

/// 分组内文件行:状态徽标 + 文件名/目录 + 行尾操作;点击看差异,长按开操作菜单。
class GitFileRow extends StatelessWidget {
  const GitFileRow({
    super.key,
    required this.file,
    required this.actionIcon,
    required this.actionTooltip,
    required this.onAction,
    required this.enabled,
    this.indent = 0,
    this.onTap,
    this.onLongPress,
  });

  final GitFileChange file;
  final IconData actionIcon;
  final String actionTooltip;
  final VoidCallback onAction;
  final bool enabled;
  final double indent;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final slash = file.path.lastIndexOf('/');
    final fileName = slash < 0 ? file.path : file.path.substring(slash + 1);
    final directory = slash < 0 ? '' : file.path.substring(0, slash);

    final row = Padding(
      padding: EdgeInsets.fromLTRB(Spacing.lg + indent, Spacing.sm, Spacing.sm, Spacing.sm),
      child: Row(
        children: [
          StatusChip(code: file.statusCode),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                if (directory.isNotEmpty)
                  Text(
                    directory,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontFamily: 'monospace',
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          IconButton(
            onPressed: enabled ? onAction : null,
            tooltip: actionTooltip,
            icon: Icon(
              actionIcon,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    if (onTap == null && onLongPress == null) return row;
    return InkWell(onTap: onTap, onLongPress: onLongPress, child: row);
  }
}

/// 未跟踪目录行(`git status` 把新目录折叠成 `dir/` 一行):
/// 点击展开/收起其中的未跟踪文件,长按开操作菜单,行尾「+」暂存整个目录。
class UntrackedDirRow extends StatelessWidget {
  const UntrackedDirRow({
    super.key,
    required this.path,
    required this.childCount,
    required this.expanded,
    required this.loading,
    required this.enabled,
    required this.onTap,
    required this.onLongPress,
    required this.onStage,
    required this.stageTooltip,
  });

  final String path;

  /// null 表示尚未展开,此时箭头左侧不显示数量。
  final int? childCount;
  final bool expanded;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onStage;
  final String stageTooltip;

  @override
  Widget build(BuildContext context) {
    final subtle = Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm),
        child: Row(
          children: [
            const StatusChip(code: '?'),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            if (loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              if (childCount != null)
                Text(
                  '$childCount',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: subtle),
                ),
              Icon(
                expanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                size: 16,
                color: subtle,
              ),
            ],
            IconButton(
              onPressed: enabled ? onStage : null,
              tooltip: stageTooltip,
              icon: Icon(LucideIcons.plus, size: 18, color: subtle),
            ),
          ],
        ),
      ),
    );
  }
}

/// 可折叠的分段小标题(左侧箭头 + 标题 + 可选「+」)。
class RefSectionHeader extends StatelessWidget {
  const RefSectionHeader({
    super.key,
    required this.title,
    required this.expanded,
    required this.onToggle,
    this.indent = 0,
    this.onAdd,
    this.addTooltip,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final int indent;
  final VoidCallback? onAdd;
  final String? addTooltip;

  @override
  Widget build(BuildContext context) {
    final subtle = context.semantic.subtleText;
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: EdgeInsets.fromLTRB(Spacing.md + indent * 16, Spacing.sm, Spacing.sm, Spacing.xs),
        child: Row(
          children: [
            Icon(
              expanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
              size: 16,
              color: subtle,
            ),
            const SizedBox(width: Spacing.xs),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: subtle,
                    ),
              ),
            ),
            if (onAdd != null)
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: onAdd,
                  tooltip: addTooltip,
                  icon: Icon(
                    LucideIcons.plus,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 分支/标签行:图标 + 名称 + 副标题,48dp 高;当前分支用主色底高亮。
class RefRow extends StatelessWidget {
  const RefRow({
    super.key,
    required this.name,
    required this.icon,
    required this.isCurrent,
    this.subtitle,
    this.isLoading = false,
    this.indent = 0,
    this.onTap,
  });

  final String name;
  final String? subtitle;
  final IconData icon;
  final bool isCurrent;
  final bool isLoading;
  final int indent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contentColor =
        isCurrent ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface;
    final row = Container(
      height: 48,
      padding: EdgeInsets.only(left: Spacing.lg + indent * 16, right: Spacing.lg),
      child: Row(
        children: [
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              icon,
              size: 18,
              color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    color: contentColor,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isCurrent
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    final colored = Container(
      color: isCurrent ? theme.colorScheme.primaryContainer : Colors.transparent,
      child: row,
    );
    if (isLoading || onTap == null) return colored;
    return InkWell(onTap: onTap, child: colored);
  }
}