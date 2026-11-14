import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../agent/models/project.dart';
import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../core/ui/swipe_to_delete_row.dart';
import '../../data/prompts.dart';
import '../../l10n/app_localizations.dart';
import 'prompts_viewmodel.dart';

/// 提示词设置页:列出所有生效片段(按编号),支持查看详情、编辑、左滑删除、重置、禁用内置。
class PromptsPage extends ConsumerStatefulWidget {
  const PromptsPage({super.key});

  @override
  ConsumerState<PromptsPage> createState() => _PromptsPageState();
}

class _PromptsPageState extends ConsumerState<PromptsPage> {
  /// 批量选择的片段编号集合。
  final Set<int> _selectedNumbers = {};

  /// 是否处于多选模式(与是否已选中片段解耦)。
  bool _isSelectionMode = false;

  bool get _selectionMode => _isSelectionMode;

  void _toggleSelect(int number) {
    setState(() {
      if (_selectedNumbers.contains(number)) {
        _selectedNumbers.remove(number);
      } else {
        _selectedNumbers.add(number);
      }
    });
  }

  /// 进入/退出多选模式,不自动选中任何片段。
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) _selectedNumbers.clear();
    });
  }

  /// 全选 / 取消全选(仅在多选模式下使用)。
  void _selectAll(List<PromptFragment> fragments) {
    final selectable = fragments.map((f) => f.number).toList();
    setState(() {
      if (_selectedNumbers.length == selectable.length && selectable.isNotEmpty) {
        _selectedNumbers.clear();
      } else {
        _selectedNumbers
          ..clear()
          ..addAll(selectable);
      }
    });
  }

  void _exitSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedNumbers.clear();
    });
  }

  Future<void> _confirmBatchDelete() async {
    final l10n = AppLocalizations.of(context);
    final vm = ref.read(promptsViewModelProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.promptsBatchDeleteTitle),
        content: Text(l10n.promptsBatchDeleteConfirm(_selectedNumbers.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await vm.deleteFragments(_selectedNumbers.toList());
      _exitSelection();
    }
  }

  Future<void> _confirmReset() async {
    final l10n = AppLocalizations.of(context);
    final vm = ref.read(promptsViewModelProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.promptsResetCustom),
        content: Text(l10n.promptsResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await vm.resetCustomFragments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(promptsViewModelProvider).state;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.promptsTitle),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (_selectionMode)
            Padding(
              padding: const EdgeInsets.only(right: Spacing.sm),
              child: Text(
                l10n.promptsSelectedCount(_selectedNumbers.length),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),

          if (!_selectionMode)
            IconButton(
              tooltip: l10n.promptsResetCustom,
              icon: const Icon(Iconfont.rotateCcw),
              onPressed: _confirmReset,
            ),

          if (_selectionMode) ...[
            IconButton(
              tooltip: _selectedNumbers.length == state.fragments.length && state.fragments.isNotEmpty
                  ? l10n.promptsDeselectAll
                  : l10n.promptsSelectAll,
              icon: const Icon(Iconfont.checkSquare),
              onPressed: () => _selectAll(state.fragments),
            ),
            IconButton(
              tooltip: l10n.commonBatchDelete,
              icon: const Icon(Iconfont.trash2),
              onPressed: _selectedNumbers.isNotEmpty ? _confirmBatchDelete : null,
              color: Theme.of(context).colorScheme.error,
            ),
          ] else
            IconButton(
              tooltip: l10n.promptsSelectMode,
              icon: const Icon(Iconfont.checkSquare),
              onPressed: _toggleSelectionMode,
            ),

          if (_selectionMode)
            IconButton(
              tooltip: l10n.commonClose, 
              icon: const Icon(Icons.close),
              onPressed: _exitSelection,
            ),
        ],
      ),
      // 仅首次加载(片段与场景都还没拿到)时整页转圈;后续刷新保留列表,
      // 避免每次保存/删除/切开关都闪一下全屏进度条。
      body: Container(
        constraints: BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.light
                ? const [Color(0xFFEDE9FE), Color(0xFFDBEAFE), Color(0xFFFCE7F3)]
                : const [Color(0xFF1E1B4B), Color(0xFF1E3A8A), Color(0xFF4C1D95)],
          ),
        ),
        child: (state.loading && state.fragments.isEmpty && state.scenarios.isEmpty)
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(context, l10n, state),
      ),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => context.push('/settings/prompts/edit'),
              tooltip: l10n.promptsAddPrompt,
              child: const Icon(Iconfont.plus),
            ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    PromptsUiState state,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        Spacing.lg,
        MediaQuery.of(context).padding.top + kToolbarHeight + Spacing.sm,
        Spacing.lg,
        140,
      ),
      children: [
        // 顶部:禁用内置提示词开关
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: SettingsGroup(
            children: [
              SettingsRow(
                icon: null,
                title: l10n.promptsDisableBuiltin,
                subtitle: l10n.promptsDisableBuiltinHint,
                trailing: Switch(
                  value: state.builtinDisabled,
                  onChanged: (v) => ref.read(promptsViewModelProvider).setBuiltinDisabled(v),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: Spacing.lg),

        // 场景提示词:按项目类型注入(编程 / 写作 / 应用逆向)
        SettingsGroupHeader(text: l10n.promptsScenarioSection),
        SettingsGroup(
          children: [
            for (var i = 0; i < state.scenarios.length; i++) ...[
              if (i > 0) const SettingsDivider(),
              _ScenarioRow(scenario: state.scenarios[i]),
            ],
          ],
        ),

        const SizedBox(height: Spacing.lg),

        // 片段列表:无自定义片段时显示空占位,但保留上面的开关与场景区
        if (state.fragments.isEmpty)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconfont.fileText, size: 48, color: context.semantic.subtleText),
                const SizedBox(height: Spacing.md),
                Text(l10n.promptsEmpty, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          )
        else
          for (var i = 0; i < state.fragments.length; i++) ...[
            if (i > 0) const SizedBox(height: Spacing.xs),
            _PromptListItem(
              fragment: state.fragments[i],
              selectionMode: _selectionMode,
              selected: _selectedNumbers.contains(state.fragments[i].number),
              onToggleSelect: _selectionMode ? () => _toggleSelect(state.fragments[i].number) : null,
              onTap: () {
                if (!_selectionMode) {
                  context.push(
                    '/settings/prompts/detail?number=${state.fragments[i].number}',
                  );
                }
              },
              onDelete: () async {
                      final vm = ref.read(promptsViewModelProvider);
                      final ok = await vm.deleteFragment(state.fragments[i].number);
                      if (!context.mounted) return;
                      if (!ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.promptsNoOverrideToDelete)),
                        );
                        return;
                      }
                      if (_selectedNumbers.contains(state.fragments[i].number)) {
                        setState(() => _selectedNumbers.remove(state.fragments[i].number));
                      }
                    },
              deleteEnabled: true,
              onLongPress: () {
                if (!_selectionMode) {
                  setState(() {
                    _isSelectionMode = true;
                    _selectedNumbers.add(state.fragments[i].number);
                  });
                }
              },
            ),
          ],
      ],
    );
  }
}

/// 单条片段行:图标 + 编号·名称 + 摘要 + 来源徽章;左滑删除,长按进入选择模式。
class _PromptListItem extends StatelessWidget {
  const _PromptListItem({
    required this.fragment,
    required this.selectionMode,
    required this.selected,
    this.onToggleSelect,
    this.onTap,
    this.onDelete,
    this.deleteEnabled = false,
    this.onLongPress,
  });

  final PromptFragment fragment;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onToggleSelect;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool deleteEnabled;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;

    final row = GestureDetector(
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: (theme.brightness == Brightness.light ? Colors.white : semantic.cardSurface)
                  .withValues(alpha: 0.35),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 12),
            child: Row(
          children: [
            // 选择模式下的勾选框
            if (selectionMode) ...[
              Checkbox(
                value: selected,
                onChanged: (_) => onToggleSelect?.call(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: Spacing.sm),
            ],

            // 图标色块
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              alignment: Alignment.center,
              child: Icon(
                Iconfont.fileText,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: Spacing.md),

            // 编号·名称 + 摘要
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${fragment.number.toString().padLeft(2, '0')} · ${fragment.title}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (fragment.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        fragment.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: semantic.subtleText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: Spacing.sm),

            // 来源徽章
            _SourceBadge(source: fragment.source),

            const SizedBox(width: Spacing.xs),

            // 箭头
            if (!selectionMode)
              Icon(
                Iconfont.chevronRight,
                size: 18,
                color: semantic.subtleText,
              ),
          ],
        ),
      ),
      ),
      ),
    );

    if (selectionMode) return row;

    return SwipeToDeleteRow(
      onDelete: onDelete ?? () {},
      onTap: onTap,
      deleteEnabled: deleteEnabled,
      decorateChild: false,
      child: row,
    );
  }
}

/// 场景提示词行:项目类型图标 + 名称 + 摘要 + 来源徽章;点击进只读详情。
class _ScenarioRow extends StatelessWidget {
  const _ScenarioRow({required this.scenario});

  final ScenarioPrompt scenario;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsRow(
      icon: _scenarioIcon(scenario.kind),
      title: _scenarioTitle(l10n, scenario.kind),
      subtitle: scenario.description,
      trailing: _SourceBadge(source: scenario.source),
      onTap: () => context.push('/settings/prompts/detail?kind=${scenario.kind.name}'),
    );
  }

  IconData _scenarioIcon(ProjectKind kind) => switch (kind) {
        ProjectKind.coding => Iconfont.code,
        ProjectKind.writing => Iconfont.pencil,
        ProjectKind.reverse => Iconfont.binary,
      };

  String _scenarioTitle(AppLocalizations l10n, ProjectKind kind) => switch (kind) {
        ProjectKind.coding => l10n.projectKindCoding,
        ProjectKind.writing => l10n.projectKindWriting,
        ProjectKind.reverse => l10n.projectKindReverse,
      };
}

/// 来源徽章:显示该编号内容来自哪一层。
class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});

  final PromptFragmentSource source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final (text, color) = switch (source) {
      PromptFragmentSource.project => (l10n.promptsSourceProject, theme.colorScheme.primary),
      PromptFragmentSource.global => (l10n.promptsSourceGlobal, theme.colorScheme.tertiary),
      PromptFragmentSource.local => (l10n.promptsSourceLocal, theme.colorScheme.secondary),
      PromptFragmentSource.builtin => (l10n.promptsSourceBuiltin, context.semantic.subtleText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

