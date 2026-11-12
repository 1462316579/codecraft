import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// 底部附加按键行（ZeroTermux 风格）
class ExtraKeysRow extends StatelessWidget {
  final bool ctrl;
  final bool alt;
  final VoidCallback onEscape;
  final VoidCallback onTab;
  final VoidCallback onToggleCtrl;
  final VoidCallback onToggleAlt;
  final void Function(String direction) onArrow;
  final ValueChanged<String> onWrite;
  final ValueChanged<List<int>> onWriteBytes;

  const ExtraKeysRow({
    super.key,
    required this.ctrl,
    required this.alt,
    required this.onEscape,
    required this.onTab,
    required this.onToggleCtrl,
    required this.onToggleAlt,
    required this.onArrow,
    required this.onWrite,
    required this.onWriteBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: Theme.of(context).colorScheme.surface,
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
          const Spacer(),
          _KeyButton(
            icon: LucideIcons.arrowLeft,
            onPressed: () => onArrow('left'),
          ),
          _KeyButton(
            icon: LucideIcons.arrowUp,
            onPressed: () => onArrow('up'),
          ),
          _KeyButton(
            icon: LucideIcons.arrowDown,
            onPressed: () => onArrow('down'),
          ),
          _KeyButton(
            icon: LucideIcons.arrowRight,
            onPressed: () => onArrow('right'),
          ),
        ],
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
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  )
                : Icon(icon, size: 18),
          ),
        ),
      ),
    );
  }
}
