import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/log/file_logger.dart';
import '../../core/log/log_store.dart';
import '../../core/theme/log_colors.dart';
import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../data/settings/app_settings.dart';
import '../../l10n/app_localizations.dart';

/// 日志页(对齐上游 LogSection):单页合并结构——
/// 等级(点击弹底部面板)+ 文件切换(底部面板)+ 搜索/复制 + MCP 过滤徽章 +
/// 结构化彩色日志列表(logcat 风格:等级徽章 + 时间 + tag + 消息)。
class LogPage extends ConsumerStatefulWidget {
  const LogPage({super.key, this.filterServerName});

  /// 从 MCP 编辑弹窗进入时按 server 名过滤(对齐上游 McpEditorDialog.onOpenLogs)。
  final String? filterServerName;

  @override
  ConsumerState<LogPage> createState() => _LogPageState();
}

class _LogPageState extends ConsumerState<LogPage> {
  /// 单文件最多渲染的行数(对齐上游 MAX_LOG_LINES):超出只取尾部。
  static const int _maxLogLines = 1200;

  LogLevel? _level;
  List<LogFileInfo> _files = const [];
  String? _selectedFileName;
  String? _filterServerName;
  String _content = '';
  int _totalLines = 0;
  int _shownLines = 0;
  bool _loading = false;
  String? _error;
  String _query = '';
  bool _followLatest = true;
  int? _copiedIndex;
  Timer? _followTimer;
  late final TextEditingController _search;
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    _filterServerName = widget.filterServerName;
    _search = TextEditingController();
    _scroll = ScrollController();
    _search.addListener(() => setState(() => _query = _search.text));
    final saved = ref.read(sharedPreferencesProvider).getString(logLevelPrefKey);
    // 未设置过时用运行期默认值(debug 全量、release 仅 INFO)作为初始展示。
    _level = saved == null ? (AppLog.instance?.minLevel ?? LogLevel.info) : LogLevel.fromName(saved);
    _load();
    // 实时滚动:跟随最新时每 3 秒静默刷新(对齐上游 LaunchedEffect + delay(3000))。
    _followTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_followLatest) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _followTimer?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final store = await ref.read(logStoreProvider.future);
      final files = store.listAppLogFiles();
      final today = 'log-${_dateStamp(DateTime.now())}.txt';
      // 选中优先级:当前文件 → 当天文件 → 最新(按名升序的最后一个)。
      final selected = files.where((f) => f.name == _selectedFileName).firstOrNull ??
          files.where((f) => f.name == today).firstOrNull ??
          (files.isEmpty ? null : files.last);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      if (selected == null) {
        setState(() {
          _files = files;
          _selectedFileName = null;
          _content = '';
          _totalLines = 0;
          _shownLines = 0;
          _error = l10n.logNoFiles;
          _loading = false;
        });
        return;
      }
      final rawLines = await File(selected.path).readAsLines();
      final filtered = _filterServerName == null
          ? rawLines
          : _filterMcpServerLines(rawLines, _filterServerName!);
      final visible = filtered.length > _maxLogLines
          ? filtered.sublist(filtered.length - _maxLogLines)
          : filtered;
      if (!mounted) return;
      setState(() {
        _files = files;
        _selectedFileName = selected.name;
        _content = visible.join('\n');
        _totalLines = filtered.length;
        _shownLines = visible.length;
        _error = null;
        _loading = false;
      });
      _followToEnd();
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _loading = false;
        _error = l10n.logReadFailed('$error');
      });
    }
  }

  /// 实时滚动开启时,新条目出现后视口跟随到底部。
  void _followToEnd() {
    if (!_followLatest) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  List<LogEntry> get _entries => LogEntry.parseLines(_content);

  /// 搜索按原始行子串匹配(忽略大小写,对齐上游 raw.contains(query, ignoreCase))。
  List<LogEntry> get _filtered {
    final query = _query.trim();
    if (query.isEmpty) return _entries;
    final lower = query.toLowerCase();
    return _entries.where((entry) => entry.raw.toLowerCase().contains(lower)).toList();
  }

  String _summary(AppLocalizations l10n) {
    if (_query.trim().isNotEmpty) return l10n.logSearchResults(_filtered.length);
    if (_totalLines > _shownLines) {
      return l10n.logShowLastLines(_filtered.length, _totalLines);
    }
    return l10n.logShowLines(_filtered.length);
  }

  static String _dateStamp(DateTime now) =>
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  static String _fileNameDisplay(String name) {
    var s = name;
    if (s.startsWith('log-')) s = s.substring(4);
    if (s.endsWith('.txt')) s = s.substring(0, s.length - 4);
    return s;
  }

  String _levelName(AppLocalizations l10n, LogLevel level) => switch (level) {
        LogLevel.verbose => l10n.logLevelVerbose,
        LogLevel.debug => l10n.logLevelDebug,
        LogLevel.info => l10n.logLevelInfo,
        LogLevel.warn => l10n.logLevelWarn,
        LogLevel.error => l10n.logLevelError,
        LogLevel.none => l10n.logLevelNone,
      };

  Future<void> _setLevel(LogLevel level) async {
    setState(() => _level = level);
    AppLog.setMinLevel(level);
    await ref.read(sharedPreferencesProvider).setString(logLevelPrefKey, level.name);
  }

  Future<void> _copy(String text) => Clipboard.setData(ClipboardData(text: text));

  void _copyLine(int index, LogEntry entry) {
    _copy(entry.raw);
    setState(() => _copiedIndex = index);
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted && _copiedIndex == index) setState(() => _copiedIndex = null);
    });
  }

  /// 该行之后的堆栈续行(等级为 null 的连续行)。
  List<LogEntry> _stackLines(List<LogEntry> entries, int index) {
    final lines = <LogEntry>[];
    for (var i = index + 1; i < entries.length; i++) {
      if (entries[i].level != null) break;
      lines.add(entries[i]);
    }
    return lines;
  }

  void _selectFile(String name) {
    setState(() {
      _selectedFileName = name;
      _content = '';
    });
    _load();
  }

  void _clearFilter() {
    setState(() => _filterServerName = null);
    _load();
  }

  // ── MCP 过滤(对齐上游 filterMcpServerLines / isMcpServerLogLine)──

  /// 标准日志行的开头(时间 + 等级),用于区分堆栈续行。
  static final RegExp _logLinePrefix = RegExp(
      r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3} (?:VERBOSE|DEBUG|INFO|WARN|ERROR) ');

  /// 只认 MCP 组件写下的日志(tag 以 Mcp 开头,如 McpManager/McpClient),
  /// 且消息里引用了该 server——要么是消息前缀 `[名字]`,要么是命名空间工具名 `mcp__名字__`。
  static bool _isMcpServerLine(String line, String serverName) {
    if (!line.contains('[Mcp')) return false;
    return line.contains('[$serverName]') || line.contains('mcp__${serverName}__');
  }

  /// 命中的标准行连同其后的堆栈续行一并保留(续行本身不含 server 名,逐行匹配会丢掉报错堆栈)。
  List<String> _filterMcpServerLines(List<String> rawLines, String serverName) {
    final result = <String>[];
    var keepContinuation = false;
    for (final line in rawLines) {
      if (_logLinePrefix.hasMatch(line)) {
        keepContinuation = _isMcpServerLine(line, serverName);
        if (keepContinuation) result.add(line);
      } else if (keepContinuation) {
        result.add(line);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final entries = _filtered;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.settingsLog),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.light
                ? const [Color(0xFFEDE9FE), Color(0xFFDBEAFE), Color(0xFFFCE7F3)]
                : const [Color(0xFF1E1B4B), Color(0xFF1E3A8A), Color(0xFF4C1D95)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.lg, 80, Spacing.lg, Spacing.lg),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 等级 + 文件:同一卡片两行 ──
            SettingsGroup(
              children: [
                SettingsRow(
                  icon: Iconfont.fileText,
                  title: l10n.logLevel,
                  trailing: _levelBadge(l10n, theme),
                  onTap: () => _openLevelSheet(),
                ),
                const SettingsDivider(),
                SettingsRow(
                  title: l10n.logFiles,
                  subtitle: _selectedFileName == null
                      ? l10n.logNoFiles
                      : _fileNameDisplay(_selectedFileName!),
                  enabled: _files.isNotEmpty,
                  onTap: _files.isEmpty ? null : () => _openFileSheet(),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            // ── 搜索 + 复制 ──
            Row(
              children: [
                Expanded(
                  child: CapsuleSearchField(
                    controller: _search,
                    hint: l10n.logSearchHint,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                _CopyLogButton(
                  text: entries.map((e) => e.raw).join('\n'),
                  enabled: entries.isNotEmpty,
                ),
              ],
            ),
            // ── MCP 过滤徽章(从 MCP 弹窗进入时显示,可清除)──
            if (_filterServerName != null) ...[
              const SizedBox(height: Spacing.sm),
              _filterBadge(l10n, theme),
            ],
            const SizedBox(height: Spacing.sm),
            // ── 日志内容卡片 ──
            Expanded(child: _contentCard(l10n, theme, entries)),
          ],
        ),
        ),
      ),
    );
  }

  /// 等级行尾徽章:等级色浅底 + 圆点 + 等级名(对齐上游 trailing Surface)。
  Widget _levelBadge(AppLocalizations l10n, ThemeData theme) {
    final level = _level ?? LogLevel.info;
    final color = LogLevelColors.of(level);
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _levelName(l10n, level),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBadge(AppLocalizations l10n, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.logMcpPrefix(_filterServerName!),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          IconButton(
            onPressed: _clearFilter,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            icon: Icon(Iconfont.x, size: 14, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _contentCard(AppLocalizations l10n, ThemeData theme, List<LogEntry> entries) {
    final Widget child;
    if (_loading) {
      child = const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (_error != null) {
      child = Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Text(
            _error!,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
          ),
        ),
      );
    } else if (entries.isEmpty) {
      // 搜索中或 MCP 过滤中显示「没有匹配」;否则兜底显示「还没有日志文件」。
      final emptyText = _query.trim().isNotEmpty || _filterServerName != null
          ? l10n.logNoMatch
          : l10n.logNoFiles;
      child = Center(
        child: Text(
          emptyText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    } else {
      child = Column(
        children: [
          _summaryRow(l10n, theme),
          Divider(
            height: 0.5,
            thickness: 0.5,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.only(bottom: Spacing.md),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _logLine(
                  theme,
                  entry,
                  copied: _copiedIndex == index,
                  onTap: () => _copyLine(index, entry),
                  onLongPress: () => _openLineMenu(index),
                );
              },
            ),
          ),
        ],
      );
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(width: 1, color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  /// 统计行:匹配/截断/全量行数 + 实时滚动开关(对齐上游 summary + AppSwitch)。
  Widget _summaryRow(AppLocalizations l10n, ThemeData theme) {
    final style = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(_summary(l10n), style: style)),
          Text(l10n.logFollowLatest, style: style),
          const SizedBox(width: Spacing.xs),
          Switch(
            value: _followLatest,
            onChanged: (v) => setState(() => _followLatest = v),
          ),
        ],
      ),
    );
  }

  /// 单条日志行:等级徽章(定宽对齐)+ 时间/tag/消息分色拼接,非日志行(堆栈续行等)整行灰色。
  Widget _logLine(
    ThemeData theme,
    LogEntry entry, {
    required bool copied,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    final hasLevel = entry.level != null;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            hasLevel ? _levelBadgeFor(entry.level!, theme) : const SizedBox(width: 56),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text.rich(
                _textSpan(entry, theme),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 16 / 11,
                ),
              ),
            ),
            if (copied)
              Padding(
                padding: const EdgeInsets.only(left: Spacing.xs, top: 2),
                child: Icon(Iconfont.check, size: 14, color: theme.colorScheme.primary),
              ),
          ],
        ),
      ),
    );
  }

  /// 等级徽章:固定宽度、等级色浅底 + 深色文字,logcat 风格(对齐上游 LogBadge)。
  Widget _levelBadgeFor(LogLevel level, ThemeData theme) {
    final color = LogLevelColors.of(level);
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Radii.xs),
      ),
      child: Text(
        _levelName(AppLocalizations.of(context), level),
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        maxLines: 1,
      ),
    );
  }

  /// 行文本:时间灰、[tag] 蓝灰、消息主题色;非标准行整行原样灰色。
  TextSpan _textSpan(LogEntry entry, ThemeData theme) {
    final level = entry.level;
    if (level == null) {
      return TextSpan(
        text: entry.raw,
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      );
    }
    return TextSpan(
      style: TextStyle(color: theme.colorScheme.onSurface),
      children: [
        TextSpan(
          text: '${entry.timestamp} ',
          style: const TextStyle(color: Color(0xFF9CA3AF)),
        ),
        if (entry.tag != null)
          TextSpan(
            text: '[${entry.tag}] ',
            style: const TextStyle(color: Color(0xFF94A3B8)),
          ),
        TextSpan(text: entry.message),
      ],
    );
  }

  // ── 底部面板 ──

  /// 日志等级底部面板:6 级单选列表,选中项右侧对勾,底部附文件位置说明。
  Future<void> _openLevelSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.logLevel,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  l10n.logLevelDesc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                for (final level in LogLevel.values)
                  InkWell(
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _setLevel(level);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: LogLevelColors.of(level),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Text(
                              _levelName(l10n, level),
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          if (level == _level)
                            Icon(Iconfont.check, size: 20, color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: Spacing.sm),
                Text(
                  l10n.logFileLocation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 日志文件底部面板:日期列表可滚动选择,选中项右侧对勾。
  Future<void> _openFileSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.logFiles,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: Spacing.sm),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final file in _files)
                          InkWell(
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _selectFile(file.name);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _fileNameDisplay(file.name),
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: file.name == _selectedFileName
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (file.name == _selectedFileName)
                                    Icon(Iconfont.check, size: 20, color: theme.colorScheme.primary),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 日志行长按操作面板:自定义复制范围(本条 / 本条及堆栈 / 仅消息内容)。
  Future<void> _openLineMenu(int index) {
    final entries = _filtered;
    final entry = entries[index];
    final stack = _stackLines(entries, index);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        final theme = Theme.of(sheetContext);
        void markCopied() {
          setState(() => _copiedIndex = index);
          Timer(const Duration(milliseconds: 1500), () {
            if (mounted && _copiedIndex == index) setState(() => _copiedIndex = null);
          });
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.logCopyMenuTitle,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: Spacing.sm),
                _menuRow(
                  sheetContext,
                  Iconfont.copy,
                  l10n.logCopyLine,
                  () {
                    Navigator.pop(sheetContext);
                    _copy(entry.raw);
                    markCopied();
                  },
                ),
                if (stack.isNotEmpty)
                  _menuRow(
                    sheetContext,
                    Iconfont.fileText,
                    l10n.logCopyWithStack,
                    () {
                      Navigator.pop(sheetContext);
                      _copy([entry, ...stack].map((e) => e.raw).join('\n'));
                      markCopied();
                    },
                  ),
                _menuRow(
                  sheetContext,
                  Iconfont.messageSquare,
                  l10n.logCopyMessage,
                  () {
                    Navigator.pop(sheetContext);
                    _copy(entry.message);
                  },
                ),
                const SizedBox(height: Spacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuRow(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: Spacing.md),
            Text(title, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

/// 复制按钮:胶囊样式对齐搜索框,点击复制后短暂切换为对勾(对齐上游 CopyLogButton)。
class _CopyLogButton extends StatefulWidget {
  const _CopyLogButton({required this.text, required this.enabled});

  final String text;
  final bool enabled;

  @override
  State<_CopyLogButton> createState() => _CopyLogButtonState();
}

class _CopyLogButtonState extends State<_CopyLogButton> {
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final idle = context.semantic.capsuleSurface;
    return Material(
      color: _copied
          ? theme.colorScheme.primary.withValues(alpha: 0.15)
          : idle,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: widget.enabled
            ? () async {
                await Clipboard.setData(ClipboardData(text: widget.text));
                setState(() => _copied = true);
                _timer?.cancel();
                _timer = Timer(const Duration(milliseconds: 1500), () {
                  if (mounted) setState(() => _copied = false);
                });
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            _copied ? Iconfont.check : Iconfont.copy,
            size: 18,
            color: _copied
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
