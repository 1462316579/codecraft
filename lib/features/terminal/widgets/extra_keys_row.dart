import 'package:flutter/material.dart';

import '../../../core/icons/iconfont.dart';

/// 底部附加按键行（ZeroTermux 风格）。
///
/// 按键等分排列，最后一个为回车；整体放在 SafeArea 内，避免被系统导航条/
/// 手势条遮挡。
class ExtraKeysRow extends StatelessWidget {
  final bool ctrl;
  final bool alt;
  final VoidCallback onEscape;
  final VoidCallback onTab;
  final VoidCallback onToggleCtrl;
  final VoidCallback onToggleAlt;
  final void Function(String direction) onArrow;
  final VoidCallback onEnter;

  const ExtraKeysRow({
    super.key,
    required this.ctrl,
    required this.alt,
    required this.onEscape,
    required this.onTab,
    required this.onToggleCtrl,
    required this.onToggleAlt,
    required this.onArrow,
    required this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            children: [
              _KeyButton(label: 'ESC', onPressed: onEscape),
              _KeyButton(label: 'TAB', onPressed: onTab),
              _KeyButton(
                label: 'CTRL',
                onPressed: onToggleCtrl,
                active: ctrl,
              ),
              _KeyButton(
                label: 'ALT',
                onPressed: onToggleAlt,
                active: alt,
              ),
              _KeyButton(
                icon: Iconfont.arrowLeft,
                onPressed: () => onArrow('left'),
              ),
              _KeyButton(
                icon: Iconfont.arrowUp,
                onPressed: () => onArrow('up'),
              ),
              _KeyButton(
                icon: Iconfont.arrowDown,
                onPressed: () => onArrow('down'),
              ),
              _KeyButton(
                icon: Iconfont.arrowRight,
                onPressed: () => onArrow('right'),
              ),
              _KeyButton(
                icon: Icons.keyboard_return,
                onPressed: onEnter,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool active;

  const _KeyButton({
    this.label,
    this.icon,
    required this.onPressed,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: active
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
            : Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: label != null
                ? Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Icon(icon, size: 18),
          ),
        ),
      ),
    );
  }
}
