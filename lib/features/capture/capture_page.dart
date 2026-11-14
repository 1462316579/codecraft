import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/icons/iconfont.dart';
import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/capture/capture_manager.dart';
import '../../data/capture/capture_pip.dart';
import '../../data/capture/capture_models.dart';
import '../../l10n/app_localizations.dart';
import 'capture_detail_page.dart';

class CapturePage extends ConsumerStatefulWidget {
  const CapturePage({super.key});

  @override
  ConsumerState<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends ConsumerState<CapturePage> {
  final _portController = TextEditingController(text: '8888');
  final _searchController = TextEditingController();
  String _query = '';
  bool _busy = false;
  bool _pipBusy = false;
  String? _hostFilter;

  @override
  void dispose() {
    _portController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _downloadCa(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final manager = ref.read(captureManagerProvider);
    final info = await manager.caInfo();
    final path = info['certPath'] as String?;
    if (path == null || !mounted) return;
    try {
      final src = File(path);
      if (!await src.exists()) return;
      final dir = await getExternalStorageDirectory();
      if (dir == null) return;
      final downloadDir = Directory('${dir.path}/Download');
      await downloadDir.create(recursive: true);
      final target = File('${downloadDir.path}/codecraft-ca.pem');
      await src.copy(target.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.captureCaPath}: ${target.path}')),
        );
      }
      await Share.shareXFiles([XFile(target.path)], text: l10n.captureCaTitle);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _installCa(BuildContext context) async {
    final manager = ref.read(captureManagerProvider);
    final info = await manager.caInfo();
    final path = info['certPath'] as String?;
    final l10n = AppLocalizations.of(context);
    if (path == null) return;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.captureCaTitle),
        content: SelectableText(
          '${l10n.captureCaPath}: $path\n\n${l10n.captureCaGuide}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
          TextButton(
            onPressed: () async {
              await CaptureChannel.openSecuritySettings();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l10n.captureOpenSecurity),
          ),
          TextButton(
            onPressed: () async {
              if (ctx.mounted) Navigator.pop(ctx);
              await _downloadCa(context);
            },
            child: Text(l10n.captureDownloadCa),
          ),
          FilledButton.tonal(
            onPressed: () async {
              final ok = await CaptureChannel.installCaCert(path);
              if (!ok) await Clipboard.setData(ClipboardData(text: path));
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted && !ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.captureCaInstallFail)),
                );
              }
            },
            child: Text(l10n.captureInstallCa),
          ),
        ],
      ),
    );
  }

  Future<void> _startCapture() async {
    final manager = ref.read(captureManagerProvider);
    final port = int.tryParse(_portController.text) ?? 8888;
    final state = await manager.start(port: port);
    if (state.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error!)),
      );
    }
  }

  Future<void> _enterPip() async {
    if (_pipBusy) return;
    setState(() => _pipBusy = true);
    try {
      final l10n = AppLocalizations.of(context);
      final manager = ref.read(captureManagerProvider);
      final ok = await CapturePictureInPicture.enter(running: manager.status().running);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.capturePipUnsupported)));
      }
    } finally {
      if (mounted) setState(() => _pipBusy = false);
    }
  }

  Future<void> _clearWithConfirm() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.captureClear),
        content: Text(l10n.captureClearConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.confirm)),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(captureManagerProvider).clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final manager = ref.watch(captureManagerProvider);
    final s = manager.status();

    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final tab = DefaultTabController.of(context).index;
          final flows = _hostFilter != null
              ? manager.search(query: _query, host: _hostFilter, limit: 300)
              : (_query.trim().isEmpty
                  ? manager.list(limit: 300)
                  : manager.search(query: _query, limit: 300));
          final hosts = tab == 1 ? manager.hosts(query: _query) : const <CaptureHostSummary>[];

          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.captureTitle),
              actions: [
                if (CapturePictureInPicture.supported)
                  IconButton(
                    tooltip: l10n.capturePip,
                    icon: _pipBusy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Iconfont.pictureInPicture, size: 20),
                    onPressed: _pipBusy ? null : _enterPip,
                  ),
                IconButton(
                  tooltip: l10n.captureCaTitle,
                  icon: const Icon(Iconfont.shield),
                  onPressed: () => _installCa(context),
                ),
                IconButton(
                  tooltip: l10n.captureClear,
                  icon: const Icon(Iconfont.trash2),
                  onPressed: s.flowCount == 0 ? null : _clearWithConfirm,
                ),
              ],
              bottom: TabBar(
                tabs: [Tab(text: l10n.captureSequence), Tab(text: l10n.captureDomains)],
              ),
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, Spacing.sm),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.captureSearchHint,
                      prefixIcon: const Icon(Iconfont.search, size: 18),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Iconfont.x, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                if (_hostFilter != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                      child: InputChip(
                        label: Text(_hostFilter!),
                        onDeleted: () => setState(() => _hostFilter = null),
                      ),
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _FlowList(flows: flows, l10n: l10n),
                      _HostList(
                        hosts: hosts,
                        l10n: l10n,
                        onSelect: (host) => setState(() => _hostFilter = host),
                      ),
                    ],
                  ),
                ),
                _StatusBar(state: s, l10n: l10n),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      try {
                        if (ref.read(captureManagerProvider).status().running) {
                          await ref.read(captureManagerProvider).stop();
                        } else {
                          await _startCapture();
                        }
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: Icon(s.running ? Iconfont.pause : Iconfont.play),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        },
      ),
    );
  }
}

/// 底部状态栏:运行中显示监听地址与记录数。
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.state, required this.l10n});

  final CaptureState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final text = state.running
        ? '${l10n.captureRunning}: 127.0.0.1:${state.port} · ${state.flowCount} flows'
            '${state.caReady ? '' : ' · CA 未就绪'}'
        : '${l10n.captureStopped} · ${state.flowCount} flows';
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
        child: Row(
          children: [
            Icon(
              state.running ? Iconfont.circleDot : Iconfont.square,
              size: 12,
              color: state.running ? context.semantic.success : context.semantic.subtleText,
            ),
            const SizedBox(width: Spacing.xs),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.semantic.subtleText, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 请求序列:最新的在最上面,每行「方法 URL」+「#序号 时间 [状态码] 类型 大小 耗时」。
class _FlowList extends StatelessWidget {
  const _FlowList({required this.flows, required this.l10n});

  final List<CaptureFlow> flows;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (flows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
          child: Text(
            l10n.captureEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.semantic.subtleText, fontSize: 13),
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: flows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final f = flows[i];
        final hasError = f.error != null;
        return InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CaptureDetailPage(flowId: f.id)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.md, 6, Spacing.sm, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 14),
                          children: [
                            TextSpan(
                              text: '${f.method} ',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _methodColor(context, f.method),
                              ),
                            ),
                            TextSpan(text: f.host),
                            TextSpan(
                              text: f.path,
                              style: TextStyle(color: context.semantic.subtleText),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '#${flows.length - i} ',
                              style: TextStyle(fontSize: 11, color: Colors.teal.shade400),
                            ),
                            TextSpan(
                              text: _subtitle(context, f),
                              style: TextStyle(
                                fontSize: 11,
                                color: hasError
                                    ? Theme.of(context).colorScheme.error
                                    : context.semantic.subtleText,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.xs),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    _statusIcon(context, f),
                    size: 16,
                    color: _statusColor(context, f),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _subtitle(BuildContext context, CaptureFlow f) {
    final time = _clock(f.startedAt);
    if (f.error != null) return '$time - ${_shortError(f.error!)}';
    final code = f.statusCode;
    final type = f.contentType.isEmpty ? '' : ' ${f.contentType}';
    final size = _sizeText(f);
    final cost = f.durationMs == null ? '' : ' ${f.durationMs}ms';
    return '$time - [${code ?? ''}]$type $size$cost';
  }

  /// 列表副标题只放错误首行:完整堆栈留给详情页,否则单行被截断后什么也看不出来。
  String _shortError(String error) {
    final line = error.split('\n').first;
    return line.length > 60 ? '${line.substring(0, 60)}…' : line;
  }

  String _clock(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

  Color _methodColor(BuildContext context, String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return const Color(0xFF2E7D32);
      case 'POST':
        return const Color(0xFF1565C0);
      case 'PUT':
      case 'PATCH':
        return const Color(0xFFEF6C00);
      case 'DELETE':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  Color _statusColor(BuildContext context, CaptureFlow f) {
    if (f.error != null) return Theme.of(context).colorScheme.error;
    final code = f.statusCode;
    if (code == null) return context.semantic.subtleText;
    if (code >= 200 && code < 300) return context.semantic.success;
    if (code >= 300 && code < 400) return const Color(0xFF1976D2);
    if (code >= 400 && code < 500) return const Color(0xFFEF6C00);
    return Theme.of(context).colorScheme.error;
  }

  IconData _statusIcon(BuildContext context, CaptureFlow f) {
    if (f.error != null) return Iconfont.alertCircle;
    final code = f.statusCode;
    if (code == null) return Iconfont.clock;
    if (code < 300) return Iconfont.checkCircle2;
    if (code < 400) return Iconfont.arrowRightCircle;
    return Iconfont.alertCircle;
  }
}

/// 按域名聚合:显示域名、最近请求时间与条数。
class _HostList extends StatelessWidget {
  const _HostList({required this.hosts, required this.l10n, required this.onSelect});

  final List<CaptureHostSummary> hosts;
  final AppLocalizations l10n;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (hosts.isEmpty) {
      return Center(
        child: Text(l10n.captureNoDomains, style: TextStyle(color: context.semantic.subtleText)),
      );
    }
    return ListView.separated(
      itemCount: hosts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final e = hosts[i];
        return ListTile(
          dense: true,
          title: Text(e.host, style: const TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            l10n.captureDomainSubtitle(
              '${e.lastAt.hour.toString().padLeft(2, '0')}:'
                  '${e.lastAt.minute.toString().padLeft(2, '0')}:'
                  '${e.lastAt.second.toString().padLeft(2, '0')}',
              e.count,
            ),
            style: TextStyle(fontSize: 11, color: context.semantic.subtleText),
          ),
          trailing: const Icon(Iconfont.chevronRight, size: 16),
          onTap: () => onSelect(e.host),
        );
      },
    );
  }
}

/// 流量字节数:对齐抓包工具的 B / KB 展示习惯。
String _sizeText(CaptureFlow f) {
  final bytes = f.requestBytes + f.responseBytes;
  if (bytes <= 0) return '0 B';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}
