import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../../agent/models/agent_attachment.dart';
import '../../../agent/models/agent_message.dart';
import '../../../agent/models/project.dart';
import '../../../agent/models/todo_item.dart';
import '../../../app/current_project.dart';
import '../../../core/icons/iconfont.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/attachment_store.dart';
import '../../../data/container/external_storage.dart';
import '../../../data/workspaces.dart';
import '../../../l10n/app_localizations.dart';
import 'image_preview.dart';
import 'todo_views.dart';

/// 消息区样式(逐值移植自上游 ChatMessageStyle.kt / MessageBubbles.kt / StatusBubbles.kt):
/// 扁平文档流——助手正文直接铺在页面底色上;用户消息是浅色药丸;思考是可折叠的一行。
abstract final class ChatStyle {
  static const double hairline = 1;
  static const double bubbleCorner = 14;
  static const double cardCorner = 10;
  static const double panelCorner = 8;
  static const double rowIconSize = 16;

  /// 正文列最大宽度(上游 ContentWidth.readable)。
  static const double readable = 800;

  /// 思考展开窗口最大高度。
  static const double reasoningWindowMaxHeight = 300;
}

/// 工具名字形映射(对齐上游 toolIcon,键为注册名,忽略大小写)。
IconData toolIconFor(String? toolName) {
  switch (toolName?.toLowerCase()) {
    case 'editfile':
    case 'writefile':
    case 'generateimage':
      return Iconfont.edit3;
    case 'readfile':
    case 'list':
    case 'sendfile':
      return Iconfont.fileText;
    case 'viewimage':
      return Iconfont.image;
    case 'search':
    case 'websearch':
    case 'webfetch':
      return Iconfont.search;
    case 'browser':
      return Iconfont.globe;
    case 'bash':
    case 'terminal':
      return Iconfont.terminal;
    case 'askuserquestion':
      return Iconfont.helpCircle;
    case 'todo':
      return Iconfont.check;
    case 'task':
      return Iconfont.cpu;
    case 'memory':
      return Iconfont.database;
    default:
      return Iconfont.wrench;
  }
}

/// 工具执行中的场景文案:把工具名归成「正在做什么」(对齐上游 toolRunningLabelRes)。
String toolRunningLabel(AppLocalizations l10n, String? toolName) {
  switch (toolName?.toLowerCase()) {
    case 'editfile':
    case 'writefile':
      return l10n.chatStatusEditingFile;
    case 'readfile':
    case 'list':
    case 'sendfile':
      return l10n.chatStatusReadingFile;
    case 'viewimage':
      return l10n.chatStatusViewingImage;
    case 'search':
    case 'websearch':
    case 'webfetch':
      return l10n.chatStatusSearchingWeb;
    case 'browser':
      return l10n.chatStatusBrowsingWeb;
    case 'bash':
    case 'terminal':
      return l10n.chatStatusRunningCommand;
    case 'askuserquestion':
      return l10n.chatStatusAskingUser;
    case 'generateimage':
      return l10n.chatStatusGeneratingImage;
    case 'todo':
      return l10n.chatStatusUpdatingTodo;
    case 'task':
      return l10n.chatStatusStartingSubagent;
    case 'memory':
      return l10n.chatStatusReadingMemory;
    default:
      return l10n.chatStatusCallingTool;
  }
}

/// 单条消息(含流式中的助手消息)的渲染。
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.role,
    required this.content,
    this.reasoning,
    this.attachments = const [],
    this.toolName,
    this.toolArgs,
    this.isError = false,
    this.timestamp = 0,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.cachedInputTokens = 0,
    this.durationMs,
    this.streaming = false,
    this.showActions = false,
    this.runningTool,
    this.onRewind,
    this.onMore,
    this.isCompactionMarker = false,
    this.isContextSummary = false,
  });

  MessageBubble.fromMessage(
    AgentMessage message, {
    super.key,
    this.durationMs,
    this.showActions = false,
    this.onRewind,
    this.onMore,
  })  : role = message.role,
        content = message.content,
        reasoning = message.reasoning,
        attachments = message.attachments,
        toolName = message.toolName,
        toolArgs = message.toolArgs,
        isError = message.isError,
        timestamp = message.timestamp,
        inputTokens = message.inputTokens,
        outputTokens = message.outputTokens,
        cachedInputTokens = message.cachedInputTokens,
        isCompactionMarker = message.isCompactionMarker,
        isContextSummary = message.isContextSummary,
        streaming = false,
        runningTool = null;

  final MessageRole role;
  final String content;
  final String? reasoning;
  final List<AgentAttachment> attachments;

  /// 流式等待中正在执行的工具名(上游 AgentBusyIndicator 的场景文案来源)。
  final String? runningTool;

  /// 仅 tool:工具名、参数(JSON 文本)与失败标记。
  final String? toolName;
  final String? toolArgs;
  final bool isError;

  final int timestamp;
  final int inputTokens;
  final int outputTokens;
  final int cachedInputTokens;
  final int? durationMs;
  final bool streaming;
  final bool showActions;

  /// 上下文压缩 marker(user 消息):渲染为压缩分隔线而非普通消息。
  final bool isCompactionMarker;

  /// 压缩产生的接手摘要(assistant 消息):渲染为摘要卡片。
  final bool isContextSummary;

  /// 点击「回退」时回调(仅用户消息展示该按钮);为 null 时不渲染。
  final VoidCallback? onRewind;

  /// 点击「更多选项」时回调;为 null 时不渲染。
  final VoidCallback? onMore;

  /// 元信息行上操作按钮之间的间距。按钮盒只比图标大 3dp,
  /// 这里再留 2dp,视觉间隙约 8dp,比照 Spacing.xs 排布明显更紧凑。
  static const double _metaGap = 2;

  bool get _isUser => role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 工具结果消息:扁平工具行(工具图标 + 工具名 + 参数摘要,可展开看结果)
    if (role == MessageRole.tool) {
      return ToolRow(
        name: toolName ?? 'tool',
        args: toolArgs,
        result: content,
        isError: isError,
      );
    }
    // 上下文压缩:marker 渲染为分隔线,摘要渲染为卡片(对齐上游压缩卡片展示)。
    if (isCompactionMarker) return _compactionDivider(context, l10n);
    if (isContextSummary) return _compactionSummaryCard(context, l10n);
    final hasReasoning = reasoning != null && reasoning!.trim().isNotEmpty;
    final hasContent = content.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Column(
        crossAxisAlignment: _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!_isUser && hasReasoning)
            ReasoningRow(text: reasoning!, live: streaming, durationMs: durationMs),
          if (_isUser && attachments.isNotEmpty) _attachmentStrip(context),
          if (_isUser && hasContent) _userContent(context),
          if (!_isUser && streaming && !hasContent && !hasReasoning)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    runningTool == null
                        ? l10n.chatStatusThinking
                        : toolRunningLabel(l10n, runningTool),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: context.semantic.subtleText,
                        ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  const TypingDots(),
                ],
              ),
            )
          else if (!_isUser && hasContent)
            MarkdownBody(
              data: content,
              selectable: true,
              styleSheet: _markdownStyle(context),
              onTapLink: (text, href, title) => _handleChatLink(context, href),
            ),
          if (!streaming && (hasContent || _isUser)) _metaRow(context, hasContent),
        ],
      ),
    );
  }

  /// 压缩 marker 的渲染:居中分隔线(对齐上游压缩卡片的展示语义)。
  Widget _compactionDivider(BuildContext context, AppLocalizations l10n) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: Row(
        children: [
          Expanded(child: Divider(color: color, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
            child: Text(
              l10n.chatContextCompressed,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.semantic.subtleText,
                  ),
            ),
          ),
          Expanded(child: Divider(color: color, height: 1)),
        ],
      ),
    );
  }

  /// 压缩产生的接手摘要卡片:弱化背景 + 标题 + Markdown 正文。
  Widget _compactionSummaryCard(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(ChatStyle.cardCorner),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compress, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: Spacing.sm),
              Text(
                l10n.chatCompactionSummary,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          MarkdownBody(
            data: _linkifyFilePathsForMarkdown(content),
            styleSheet: _markdownStyle(context),
            onTapLink: (text, href, title) => _handleChatLink(context, href),
          ),
        ],
      ),
    );
  }

  /// 消息附件列表(对齐上游 MessageAttachmentList):一行一个文件——
  /// 44dp 缩略图(图片真缩略图,其它文件图标)+ 文件名 + 「大小 · 容器路径」,图片可点开全屏。
  Widget _attachmentStrip(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.xs, bottom: Spacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final attachment in attachments) ...[
            if (attachment != attachments.first) const SizedBox(height: Spacing.xs),
            _AttachmentRow(attachment: attachment),
          ],
        ],
      ),
    );
  }

  static final RegExp _pathCandidate = RegExp(
    r'''(?:[~./\\]?(?:[\w\u4e00-\u9fff.-]+[/\\])+[\w\u4e00-\u9fff.-]+\.[\w]+|[\w\u4e00-\u9fff.-]+\.[A-Za-z0-9]{1,8})''',
  );

  Widget _userContent(BuildContext context) {
    final l10nMaxWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = (l10nMaxWidth < ChatStyle.readable ? l10nMaxWidth : ChatStyle.readable) -
        Spacing.lg * 2;
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(ChatStyle.bubbleCorner),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      child: SelectableText.rich(
        _buildLinkifiedTextSpan(context, content) as TextSpan,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              height: 20 / 14,
            ),
      ),
    );
  }

  InlineSpan _buildLinkifiedTextSpan(BuildContext context, String text) {
    final spans = <InlineSpan>[];
    int start = 0;
    for (final match in _pathCandidate.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      final raw = match.group(0)!;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: InkWell(
            onTap: () => _handleChatLink(context, raw),
            child: Text(
              raw,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: Theme.of(context).colorScheme.primary,
                    height: 20 / 14,
                  ),
            ),
          ),
        ),
      );
      start = match.end;
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return TextSpan(children: spans.isEmpty ? [TextSpan(text: text)] : spans);
  }

  /// 气泡下方的元信息行:用户 = 时间 + 复制;助手(最新一条)= 用量 + 缓存命中 + 复制。
  Widget _metaRow(BuildContext context, bool hasContent) {
    final l10n = AppLocalizations.of(context);
    final children = <Widget>[];
    var emitted = false;
    void gap(double size) {
      if (emitted) children.add(SizedBox(width: size));
    }

    if (_isUser) {
      children.add(ChatMetaText(text: formatClockTime(timestamp)));
      emitted = true;
      // 用户消息的复制按钮常驻(上游:每条用户消息都挂操作)
      if (hasContent) {
        gap(_metaGap);
        children.add(_CopyAction(text: content));
        emitted = true;
      }
      if (onRewind != null) {
        gap(_metaGap);
        children.add(_MetaAction(
          icon: Iconfont.rotateCcw,
          tooltip: l10n.checkpointRewindTitle,
          onTap: onRewind!,
        ));
        emitted = true;
      }
    } else {
      if (inputTokens > 0 || outputTokens > 0) {
        children.add(ChatMetaText(
          text: '↑${formatTokenCount(inputTokens)} ↓${formatTokenCount(outputTokens)}',
        ));
        emitted = true;
      }
      final cacheRate = formatCacheHitRate(inputTokens, cachedInputTokens);
      if (cacheRate != null) {
        gap(Spacing.sm);
        children.add(Icon(Iconfont.database, size: 12, color: context.semantic.subtleText));
        children.add(const SizedBox(width: 2));
        children.add(ChatMetaText(text: cacheRate));
        emitted = true;
      }
      if (durationMs != null && durationMs! > 0) {
        gap(Spacing.sm);
        children.add(Icon(Iconfont.clock, size: 13, color: context.semantic.subtleText));
        children.add(const SizedBox(width: 2));
        children.add(ChatMetaText(text: formatTaskDuration(durationMs!)));
        emitted = true;
      }
      if (hasContent && showActions) {
        gap(Spacing.xs);
        children.add(_CopyAction(text: content));
        emitted = true;
      }
    }

    // 「更多选项」排在元信息行最后(先给信息,再给操作入口)。
    if (onMore != null && (_isUser || showActions)) {
      gap(_metaGap);
      children.add(_MetaAction(
        icon: Iconfont.moreHorizontal,
        tooltip: l10n.chatMoreOptions,
        onTap: onMore!,
      ));
      emitted = true;
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.xs),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  MarkdownStyleSheet _markdownStyle(BuildContext context) {
    final theme = Theme.of(context);
    final codeStyle = theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', height: 1.4);
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface,
        height: 24 / 16,
      ),
      code: codeStyle?.copyWith(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(ChatStyle.cardCorner),
        border: Border.all(
          width: ChatStyle.hairline,
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      blockquoteDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(ChatStyle.panelCorner),
      ),
    );
  }
}

/// 工具结果行(移植上游工具行的 Phase 2 子集):
/// 圆角面板 + 状态圆点(成功绿/失败红)+ 工具名 + 参数摘要,点开显示完整结果。
class ToolRow extends StatefulWidget {
  const ToolRow({
    super.key,
    required this.name,
    this.args,
    required this.result,
    this.isError = false,
  });

  final String name;
  final String? args;
  final String result;
  final bool isError;

  @override
  State<ToolRow> createState() => _ToolRowState();
}

class _ToolRowState extends State<ToolRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantic = context.semantic;
    // 图标基色对齐上游 ToolStatusIcon:失败=删除色,其余=中性色(运行中才用主色)。
    final statusColor = widget.isError ? semantic.diffRemove : theme.colorScheme.onSurfaceVariant;
    final todo = widget.name == 'todo' && !widget.isError
        ? TodoSnapshot.parseToolResult(widget.result)
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(ChatStyle.panelCorner),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Icon(
                    toolIconFor(widget.name),
                    size: ChatStyle.rowIconSize,
                    color: statusColor,
                    semanticLabel: widget.isError ? l10n.chatToolFailed : l10n.chatToolSucceeded,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    widget.name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      _argsSummary(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: semantic.subtleText,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 待办:标题行行尾的完成度计数(全部完成时转绿)。
                  if (todo != null && todo.total > 0) ...[
                    const SizedBox(width: Spacing.sm),
                    Text(
                      '${todo.completed}/${todo.total}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: todo.completed == todo.total
                            ? semantic.diffAdd
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  Icon(
                    _expanded ? Icons.expand_more : Icons.chevron_right,
                    size: 16,
                    color: semantic.subtleText,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 6),
              if (todo != null && todo.items.isNotEmpty)
                TodoCard(items: todo.items)
              else
                SelectableText(
                  _prettyResult(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    height: 1.4,
                    color: semantic.subtleText,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// 参数摘要:优先展示 command/path/args/pattern 这类关键字段(对齐上游 toolArgHint)。
  String _argsSummary() {
    final raw = widget.args;
    if (raw == null || raw.isEmpty) return '';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        for (final key in [
          'command',
          'cmd',
          'path',
          'file_path',
          'file',
          'query',
          'pattern',
          'url',
          'name',
          'args',
          'subject',
        ]) {
          final value = decoded[key];
          if (value is String && value.isNotEmpty) return value;
        }
        if (decoded.isNotEmpty) return decoded.values.first.toString();
      }
    } catch (_) {
      // 非 JSON 参数直接原样展示
    }
    return raw;
  }

  /// 结果正文:解析传输串后美化输出(成功取 data,失败取 message)。
  String _prettyResult() {
    try {
      final decoded = jsonDecode(widget.result);
      if (decoded is Map) {
        final status = decoded['status'];
        if (status == 'error') {
          return '${decoded['message'] ?? ''}'
              '${decoded['code'] != null ? ' (${decoded['code']})' : ''}';
        }
        final data = decoded['data'];
        if (data is Map) {
          final output = data['output'];
          if (output is String) return output;
          return const JsonEncoder.withIndent('  ').convert(data);
        }
      }
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return widget.result;
    }
  }
}

/// 附件缩略图边长:一行一个文件时左侧的小图(上游 AttachmentThumbSize)。
const double _attachmentThumbSize = 44;

/// 已发送附件的一行(上游 MessageAttachmentRow):缩略图 + 文件名 + 大小 · 容器路径。
class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.attachment});

  final AgentAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = attachment.fileName.isEmpty ? l10n.fileFallback : attachment.fileName;
    final meta = [
      if (attachment.sizeBytes > 0) formatBytes(attachment.sizeBytes),
      if (attachment.containerPath.isNotEmpty) attachment.containerPath,
    ].join(' · ');
    final clickable = attachment.isImage;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: (MediaQuery.sizeOf(context).width < ChatStyle.readable
                ? MediaQuery.sizeOf(context).width
                : ChatStyle.readable) -
            Spacing.lg * 2,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(ChatStyle.cardCorner),
        ),
        child: InkWell(
          onTap: clickable
              ? () => showImagePreview(
                    context,
                    path: attachment.localPath,
                    title: name,
                  )
              : null,
          borderRadius: BorderRadius.circular(ChatStyle.cardCorner),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.sm),
            child: Row(
              children: [
                _AttachmentThumb(attachment: attachment),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        meta,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (clickable)
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: context.semantic.subtleText,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 附件行的缩略图:图片直接读本地文件,其它类型给文件图标。
class _AttachmentThumb extends StatelessWidget {
  const _AttachmentThumb({required this.attachment});

  final AgentAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 缩略图按物理像素采样解码(对齐上游 ThumbnailCache 的 180px 档):44dp
    // 小图不需要全分辨率位图;解码结果由框架 ImageCache 持有,滑出再滑回直接
    // 命中,不再重读原图解码。
    final thumbPixels =
        (_attachmentThumbSize * MediaQuery.of(context).devicePixelRatio).round();
    return SizedBox(
      width: _attachmentThumbSize,
      height: _attachmentThumbSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: attachment.isImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(Radii.sm),
                child: Image.file(
                  File(attachment.localPath),
                  cacheWidth: thumbPixels,
                  cacheHeight: thumbPixels,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => _fallbackIcon(context, Iconfont.image),
                ),
              )
            : _fallbackIcon(context, Iconfont.fileText),
      ),
    );
  }

  Widget _fallbackIcon(BuildContext context, IconData icon) => Center(
        child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      );
}

/// 消息下方的 12sp 弱化小字(上游 ChatMetaText)。
class ChatMetaText extends StatelessWidget {
  const ChatMetaText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.semantic.subtleText),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// 复制按钮:24dp 命中区 + 14dp 图标;复制成功短暂变对勾(上游 ChatCopyAction/MessageActionIconButton)。
class _CopyAction extends StatefulWidget {
  const _CopyAction({required this.text});

  final String text;

  @override
  State<_CopyAction> createState() => _CopyActionState();
}

class _CopyActionState extends State<_CopyAction> {
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 20dp 定尺寸:IconButton 的 constraints 只是下限,默认 tapTargetSize 会撑到 48dp。
    // 盒子只比 14dp 图标大 3dp,三个按钮的视觉间隙才紧凑。
    return SizedBox(
      width: 20,
      height: 20,
      child: IconButton(
      padding: EdgeInsets.zero,
      color: context.semantic.subtleText,
      tooltip: _copied ? l10n.copied : l10n.copy,
      icon: Icon(_copied ? Icons.check : Iconfont.copy, size: 14),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: widget.text));
        setState(() => _copied = true);
        _timer?.cancel();
        _timer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _copied = false);
        });
      },
      ),
    );
  }
}

/// 元信息行上的普通图标按钮(回退 / 更多选项),与复制按钮同尺寸同样式。
class _MetaAction extends StatelessWidget {
  const _MetaAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 与复制按钮同尺寸(20dp 定尺寸),三者间距才一致。
    return SizedBox(
      width: 20,
      height: 20,
      child: IconButton(
        padding: EdgeInsets.zero,
        color: context.semantic.subtleText,
        tooltip: tooltip,
        icon: Icon(icon, size: 14),
        onPressed: onTap,
      ),
    );
  }
}

/// 思考过程折叠行(上游 ReasoningBubble):默认收起为一行,
/// 左侧思考图标 + 文案(进行中/完成 + 耗时)+ 展开箭头;展开后渲染 Markdown,限高 300。
class ReasoningRow extends StatefulWidget {
  const ReasoningRow({
    super.key,
    required this.text,
    this.live = false,
    this.durationMs,
  });

  final String text;
  final bool live;
  final int? durationMs;

  @override
  State<ReasoningRow> createState() => _ReasoningRowState();
}

/// 折叠行的内容预览(对齐上游 reasoningPreviewLine):
/// 进行中取最后一行(跟着模型正在写的内容滚动),结束后取第一行。
String reasoningPreviewLine(String text, {required bool live}) {
  final normalized = text.replaceAll('\r\n', '\n');
  if (live) {
    var end = normalized.length;
    while (end > 0 && normalized[end - 1].trim().isEmpty) {
      end--;
    }
    if (end == 0) return '';
    final start = normalized.lastIndexOf('\n', end - 1) + 1;
    return normalized.substring(start, end).trim();
  }
  for (final line in normalized.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return '';
}

class _ReasoningRowState extends State<ReasoningRow> {
  bool _expanded = false;
  Timer? _ticker;
  /// 绝对起始时间戳:切页/重新挂载后显示的仍是真实时长(上游存 timerStartMillis 而非累加)。
  DateTime? _startedAt;
  int _elapsedMs = 0;

  @override
  void initState() {
    super.initState();
    if (widget.live) _startTicker();
  }

  @override
  void didUpdateWidget(ReasoningRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.live && !oldWidget.live) _startTicker();
    if (!widget.live && oldWidget.live) _stopTicker();
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }

  void _startTicker() {
    _startedAt ??= DateTime.now();
    _ticker ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
      final start = _startedAt;
      if (mounted && start != null) {
        setState(() => _elapsedMs = DateTime.now().difference(start).inMilliseconds);
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// 折叠行的内容预览(对齐上游 reasoningPreviewLine):
  /// 进行中取最后一行(跟着模型正在写的内容滚动),结束后取第一行。
  static String previewLine(String text, {required bool live}) =>
      reasoningPreviewLine(text, live: live);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semantic = context.semantic;
    final iconGray = semantic.subtleText;
    final elapsed = widget.live ? _elapsedMs : (widget.durationMs ?? 0);
    // 上游:耗时为空或 <=0 时只显示「思考完成」,不编造最小时长。
    final seconds = elapsed > 0 ? (elapsed / 1000).toStringAsFixed(1) : null;
    final label = widget.live
        ? l10n.chatThinkingRunningTime(seconds ?? '0.1')
        : seconds != null
            ? l10n.chatThinkingDoneTime(seconds)
            : l10n.chatThinkingDone;
    final preview = previewLine(widget.text, live: widget.live);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 28),
            child: Row(
              children: [
                Icon(Iconfont.atom, size: ChatStyle.rowIconSize, color: iconGray),
                const SizedBox(width: Spacing.sm),
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: semantic.subtleText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // 收起态在同行展示一行内容预览(上游 reasoningPreviewLine)。
                if (!_expanded && preview.isNotEmpty) ...[
                  const SizedBox(width: Spacing.xs),
                  Expanded(
                    child: Text(
                      preview,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: semantic.subtleText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  const Spacer(),
                const SizedBox(width: Spacing.xs),
                Icon(
                  _expanded ? Icons.expand_more : Icons.chevron_right,
                  size: 18,
                  color: iconGray,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _expanded ? 1 : 0,
            child: !_expanded
                ? const SizedBox(width: double.infinity)
                : GestureDetector(
                    // 上游支持双击收起(detectTapGestures onDoubleTap)。
                    onDoubleTap: () => setState(() => _expanded = false),
                    child: Padding(
                      padding: const EdgeInsets.only(top: Spacing.sm),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: ChatStyle.reasoningWindowMaxHeight,
                        ),
                        child: SingleChildScrollView(
                          child: MarkdownBody(
                            data: _linkifyFilePathsForMarkdown(widget.text),
                            selectable: true,
                            onTapLink: (text, href, title) => _handleChatLink(context, href),
                            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                              p: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: semantic.subtleText,
                                    height: 1.5,
                                  ),
                            ),
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
}

/// 三个循环跳动的点(上游 TypingDots):正在生成但还没有内容时的占位指示。
class TypingDots extends StatefulWidget {
  const TypingDots({super.key, this.color, this.dotSize = 6});

  final Color? color;
  final double dotSize;

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.semantic.subtleText;
    return SizedBox(
      height: widget.dotSize + 10,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < 3; index++) ...[
              if (index > 0) const SizedBox(width: 4),
              Transform.translate(
                offset: Offset(0, _offsetFor(index)),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 关键帧:0→180ms 上移 5px,180→360ms 回落,其余时间静止;三个点各错开 150ms。
  double _offsetFor(int index) {
    final t = (_controller.value * 900 - index * 150) % 900;
    final phase = t < 0 ? t + 900 : t;
    if (phase <= 180) return -5 * (phase / 180);
    if (phase <= 360) return -5 * (1 - (phase - 180) / 180);
    return 0;
  }
}

/// 时间戳格式(上游 formatClockTime):HH:mm。
String formatClockTime(int millis) {
  final dt = DateTime.fromMillisecondsSinceEpoch(millis);
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

/// token 数量简写(上游 formatTokenCount):1.2k / 1.2M。
String formatTokenCount(int tokens) {
  if (tokens >= 1000000) return '${(tokens / 1000000).toStringAsFixed(1)}M';
  if (tokens >= 1000) return '${(tokens / 1000).toStringAsFixed(1)}k';
  return '$tokens';
}

/// 任务耗时格式(上游 formatTaskDuration):12s / 2:05 / 1:02:05。
String formatTaskDuration(int millis) {
  final totalSeconds = ((millis + 500) ~/ 1000).clamp(1, 1 << 62);
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  final padded = seconds.toString().padLeft(2, '0');
  if (hours > 0) return '$hours:${minutes.toString().padLeft(2, '0')}:$padded';
  if (minutes > 0) return '$minutes:$padded';
  return '${seconds}s';
}

final RegExp _barePathPattern = RegExp(
  r'''(?<!\]\(|`|[<"'])([~./]?(?:[\w\u4e00-\u9fff.-]+[/\\])+[\w\u4e00-\u9fff.-]+\.[A-Za-z0-9]{1,8}|[\w\u4e00-\u9fff.-]+[/\\][\w\u4e00-\u9fff.-]+\.[A-Za-z0-9]{1,8})(?![`"'>)])''',
);

String _linkifyFilePathsForMarkdown(String md) {
  if (md.isEmpty) return md;
  final lines = md.split('\n');
  final out = <String>[];
  bool inFence = false;
  for (final line in lines) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('```')) {
      inFence = !inFence;
      out.add(line);
      continue;
    }
    if (inFence) {
      out.add(line);
      continue;
    }
    out.add(
      line.replaceAllMapped(_barePathPattern, (m) {
        final path = m.group(1)!;
        // Skip if it looks like a URL segment inside text unlikely; keep simple.
        if (path.contains('://')) return path;
        final encoded = path.replaceAll(' ', '%20');
        return '[$path]($encoded)';
      }),
    );
  }
  return out.join('\n');
}

/// 聊天正文里点击文件链接时打开编辑器。
Future<void> _handleChatLink(BuildContext context, String? href) async {
  if (href == null || href.isEmpty) return;
  if (href.startsWith('http://') || href.startsWith('https://')) return;
  var path = href;
  if (path.startsWith('file://')) {
    path = Uri.tryParse(path)?.toFilePath() ?? path.substring(7);
  }
  path = Uri.decodeComponent(path);
  if (path.startsWith('~/')) path = path.substring(2);
  if (path.startsWith('./')) path = path.substring(2);
  // 模型/工具输出有时会写成 ~/workspace/小说章节/... 这类「容器工作区」路径;
  // 在写作项目里实际文件在外部工作区(AI小说/<项目名>)。只去掉字面 workspace/
  // 会把相对路径拼到沙盒 default 目录,导致打开时报 PathNotFound。
  if (path.startsWith('workspace/')) path = path.substring('workspace/'.length);

  // 拆分行号后缀: `第2章.md:25` → path=`第2章.md`, line=25
  int? line;
  final lineMatch = RegExp(r':(\d+)$').firstMatch(path);
  if (lineMatch != null) {
    line = int.tryParse(lineMatch.group(1)!);
    path = path.substring(0, lineMatch.start);
  }

  final container = ProviderScope.containerOf(context, listen: false);

  String resolved;
  if (path.startsWith('/')) {
    resolved = path;
  } else {
    // 相对路径按多个已知工作区根目录逐一解析:当前项目工作区优先(写作项目会
    // 指向 AI小说/<项目名>),再试全局已知工作区。先等待 workspacesProvider
    // 就绪,否则它还未加载时只有沙盒 rootPath 作为候选,会把外部写作文件
    // 错误地拼到容器沙盒下并报 PathNotFoundException。
    final roots = <String>[];
    try {
      final all = await container.read(workspacesProvider.future);
      for (final ws in all.workspaces) {
        if (ws.path.isNotEmpty) roots.add(ws.path);
      }
    } catch (_) {
      // workspaces 尚未就绪时,至少保留当前工作区根作为兜底候选。
    }
    // 写作项目:明确加入 AI小説/<项目名> 作为候选根,不依赖
    // currentWorkspaceProvider 可能因 workspacesProvider 尚未就绪而回退到沙盒。
    final project = container.read(currentProjectProvider);
    if (project != null && project.kind == ProjectKind.writing) {
      try {
        final externalRoot = p.join(await ExternalStorage.primaryRoot(), writingWorkspaceName);
        final writingProjectDir = p.join(externalRoot, project.name);
        if (!roots.contains(writingProjectDir)) roots.add(writingProjectDir);
      } catch (_) {
        // 外部存储不可访问时跳过,继续尝试其它根。
      }
    }

    final primary = container.read(currentWorkspaceProvider).rootPath;
    if (primary.isNotEmpty && !roots.contains(primary)) roots.add(primary);
    final candidates = roots
        .map((r) => r.endsWith(Platform.pathSeparator)
            ? '$r$path'
            : '$r${Platform.pathSeparator}$path')
        .toList();
    resolved = path;
    for (final c in candidates) {
      try {
        if (await File(c).exists() || await Directory(c).exists()) {
          resolved = c;
          break;
        }
      } catch (_) {
        // 某个根目录不可访问时跳过,尝试下一个。
      }
    }
    if (resolved == path && primary.isNotEmpty) {
      resolved = primary.endsWith(Platform.pathSeparator)
          ? '$primary$path'
          : '$primary${Platform.pathSeparator}$path';
    }
  }

  if (!context.mounted) return;
  final query = <String, String>{'path': resolved};
  if (line != null) query['line'] = line.toString();
  context.push(Uri(path: '/editor', queryParameters: query).toString());
}

/// 缓存命中率(上游 formatCacheHitRate):命中/总输入,取整;无数据或未命中返回 null。
String? formatCacheHitRate(int inputTokens, int cachedInputTokens) {
  if (inputTokens <= 0 || cachedInputTokens <= 0) return null;
  final rate = (cachedInputTokens * 100.0 / inputTokens).clamp(0.0, 100.0);
  return '${rate.round()}%';
}