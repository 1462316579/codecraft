import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/iconfont.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../agent/chat_controller.dart';
import '../../agent/tools/workspace.dart';
import '../../agent/models/chat_session.dart';
import '../../agent/models/project.dart';
import '../../agent/sessions_controller.dart';
import '../../data/db/app_database.dart';
import '../../data/db/daos.dart';
import '../../data/session_export.dart';
import '../../app/shell.dart';
import '../../core/util/window_size.dart';
import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/segmented_tabs.dart';
import '../../core/ui/settings_group.dart';
import '../../data/workbench.dart';
import '../../core/ui/text_input_dialog.dart';
import '../../l10n/app_localizations.dart';
import 'file_tree_tab.dart';

/// 多选模式下已勾选的会话 id。
class SessionSelection extends StateNotifier<Set<String>> {
  SessionSelection() : super(const {});

  void toggle(String id) {
    state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
  }

  void clear() => state = const {};

  void setAll(Iterable<String> ids) => state = ids.toSet();
}

final sessionSelectionProvider =
    StateNotifierProvider<SessionSelection, Set<String>>((ref) => SessionSelection());

/// 会话侧边栏内容(对齐上游 ChatDrawerContent 的会话部分):
/// 搜索框 + 按时间分组的会话列表(置顶/今天/昨天/7天内/30天内/按月)+ 底部设置入口。
/// 窄屏用作抽屉,宽屏用作常驻侧栏。
class SessionsDrawer extends ConsumerStatefulWidget {
  const SessionsDrawer({super.key});

  @override
  ConsumerState<SessionsDrawer> createState() => _SessionsDrawerState();
}

class _SessionsDrawerState extends ConsumerState<SessionsDrawer> {
  final _searchController = TextEditingController();
  String _query = '';
  int _tab = 0;

  /// 多选模式(长按菜单「批量选择」进入):行前出现勾选框,顶部出现批量操作条。
  bool _selectionMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 批量操作条:已选数量 + 全选 + 取消 + 删除。
  Widget _buildSelectionBar(AppLocalizations l10n, List<ChatSession> sessions) {
    final selected = ref.watch(sessionSelectionProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.xs, Spacing.sm, Spacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.sessionSelectedCount("${selected.length}"),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: context.semantic.subtleText,
                  ),
            ),
          ),
          TextButton(
            onPressed: () => ref
                .read(sessionSelectionProvider.notifier)
                .setAll(sessions.map((session) => session.id)),
            child: Text(l10n.sessionSelectAll),
          ),
          IconButton(
            tooltip: l10n.sessionDeleteSelected,
            onPressed: selected.isEmpty ? null : () => _deleteSelected(),
            icon: Icon(
              Iconfont.trash2,
              size: 18,
              color: selected.isEmpty
                  ? context.semantic.subtleText
                  : Theme.of(context).colorScheme.error,
            ),
          ),
          IconButton(
            tooltip: l10n.sessionCancelSelect,
            onPressed: () => setState(() {
              _selectionMode = false;
              ref.read(sessionSelectionProvider.notifier).clear();
            }),
            icon: const Icon(Iconfont.x, size: 18),
          ),
        ],
      ),
    );
  }

  /// 批量删除已勾选的会话。
  Future<void> _deleteSelected() async {
    final l10n = AppLocalizations.of(context);
    final ids = ref.read(sessionSelectionProvider).toList();
    if (ids.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.sessionDeleteSelected),
        content: Text(l10n.sessionDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              l10n.delete,
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(sessionsProvider.notifier).removeMany(ids);
    if (!mounted) return;
    setState(() {
      _selectionMode = false;
      ref.read(sessionSelectionProvider.notifier).clear();
    });
  }

  /// 长按菜单(对齐上游 SessionActionSheet):置顶 / 重命名 / 导出 / 批量选择 / 删除。
  Future<void> _showActions(ChatSession session) async {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(sessionsProvider.notifier);
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.md),
                child: Text(
                  session.title.trim().isEmpty ? l10n.untitled : session.title,
                  style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                        color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _SheetAction(
                icon: session.isPinned ? Iconfont.pinOff : Iconfont.pin,
                label: session.isPinned ? l10n.unpin : l10n.pin,
                onTap: () => Navigator.pop(sheetContext, 'pin'),
              ),
              _SheetAction(
                icon: Iconfont.edit2,
                label: l10n.rename,
                onTap: () => Navigator.pop(sheetContext, 'rename'),
              ),
              _SheetAction(
                icon: Iconfont.download,
                label: l10n.sessionExport,
                onTap: () => Navigator.pop(sheetContext, 'export'),
              ),
              _SheetAction(
                icon: Iconfont.checkSquare,
                label: l10n.sessionBatchSelect,
                onTap: () => Navigator.pop(sheetContext, 'batch'),
              ),
              _SheetAction(
                icon: Iconfont.trash2,
                label: l10n.delete,
                color: Theme.of(sheetContext).colorScheme.error,
                onTap: () => Navigator.pop(sheetContext, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'pin':
        await notifier.togglePin(session.id);
      case 'rename':
        await _rename(session);
      case 'export':
        await _export(session);
      case 'batch':
        setState(() {
          _selectionMode = true;
          ref.read(sessionSelectionProvider.notifier).clear();
        });
      case 'delete':
        await _delete(session);
    }
  }

  Future<void> _rename(ChatSession session) async {
    final l10n = AppLocalizations.of(context);
    final name = await showTextInputDialog(
      context,
      title: l10n.rename,
      confirmLabel: l10n.rename,
      initial: session.title,
    );
    if (name == null || name.isEmpty) return;
    await ref.read(sessionsProvider.notifier).rename(session.id, name);
  }

  Future<void> _delete(ChatSession session) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.sessionDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              l10n.delete,
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(sessionsProvider.notifier).remove(session.id);
  }

  /// 导出会话为 Markdown 文件,落在 `<配置目录>/exports/`。
  Future<void> _export(ChatSession session) async {
    final l10n = AppLocalizations.of(context);
    try {
      final db = ref.read(databaseProvider);
      final messages = await db.messageDao.listBySession(session.id);
      final exporter = SessionExporter(
        Directory(p.join(ref.read(configDirProvider), 'exports')),
      );
      final path = await exporter.export(session, messages);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.sessionExportDone(path))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.sessionExportFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sessions = ref.watch(sessionsProvider);
    final selectedId = ref.watch(selectedSessionProvider);
    final theme = Theme.of(context);
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          color: (theme.brightness == Brightness.light ? Colors.white : context.semantic.mutedSurface)
              .withValues(alpha: 0.35),
          child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, Spacing.sm),
            child: SegmentedTabs(
              selected: _tab,
              labels: [l10n.tabSessions, l10n.tabFiles],
              onSelect: (index) => setState(() => _tab = index),
            ),
          ),
          // 多选模式:搜索框换成批量操作条(对齐上游选中态的顶部工具条)。
          if (_tab == 0 && _selectionMode)
            _buildSelectionBar(l10n, sessions.valueOrNull ?? const [])
          else if (_tab == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.xs, Spacing.lg, Spacing.sm),
              child: CapsuleSearchField(
                controller: _searchController,
                hint: l10n.searchSessions,
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
            ),
          Expanded(
            child: _tab == 1 ? const FileTreeTab() : sessions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('${l10n.errorGeneric}: $error')),
              data: (list) {
                // 侧栏只列当前项目下的会话:写作项目里不该出现代码会话,反之亦然。
                // 未打开项目时(理论上只在极端时序下出现)退回按模式过滤。
                final projectId = ref.watch(selectedProjectProvider);
                final inProject = projectId == null
                    ? list.where((s) =>
                        (s.mode == AgentMode.write) ==
                        (ref.watch(currentAgentModeProvider) == AgentMode.write))
                    : list.where((s) => s.projectId == projectId);
                final filtered = _query.isEmpty
                    ? inProject.toList()
                    : inProject
                        .where((s) => s.title.toLowerCase().contains(_query.toLowerCase()))
                        .toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noSessions,
                      style: TextStyle(color: context.semantic.subtleText),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.only(bottom: Spacing.sm),
                  children: [
                    for (final group in groupSessions(filtered, DateTime.now()))
                      ...[
                        SettingsGroupHeader(
                          text: groupLabel(l10n, group.key, group.sessions.first.updatedAt),
                        ),
                        for (var index = 0; index < group.sessions.length; index++) ...[
                          // 置顶组内用间距分隔,其余组用与设置页一致的分隔线(对齐上游)。
                          if (index > 0)
                            group.key == 'pinned'
                                ? const SizedBox(height: Spacing.sm)
                                : const SettingsDivider(),
                          _SessionRow(
                            session: group.sessions[index],
                            selected: !_selectionMode && group.sessions[index].id == selectedId,
                            selectionMode: _selectionMode,
                            checked: ref
                                .watch(sessionSelectionProvider)
                                .contains(group.sessions[index].id),
                            onLongPress: () => _showActions(group.sessions[index]),
                          ),
                        ],
                      ],
                  ],
                );
              },
            ),
          ),
          // 抓包:应用逆向与编程项目可用。浏览器仅编程项目。
          if (ref.watch(currentAgentModeProvider) == AgentMode.build)
            Builder(builder: (context) {
              final kind = ref.watch(currentProjectProvider)?.kind;
              final showCapture = kind == ProjectKind.coding || kind == ProjectKind.reverse;
              final showCodingTools = kind == ProjectKind.coding;
              if (!showCapture) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: SettingsGroup(
                  children: [
                    SettingsRow(
                      icon: Iconfont.radio,
                      title: l10n.captureTitle,
                      onTap: () => context.push('/capture'),
                    ),
                    if (showCodingTools) ...[
                      const SettingsDivider(),
                      SettingsRow(
                        icon: Icons.public,
                        title: l10n.browserTitle,
                        onTap: () => openWorkbench(
                          context,
                          ref,
                          WorkbenchPaneKind.browser,
                          isWideLayout(context),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          const SizedBox(height: Spacing.md),
        ],
      ),
    ),
  ),
  );
  }
}

class _SessionRow extends ConsumerStatefulWidget {
  const _SessionRow({
    required this.session,
    required this.selected,
    required this.onLongPress,
    this.selectionMode = false,
    this.checked = false,
  });

  final ChatSession session;
  final bool selected;
  final VoidCallback onLongPress;
  final bool selectionMode;
  final bool checked;

  @override
  ConsumerState<_SessionRow> createState() => _SessionRowState();
}

/// 会话行(对齐上游 ChatSessionRow):
/// 只有标题一行;选中 = 主色文字加粗(无背景);置顶 = 整行 primaryContainer 背景;
/// 左侧状态点:等待授权橙色常亮优先,其次执行中绿色脉冲。
class _SessionRowState extends ConsumerState<_SessionRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semantic = context.semantic;
    final title = widget.session.title.trim().isEmpty ? l10n.untitled : widget.session.title;
    // 状态来自该会话自己的控制器(provider 非 autoDispose,非当前会话也能读到)。
    final state = ref.watch(chatControllerProvider(widget.session.id));
    final awaitingPermission = state.pendingPermission != null;
    final isExecuting = state.streaming;
    if (isExecuting && !awaitingPermission) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else if (_pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 1;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 1),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.mdLarge),
        onTap: () {
          if (widget.selectionMode) {
            ref.read(sessionSelectionProvider.notifier).toggle(widget.session.id);
          } else {
            openSession(context, ref, widget.session.id);
          }
        },
        onLongPress: widget.onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            // 置顶行整行浅蓝底(对齐上游),选中态改用文字色区分、不再叠背景。
            color: widget.session.isPinned
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(Radii.mdLarge),
          ),
          child: Row(
            children: [
              if (widget.selectionMode) ...[
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: widget.checked,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    onChanged: (_) => ref
                        .read(sessionSelectionProvider.notifier)
                        .toggle(widget.session.id),
                  ),
                ),
                const SizedBox(width: Spacing.xs),
              ],
              if (awaitingPermission) ...[
                // 等待授权:橙色常亮,优先级高于执行中。
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: semantic.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: Spacing.md),
              ] else if (isExecuting) ...[
                // 执行中:绿色脉冲(alpha 1 ↔ 0.25 往复)。
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: semantic.success.withValues(alpha: 1 - 0.75 * _pulse.value),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.md),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: widget.selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: widget.selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
        child: Row(
          children: [
            Icon(icon, size: 20, color: tint),
            const SizedBox(width: Spacing.lg),
            Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: tint)),
          ],
        ),
      ),
    );
  }
}

/// 会话分组(移植上游 buildSessionGroups/sessionGroupKey):
/// 置顶单独一组;其余按最后回复时间分成 今天 / 昨天 / 7天内 / 30天内 / 更早按月。
class SessionGroup {
  const SessionGroup(this.key, this.sessions);

  final String key;
  final List<ChatSession> sessions;
}

List<SessionGroup> groupSessions(List<ChatSession> sessions, DateTime now) {
  final groups = <SessionGroup>[];
  final pinned = sessions.where((s) => s.isPinned).toList();
  if (pinned.isNotEmpty) groups.add(SessionGroup('pinned', pinned));
  for (final session in sessions.where((s) => !s.isPinned)) {
    final key = _groupKey(session.updatedAt, now);
    if (groups.isNotEmpty && groups.last.key == key && groups.last.key != 'pinned') {
      groups.last.sessions.add(session);
    } else {
      groups.add(SessionGroup(key, [session]));
    }
  }
  return groups;
}

String _groupKey(int updatedAt, DateTime now) {
  final dt = DateTime.fromMillisecondsSinceEpoch(updatedAt);
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dt.year, dt.month, dt.day);
  final days = today.difference(day).inDays;
  if (days <= 0) return 'today';
  if (days == 1) return 'yesterday';
  if (days <= 7) return '7d';
  if (days <= 30) return '30d';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
}

String groupLabel(AppLocalizations l10n, String key, int anchorMs) => switch (key) {
      'pinned' => l10n.sessionGroupPinned,
      'today' => l10n.sessionGroupToday,
      'yesterday' => l10n.sessionGroupYesterday,
      '7d' => l10n.sessionGroupLast7Days,
      '30d' => l10n.sessionGroupLast30Days,
      _ => DateFormat(l10n.sessionGroupMonthFormat)
          .format(DateTime.fromMillisecondsSinceEpoch(anchorMs)),
    };