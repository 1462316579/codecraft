import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../g11n/app_globalizations.dart';

/// 编辑消息正文的弹窗(对齐上游 EditMessageDialog):确定返回新内容,取消返回 null。
Future<String?> showEditMessageDialog(
  BuildContext context, {
  required String initialText,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _EditMessageDialog(initialText: initialText),
  );
}

class _EditMessageDialog extends StatefulWidget {
  const _EditMessageDialog({required this.initialText});

  final String initialText;

  @override
  State<_EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<_EditMessageDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    return AlertDialog(
      title: Text(g11n.chatEditMessageTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: TextField(
          controller: _controller,
          autofocus: true,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(g11n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(g11n.commonConfirm),
        ),
      ],
    );
  }
}
