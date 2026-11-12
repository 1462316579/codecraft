import 'package:flutter/material.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

/// 居中欢迎文案(上游 WelcomeState 的「有什么可以帮你的?」):
/// 空会话的聊天页展示;应用启动即保证有一个当前会话,因此不再需要独立的欢迎页。
///
/// 垂直位置对齐上游:在可用高度 13% 与输入栏一半高度之间取较大偏移量向上抬,
/// 避免文案正好压在输入框上方显得拥挤。上游在 Android 12+ 用 snap() 无动画,
/// Flutter 拿不到系统 SDK 号,统一用 220ms 过渡。
class ChatWelcomeMessage extends StatelessWidget {
  const ChatWelcomeMessage({super.key, this.bottomReserve = 0});

  /// 底部输入栏的实测高度(dp);0 表示尚未测量。
  final double bottomReserve;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subtle = context.semantic.subtleText;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 0.0;
        // 上游:minOf(-(maxHeight * 0.13f), -(bottomReserve / 2))。
        final byHeight = -maxHeight * 0.13;
        final byReserve = -(bottomReserve / 2);
        final targetOffset = byHeight < byReserve ? byHeight : byReserve;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: targetOffset, end: targetOffset),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          builder: (context, offset, child) => Transform.translate(
            offset: Offset(0, offset),
            child: child,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.chatPlaceholder,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    l10n.chatInputHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: subtle),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
