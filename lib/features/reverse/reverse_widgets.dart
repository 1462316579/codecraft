import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../g11n/app_globalizations.dart';

/// 字符串等长替换的编辑弹窗。
///
/// 与普通的单行输入不同,这里必须把「为什么不能改」实时展示给用户:
/// 等长替换的约束(编码后字节数不变)不看提示根本猜不到。
Future<String?> showStringEditDialog(
  BuildContext context, {
  required String title,
  required String initial,
  required String? Function(String value) validate,
  String? helper,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _StringEditDialog(
      title: title,
      initial: initial,
      validate: validate,
      helper: helper,
    ),
  );
}

class _StringEditDialog extends StatefulWidget {
  const _StringEditDialog({
    required this.title,
    required this.initial,
    required this.validate,
    this.helper,
  });

  final String title;
  final String initial;
  final String? Function(String value) validate;
  final String? helper;

  @override
  State<_StringEditDialog> createState() => _StringEditDialogState();
}

class _StringEditDialogState extends State<_StringEditDialog> {
  // 控制器由 State 持有:弹窗退场动画期间输入框仍在读它。
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.validate(widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _error = widget.validate(value));
  }

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: null,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: InputDecoration(
              helperText: _error ?? widget.helper,
              helperMaxLines: 3,
              errorText: null,
            ),
            onChanged: _onChanged,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(g11n.cancel),
        ),
        TextButton(
          onPressed: _error == null
              ? () => Navigator.pop(context, _controller.text)
              : null,
          child: Text(g11n.save),
        ),
      ],
    );
  }
}

/// 分组小标题。
class ReverseSectionHeader extends StatelessWidget {
  const ReverseSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, Spacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
        ],
      ),
    );
  }
}

/// 空态/错误态提示。
class ReverseHint extends StatelessWidget {
  const ReverseHint({super.key, required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: Spacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}