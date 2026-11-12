import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../core/theme/tokens.dart';

/// 提示词正文与帮助说明的 Markdown 样式(与聊天消息正文一致)。
MarkdownStyleSheet promptMarkdownStyle(BuildContext context) {
  final theme = Theme.of(context);
  final codeStyle = theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', height: 1.4);
  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurface,
      height: 24 / 16,
    ),
    code: codeStyle?.copyWith(backgroundColor: theme.colorScheme.surfaceContainerHighest),
    codeblockDecoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(Radii.mdLarge),
      border: Border.all(width: 1, color: theme.colorScheme.outlineVariant),
    ),
    blockquoteDecoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(Radii.lg),
    ),
  );
}
