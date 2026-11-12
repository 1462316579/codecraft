import 'package:flutter/material.dart';

import '../theme/semantic_colors.dart';
import '../theme/tokens.dart';

/// iOS 风分段控件(逐值移植上游 SegmentedTabs.kt):
/// 中性灰轨道(42dp 高、圆角 12、内边距 3)+ 弹性滑动滑块(圆角 9、白底/深色抬起灰、轻阴影)。
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.selected,
    required this.labels,
    required this.onSelect,
  });

  final int selected;
  final List<String> labels;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final isDark = theme.brightness == Brightness.dark;
    final thumbColor = isDark ? semantic.capsuleSurface : semantic.cardSurface;
    return LayoutBuilder(
      builder: (context, constraints) {
        final thumbWidth = (constraints.maxWidth - 6) / labels.length;
        return Container(
          height: 42,
          decoration: BoxDecoration(
            color: semantic.mutedSurface,
            borderRadius: BorderRadius.circular(Radii.mdLarge),
          ),
          padding: const EdgeInsets.all(3),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: thumbWidth * selected,
                top: 0,
                bottom: 0,
                width: thumbWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: thumbColor,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var index = 0; index < labels.length; index++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelect(index),
                        child: Center(
                          child: Text(
                            labels[index],
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight:
                                  index == selected ? FontWeight.w600 : FontWeight.w400,
                              color: index == selected
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}