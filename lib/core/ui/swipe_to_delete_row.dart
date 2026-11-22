import 'dart:ui';

import 'package:flutter/material.dart';
import '../icons/iconfont.dart';

import '../theme/semantic_colors.dart';
import '../theme/tokens.dart';
import '../../g11n/app_globalizations.dart';

/// 全项目统一的左滑删除行容器(逐值移植上游 core/ui/SwipeToDeleteRow.kt):
/// 底层红色删除按钮固定在右端,随左滑露出(带缩放/透明度渐变),表层内容整体左滑,
/// 滑开时点击表层收回、不触发 [onTap];只有点按删除按钮才回调 [onDelete]。
///
/// 手势与动画参数全项目保持一致(露出宽度 112dp、按钮上限 104dp),改这里即全局生效。
class SwipeToDeleteRow extends StatefulWidget {
  const SwipeToDeleteRow({
    super.key,
    required this.child,
    required this.onDelete,
    this.onTap,
    this.deleteEnabled = true,
    this.decorateChild = true,
  });

  /// 表层行内容;背景由本组件提供,内边距由调用方内容自带。
  final Widget child;

  /// 点按删除按钮后触发(先收回再回调)。是否弹二次确认由调用方决定。
  final VoidCallback onDelete;

  /// 表层未滑开时的点击回调;null 表示整行不可点击。
  final VoidCallback? onTap;

  /// false 时删除按钮可露出但点击无效(如未下载完成的镜像不可删),按钮呈灰色。
  final bool deleteEnabled;

  /// false 时不给 child 再包一层柔光玻璃,仅做平移(child 自带玻璃时用,
  /// 否则会叠出双层模糊)。默认 true。
  final bool decorateChild;

  @override
  State<SwipeToDeleteRow> createState() => _SwipeToDeleteRowState();
}

class _SwipeToDeleteRowState extends State<SwipeToDeleteRow>
    with SingleTickerProviderStateMixin {
  /// 与上游一致:最大露出宽度。
  static const double _revealWidth = 112;
  static const double _maxButtonWidth = 104;
  static const double _gap = 8;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  double _offset = 0;
  double _animFrom = 0;
  double _animTo = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _offset = _animFrom + (_animTo - _animFrom) * _controller.value);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target, {bool bouncy = false}) {
    if (_offset == target) return;
    _animFrom = _offset;
    _animTo = target;
    _controller.forward(from: 0);
    // 回弹只影响观感:用 easeOutBack 近似上游 LowBouncy 弹簧,收起用 easeOut 不越界。
    _controller.duration = Duration(milliseconds: bouncy ? 320 : 200);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _controller.stop();
    setState(() => _offset = (_offset + details.delta.dx).clamp(-_revealWidth, 0.0));
  }

  void _onDragEnd(DragEndDetails details) {
    // 滑过一半就停在露出态,否则收回(对齐上游 1/2 阈值)。
    final shouldOpen = _offset < -_revealWidth / 2;
    _animateTo(shouldOpen ? -_revealWidth : 0, bouncy: shouldOpen);
  }

  void _handleTap() {
    if (_offset != 0) {
      _animateTo(0);
      return;
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final revealed = (-_offset).clamp(0.0, _revealWidth);
    final buttonWidth = revealed > _gap ? (revealed - _gap).clamp(0.0, _maxButtonWidth) : 0.0;
    final progress = (buttonWidth / _maxButtonWidth).clamp(0.0, 1.0);
    final buttonBg = widget.deleteEnabled ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF);
    final buttonBorder = widget.deleteEnabled ? const Color(0xFFF87171) : const Color(0xFFD1D5DB);

    return TapRegionSurface(
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Align(
                alignment: Alignment.centerRight,
                child: buttonWidth <= 0
                    ? const SizedBox.shrink()
                    : TapRegion(
                        onTapInside: widget.deleteEnabled
                            ? (_) {
                                _animateTo(0);
                                widget.onDelete();
                              }
                            : null,
                        child: Opacity(
                          opacity: (progress * 1.2).clamp(0.0, 1.0),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..scale(
                                0.4 + 0.6 * progress,
                                0.7 + 0.3 * progress,
                              ),
                            child: Container(
                              width: buttonWidth,
                              decoration: BoxDecoration(
                                color: buttonBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: buttonBorder),
                              ),
                              alignment: Alignment.center,
                              clipBehavior: Clip.hardEdge,
                              child: OverflowBox(
                                maxWidth: _maxButtonWidth,
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: _maxButtonWidth,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Iconfont.trash2, size: 20, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppGlobalizations.of(context).delete,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(_offset, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              onTap: _handleTap,
              child: widget.decorateChild
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.lg),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: (Theme.of(context).brightness == Brightness.light
                                    ? Colors.white
                                    : context.semantic.cardSurface)
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(Radii.lg),
                            border: Border.all(
                              width: 0.5,
                              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          child: widget.child,
                        ),
                      ),
                    )
                    : widget.child,
            ),
          ),
        ],
      ),
    );
  }
}