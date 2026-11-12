import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/semantic_colors.dart';
import '../theme/tokens.dart';

/// 底部悬浮 tab 栏的单个 tab 项:图标 + 文案。
class FloatingTabItem {
  const FloatingTabItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// 底部悬浮液态玻璃 Tab 栏(对齐上游 `FloatingTabBar` 的 Pager 联动版):
/// - 滑动页面主体时,底栏指示器跟手平移;
/// - 长按底栏左右拖拽时,上方页面同步滑动,松手吸附;
/// - 点击 Tab 项平滑滚动至对应页面。
class FloatingTabBar extends StatefulWidget {
  const FloatingTabBar({
    super.key,
    required this.controller,
    required this.page,
    required this.items,
    required this.maskColor,
    required this.onSelect,
    this.isScrolling = false,
  });

  final PageController controller;
  final int page;
  final List<FloatingTabItem> items;
  final Color maskColor;
  final ValueChanged<int> onSelect;
  final bool isScrolling;

  @override
  State<FloatingTabBar> createState() => _FloatingTabBarState();
}

class _FloatingTabBarState extends State<FloatingTabBar> {
  final List<GlobalKey> _tabKeys = [];
  Map<int, Rect> _bounds = {};

  @override
  void initState() {
    super.initState();
    _ensureKeys();
    widget.controller.addListener(_onPageScrolled);
  }

  @override
  void didUpdateWidget(FloatingTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onPageScrolled);
      widget.controller.addListener(_onPageScrolled);
    }
    _ensureKeys();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPageScrolled);
    super.dispose();
  }

  /// PageController 在每次滚动帧(手势 / 动画 / 编程切换)都会通知监听器,
  /// 这里 setState 让指示器逐帧跟手——对齐上游 derivedStateOf(currentPage + offsetFraction)。
  /// 否则 animateToPage 动画中 onPageChanged 在 0.5 处触发一次重建后指示器就冻在半空。
  void _onPageScrolled() {
    if (mounted) setState(() {});
  }

  void _ensureKeys() {
    while (_tabKeys.length < widget.items.length) {
      _tabKeys.add(GlobalKey());
    }
  }

  /// 重新测量各 tab 的位置(父级布局变化时调用)。
  /// 结果变化时 setState——对齐上游 onGloballyPositioned 写入 StateMap 自动重组;
  /// 否则首帧 _bounds 为空、指示器不渲染,默认选中态(配置页)丢失。
  void _measure() {
    final measured = <int, Rect>{};
    for (var i = 0; i < _tabKeys.length; i++) {
      final context = _tabKeys[i].currentContext;
      if (context == null) continue;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      measured[i] = box.localToGlobal(Offset.zero) & box.size;
    }
    if (_sameBounds(measured)) return;
    setState(() => _bounds = measured);
  }

  bool _sameBounds(Map<int, Rect> other) {
    if (other.length != _bounds.length) return false;
    for (final entry in other.entries) {
      if (_bounds[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final isLight = theme.colorScheme.surface.computeLuminance() > 0.5;
    final glassBackground = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isLight
          ? [semantic.cardSurface.withValues(alpha: 0.94), semantic.mutedSurface.withValues(alpha: 0.90)]
          : [
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
              theme.colorScheme.surface.withValues(alpha: 0.88),
            ],
    );
    final glassBorder = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isLight
          ? [
              Colors.black.withValues(alpha: 0.12),
              Colors.black.withValues(alpha: 0.06),
              Colors.black.withValues(alpha: 0.14),
            ]
          : [
              theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
              theme.colorScheme.outlineVariant.withValues(alpha: 0.20),
              semantic.pageBackground.withValues(alpha: 0.60),
            ],
    );

    return SizedBox(
      width: double.infinity,
      height: 68,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [widget.maskColor.withValues(alpha: 0), widget.maskColor.withValues(alpha: 0.98)],
          ),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: widget.isScrolling ? 0.35 : 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: glassBackground,
                  borderRadius: BorderRadius.circular(Radii.pill),
                  border: Border.all(color: Colors.transparent, width: 0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isLight ? 0.10 : 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildGlass(
                  context,
                  glassBorder,
                  theme,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlass(BuildContext context, LinearGradient border, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _measure();
          });
          final positions = _tabPositions();
          final position = _continuousPosition();
          final indicator = _buildIndicator(theme, position, positions);
          return GestureDetector(
            onLongPressStart: (_) => _scrub(_lastGlobalX ?? 0, positions),
            onLongPressMoveUpdate: (details) {
              _lastGlobalX = details.globalPosition.dx;
              _scrub(details.globalPosition.dx, positions);
            },
            onLongPressEnd: (_) => _snap(),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (indicator != null) indicator,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < widget.items.length; i++) ...[
                      if (i > 0) const SizedBox(width: Spacing.xs),
                      _buildTab(context, theme, i, positions),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  double? _lastGlobalX;

  /// 各 tab 相对本容器的左边界;未测量到的下标为 null。
  List<double?> _tabPositions() {
    if (_bounds.isEmpty) return const [];
    final origin = _bounds.values.map((rect) => rect.left).reduce(math.min);
    return [
      for (var i = 0; i < widget.items.length; i++)
        _bounds[i] == null ? null : _bounds[i]!.left - origin,
    ];
  }

  double _continuousPosition() {
    if (!widget.controller.hasClients) return widget.page.toDouble();
    final page = widget.controller.page;
    if (page == null) return widget.page.toDouble();
    return page.clamp(0.0, (widget.items.length - 1).toDouble());
  }

  Widget? _buildIndicator(ThemeData theme, double position, List<double?> positions) {
    if (positions.isEmpty) return null;
    final floor = position.floor().clamp(0, widget.items.length - 1);
    final ceil = (floor + 1).clamp(0, widget.items.length - 1);
    final fraction = position - floor;
    // 对齐上游:floor/ceil 任一未测量到时,回退到当前页的边界。
    final double left;
    final double width;
    if (positions[floor] != null && positions[ceil] != null) {
      left = positions[floor]! + (positions[ceil]! - positions[floor]!) * fraction;
      width = _bounds[floor]!.width;
    } else {
      final pageIndex = widget.page.clamp(0, widget.items.length - 1);
      final pageLeft = positions[pageIndex];
      final pageBounds = _bounds[pageIndex];
      if (pageLeft == null || pageBounds == null) return null;
      left = pageLeft;
      width = pageBounds.width;
    }

    // 果冻拉伸:位移中段横向拉长、纵向略压扁。
    final stretch = 1 + 0.14 * (1 - (fraction - 0.5).abs() * 2);
    final color = theme.colorScheme.primaryContainer;
    return Positioned(
      left: left,
      width: width,
      height: 44,
      child: IgnorePointer(
        child: Transform.scale(
          scaleX: stretch,
          scaleY: (2 - stretch).clamp(0.94, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.95),
                  color.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(Radii.pill),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, ThemeData theme, int index, List<double?> positions) {
    final selected = index == widget.page;
    final foreground = selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
    return GestureDetector(
      key: _tabKeys[index],
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onSelect(index),
      child: Container(
        constraints: const BoxConstraints(minWidth: 84),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: const Duration(milliseconds: 200),
              child: Icon(widget.items[index].icon, size: 20, color: foreground),
            ),
            const SizedBox(height: 3),
            Text(
              widget.items[index].label,
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 长按拖拽:按横向位置换算目标页并直接滚动(1:1 跟手)。
  void _scrub(double globalX, List<double?> positions) {
    if (positions.isEmpty || positions.any((left) => left == null)) return;
    if (!widget.controller.hasClients || widget.items.length < 2) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final localX = box.globalToLocal(Offset(globalX, 0)).dx;
    final first = positions.first!;
    final last = positions.last!;
    if (last <= first) return;
    final progress = ((localX - first) / (last - first)).clamp(0.0, 1.0);
    final target = progress * (widget.items.length - 1);
    final page = target.round().clamp(0, widget.items.length - 1);
    widget.controller.jumpToPage(page);
  }

  void _snap() {
    if (!widget.controller.hasClients) return;
    final page = (widget.controller.page ?? widget.page.toDouble()).round();
    widget.controller.animateToPage(
      page.clamp(0, widget.items.length - 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
    );
  }
}