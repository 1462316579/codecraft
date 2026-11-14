import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../core/ui/swipe_to_delete_row.dart';
import '../../data/permissions.dart';

import '../../l10n/app_localizations.dart';

/// 「工具授权」二级页(对齐上游 PermissionsSection):
/// 顶部是「安全防护」开关(禁用安全拦截);其下按「当前项目 / 全局」分组列出已保存的授权规则
/// (可折叠、左滑删除、项目规则可提升为全局),页脚说明「始终允许」的落点。
class PermissionsPage extends ConsumerStatefulWidget {
  const PermissionsPage({super.key});

  @override
  ConsumerState<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends ConsumerState<PermissionsPage> {
  bool _globalExpanded = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semantic = context.semantic;
    final theme = Theme.of(context);
    final rulesAsync = ref.watch(permissionRulesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
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
        child: rulesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('${l10n.errorGeneric}: $error')),
          data: (rules) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              Spacing.lg,
              MediaQuery.of(context).padding.top + kToolbarHeight + Spacing.lg,
              Spacing.lg,
              Spacing.xxl,
            ),
          children: [
            SettingsPageHeader(
              title: l10n.permissionsTitle,
              subtitle: l10n.permissionsSubtitle,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CollapsibleGroupHeader(
                    text: l10n.permGlobal,
                    expanded: _globalExpanded,
                    onToggle: () => setState(() => _globalExpanded = !_globalExpanded),
                  ),
                  if (_globalExpanded)
                    SettingsGroup(
                      children: _rulesGroup(
                        l10n,
                        rules.global,
                        emptyHint: l10n.permNoGlobalRules,
                        onDelete: (rule) =>
                            ref.read(permissionRulesProvider.notifier).removeGlobal(rule),
                        onPromote: null,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.xs, 0, 0),
                    child: Text(
                      l10n.permRulesShort,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: semantic.subtleText),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        ),
    );
  }

  List<Widget> _rulesGroup(
    AppLocalizations l10n,
    List<PermissionRule> rules, {
    required String emptyHint,
    required ValueChanged<PermissionRule> onDelete,
    required ValueChanged<PermissionRule>? onPromote,
  }) {
    if (rules.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 12),
          child: Text(
            emptyHint,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: context.semantic.subtleText),
          ),
        ),
      ];
    }
    return [
      for (var index = 0; index < rules.length; index++) ...[
        if (index > 0) const SettingsDivider(),
        _RuleRow(
          l10n: l10n,
          rule: rules[index],
          onDelete: () => onDelete(rules[index]),
          onPromote: onPromote == null ? null : () => onPromote(rules[index]),
        ),
      ],
    ];
  }
}

/// 单条规则行(对齐上游 RuleRow):判定图标 + 工具名 + 「匹配范围 · 允许/禁止」+ 可选「提升为全局」。
class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.l10n,
    required this.rule,
    required this.onDelete,
    required this.onPromote,
  });

  final AppLocalizations l10n;
  final PermissionRule rule;
  final VoidCallback onDelete;
  final VoidCallback? onPromote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final allowed = rule.decision == PermissionDecision.allow;
    final tint = allowed ? theme.colorScheme.primary : theme.colorScheme.error;
    final scopeText = rule.pattern == PermissionRule.wholeTool ? l10n.permEntireTool : rule.pattern;

    return SwipeToDeleteRow(
      onDelete: onDelete,
      decorateChild: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.lg, 11, Spacing.xs, 11),
        child: Row(
          children: [
            Icon(allowed ? Iconfont.checkCircle : Iconfont.xCircle, size: 18, color: tint),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule.toolName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '$scopeText · ${allowed ? l10n.allow : l10n.permDeny}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(color: semantic.subtleText),
                  ),
                ],
              ),
            ),
            if (onPromote != null)
              IconButton(
                icon: Icon(Iconfont.plus, size: 18, color: tint),
                tooltip: l10n.permPromoteToGlobal,
                onPressed: onPromote,
              ),
          ],
        ),
      ),
    );
  }
}