import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/iconfont.dart';
import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/capture/capture_manager.dart';
import '../../data/capture/capture_models.dart';
import '../../l10n/app_localizations.dart';

/// 请求详情:概览 / 请求 / 响应 / Cookies 四个分区。
class CaptureDetailPage extends ConsumerWidget {
  const CaptureDetailPage({super.key, required this.flowId});

  final String flowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    ref.watch(captureManagerProvider);
    final flow = ref.read(captureManagerProvider).get(flowId);
    if (flow == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.captureDetail)),
        body: Center(child: Text(l10n.captureNotFound)),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: _TitleBar(flow: flow, l10n: l10n),
          titleSpacing: Spacing.md,
          actions: [
            IconButton(
              icon: const Icon(Iconfont.copy, size: 18),
              tooltip: l10n.captureCopyUrl,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: flow.url));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.copied)));
                }
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.captureOverview),
              Tab(text: l10n.captureRequest),
              Tab(text: l10n.captureResponse),
              Tab(text: l10n.captureCookies),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _Overview(flow: flow, l10n: l10n),
            _MessageSection(
              l10n: l10n,
              leadingRows: [
                (l10n.capturePath, Uri.decodeFull(flow.path)),
              ],
              headers: flow.requestHeaders,
              body: flow.requestBody,
              truncated: flow.bodyTruncated,
              isRequest: true,
            ),
            _MessageSection(
              l10n: l10n,
              leadingRows: [
                (l10n.captureStatusCode, flow.statusCode?.toString() ?? '-'),
              ],
              headers: flow.responseHeaders,
              body: flow.responseBody,
              truncated: flow.bodyTruncated,
              isRequest: false,
              error: flow.error,
            ),
            _Cookies(flow: flow, l10n: l10n),
          ],
        ),
      ),
    );
  }
}

/// 标题:方法 + 主机,第二行完整 URL。
class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.flow, required this.l10n});

  final CaptureFlow flow;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${flow.method} ${flow.host}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        Text(
          flow.url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: context.semantic.subtleText),
        ),
      ],
    );
  }
}

/// 概览:卡片式键值行,与抓包工具的 General 分区一致。
class _Overview extends StatelessWidget {
  const _Overview({required this.flow, required this.l10n});

  final CaptureFlow flow;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      children: [
        _kv(context, 'URL', flow.url),
        _kv(
          context,
          l10n.captureStatusCode,
          flow.statusCode?.toString() ?? (flow.error == null ? '-' : 'ERR'),
          valueColor: _statusColor(context),
        ),
        _kv(context, l10n.captureProtocol, flow.protocolVersion),
        _kv(context, l10n.captureDuration, flow.durationMs == null ? '-' : '${flow.durationMs} ms'),
        _kv(context, l10n.captureSize, _sizeText(flow)),
        _kv(context, l10n.captureRemoteAddress, flow.remoteAddress ?? '-'),
        _kv(context, l10n.captureRequestTime, _timeText(flow.startedAt)),
        if (flow.host.isNotEmpty) _kv(context, 'Host', flow.host),
        if (flow.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, Spacing.sm),
            child: Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: SelectableText(
                flow.error!,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color? _statusColor(BuildContext context) {
    if (flow.error != null) return Theme.of(context).colorScheme.error;
    final code = flow.statusCode;
    if (code == null) return null;
    if (code < 300) return context.semantic.success;
    if (code < 400) return const Color(0xFF1976D2);
    if (code < 500) return const Color(0xFFEF6C00);
    return Theme.of(context).colorScheme.error;
  }

  Widget _kv(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, height: 1.5, color: context.semantic.subtleText),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 请求 / 响应分区:首行关键信息 + 可折叠 Headers + Body。
class _MessageSection extends StatefulWidget {
  const _MessageSection({
    required this.l10n,
    required this.leadingRows,
    required this.headers,
    required this.body,
    required this.truncated,
    required this.isRequest,
    this.error,
  });

  final AppLocalizations l10n;
  final List<(String, String)> leadingRows;
  final Map<String, String> headers;
  final String body;
  final bool truncated;
  final bool isRequest;
  final String? error;

  @override
  State<_MessageSection> createState() => _MessageSectionState();
}

class _MessageSectionState extends State<_MessageSection> {
  bool _headersExpanded = true;
  bool _showRawBody = false;

  @override
  Widget build(BuildContext context) {
    final body = widget.body;
    final prettyJson = _tryPrettyJson(body);
    final shown = _showRawBody || prettyJson == null ? body : prettyJson;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      children: [
        for (final row in widget.leadingRows)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    row.$1,
                    style: TextStyle(fontSize: 13, height: 1.5, color: context.semantic.subtleText),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    row.$2,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        if (widget.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 6),
            child: SelectableText(
              widget.error!,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        const Divider(height: 1),
        // Headers 分区:默认展开,长列表可折叠以免遮住 body。
        InkWell(
          onTap: () => setState(() => _headersExpanded = !_headersExpanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, Spacing.xs),
            child: Row(
              children: [
                Text(
                  widget.isRequest ? widget.l10n.captureRequestHeaders : widget.l10n.captureResponseHeaders,
                  style: TextStyle(fontSize: 13, color: context.semantic.subtleText),
                ),
                const SizedBox(width: 2),
                Icon(
                  _headersExpanded ? Iconfont.chevronDown : Iconfont.chevronRight,
                  size: 14,
                  color: context.semantic.subtleText,
                ),
                if (!_headersExpanded)
                  Text(
                    ' · ${widget.headers.length}',
                    style: TextStyle(fontSize: 13, color: context.semantic.subtleText),
                  ),
                const Spacer(),
                if (_headersExpanded)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 15,
                    tooltip: widget.l10n.copy,
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _rawHeaders()));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(widget.l10n.copied)),
                        );
                      }
                    },
                    icon: const Icon(Iconfont.copy),
                  ),
              ],
            ),
          ),
        ),
        if (_headersExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.sm),
            child: SelectableText(
              widget.headers.isEmpty ? '(no headers)' : _rawHeaders(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.5,
                color: context.semantic.subtleText,
              ),
            ),
          ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, Spacing.xs),
          child: Row(
            children: [
              Text(
                widget.isRequest ? widget.l10n.captureRequestBody : widget.l10n.captureResponseBody,
                style: TextStyle(fontSize: 13, color: context.semantic.subtleText),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                '${body.length} chars',
                style: TextStyle(fontSize: 11, color: context.semantic.subtleText),
              ),
              if (prettyJson != null) ...[
                const Spacer(),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () => setState(() => _showRawBody = !_showRawBody),
                  child: Text(
                    _showRawBody ? widget.l10n.captureFormatted : widget.l10n.captureRaw,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (widget.truncated)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            child: Text(
              widget.l10n.captureBodyTruncated,
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.tertiary),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.lg),
          child: SelectableText(
            shown.isEmpty ? '(empty body)' : shown,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.5),
          ),
        ),
      ],
    );
  }

  String _rawHeaders() => widget.headers.entries.map((e) => '${e.key}: ${e.value}').join('\n');

  /// JSON 响应体解析成缩进格式;解析失败返回 null(按原文展示)。
  static String? _tryPrettyJson(String body) {
    final t = body.trim();
    if (t.isEmpty) return null;
    if (!(t.startsWith('{') || t.startsWith('['))) return null;
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(t));
    } catch (_) {
      return null;
    }
  }
}

/// Cookies:请求侧 Cookie 与响应侧 Set-Cookie 分两组列出。
class _Cookies extends StatelessWidget {
  const _Cookies({required this.flow, required this.l10n});

  final CaptureFlow flow;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final req = flow.requestCookies;
    final res = flow.responseCookies;
    if (req.isEmpty && res.isEmpty) {
      return Center(
        child: Text(
          l10n.captureNoCookies,
          style: TextStyle(color: context.semantic.subtleText, fontSize: 13),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        if (req.isNotEmpty) ...[
          _sectionTitle(context, l10n.captureRequestCookies),
          for (final c in req) _cookieRow(context, c),
          const SizedBox(height: Spacing.md),
        ],
        if (res.isNotEmpty) ...[
          _sectionTitle(context, l10n.captureResponseCookies),
          for (final c in res) _cookieRow(context, c),
        ],
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xs),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.semantic.subtleText),
      ),
    );
  }

  Widget _cookieRow(BuildContext context, String raw) {
    final idx = raw.indexOf('=');
    final name = idx > 0 ? raw.substring(0, idx).trim() : raw;
    final value = idx > 0 ? raw.substring(idx + 1).trim() : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: SelectableText(
              name,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: context.semantic.subtleText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _sizeText(CaptureFlow flow) {
  final bytes = flow.requestBytes + flow.responseBytes;
  if (bytes <= 0) return '0 B';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}

String _timeText(DateTime t) =>
    '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:'
    '${t.second.toString().padLeft(2, '0')}.${t.millisecond.toString().padLeft(3, '0')}';
