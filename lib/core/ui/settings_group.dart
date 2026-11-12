import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/semantic_colors.dart';
import '../theme/tokens.dart';

/// 设置页分组组件(逐值移植自上游 SettingsGroupComponents.kt,行样式对齐新版设置页截图):
/// 页面底色 + 圆角 14 的分组卡片 + 圆角色块图标 + 行内分隔线。

/// 页面大标题 + 副标题(新版设置页头部)。
class SettingsPageHeader extends StatelessWidget {
  const SettingsPageHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.sm, Spacing.lg, Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.xs),
              child: Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.semantic.subtleText,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 分组小标题:卡片上方灰色小字(labelLarge 13sp / Normal / onSurfaceVariant)。
class SettingsGroupHeader extends StatelessWidget {
  const SettingsGroupHeader({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.lg, 0, Spacing.sm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

/// 可折叠分组小标题:标题 + 展开箭头,点击切换(对齐上游 CollapsibleGroupHeader)。
class CollapsibleGroupHeader extends StatelessWidget {
  const CollapsibleGroupHeader({
    super.key,
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.lg, Spacing.md, Spacing.sm),
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
            Icon(
              expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 16,
              color: context.semantic.subtleText,
            ),
          ],
        ),
      ),
    );
  }
}

/// 分组圆角卡片容器:圆角 14、cardSurface 底色、无描边无阴影;行间由 [SettingsDivider] 分隔。
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (theme.brightness == Brightness.light
                    ? Colors.white
                    : context.semantic.cardSurface)
                .withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(
              width: 0.5,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }
}

/// 分组内单行:左「圆角色块图标」(主色 12% 底 + 主色图标)+ 标题/副标题,右侧可选尾随组件;
/// [onTap] 非空时行尾自动附加 22dp chevron;[enabled] 为 false 时整体 0.5 透明度。
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  /// 图标色块尺寸与文字列左边缘(分隔线缩进对齐同一位置)。
  static const double iconBoxSize = 44;
  static const double textIndent = Spacing.lg + iconBoxSize + Spacing.md;

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 10),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Radii.mdLarge),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 22, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: Spacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                                color: semantic.subtleText,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (onTap != null && enabled) ...[
                const SizedBox(width: Spacing.xs),
                Icon(Icons.chevron_right, size: 22, color: semantic.subtleText),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 分组内行间分隔线:0.5dp、subtleBorder;
/// [indent] 默认 16(无图标行),带图标的设置页传 [SettingsRow.textIndent] 与文字左边缘对齐。
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key, this.indent = Spacing.lg});

  final double indent;

  @override
  Widget build(BuildContext context) => Divider(
        height: 0.5,
        thickness: 0.5,
        indent: indent,
        endIndent: Spacing.lg,
        color: context.semantic.subtleBorder,
      );
}

/// iOS 风格搜索框(上游 ModelSearchField):胶囊底色、无边框、最小高度 40。
class CapsuleSearchField extends StatelessWidget {
  const CapsuleSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (theme.brightness == Brightness.light
                    ? Colors.white
                    : semantic.capsuleSurface)
                .withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(
              width: 0.5,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: semantic.subtleText),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: semantic.subtleText,
                          ),
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}