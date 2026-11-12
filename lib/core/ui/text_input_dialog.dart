import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// 单行文本输入弹窗:确定返回去空白后的内容,取消返回 null。
///
/// 控制器必须由 State 持有并在 dispose 里释放。若在 `showDialog` 返回后立刻
/// `controller.dispose()`,弹窗还没走完退场动画、输入框仍在被拆除,就会触发
/// 「A TextEditingController was used after being disposed」,进而把紧随其后的
/// `_dependents.isEmpty` 断言一起带崩。
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initial = '',
  String? hintText,
  String? labelText,
  bool Function(String value)? isAcceptable,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _TextInputDialog(
      title: title,
      confirmLabel: confirmLabel,
      initial: initial,
      hintText: hintText,
      labelText: labelText,
      isAcceptable: isAcceptable,
    ),
  );
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.confirmLabel,
    required this.initial,
    this.hintText,
    this.labelText,
    this.isAcceptable,
  });

  final String title;
  final String confirmLabel;
  final String initial;
  final String? hintText;
  final String? labelText;

  /// 额外的可提交条件;默认只要非空即可。
  final bool Function(String value)? isAcceptable;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    if (widget.isAcceptable != null && !widget.isAcceptable!(value)) return;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.hintText,
          labelText: widget.labelText,
        ),
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _confirm,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}