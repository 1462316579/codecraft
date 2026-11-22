import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../agent/models/skill.dart';
import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../core/ui/swipe_to_delete_row.dart';
import '../../data/skills.dart';
import '../../data/workspaces.dart';
import '../../g11n/app_globalizations.dart';

/// Skill 管理(对齐上游 SkillsSection):按作用域分组的技能列表——
/// 「当前项目 / 全局」两组,每行名称 + 描述 + 启停开关,点击进入详情/编辑页。
class SkillsPage extends ConsumerWidget {
  const SkillsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g11n = AppGlobalizations.of(context);
    final theme = Theme.of(context);
    final skills = ref.watch(skillsProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(g11n.skillsTitle),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: g11n.skillsNew,
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/settings/skills/edit'),
          ),
          IconButton(
            tooltip: g11n.skillsImport,
            icon: const Icon(Iconfont.fileUp),
            onPressed: () => _importMarkdown(context, ref, SkillScope.global),
          ),
        ],
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
        child: skills.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            '${g11n.errorGeneric}: $error',
            style: TextStyle(color: context.semantic.subtleText),
          ),
        ),
        data: (entries) => _list(context, ref, g11n, entries),
      ),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    AppGlobalizations g11n,
    List<SkillEntry> entries,
  ) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xl, vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(Radii.lg),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Iconfont.book,
                  size: 28,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.md),
              Text(g11n.skillsEmpty, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: Spacing.xs),
              Text(
                g11n.skillsEmptyHint,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: context.semantic.subtleText),
              ),
            ],
          ),
        ),
      );
    }

    final projectEntries = entries.where((entry) => entry.scope == SkillScope.project).toList();
    final globalEntries = entries.where((entry) => entry.scope == SkillScope.global).toList();
    final projectName = ref.watch(currentWorkspaceInfoProvider)?.name;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, 80, Spacing.lg, Spacing.xxl),
      children: [
        SettingsGroupHeader(
          text: projectName == null
              ? g11n.skillsScopeProject
              : g11n.skillsProjectGroup(projectName),
        ),
        SettingsGroup(
          children: [
            if (projectEntries.isEmpty)
              _emptyHint(context, g11n.skillsNoProjectSkills)
            else
              for (var index = 0; index < projectEntries.length; index++) ...[
                if (index > 0) const SettingsDivider(),
                _row(context, ref, g11n, projectEntries[index]),
              ],
          ],
        ),
        SettingsGroupHeader(text: g11n.skillsScopeGlobal),
        SettingsGroup(
          children: [
            if (globalEntries.isEmpty)
              _emptyHint(context, g11n.skillsNoGlobalSkills)
            else
              for (var index = 0; index < globalEntries.length; index++) ...[
                if (index > 0) const SettingsDivider(),
                _row(context, ref, g11n, globalEntries[index]),
              ],
          ],
        ),
      ],
    );
  }

  Widget _emptyHint(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.semantic.subtleText),
        ),
      );

  Widget _row(
    BuildContext context,
    WidgetRef ref,
    AppGlobalizations g11n,
    SkillEntry entry,
  ) {
    final disabled = ref.watch(disabledSkillsProvider).valueOrNull ?? const <String>{};
    final isDisabled = disabled.contains(entry.skill.name.toLowerCase());
    final row = SettingsRow(
      icon: Iconfont.book,
      title: entry.skill.name,
      subtitle: entry.skill.description.isEmpty ? null : entry.skill.description,
      onTap: () => context.push(
        '/settings/skills/edit?scope=${entry.scope.name}&name=${Uri.encodeComponent(entry.skill.name)}',
      ),
      trailing: Switch(
        value: !isDisabled,
        onChanged: (value) async {
          await ref
              .read(skillsStoreProvider)
              .setDisabled(entry.skill.name, !value, entry.scope);
          refreshSkills(ref);
        },
      ),
    );
    return SwipeToDeleteRow(
      onDelete: () => _confirmDelete(context, ref, g11n, entry),
      child: row,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppGlobalizations g11n,
    SkillEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(g11n.skillsDeleteTitle),
        content: Text(g11n.skillsDeleteConfirm(entry.skill.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(g11n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(dialogContext).colorScheme.error),
            child: Text(g11n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await ref.read(skillsStoreProvider).delete(entry.skill.name, entry.scope);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      refreshSkills(ref);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(g11n.errorGeneric)));
    }
  }

  /// 从 Markdown 文件导入技能(对齐上游「导入技能」的来源之一)。
  Future<void> _importMarkdown(BuildContext context, WidgetRef ref, SkillScope scope) async {
    final g11n = AppGlobalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final file = await file_selector.openFile(
      acceptedTypeGroups: const [file_selector.XTypeGroup(label: 'Markdown', extensions: ['md'])],
    );
    if (file == null) return;
    final fallbackName = file.name.replaceAll(RegExp(r'\.md$', caseSensitive: false), '');
    try {
      final result = await ref
          .read(skillsStoreProvider)
          .importMarkdown(await file.readAsString(), fallbackName, scope);
      if (result.imported.isNotEmpty) {
        refreshSkills(ref);
        messenger.showSnackBar(
          SnackBar(content: Text(g11n.skillsImported(result.imported.first))),
        );
        return;
      }
      final failure = result.failures.isEmpty ? null : result.failures.first;
      messenger.showSnackBar(
        SnackBar(content: Text(_importErrorText(g11n, failure?.name ?? '', failure?.error))),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('${g11n.errorGeneric}: $error')));
    }
  }

  String _importErrorText(AppGlobalizations g11n, String name, SkillImportError? error) =>
      switch (error) {
        SkillImportError.invalidName => g11n.skillsErrorInvalidName,
        SkillImportError.nameConflict => g11n.skillsErrorNameConflict(name),
        SkillImportError.emptyContent => g11n.skillsErrorEmptyInstructions,
        SkillImportError.noSkillFound => g11n.skillsErrorNoSkill,
        SkillImportError.ioFailed || null => g11n.skillsErrorIoFailed,
      };
}

/// 技能列表与启停状态在增删改后一起刷新。
void refreshSkills(WidgetRef ref) {
  ref.invalidate(skillsProvider);
  ref.invalidate(disabledSkillsProvider);
}