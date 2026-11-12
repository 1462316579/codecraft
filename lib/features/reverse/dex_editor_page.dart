import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/workspace_files.dart';
import '../../l10n/app_localizations.dart';
import '../../reverse/binary/byte_reader.dart';
import '../../reverse/dex/dalvik_disassembler.dart';
import '../../reverse/dex/dex_editor.dart';
import '../../reverse/dex/dex_file.dart';
import '../../reverse/hex/hex_dump.dart';
import 'hex_view.dart';
import 'reverse_widgets.dart';

/// Dex 编辑器:一个 dex 文件的结构浏览、字符串常量池编辑、反编译与十六进制视图。
class DexEditorPage extends ConsumerStatefulWidget {
  const DexEditorPage({super.key, required this.path});

  final String path;

  @override
  ConsumerState<DexEditorPage> createState() => _DexEditorPageState();
}

class _DexEditorPageState extends ConsumerState<DexEditorPage>
    with SingleTickerProviderStateMixin {
  Uint8List? _bytes;
  DexFile? _dex;
  String? _error;
  bool _loading = true;
  bool _dirty = false;
  bool _saving = false;

  /// 本次会话改过的偏移(十六进制视图高亮)。
  final Set<int> _modified = {};
  final ScrollController _hexScroll = ScrollController();
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final TextEditingController _classQuery = TextEditingController();
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
    _classQuery.dispose();
    _stringQuery.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final files = await ref.read(workspaceFilesProvider.future);
      final bytes = await files.readBytes(widget.path);
      final dex = DexFile.parse(bytes);
      // 6 千多个类的解析在手机上要一两秒:放在加载阶段,
      // 至少转圈还转得动,而不是等界面出来了再冻一下。
      dex.classes;
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _dex = dex;
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

  /// 应用一次编辑:换掉字节、重新解析(解析很便宜,dex 头 2ms 级)。
  ///
  /// [touched] 是本次被改动的字节偏移,必须和字节一起进 setState——
  /// 高亮集合若在 setState 之后再改,十六进制页不会重建,改动就看不见了。
  void _apply(EditOutcome outcome, {Iterable<int>? touched}) {
    if (!outcome.isOk) {
      _toast(outcome.error ?? '');
      return;
    }
    try {
      final dex = DexFile.parse(outcome.bytes!);
      setState(() {
        _bytes = outcome.bytes;
        _dex = dex;
        _dirty = true;
        if (touched != null) _modified.addAll(touched);
      });
    } on BinaryFormatException catch (error) {
      // 编辑把文件改坏了:保留原字节,不落盘。
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
    final dex = _dex;
    final bytes = _bytes;
    if (dex == null || bytes == null) return;
    final l10n = AppLocalizations.of(context);
    final editor = DexEditor(dex);
    final original = dex.stringAt(index);
    final value = await showStringEditDialog(
      context,
      title: l10n.reverseEditString,
      initial: original,
      helper: l10n.reverseEqualLengthHint,
      validate: (input) => editor.validateReplace(index, input),
    );
    if (value == null || !mounted || value == original) return;
    final range = dex.stringBytesRange(index);
    // 字符串本体 + 文件头的 checksum/sha1 都会被重算,一起标出来。
    _apply(
      editor.replaceString(index, value),
      touched: [
        for (var i = range.start; i < range.end; i++) i,
        for (var i = 8; i < 32; i++) i,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dex = _dex;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.semantic.cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(_fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (dex != null) HexJumpButton(onJump: _jump),
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
            Tab(text: l10n.reverseTabClasses),
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
                    // 首次非空断言之后,flow analysis 会把 dex 提升为非空,
                    // 后续再用无需重复加 `!`。
                    _classesTab(l10n, dex!),
                    _stringsTab(l10n, dex),
                    _hexTab(l10n),
                  ],
                ),
    );
  }

  String get _fileName {
    final slash = widget.path.lastIndexOf('/');
    return slash < 0 ? widget.path : widget.path.substring(slash + 1);
  }

  /// 跳到十六进制视图的目标偏移。
  ///
  /// 先切到十六进制页再滚动:还没切过去时 ListView 尚未挂载,
  /// 直接 jumpTo 会打在空的 ScrollController 上。
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

  Widget _classesTab(AppLocalizations l10n, DexFile dex) {
    final query = _classQuery.text.trim().toLowerCase();
    return Column(
      children: [
        _searchField(_classQuery, l10n.reverseSearchClassHint),
        Expanded(
          child: Builder(builder: (context) {
            final classes = dex.classes;
            final matched = query.isEmpty
                ? classes
                : classes.where((c) => c.name.toLowerCase().contains(query)).toList();
            if (matched.isEmpty) return ReverseHint(text: l10n.reverseNoMatch);
            return ListView.builder(
              itemCount: matched.length,
              itemBuilder: (context, index) {
                final type = matched[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    type.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                  ),
                  subtitle: Text(
                    '${l10n.reverseMethodCount(type.methods.length)} · '
                    '${l10n.reverseFieldCount(type.fields.length)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(LucideIcons.chevronRight, size: 16),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DexClassPage(dex: dex, type: type),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _stringsTab(AppLocalizations l10n, DexFile dex) {
    final query = _stringQuery.text.trim().toLowerCase();
    return Column(
      children: [
        _searchField(_stringQuery, l10n.reverseSearchStringHint),
        Expanded(
          child: Builder(builder: (context) {
            final indexes = <int>[];
            for (var i = 0; i < dex.stringCount; i++) {
              if (query.isEmpty) {
                indexes.add(i);
                continue;
              }
              if (dex.stringAt(i).toLowerCase().contains(query)) indexes.add(i);
            }
            if (indexes.isEmpty) return ReverseHint(text: l10n.reverseNoMatch);
            return ListView.builder(
              itemCount: indexes.length,
              itemBuilder: (context, position) {
                final index = indexes[position];
                return ListTile(
                  dense: true,
                  leading: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.semantic.subtleText,
                      fontFamily: 'monospace',
                    ),
                  ),
                  title: Text(
                    dex.stringAt(index),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () => _editString(index),
                );
              },
            );
          }),
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
    final dex = _dex;
    final bytes = _bytes;
    if (dex == null || bytes == null) return;
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
    _apply(
      DexEditor(dex).applyByteEdits({offset: value}),
      touched: [offset],
    );
  }

  Widget _searchField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.xs, Spacing.md, Spacing.xs),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          prefixIcon: const Icon(LucideIcons.search, size: 16),
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}

/// 单个类的结构详情:父类、接口、字段、方法。
class DexClassPage extends StatelessWidget {
  const DexClassPage({super.key, required this.dex, required this.type});

  final DexFile dex;
  final DexClass type;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(type.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(
        children: [
          if (type.superclass != null)
            _kv(context, l10n.reverseSuperclass, type.superclass!),
          if (type.interfaces.isNotEmpty)
            _kv(context, l10n.reverseInterfaces, type.interfaces.join('\n')),
          _kv(context, l10n.reverseAccessFlags,
              DexAccess.describe(type.accessFlags, forClass: true).join(' ')),
          if (type.fields.isNotEmpty) ...[
            ReverseSectionHeader(title: l10n.reverseFields, trailing: '${type.fields.length}'),
            for (final field in type.fields)
              ListTile(
                dense: true,
                title: Text(
                  '${DexFile.prettyType(field.field.type)} ${field.field.name}',
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                ),
                subtitle: Text(
                  DexAccess.describe(field.accessFlags, forClass: false).join(' '),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
          ],
          ReverseSectionHeader(
            title: l10n.reverseMethods,
            trailing: '${type.methods.length}',
          ),
          for (final method in type.methods)
            ListTile(
              dense: true,
              title: Text(
                method.method.signature,
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              ),
              subtitle: Text(
                DexAccess.describe(method.accessFlags, forClass: false).join(' '),
                style: const TextStyle(fontSize: 11),
              ),
              trailing: method.hasCode
                  ? const Icon(LucideIcons.chevronRight, size: 16)
                  : Text(
                      l10n.reverseAbstractMethod,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
              onTap: method.hasCode
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DexMethodPage(
                            dex: dex,
                            owner: type.name,
                            method: method,
                          ),
                        ),
                      )
                  : null,
            ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String key, String value) => Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Text(
                key,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      );
}

/// 单个方法的反编译视图(smali 指令流)。
class DexMethodPage extends StatelessWidget {
  const DexMethodPage({
    super.key,
    required this.dex,
    required this.owner,
    required this.method,
  });

  final DexFile dex;
  final String owner;
  final DexEncodedMethod method;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final code = dex.codeAt(method.codeOff);
    final insns = DalvikDisassembler(dex).disassemble(code);
    final header = StringBuffer()
      ..writeln('# ${DexAccess.describe(method.accessFlags, forClass: false).join(' ')}')
      ..writeln('# owner: $owner')
      ..writeln('# registers: ${code.registersSize} '
          '(params ${code.insSize}, outs ${code.outsSize})')
      ..writeln('# instructions: ${insns.length}')
      ..writeln('.method ${method.method.name}(${method.method.proto.parameters.join()})'
          '${method.method.proto.returnType}');
    return Scaffold(
      appBar: AppBar(
        title: Text(method.method.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        itemCount: insns.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              child: Text(
                header.toString().trimRight(),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.outline,
                ),
              ),
            );
          }
          final insn = insns[index - 1];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    insn.address.toRadixString(16).padLeft(4, '0'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    insn.text,
                    style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(Spacing.sm),
        color: theme.colorScheme.surfaceContainerHighest,
        child: Text(
          l10n.reverseSmaliHint,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
        ),
      ),
    );
  }
}
