import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../g11n/app_globalizations.dart';
import '../../reverse/hex/hex_dump.dart';

/// 可复用的十六进制视图:偏移 + 十六进制 + ASCII 三栏。
///
/// 只负责展示与定位,改字节由调用方决定(Dex/ARSC 页需要顺带重算文件头)。
class HexView extends StatelessWidget {
  const HexView({
    super.key,
    required this.bytes,
    required this.scrollController,
    this.modifiedOffsets = const {},
    this.onByteTap,
    this.bytesPerRow = 8,
  });

  final Uint8List bytes;
  final ScrollController scrollController;

  /// 本次会话改过的偏移,高亮标出。
  final Set<int> modifiedOffsets;

  /// 点某个字节;null 表示只读。
  final void Function(int offset)? onByteTap;

  final int bytesPerRow;

  /// 行高固定,才能支撑几十万行的 ListView 精确跳转。
  static const double rowHeight = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g11n = AppGlobalizations.of(context);
    if (bytes.isEmpty) {
      return Center(
        child: Text(
          g11n.reverseEmptyFile,
          style: theme.textTheme.bodyMedium?.copyWith(color: context.semantic.subtleText),
        ),
      );
    }
    final total = HexDump.rowCount(bytes.length, bytesPerRow: bytesPerRow);
    final mono = theme.textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      fontSize: 11,
      height: 1.2,
    );
    return ListView.builder(
      controller: scrollController,
      itemCount: total,
      itemExtent: rowHeight,
      itemBuilder: (context, index) {
        final start = index * bytesPerRow;
        final end = (start + bytesPerRow).clamp(0, bytes.length);
        final slice = Uint8List.sublistView(bytes, start, end);
        return _HexRowView(
          row: HexRow(
            offset: start,
            bytes: slice.toList(),
            ascii: String.fromCharCodes(
              slice.map((b) => b >= 0x20 && b <= 0x7E ? b : 0x2E),
            ),
            bytesPerRow: bytesPerRow,
          ),
          style: mono,
          modifiedOffsets: modifiedOffsets,
          onByteTap: onByteTap,
        );
      },
    );
  }
}

class _HexRowView extends StatelessWidget {
  const _HexRowView({
    required this.row,
    required this.style,
    required this.modifiedOffsets,
    required this.onByteTap,
  });

  final HexRow row;
  final TextStyle? style;
  final Set<int> modifiedOffsets;
  final void Function(int offset)? onByteTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normal = style?.copyWith(color: context.semantic.subtleText);
    final highlight = style?.copyWith(color: theme.colorScheme.primary);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(row.offsetText, style: normal),
          ),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < row.bytes.length; i++)
                  GestureDetector(
                    onTap: onByteTap == null
                        ? null
                        : () => onByteTap!(row.offset + i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      color: modifiedOffsets.contains(row.offset + i)
                          ? theme.colorScheme.primary.withValues(alpha: 0.18)
                          : null,
                      child: Text(
                        row.bytes[i].toRadixString(16).padLeft(2, '0'),
                        style: modifiedOffsets.contains(row.offset + i)
                            ? highlight
                            : style,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(row.ascii, style: normal, overflow: TextOverflow.clip),
          ),
        ],
      ),
    );
  }
}

/// 十六进制页的标题栏动作:跳转偏移。
class HexJumpButton extends StatelessWidget {
  const HexJumpButton({super.key, required this.onJump});

  final void Function(int offset) onJump;

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    return IconButton(
      tooltip: g11n.reverseJumpToOffset,
      icon: const Icon(Iconfont.crosshair, size: 18),
      onPressed: () async {
        final offset = await showDialog<int>(
          context: context,
          builder: (context) => const _JumpDialog(),
        );
        if (offset != null) onJump(offset);
      },
    );
  }
}

class _JumpDialog extends StatefulWidget {
  const _JumpDialog();

  @override
  State<_JumpDialog> createState() => _JumpDialogState();
}

class _JumpDialogState extends State<_JumpDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    return AlertDialog(
      title: Text(g11n.reverseJumpToOffset),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: '0x1000',
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(g11n.cancel),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(g11n.confirm),
        ),
      ],
    );
  }

  void _submit() {
    final text = _controller.text.trim();
    final value = int.tryParse(
      text.toLowerCase().startsWith('0x') ? text.substring(2) : text,
      radix: 16,
    );
    if (value == null || value < 0) {
      setState(() => _error = AppGlobalizations.of(context).reverseOffsetInvalid);
      return;
    }
    Navigator.pop(context, value);
  }
}