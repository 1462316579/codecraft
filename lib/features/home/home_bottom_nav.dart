import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';

import '../../../core/theme/semantic_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// 底部导航的两个页签。
enum HomeTab { projects, settings }

/// 底部导航栏:项目 / 设置。
///
/// 选中态用实心图标 + 主色,未选中用线性图标 + 次要文字色(对齐上游 HomeBottomBar
/// 的 outlined/filled 图标切换)。窄屏与宽屏都显示。
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final HomeTab current;
  final ValueChanged<HomeTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 25),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: (theme.brightness == Brightness.light
                        ? Colors.white
                        : context.semantic.mutedSurface)
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  width: 0.5,
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
              child: SizedBox(
                height: 54,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _NavItem(
                        icon: current == HomeTab.projects ? Iconfont.folderOpen : Iconfont.folder,
                        label: l10n.tabProjects,
                        selected: current == HomeTab.projects,
                        onTap: () => onSelect(HomeTab.projects),
                      ),
                      const SizedBox(width: 46),
                      _NavItem(
                        icon: Iconfont.settings,
                        label: l10n.settings,
                        selected: current == HomeTab.settings,
                        onTap: () => onSelect(HomeTab.settings),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? theme.colorScheme.primary : context.semantic.subtleText;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.18),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 30, color: color),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 9,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
