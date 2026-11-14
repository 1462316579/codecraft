import 'dart:async';
import 'dart:convert';

import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../agent/file_version_registry.dart';
import '../../agent/models/project.dart';
import '../../app/current_project.dart';
import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/line_diff.dart';
import '../../core/util/text_typeset.dart';
import '../../data/workspace_files.dart';
import '../../data/settings/editor_settings.dart';
import '../../l10n/app_localizations.dart';
import '../reverse/hex_editor_page.dart';
import '../sessions/file_type_icon.dart';
import 'editor_settings_page.dart';

/// 平台视图类型名(需与 Kotlin 侧 `registerViewFactory("codecraft/editor", ...)` 一致)。
const String _editorViewType = 'codecraft/editor';

/// 单个文件可编辑的上限:全量读入内存,超过就拒绝打开以避免 OOM 与长时间卡顿。
const int maxEditableBytes = 2 * 1024 * 1024;

/// 文件能否以文本打开。
enum EditorLoadKind { editable, tooLarge, binary }

/// 判定文件能否以文本打开。
EditorLoadKind classifyFile({required int sizeBytes, required bool binary}) {
  if (sizeBytes > maxEditableBytes) return EditorLoadKind.tooLarge;
  if (binary) return EditorLoadKind.binary;
  return EditorLoadKind.editable;
}

/// 保存前是否需要让用户确认覆盖。
bool saveConflicts({required String? loadedFingerprint, required String? diskFingerprint}) {
  if (loadedFingerprint == null || diskFingerprint == null) return false;
  return loadedFingerprint != diskFingerprint;
}

/// 编辑器指令控制器:用于在 Page 和 ViewWidget 之间传递指令,
/// 避免因为 UI 重建导致 MethodChannel 丢失或视图重启。
class EditorViewController {
  MethodChannel? methods;
  
  Future<void> invoke(String method, [Map<String, Object?>? args]) async {
    await methods?.invokeMethod(method, args);
  }

  Future<String?> readText() async {
    return await methods?.invokeMethod<String>('getText');
  }
}

/// 代码编辑器页(sora-editor PlatformView):从容器读文件、可编辑、保存回容器。
class EditorPage extends ConsumerStatefulWidget {
  const EditorPage({
    super.key,
    required this.path,
    this.line,
    this.onNavigateBack,
    this.embedded = false,
  });

  final String path;
  final int? line;
  final VoidCallback? onNavigateBack;
  final bool embedded;

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  final EditorViewController _controller = EditorViewController();
  StreamSubscription<dynamic>? _eventSubscription;

  String _baselineText = '';
  String? _baselineFingerprint;
  EditorLoadKind? _kind;
  int _tooLargeBytes = 0;
  String? _error;
  bool _loading = true;
  bool _dirty = false;
  bool _saving = false;
  bool _canUndo = false;
  bool _canRedo = false;
  int _cursorLine = 1;
  int _cursorColumn = 1;
  bool _previewMode = false;
  String _previewText = '';
  bool _revealed = false;
  double _layoutNudge = 0.0;
  Color? _editorBackground;
  bool? _appliedDark;

  final ValueNotifier<bool> _creatingNotifier = ValueNotifier(true);
  String _currentText = '';
  bool _searchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _searchDebounce;
  int _matchCount = 0;
  int _matchIndex = 0;
  Timer? _autoSaveTimer;
  static const Duration _autoSaveDelay = Duration(milliseconds: 1500);
  VoidCallback? _pendingLeave;

  bool get _isMarkdown {
    final dot = widget.path.lastIndexOf('.');
    if (dot < 0) return false;
    final ext = widget.path.substring(dot + 1).toLowerCase();
    return ext == 'md' || ext == 'markdown';
  }

  bool get _dark => Theme.of(context).brightness == Brightness.dark;
  bool get _editable => _kind == EditorLoadKind.editable;

  bool get _isImage {
    final dot = widget.path.lastIndexOf('.');
    if (dot < 0) return false;
    const imageExts = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'svg', 'ico', 'heic', 'heif', 'avif', 'tif', 'tiff'};
    return imageExts.contains(widget.path.substring(dot + 1).toLowerCase());
  }

  Uint8List? _imageBytes;
  Uint8List? _audioBytes;
  AudioPlayer? _audioPlayer;
  String? _tempAudioPath;
  Uint8List? _videoBytes;
  VideoPlayerController? _videoController;
  String? _tempVideoPath;

  bool get _isAudio {
    final dot = widget.path.lastIndexOf('.');
    if (dot < 0) return false;
    const audioExts = {'mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a', 'wma'};
    return audioExts.contains(widget.path.substring(dot + 1).toLowerCase());
  }

  bool get _isVideo {
    final dot = widget.path.lastIndexOf('.');
    if (dot < 0) return false;
    const videoExts = {'mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm'};
    return videoExts.contains(widget.path.substring(dot + 1).toLowerCase());
  }

  bool get _writing => ref.watch(currentProjectProvider)?.kind == ProjectKind.writing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_creatingNotifier.value && _appliedDark != _dark) {
      _appliedDark = _dark;
      unawaited(_applyTheme());
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _autoSaveTimer?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _eventSubscription?.cancel();
    _audioPlayer?.dispose();
    _audioPlayer = null;
    if (_tempAudioPath != null) {
      try { File(_tempAudioPath!).delete(); } catch (_) {}
      _tempAudioPath = null;
    }
    _videoController?.dispose();
    _videoController = null;
    if (_tempVideoPath != null) {
      try { File(_tempVideoPath!).delete(); } catch (_) {}
      _tempVideoPath = null;
    }
    _creatingNotifier.dispose();
    super.dispose();
  }

  void _onEvent(dynamic event) {
    if (event is! Map) return;
    switch (event['type']) {
      case 'contentChanged':
        final text = event['text'];
        if (text is! String) return;
        final dirty = text != _baselineText;
        final canUndo = event['canUndo'] == true;
        final canRedo = event['canRedo'] == true;
        if (dirty != _dirty || canUndo != _canUndo || canRedo != _canRedo) {
          setState(() {
            _currentText = text;
            _dirty = dirty;
            _canUndo = canUndo;
            _canRedo = canRedo;
          });
        } else if (text != _currentText) {
          setState(() => _currentText = text);
        }
        if (ref.read(currentProjectProvider)?.kind == ProjectKind.writing && _editable) {
          _scheduleAutoSave();
        }
      case 'searchResult':
        final count = event['count'];
        final index = event['index'];
        if (count is int && index is int) {
          setState(() {
            _matchCount = count;
            _matchIndex = index >= 0 ? index + 1 : (count > 0 ? 1 : 0);
          });
        }
      case 'selectionChanged':
        final line = event['line'];
        final column = event['column'];
        if (line is int && column is int && (line != _cursorLine || column != _cursorColumn)) {
          setState(() {
            _cursorLine = line;
            _cursorColumn = column;
          });
        }
    }
  }

  Future<WorkspaceFiles> _files() => ref.read(workspaceFilesProvider.future);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _kind = null;
    });
    try {
      final files = await _files();
      final bytes = await files.readBytes(widget.path);
      if (!mounted) return;
      final size = bytes.length;
      final binary = looksBinary(bytes);
      final kind = classifyFile(sizeBytes: size, binary: binary);

      if (_isImage) {
        setState(() {
          _loading = false;
          _kind = kind;
          _tooLargeBytes = size;
          _imageBytes = bytes;
        });
        return;
      }
      if (_isAudio) {
        setState(() {
          _loading = false;
          _kind = kind;
          _tooLargeBytes = size;
          _audioBytes = bytes;
        });
        return;
      }
      if (_isVideo) {
        setState(() {
          _loading = false;
          _kind = kind;
          _tooLargeBytes = size;
          _videoBytes = bytes;
        });
        return;
      }

      if (size > maxEditableBytes) {
        setState(() {
          _loading = false;
          _kind = EditorLoadKind.tooLarge;
          _tooLargeBytes = size;
        });
        return;
      }
      if (kind != EditorLoadKind.editable) {
        setState(() {
          _loading = false;
          _kind = kind;
          _tooLargeBytes = size;
        });
        return;
      }
      final text = _decodeText(bytes);
      setState(() {
        _kind = EditorLoadKind.editable;
        _baselineText = text;
        _currentText = text;
        _baselineFingerprint = FileVersionRegistry.fingerprintOf(text);
        _dirty = false;
        _canUndo = false;
        _canRedo = false;
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

  Future<void> _invoke(String method, [Map<String, Object?>? args]) async {
    await _controller.invoke(method, args);
  }

  Future<String?> _readEditorText() async {
    return await _controller.readText();
  }

  Future<void> _requestSave({bool silent = false}) async {
    if (_saving || !_editable || _creatingNotifier.value) return;
    final text = await _readEditorText();
    if (!mounted || text == null) return;
    if (silent && text.isEmpty && _baselineText.isNotEmpty) return;

    setState(() => _saving = true);
    try {
      final files = await _files();
      String? diskText;
      try {
        diskText = await files.readText(widget.path);
      } catch (_) {
        diskText = null;
      }
      if (!mounted) return;
      if (saveConflicts(
        loadedFingerprint: _baselineFingerprint,
        diskFingerprint: diskText == null ? null : FileVersionRegistry.fingerprintOf(diskText),
      )) {
        setState(() => _saving = false);
        _pendingLeave = null;
        await _showConflict(diskText!, text);
        return;
      }
      await _writeThrough(text, silent: silent);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('$error');
    }
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDelay, () {
      if (!mounted || !_dirty || _saving) return;
      unawaited(_requestSave(silent: true));
    });
  }

  Future<void> _writeThrough(String text, {bool silent = false}) async {
    final l10n = AppLocalizations.of(context);
    try {
      final files = await _files();
      await files.writeText(widget.path, text);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _baselineText = text;
        _currentText = text;
        _baselineFingerprint = FileVersionRegistry.fingerprintOf(text);
        _dirty = false;
      });
      if (!silent) _toast(l10n.editorSaved);
      final leave = _pendingLeave;
      if (leave != null) {
        _pendingLeave = null;
        leave();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('$error');
    }
  }

  Future<void> _reloadFromDisk() async {
    await _load();
    if (!mounted || !_editable) return;
    await _invoke('setText', {'text': _baselineText});
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleBack() {
    if (!_dirty) {
      _leaveNow();
      return;
    }
    unawaited(_confirmUnsaved());
  }

  Future<void> _confirmUnsaved() async {
    final l10n = AppLocalizations.of(context);
    final choice = await showDialog<_UnsavedChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.editorUnsavedTitle),
        content: Text(l10n.editorUnsavedMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, _UnsavedChoice.save), child: Text(l10n.editorSaveAndExit)),
          TextButton(onPressed: () => Navigator.pop(dialogContext, _UnsavedChoice.discard), child: Text(l10n.editorDontSave)),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case _UnsavedChoice.save:
        _pendingLeave = _leaveNow;
        await _requestSave();
      case _UnsavedChoice.discard:
        _leaveNow();
      case null:
        break;
    }
  }

  Future<void> _showConflict(String diskContent, String pendingText) async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final action = await showDialog<_ConflictChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.editorSaveConflictTitle),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.editorSaveConflictMessage),
            Padding(
              padding: const EdgeInsets.only(top: Spacing.sm),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: SingleChildScrollView(
                  child: Text(
                    l10n.editorSaveConflictDiff(LineDiff.toUnified(diskContent, pendingText)),
                    style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.editorSaveConflictCancel)),
          TextButton(onPressed: () => Navigator.pop(dialogContext, _ConflictChoice.discard), child: Text(l10n.editorSaveConflictDiscard)),
          TextButton(onPressed: () => Navigator.pop(dialogContext, _ConflictChoice.overwrite), child: Text(l10n.editorSaveConflictOverwrite)),
        ],
      ),
    );
    if (!mounted) return;
    switch (action) {
      case _ConflictChoice.overwrite:
        await _writeThrough(pendingText);
      case _ConflictChoice.discard:
        await _reloadFromDisk();
        if (mounted) _toast(l10n.editorSaveConflictDiscarded);
      case null:
        break;
    }
  }

  void _leaveNow() {
    final back = widget.onNavigateBack;
    if (back != null) {
      back();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _togglePreview() async {
    if (_previewMode) {
      setState(() => _previewMode = false);
      return;
    }
    final text = await _readEditorText();
    final previewText = (text == null || text.isEmpty) ? _baselineText : text;
    if (!mounted) return;
    setState(() {
      _previewText = previewText;
      _previewMode = true;
    });
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
  }

  void _closeSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(_invoke('stopSearch'));
    setState(() {
      _searchOpen = false;
      _matchCount = 0;
      _matchIndex = 0;
    });
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.isEmpty) {
      unawaited(_invoke('stopSearch'));
      setState(() {
        _searchOpen = false;
        _matchCount = 0;
        _matchIndex = 0;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 250), () => unawaited(_invoke('search', {'query': query})));
  }

  Future<void> _goToMatch({required bool next}) async {
    await _invoke(next ? 'searchNext' : 'searchPrevious');
    if (!mounted || !_searchOpen) return;
    _searchFocus.requestFocus();
  }

  String _decodeText(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      try {
        return utf8.decode(bytes, allowMalformed: true);
      } catch (_) {
        return latin1.decode(bytes);
      }
    }
  }

  Future<void> _typeset() async {
    final l10n = AppLocalizations.of(context);
    final text = await _readEditorText();
    if (!mounted || text == null) return;
    final formatted = typesetText(text);
    if (formatted == text) return;
    await _invoke('replaceAll', {'text': formatted});
    if (mounted) _toast(l10n.editorTypesetDone);
  }

  Future<void> _copyAll() async {
    final l10n = AppLocalizations.of(context);
    final text = await _readEditorText();
    if (!mounted || text == null) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _toast(l10n.editorCopied);
  }

  Future<void> _applyTheme() async {
    final surface = Theme.of(context).colorScheme.surface;
    await _invoke('setTheme', {'dark': _dark, 'surface': surface.value});
  }

  Future<void> _ensureTextLoaded() async {
    if (_baselineText.isEmpty) return;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await _invoke('setText', {'text': _baselineText});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(editorSettingsProvider);
    ref.listen<EditorSettings>(editorSettingsProvider, (previous, next) {
      unawaited(_invoke('applySettings', {
        'fontSize': next.fontSizeSp,
        'wordWrap': next.wordWrap,
        'showIndentGuide': next.showIndentGuide,
        'showWhitespace': next.showWhitespace,
      }));
    });
    final fileName = widget.path.contains('/') ? widget.path.substring(widget.path.lastIndexOf('/') + 1) : widget.path;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: context.semantic.pageBackground,
        appBar: _writing ? _writingAppBar(l10n, fileName) : _codeAppBar(l10n, fileName),
        body: Column(
          children: [
            if (_searchOpen) _searchBar(l10n),
            if (_editable && !_writing) _fileTitleBar(l10n, fileName),
            if (_editable && !_writing) const Divider(height: 0.5, thickness: 0.5),
            Expanded(child: _body(l10n, settings)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _writingAppBar(AppLocalizations l10n, String fileName) {
    final theme = Theme.of(context);
    final canEdit = _editable;
    final status = canEdit ? '${l10n.editorWordCount(countWords(_currentText))} · ${_dirty ? l10n.editorUnsavedState : l10n.editorSaved}' : null;
    return AppBar(
      backgroundColor: context.semantic.cardSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: _handleBack,
        tooltip: widget.embedded ? l10n.close : l10n.back,
        icon: Icon(widget.embedded ? Iconfont.x : Iconfont.arrowLeft, size: 20),
      ),
      title: Row(
        children: [
          Icon(fileTypeIconFor(fileName), size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (status != null) Text(status, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: context.semantic.subtleText)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _actionIcon(tooltip: l10n.editorUndo, icon: Iconfont.undo2, onTap: canEdit && _canUndo ? () => _invoke('undo') : null),
        _actionIcon(tooltip: l10n.editorRedo, icon: Iconfont.redo2, onTap: canEdit && _canRedo ? () => _invoke('redo') : null),
        if (_isMarkdown && canEdit) _actionIcon(tooltip: _previewMode ? l10n.editorMdShowSource : l10n.editorMdPreview, icon: _previewMode ? Iconfont.code : Iconfont.eye, onTap: _togglePreview),
        _actionIcon(tooltip: l10n.editorSearch, icon: Iconfont.search, onTap: canEdit ? (_searchOpen ? _closeSearch : _openSearch) : null),
        _actionIcon(tooltip: l10n.editorTypeset, icon: Iconfont.type, onTap: canEdit ? _typeset : null),
        _actionIcon(tooltip: l10n.editorCopy, icon: Iconfont.copy, onTap: canEdit ? _copyAll : null),
        const SizedBox(width: Spacing.xs),
      ],
    );
  }

  PreferredSizeWidget _codeAppBar(AppLocalizations l10n, String fileName) {
    return AppBar(
      backgroundColor: context.semantic.cardSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: _handleBack,
        tooltip: widget.embedded ? l10n.close : l10n.back,
        icon: Icon(widget.embedded ? Iconfont.x : Iconfont.arrowLeft, size: 18),
      ),
      actions: [
        if (_isMarkdown && _editable) IconButton(onPressed: _togglePreview, tooltip: _previewMode ? l10n.editorMdShowSource : l10n.editorMdPreview, icon: Icon(_previewMode ? Iconfont.code : Iconfont.eye, size: 18)),
        IconButton(onPressed: _editable && _canUndo ? () => _invoke('undo') : null, tooltip: l10n.editorUndo, icon: const Icon(Iconfont.undo2, size: 18)),
        IconButton(onPressed: _editable && _canRedo ? () => _invoke('redo') : null, tooltip: l10n.editorRedo, icon: const Icon(Iconfont.redo2, size: 18)),
        IconButton(onPressed: _editable && _dirty && !_saving ? _requestSave : null, tooltip: l10n.save, icon: _saving ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Iconfont.save, size: 18)),
        IconButton(onPressed: _editable ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditorSettingsPage())) : null, tooltip: l10n.editorSettings, icon: const Icon(Iconfont.slidersHorizontal, size: 18)),
      ],
    );
  }

  Widget _actionIcon({required String tooltip, required IconData icon, required VoidCallback? onTap}) =>
      IconButton(onPressed: onTap, tooltip: tooltip, visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 38, minHeight: 38), icon: Icon(icon, size: 18));

  Widget _searchBar(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final counter = _matchCount == 0 ? '0/0' : '$_matchIndex/$_matchCount';
    return Container(
      color: context.semantic.cardSurface,
      padding: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.xs, Spacing.xs),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              autofocus: true,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _goToMatch(next: true),
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.editorSearchHint,
                prefixIcon: const Icon(Iconfont.search, size: 16),
                prefixIconConstraints: const BoxConstraints(minWidth: 32),
                border: InputBorder.none,
              ),
            ),
          ),
          Text(counter, style: theme.textTheme.bodySmall?.copyWith(color: context.semantic.subtleText)),
          _actionIcon(tooltip: l10n.editorSearchPrev, icon: Iconfont.chevronUp, onTap: _matchCount == 0 ? null : () => _goToMatch(next: false)),
          _actionIcon(tooltip: l10n.editorSearchNext, icon: Iconfont.chevronDown, onTap: _matchCount == 0 ? null : () => _goToMatch(next: true)),
          _actionIcon(tooltip: l10n.close, icon: Iconfont.x, onTap: _closeSearch),
        ],
      ),
    );
  }

  Widget _fileTitleBar(AppLocalizations l10n, String fileName) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(fontFamily: 'monospace');
    return Container(
      width: double.infinity,
      color: context.semantic.cardSurface,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 2),
      child: Row(
        children: [
          if (_dirty) Padding(padding: const EdgeInsets.only(right: 2), child: Text('*', style: style?.copyWith(color: theme.colorScheme.primary))),
          Expanded(child: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: style)),
          Padding(padding: const EdgeInsets.only(left: Spacing.sm), child: Text(l10n.editorLineColumn(_cursorLine, _cursorColumn), style: style?.copyWith(color: context.semantic.subtleText))),
          Padding(padding: const EdgeInsets.only(left: Spacing.md), child: Text('UTF-8', style: style?.copyWith(color: context.semantic.subtleText))),
        ],
      ),
    );
  }

  Widget _body(AppLocalizations l10n, EditorSettings settings) {
    final fileName = widget.path.contains('/') ? widget.path.substring(widget.path.lastIndexOf('/') + 1) : widget.path;
    if (_loading) return const Center(child: CircularProgressIndicator());
    switch (_kind) {
      case EditorLoadKind.tooLarge:
        return _hint(l10n.editorFileTooLarge(_tooLargeBytes ~/ 1024 ~/ 1024));
      case EditorLoadKind.binary:
        if (_imageBytes != null) return Center(child: InteractiveViewer(child: Image.memory(_imageBytes!, fit: BoxFit.contain)));
        if (_audioBytes != null) return _AudioPlayerWidget(bytes: _audioBytes!, fileName: fileName);
        if (_videoBytes != null) return _VideoPlayerWidget(bytes: _videoBytes!, fileName: fileName);
        return _hint(l10n.editorBinaryUnsupported, action: ref.watch(currentProjectProvider)?.kind == ProjectKind.reverse ? FilledButton.tonal(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HexEditorPage(path: widget.path))), child: Text(l10n.reverseOpenAsHex)) : null);
      case EditorLoadKind.editable:
        return Stack(
          children: [
            Visibility(
              visible: !_previewMode,
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              child: EditorViewWidget(
                path: widget.path,
                line: widget.line,
                onNavigateBack: widget.onNavigateBack ?? () {},
                embedded: widget.embedded,
                settings: settings,
                creatingNotifier: _creatingNotifier,
                controller: _controller,
              ),
            ),
            if (_previewMode) _markdownPreview(),
            ValueListenableBuilder<bool>(
              valueListenable: _creatingNotifier,
              builder: (context, creating, _) => creating ? const Center(child: CircularProgressIndicator()) : const SizedBox.shrink(),
            ),
          ],
        );
      case null:
        return _hint(_error ?? l10n.editorLoadFailed);
    }
  }

  Widget _hint(String text, {Widget? action}) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: context.semantic.subtleText)),
            if (action != null) ...[const SizedBox(height: Spacing.md), action],
          ],
        ),
      ),
    );
  }

  Widget _markdownPreview() {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: Markdown(
        data: _previewText,
        padding: const EdgeInsets.all(Spacing.lg),
        styleSheet: MarkdownStyleSheet.fromTheme(theme),
      ),
    );
  }
}

class EditorViewWidget extends StatefulWidget {
  const EditorViewWidget({
    super.key,
    required this.path,
    this.line,
    required this.onNavigateBack,
    this.embedded = false,
    required this.settings,
    required this.creatingNotifier,
    required this.controller,
  });

  final String path;
  final int? line;
  final VoidCallback onNavigateBack;
  final bool embedded;
  final EditorSettings settings;
  final ValueNotifier<bool> creatingNotifier;
  final EditorViewController controller;

  @override
  State<EditorViewWidget> createState() => _EditorViewWidgetState();
}

class _EditorViewWidgetState extends State<EditorViewWidget> {
  StreamSubscription<dynamic>? _eventSubscription;
  Color? _editorBackground;
  double _layoutNudge = 0.0;

  /// 遮罩淡出完成后将其从树上移除:Opacity(0) 仍参与命中测试,
  /// 不移除会持续吞掉点击与滑动,导致编辑器无法编辑/滚动。
  bool _masking = true;

  Future<void> _applyTheme() async {
    final methods = widget.controller.methods;
    if (methods == null) return;
    final surface = Theme.of(context).colorScheme.surface;
    try {
      await methods.invokeMethod<void>('setTheme', {
        'dark': Theme.of(context).brightness == Brightness.dark,
        'surface': surface.value,
      });
      final value = await methods.invokeMethod<int>('getBackgroundColor');
      if (mounted && value != null) setState(() => _editorBackground = Color(value));
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _masking = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(_layoutNudge),
          child: PlatformViewLink(
            viewType: _editorViewType,
            surfaceFactory: (context, controller) => AndroidViewSurface(
              controller: controller as AndroidViewController,
              gestureRecognizers: const {},
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            ),
            onCreatePlatformView: (params) {
              final controller = PlatformViewsService.initSurfaceAndroidView(
                id: params.id,
                viewType: _editorViewType,
                layoutDirection: Directionality.of(context),
                creationParams: const <String, dynamic>{},
                creationParamsCodec: const StandardMessageCodec(),
              );
              final events = EventChannel('codecraft/editor/events/${params.id}');
              widget.controller.methods = MethodChannel('codecraft/editor/methods/${params.id}');
              controller.addOnPlatformViewCreatedListener(params.onPlatformViewCreated);
              controller.addOnPlatformViewCreatedListener((_) async {
                widget.creatingNotifier.value = false;
                final pageState = context.findAncestorStateOfType<_EditorPageState>();
                if (pageState != null) {
                  pageState._eventSubscription = events.receiveBroadcastStream().listen(pageState._onEvent, onError: (_) {});
                }
                unawaited(_applyTheme());
                unawaited(widget.controller.invoke('applySettings', {
                  'fontSize': widget.settings.fontSizeSp,
                  'wordWrap': MediaQuery.of(context).size.width < 600 || widget.settings.wordWrap,
                  'showIndentGuide': widget.settings.showIndentGuide,
                  'showWhitespace': widget.settings.showWhitespace,
                }));
                if (pageState != null) {
                  unawaited(pageState._ensureTextLoaded());
                  if (widget.line != null) unawaited(widget.controller.invoke('ensureLineVisible', {'line': widget.line! - 1}));
                }
                setState(() => _layoutNudge = 1.0);
                Future.delayed(const Duration(milliseconds: 50), () { if (mounted) setState(() => _layoutNudge = 0.0); });
                SchedulerBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() {}); });
              });
              controller.create();
              return controller;
            },
          ),
        ),
        // 视觉掩盖层: 用编辑器底色覆盖首帧白屏, 淡出后移除。
        // 必须包 IgnorePointer: 遮罩在淡出期间仍处于最上层, 不忽略的话
        // 所有点击/滑动都会被它吃掉, 原生编辑器收不到任何事件。
        if (_masking)
          IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1.0, end: 0.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, opacity, _) {
                return Opacity(
                  opacity: opacity,
                  child: Container(color: _editorBackground ?? Theme.of(context).colorScheme.surface),
                );
              },
            ),
          ),
      ],
    );
  }
}

enum _UnsavedChoice { save, discard }
enum _ConflictChoice { overwrite, discard }
const List<String> _editorSymbols = [
  '{', '}', '(', ')', '[', ']', '<', '>', 
  '=', '+', '-', '*', '/', '\\',
  ';', ':', ',', '.', '_', '\"', "'", '`',
  '|', '&', '!', '?', '@', '#', '\$', '%',
];

class _AudioPlayerWidget extends StatefulWidget {
  const _AudioPlayerWidget({required this.bytes, required this.fileName});
  final Uint8List bytes;
  final String fileName;
  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  late final AudioPlayer _player;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.play(BytesSource(widget.bytes));
      await _player.pause();
      _player.onDurationChanged.listen((d) { if (!mounted) return; setState(() => _duration = d); });
      setState(() => _initialized = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _initialized = true);
    }
    _player.onPositionChanged.listen((p) { if (!mounted) return; setState(() => _position = p); });
    _player.onPlayerStateChanged.listen((state) { if (!mounted) return; setState(() => _playing = state == PlayerState.playing); });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 32),
            Icon(Iconfont.music, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(widget.fileName, style: theme.textTheme.titleMedium, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 24),
            if (!_initialized) const CircularProgressIndicator()
            else Column(
              children: [
                Slider(
                  min: 0,
                  max: _duration.inMilliseconds.toDouble(),
                  value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
                  onChanged: (v) async => await _player.seek(Duration(milliseconds: v.toInt())),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_format(_position), style: theme.textTheme.bodySmall),
                      Text(_format(_duration), style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                IconButton(
                  onPressed: _playing ? _player.pause : _player.resume,
                  icon: Icon(_playing ? Iconfont.pause : Iconfont.play, size: 36),
                  style: IconButton.styleFrom(backgroundColor: theme.colorScheme.primaryContainer, foregroundColor: theme.colorScheme.onPrimaryContainer),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  const _VideoPlayerWidget({required this.bytes, required this.fileName});
  final Uint8List bytes;
  final String fileName;
  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  String? _tempPath;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/codecraft_video_${DateTime.now().millisecondsSinceEpoch}.${widget.fileName.split('.').last}');
      await file.writeAsBytes(widget.bytes);
      _tempPath = file.path;
      _controller = VideoPlayerController.file(File(_tempPath!))..initialize().then((_) { if (!mounted) return; setState(() => _initialized = true); });
    } catch (_) {
      if (!mounted) return;
      setState(() => _initialized = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_tempPath != null) {
      try { File(_tempPath!).delete(); } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(widget.fileName, style: theme.textTheme.titleMedium, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          if (!_initialized) const CircularProgressIndicator()
          else AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              children: [
                VideoPlayer(_controller),
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()),
                    child: Center(
                      child: Icon(_controller.value.isPlaying ? Iconfont.pause : Iconfont.play, size: 64, color: Colors.white.withOpacity(0.7)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          VideoProgressIndicator(_controller, allowScrubbing: true),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}