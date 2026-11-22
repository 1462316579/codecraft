import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';

import '../../../core/theme/semantic_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../g11n/app_globalizations.dart';

/// 底部导航的页签。
enum HomeTab { projects, settings }

/// 底部导航栏:项目 / 音乐 / 设置。
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
    final g11n = AppGlobalizations.of(context);
    final bright = theme.brightness == Brightness.light;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 25),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: bright ? 0.55 : 0.18),
                    Colors.white.withValues(alpha: bright ? 0.22 : 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  width: 1,
                  color: Colors.white.withValues(alpha: bright ? 0.6 : 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Brand.violet.withValues(alpha: bright ? 0.08 : 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: SizedBox(
                height: 54,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _NavItem(
                      icon: current == HomeTab.projects ? Iconfont.folderOpen : Iconfont.folder,
                      label: g11n.tabProjects,
                      selected: current == HomeTab.projects,
                      onTap: () => onSelect(HomeTab.projects),
                    ),
                    const SizedBox(width: 30),
                    _NavItem(
                      icon: Iconfont.settings,
                      label: g11n.settings,
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
