import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/workspace_files.dart';
import '../../l10n/app_localizations.dart';
import '../../reverse/arsc/arsc_editor.dart';
import '../../reverse/arsc/arsc_file.dart';
import '../../reverse/dex/dex_editor.dart' show EditOutcome;
import '../../reverse/binary/byte_reader.dart';
import '../../reverse/hex/hex_dump.dart';
import 'hex_view.dart';
import 'reverse_widgets.dart';

/// ARSC 编辑器:资源表浏览、全局字符常量池编辑、十六进制视图。
class ArscEditorPage extends ConsumerStatefulWidget {
  const ArscEditorPage({super.key, required this.path});

  final String path;

  @override
  ConsumerState<ArscEditorPage> createState() => _ArscEditorPageState();
}

class _ArscEditorPageState extends ConsumerState<ArscEditorPage>
    with SingleTickerProviderStateMixin {
  Uint8List? _bytes;
  ArscFile? _arsc;
  String? _error;
  bool _loading = true;
  bool _dirty = false;
  bool _saving = false;

  late final TabController _tabs = TabController(length: 3, vsync: this);
  final Set<int> _modified = {};
  final ScrollController _hexScroll = ScrollController();
  final TextEditingController _resourceQuery = TextEditingController();
  final TextEditingController _stringQuery = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _hexScroll.dispose();
    _resourceQuery.dispose();
    _stringQuery.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final files = await ref.read(workspaceFilesProvider.future);
      final bytes = await files.readBytes(widget.path);
      final arsc = ArscFile.parse(bytes);
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _arsc = arsc;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  void _apply(EditOutcome outcome, {Iterable<int>? touched}) {
    if (!outcome.isOk) {
      _toast(outcome.error ?? '');
      return;
    }
    try {
      final arsc = ArscFile.parse(outcome.bytes!);
      setState(() {
        _bytes = outcome.bytes;
        _arsc = arsc;
        _dirty = true;
        if (touched != null) _modified.addAll(touched);
      });
    } on BinaryFormatException catch (error) {
      _toast(error.message);
    }
  }

  Future<void> _save() async {
    final bytes = _bytes;
    if (bytes == null || _saving) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      final files = await ref.read(workspaceFilesProvider.future);
      await files.writeBytes(widget.path, bytes);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _dirty = false;
        _modified.clear();
      });
      _toast(l10n.editorSaved);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('$error');
    }
  }

  void _toast(String text) {
    if (!mounted || text.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _editString(int index) async {
    final arsc = _arsc;
    if (arsc == null) return;
    final l10n = AppLocalizations.of(context);
    final editor = ArscEditor(arsc);
    final original = arsc.globalStrings.at(index);
    final value = await showStringEditDialog(
      context,
      title: l10n.reverseEditString,
      initial: original,
      helper: l10n.reverseEqualLengthHint,
      validate: (input) => editor.validateReplace(index, input),
    );
    if (value == null || !mounted || value == original) return;
    final range = arsc.globalStrings.rangeOf(arsc.bytes, index);
    _apply(
      editor.replaceGlobalString(index, value),
      touched: range == null
          ? null
          : [for (var i = range.dataStart; i < range.dataEnd; i++) i],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arsc = _arsc;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.semantic.cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(_fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (arsc != null) HexJumpButton(onJump: _jump),
          IconButton(
            tooltip: l10n.save,
            onPressed: _dirty && !_saving ? _save : null,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.save, size: 18),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: context.semantic.subtleText,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: [
            Tab(text: l10n.reverseTabResources),
            Tab(text: l10n.reverseTabStrings),
            Tab(text: l10n.reverseTabHex),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ReverseHint(text: '${l10n.reverseParseFailed}\n$_error')
              : TabBarView(
                  controller: _tabs,
                  children: [
                    // 首次非空断言之后,flow analysis 会把 arsc 提升为非空。
                    _resourcesTab(l10n, arsc!),
                    _stringsTab(l10n, arsc),
                    _hexTab(l10n),
                  ],
                ),
    );
  }

  String get _fileName {
    final slash = widget.path.lastIndexOf('/');
    return slash < 0 ? widget.path : widget.path.substring(slash + 1);
  }

  /// 跳到十六进制视图的目标偏移:先切页,等 ListView 挂载后再滚。
  void _jump(int offset) {
    _tabs.animateTo(2);
    final row = HexDump.rowOf(offset, bytesPerRow: 8);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_hexScroll.hasClients) return;
      _hexScroll.jumpTo(
        (row * HexView.rowHeight)
            .clamp(0, _hexScroll.position.maxScrollExtent)
            .toDouble(),
      );
    });
  }

  Widget _resourcesTab(AppLocalizations l10n, ArscFile arsc) {
    final query = _resourceQuery.text.trim().toLowerCase();
    final resources = arsc.resources;
    final matched = query.isEmpty
        ? resources
        : resources
            .where((r) =>
                r.key.toLowerCase().contains(query) ||
                r.type.toLowerCase().contains(query) ||
                '0x${r.id.toRadixString(16)}'.contains(query))
            .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.xs, Spacing.md, Spacing.xs),
          child: TextField(
            controller: _resourceQuery,
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.reverseSearchResourceHint,
              prefixIcon: const Icon(LucideIcons.search, size: 16),
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: matched.isEmpty
              ? ReverseHint(text: l10n.reverseNoMatch)
              : ListView.builder(
                  itemCount: matched.length,
                  itemBuilder: (context, index) {
                    final resource = matched[index];
                    final primary = resource.primary;
                    return ListTile(
                      dense: true,
                      leading: SizedBox(
                        width: 76,
                        child: Text(
                          resource.type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.semantic.subtleText,
                          ),
                        ),
                      ),
                      title: Text(
                        resource.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        primary == null ? '<bag>' : primary.render(arsc.globalStrings),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                      trailing: Text(
                        '${resource.values.length}',
                        style: TextStyle(fontSize: 11, color: context.semantic.subtleText),
                      ),
                      onTap: () => _showResourceSheet(l10n, arsc, resource),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// 一个资源在全部配置下的取值:多语言包动辄几十个配置,单独一页看。
  void _showResourceSheet(AppLocalizations l10n, ArscFile arsc, ResResource resource) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, controller) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${resource.type}/${resource.key}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '0x${resource.id.toRadixString(16).padLeft(8, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: context.semantic.subtleText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: resource.values.length,
                itemBuilder: (context, index) {
                  final value = resource.values[index];
                  return ListTile(
                    dense: true,
                    leading: SizedBox(
                      width: 88,
                      child: Text(
                        value.config.qualifier,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.semantic.subtleText,
                        ),
                      ),
                    ),
                    title: SelectableText(
                      value.render(arsc.globalStrings),
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stringsTab(AppLocalizations l10n, ArscFile arsc) {
    final query = _stringQuery.text.trim().toLowerCase();
    final pool = arsc.globalStrings;
    final indexes = <int>[];
    for (var i = 0; i < pool.count; i++) {
      if (query.isEmpty || pool.at(i).toLowerCase().contains(query)) indexes.add(i);
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.xs, Spacing.md, Spacing.xs),
          child: TextField(
            controller: _stringQuery,
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.reverseSearchStringHint,
              prefixIcon: const Icon(LucideIcons.search, size: 16),
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: indexes.isEmpty
              ? ReverseHint(text: l10n.reverseNoMatch)
              : ListView.builder(
                  itemCount: indexes.length,
                  itemBuilder: (context, position) {
                    final index = indexes[position];
                    return ListTile(
                      dense: true,
                      leading: Text(
                        '$index',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: context.semantic.subtleText,
                        ),
                      ),
                      title: Text(
                        pool.at(index),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      onTap: () => _editString(index),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _hexTab(AppLocalizations l10n) {
    final bytes = _bytes;
    if (bytes == null) return ReverseHint(text: l10n.reverseEmptyFile);
    return HexView(
      bytes: bytes,
      scrollController: _hexScroll,
      modifiedOffsets: _modified,
      onByteTap: _editByte,
    );
  }

  Future<void> _editByte(int offset) async {
    final arsc = _arsc;
    final bytes = _bytes;
    if (arsc == null || bytes == null) return;
    final l10n = AppLocalizations.of(context);
    final current = bytes[offset];
    final input = await showStringEditDialog(
      context,
      title: l10n.reverseEditByte,
      initial: current.toRadixString(16).padLeft(2, '0'),
      helper: l10n.reverseEditByteHint,
      validate: (value) => parseHexByte(value) == null ? l10n.reverseInvalidByte : null,
    );
    if (input == null || !mounted) return;
    final value = parseHexByte(input);
    if (value == null || value == current) return;
    _apply(ArscEditor(arsc).applyByteEdits({offset: value}), touched: [offset]);
  }
}