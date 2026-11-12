import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/workspace_files.dart';
import '../../l10n/app_localizations.dart';
import '../../reverse/axml/axml_file.dart';
import 'hex_view.dart';
import 'reverse_widgets.dart';

/// AndroidManifest.xml 反编译页:把二进制 AXML 解析为可读的 XML 文本。
class AXmlEditorPage extends ConsumerStatefulWidget {
  const AXmlEditorPage({super.key, required this.path});

  final String path;

  @override
  ConsumerState<AXmlEditorPage> createState() => _AXmlEditorPageState();
}

class _AXmlEditorPageState extends ConsumerState<AXmlEditorPage> {
  Uint8List? _bytes;
  String? _xmlText;
  String? _error;
  bool _loading = true;
  bool _showHex = false;
  final Set<int> _modified = {};
  final ScrollController _hexScroll = ScrollController();
  final ScrollController _textScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _hexScroll.dispose();
    _textScroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final files = await ref.read(workspaceFilesProvider.future);
      final bytes = await files.readBytes(widget.path);
      if (!mounted) return;
      String? text;
      try {
        final doc = AXmlFile.parse(bytes);
        text = doc.nodes.map((n) => n.render()).join('\n');
      } catch (_) {
        text = null;
      }
      setState(() {
        _bytes = bytes;
        _xmlText = text;
        _loading = false;
        _error = text == null ? 'AXML 解析失败,以十六进制显示' : null;
        _showHex = text == null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$error';
        _showHex = true;
      });
    }
  }

  String get _fileName {
    final slash = widget.path.lastIndexOf('/');
    return slash < 0 ? widget.path : widget.path.substring(slash + 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bytes = _bytes;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.semantic.cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(_fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: _showHex ? '显示 XML' : '显示十六进制',
            onPressed: () => setState(() => _showHex = !_showHex),
            icon: Icon(_showHex ? LucideIcons.fileCode : LucideIcons.hash, size: 18),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _showHex
              ? (bytes == null
                  ? ReverseHint(text: '${l10n.reverseLoadFailed}\n$_error')
                  : HexView(
                      bytes: bytes,
                      scrollController: _hexScroll,
                      modifiedOffsets: _modified,
                    ))
              : SingleChildScrollView(
                  controller: _textScroll,
                  padding: const EdgeInsets.all(Spacing.md),
                  child: SelectableText(
                    _xmlText ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
    );
  }
}
