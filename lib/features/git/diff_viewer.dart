import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/line_diff.dart';
import '../../data/git/diff_data.dart';
import '../../l10n/app_localizations.dart';

/// 差异查看器(对齐上游 `DiffViewerScreen`):独立全屏页,不叠加在 Git 页顶栏之下。
class DiffViewerScreen extends StatelessWidget {
  const DiffViewerScreen({
    super.key,
    required this.diffData,
    required this.filePath,
    required this.onBack,
    this.onOpenInEditor,
  });

  final DiffData? diffData;
  final String? filePath;
  final VoidCallback onBack;
  final void Function(String path)? onOpenInEditor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final path = diffData?.filePath ?? filePath;
    return Scaffold(
      appBar: AppBar(
        title: path == null
            ? Text(
                l10n.gitComputingDiff,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    path.contains('/') ? path.substring(path.lastIndexOf('/') + 1) : path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
        leading: IconButton(
          onPressed: onBack,
          tooltip: l10n.back,
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        actions: [
          if (path != null && onOpenInEditor != null)
            IconButton(
              onPressed: () {
                onBack();
                onOpenInEditor!(path);
              },
              tooltip: l10n.gitOpenInEditor,
              icon: const Icon(LucideIcons.pencil, size: 18),
            ),
        ],
      ),
      body: switch (diffData) {
        null => _DiffLoading(),
        final data when data.isBinary => const _DiffHint(
            icon: LucideIcons.file,
            messageKey: _DiffHintKind.binary,
          ),
        final data when data.isLarge => const _DiffHint(
            messageKey: _DiffHintKind.large,
          ),
        final data when data.rows.isEmpty => const _DiffHint(messageKey: _DiffHintKind.empty),
        final data => _DiffContent(data: data),
      },
    );
  }
}

class _DiffLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: Spacing.sm),
          Text(
            l10n.gitComputingDiff,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

enum _DiffHintKind { binary, large, empty }

class _DiffHint extends StatelessWidget {
  const _DiffHint({required this.messageKey, this.icon});

  final _DiffHintKind messageKey;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final subtle = theme.colorScheme.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 32, color: subtle),
            const SizedBox(height: Spacing.sm),
          ],
          Text(
            switch (messageKey) {
              _DiffHintKind.binary => l10n.diffBinaryFile,
              _DiffHintKind.large => l10n.diffFileTooLarge,
              _DiffHintKind.empty => l10n.diffNoChanges,
            },
            style: theme.textTheme.bodyMedium?.copyWith(color: subtle),
          ),
          if (messageKey == _DiffHintKind.large) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              l10n.diffFileTooLargeDesc,
              style: theme.textTheme.bodySmall?.copyWith(color: subtle),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiffContent extends StatefulWidget {
  const _DiffContent({required this.data});

  final DiffData data;

  @override
  State<_DiffContent> createState() => _DiffContentState();
}

class _DiffContentState extends State<_DiffContent> {
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final data = widget.data;
    final maxLineNum = data.rows.fold<int>(0, (max, row) {
      final candidate = row.oldLineNum != null && row.newLineNum != null
          ? (row.oldLineNum! > row.newLineNum! ? row.oldLineNum! : row.newLineNum!)
          : (row.oldLineNum ?? row.newLineNum ?? 0);
      return candidate > max ? candidate : max;
    });
    final digits = maxLineNum.toString().length;
    final gutterWidth = (digits < 3 ? 3 : digits) * 8.0 + 8;

    return Column(
      children: [
        // 增删统计条
        Container(
          width: double.infinity,
          color: theme.colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm),
          child: Row(
            children: [
              Text(
                '+${data.addedCount}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: semantic.diffAdd,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                '-${data.removedCount}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: semantic.diffRemove,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: _horizontal,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontal,
              scrollDirection: Axis.horizontal,
              child: IntrinsicWidth(
                child: SizedBox(
                  width: _estimatedWidth(context, gutterWidth, data),
                  child: ListView.builder(
                    itemCount: data.rows.length,
                    itemBuilder: (context, index) => _DiffLineRow(
                      row: data.rows[index],
                      gutterWidth: gutterWidth,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 横向内容宽度:按最长行的字符数粗估(等宽字体 8dp/字符)。
  double _estimatedWidth(BuildContext context, double gutterWidth, DiffData data) {
    var longest = 0;
    for (final row in data.rows) {
      if (row.text.length > longest) longest = row.text.length;
    }
    final screen = MediaQuery.sizeOf(context).width;
    final estimated = gutterWidth * 2 + 1 + 14 + Spacing.lg + longest * 8.0 + 24;
    return estimated > screen ? estimated : screen;
  }
}

/// 差异中的一行:双行号栏 + 分隔线 + 前缀列 + 文本(带语法高亮)。
class _DiffLineRow extends StatelessWidget {
  const _DiffLineRow({required this.row, required this.gutterWidth});

  final DiffRow row;
  final double gutterWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final (background, prefix, prefixColor) = switch (row.type) {
      DiffLineType.add => (semantic.diffAddBg, '+', semantic.diffAdd),
      DiffLineType.remove => (semantic.diffRemoveBg, '-', semantic.diffRemove),
      DiffLineType.context => (Colors.transparent, ' ', theme.colorScheme.onSurfaceVariant),
    };
    final gutterBackground = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final gutterText = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
    final baseStyle = theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace');

    return Container(
      color: background,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _gutterText(row.oldLineNum, gutterWidth, gutterBackground, gutterText, baseStyle),
          Container(
            width: 1,
            height: 18,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          _gutterText(row.newLineNum, gutterWidth, gutterBackground, gutterText, baseStyle),
          SizedBox(
            width: 14,
            child: Text(
              prefix,
              style: baseStyle?.copyWith(
                color: prefixColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: Spacing.lg),
            child: _highlightedText(row, baseStyle),
          ),
        ],
      ),
    );
  }

  Widget _gutterText(
    int? lineNum,
    double width,
    Color background,
    Color color,
    TextStyle? style,
  ) {
    return Container(
      width: width,
      color: background,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
      alignment: Alignment.centerRight,
      child: Text(
        lineNum?.toString() ?? '',
        maxLines: 1,
        softWrap: false,
        style: style?.copyWith(fontSize: 11, color: color),
      ),
    );
  }

  Widget _highlightedText(DiffRow row, TextStyle? baseStyle) {
    if (row.spans.isEmpty) {
      return Text(row.text, softWrap: false, style: baseStyle);
    }
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final span in row.spans) {
      if (span.start > cursor) {
        spans.add(TextSpan(text: row.text.substring(cursor, span.start)));
      }
      spans.add(TextSpan(text: row.text.substring(span.start, span.end), style: span.style));
      cursor = span.end;
    }
    if (cursor < row.text.length) {
      spans.add(TextSpan(text: row.text.substring(cursor)));
    }
    return Text.rich(TextSpan(children: spans), softWrap: false, style: baseStyle);
  }
}