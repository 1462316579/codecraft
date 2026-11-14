import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../agent/models/project.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../data/prompts.dart';
import '../../l10n/app_localizations.dart';
import 'prompt_markdown.dart';
import 'prompts_viewmodel.dart';

/// 提示词详情页:只读预览。
/// [kind] 非空时显示场景提示词(编程 / 写作 / 应用逆向),否则按编号显示片段。
class PromptDetailPage extends ConsumerWidget {
  const PromptDetailPage({super.key, this.number, this.kind});

  final int? number;
  final ProjectKind? kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final vm = ref.watch(promptsViewModelProvider);
    final state = vm.state;

    final gradient = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: theme.brightness == Brightness.light
            ? const [Color(0xFFEDE9FE), Color(0xFFDBEAFE), Color(0xFFFCE7F3)]
            : const [Color(0xFF1E1B4B), Color(0xFF1E3A8A), Color(0xFF4C1D95)],
      ),
    );

    // provider 首次创建时 refresh 未完成,片段/场景为空,firstWhere 会抛异常;
    // 深层链接直接进详情页时必须显示进度而不是红屏。
    if (state.loading) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(l10n.promptsTitle),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: Container(
          constraints: BoxConstraints.expand(),
          decoration: gradient,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (kind != null) {
      final scenario = state.scenarios.firstWhere((s) => s.kind == kind);
      final k = kind!;
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(l10n.promptsTitle),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            IconButton(
              tooltip: l10n.commonEdit,
              icon: const Icon(Iconfont.edit),
              onPressed: () => context.push(
                '/settings/prompts/edit?kind=${k.name}&scope=${scenario.source.name}',
              ),
            ),
          ],
        ),
        body: Container(
          constraints: BoxConstraints.expand(),
          decoration: gradient,
          child: _ScenarioDetailSection(scenario: scenario),
        ),
      );
    }

    final fragment = state.fragments.firstWhere(
      (f) => f.number == number,
      orElse: () => throw StateError('Fragment not found: $number'),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.promptsTitle),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: l10n.commonEdit,
            icon: const Icon(Iconfont.edit),
            onPressed: () => context.push('/settings/prompts/edit?number=$number'),
          ),
        ],
      ),
      body: Container(
        constraints: BoxConstraints.expand(),
        decoration: gradient,
        child: PromptDetailSection(fragment: fragment),
      ),
    );
  }
}

/// 详情内容区(复用于列表点击进入)。
class PromptDetailSection extends StatelessWidget {
  const PromptDetailSection({super.key, required this.fragment});

  final PromptFragment fragment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        Spacing.lg,
        MediaQuery.of(context).padding.top + kToolbarHeight + Spacing.lg - 55,
        Spacing.lg,
        Spacing.xxl,
      ),
      children: [
        SettingsGroup(
          children: [
            _InfoRow(
              label: l10n.promptsFieldNumber,
              value: fragment.number.toString().padLeft(2, '0'),
            ),
            const SettingsDivider(indent: SettingsRow.textIndent),
            _InfoRow(
              label: l10n.promptsFieldTitle,
              value: fragment.title,
            ),
            const SettingsDivider(indent: SettingsRow.textIndent),
            _InfoRow(
              label: l10n.promptsScope,
              value: _sourceLabel(context, fragment.source),
            ),
          ],
        ),

        if (fragment.description.isNotEmpty) ...[
          const SizedBox(height: Spacing.md),
          SettingsGroupHeader(text: l10n.promptsSummary),
          SettingsGroup(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.lg, 12, Spacing.lg, 12),
                child: Text(
                  fragment.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: Spacing.md),
        SettingsGroupHeader(text: l10n.promptsFieldContent),
        SettingsGroup(
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: MarkdownBody(
                data: fragment.body,
                styleSheet: promptMarkdownStyle(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _sourceLabel(BuildContext context, PromptFragmentSource source) {
    final l10n = AppLocalizations.of(context);
    return switch (source) {
      PromptFragmentSource.project => l10n.promptsSourceProject,
      PromptFragmentSource.global => l10n.promptsSourceGlobal,
      PromptFragmentSource.local => l10n.promptsSourceLocal,
      PromptFragmentSource.builtin => l10n.promptsSourceBuiltin,
    };
  }
}

/// 场景提示词详情:只读预览——项目类型、来源、摘要、正文(Markdown)。
class _ScenarioDetailSection extends StatelessWidget {
  const _ScenarioDetailSection({required this.scenario});

  final ScenarioPrompt scenario;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final title = switch (scenario.kind) {
      ProjectKind.coding => l10n.projectKindCoding,
      ProjectKind.writing => l10n.projectKindWriting,
      ProjectKind.reverse => l10n.projectKindReverse,
    };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        Spacing.lg,
        MediaQuery.of(context).padding.top + kToolbarHeight + Spacing.lg - 55,
        Spacing.lg,
        Spacing.xxl,
      ),
      children: [
        SettingsGroup(
          children: [
            _InfoRow(label: l10n.promptsFieldTitle, value: title),
            const SettingsDivider(indent: SettingsRow.textIndent),
            _InfoRow(label: l10n.promptsScope, value: _sourceLabel(context, scenario.source)),
          ],
        ),

        if (scenario.description.isNotEmpty) ...[
          const SizedBox(height: Spacing.md),
          SettingsGroupHeader(text: l10n.promptsSummary),
          SettingsGroup(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.lg, 12, Spacing.lg, 12),
                child: Text(
                  scenario.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: Spacing.md),
        SettingsGroupHeader(text: l10n.promptsFieldContent),
        SettingsGroup(
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: MarkdownBody(
                data: scenario.body,
                styleSheet: promptMarkdownStyle(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _sourceLabel(BuildContext context, PromptFragmentSource source) {
    final l10n = AppLocalizations.of(context);
    return switch (source) {
      PromptFragmentSource.project => l10n.promptsSourceProject,
      PromptFragmentSource.global => l10n.promptsSourceGlobal,
      PromptFragmentSource.local => l10n.promptsSourceLocal,
      PromptFragmentSource.builtin => l10n.promptsSourceBuiltin,
    };
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}