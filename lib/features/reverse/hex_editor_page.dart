import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/workspace_files.dart';
import '../../g11n/app_globalizations.dart';
import '../../reverse/hex/hex_dump.dart';
import 'hex_view.dart';
import 'reverse_widgets.dart';

/// 通用十六进制视图:任何二进制文件都能打开,改字节后写回。
///
/// 与 Dex/ARSC 的十六进制页不同,这里不知道文件格式,所以不做任何头部修补——
/// 改的是原始字节。dex 请走 Dex 编辑器,那边会自动重算 checksum 与 sha1。
class HexEditorPage extends ConsumerStatefulWidget {
  const HexEditorPage({super.key, required this.path});

  final String path;

  @override
  ConsumerState<HexEditorPage> createState() => _HexEditorPageState();
}

class _HexEditorPageState extends ConsumerState<HexEditorPage> {
  Uint8List? _bytes;
  String? _error;
  bool _loading = true;
  bool _dirty = false;
  bool _saving = false;
  final Set<int> _modified = {};
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final files = await ref.read(workspaceFilesProvider.future);
      final bytes = await files.readBytes(widget.path);
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  Future<void> _save() async {
    final bytes = _bytes;
    if (bytes == null || _saving) return;
    final g11n = AppGlobalizations.of(context);
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
      _toast(g11n.editorSaved);
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

  Future<void> _editByte(int offset) async {
    final bytes = _bytes;
    if (bytes == null) return;
    final g11n = AppGlobalizations.of(context);
    final current = bytes[offset];
    final input = await showStringEditDialog(
      context,
      title: g11n.reverseEditByte,
      initial: current.toRadixString(16).padLeft(2, '0'),
      helper: g11n.reverseEditByteHint,
      validate: (value) => parseHexByte(value) == null ? g11n.reverseInvalidByte : null,
    );
    if (input == null || !mounted) return;
    final value = parseHexByte(input);
    if (value == null || value == current) return;
    final updated = Uint8List.fromList(bytes);
    updated[offset] = value;
    setState(() {
      _bytes = updated;
      _dirty = true;
      _modified.add(offset);
    });
  }

  void _jump(int offset) {
    final row = HexDump.rowOf(offset, bytesPerRow: 8);
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(
      (row * HexView.rowHeight).clamp(0, _scroll.position.maxScrollExtent).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    final bytes = _bytes;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.semantic.cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.path.contains('/')
              ? widget.path.substring(widget.path.lastIndexOf('/') + 1)
              : widget.path,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (bytes != null)
            HexJumpButton(onJump: _jump),
          IconButton(
            tooltip: g11n.save,
            onPressed: _dirty && !_saving ? _save : null,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Iconfont.save, size: 18),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ReverseHint(text: '${g11n.reverseLoadFailed}\n$_error')
              : HexView(
                  bytes: bytes!,
                  scrollController: _scroll,
                  modifiedOffsets: _modified,
                  onByteTap: _editByte,
                ),
      bottomNavigationBar: bytes == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.xs,
              ),
              color: context.semantic.cardSurface,
              child: Text(
                g11n.reverseHexByteCount(bytes.length),
                style: TextStyle(
                  fontSize: 11,
                  color: context.semantic.subtleText,
                  fontFamily: 'monospace',
                ),
              ),
            ),
    );
  }
}