import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../core/util/window_size.dart';
import '../../data/codespaces.dart';
import '../../data/codespaces_controller.dart';
import '../../data/codespaces_gh.dart';
import '../../data/codespaces_readiness.dart';
import '../../data/execution_target.dart';
import '../../data/workbench.dart';
import '../../l10n/app_localizations.dart';
import 'codespace_dialogs.dart';
import 'package:go_router/go_router.dart';

/// GitHub Codespaces 页:令牌取自 Git 凭据(需 codespace 作用域),列出账号下的 Codespace,
/// 支持启动/停止/删除与在浏览器打开。
class CodespacesPage extends ConsumerStatefulWidget {
  const CodespacesPage({super.key, this.onNavigateBack});

  final VoidCallback? onNavigateBack;

  @override
  ConsumerState<CodespacesPage> createState() => _CodespacesPageState();
}

class _CodespacesPageState extends ConsumerState<CodespacesPage> {
  /// 正在重建的 Codespace 名(重建耗时较长,按钮要一直转圈)。
  String? _rebuilding;

  @override
  void initState() {
    super.initState();
    // 令牌来自 Git 凭据:每次进入本页重读一次,用户刚填完凭据返回即可见效。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.load();
    });
  }

  CodespacesController get _controller => ref.read(codespacesProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(codespacesProvider);
    return Scaffold(
      backgroundColor: context.semantic.pageBackground,
      appBar: AppBar(
        backgroundColor: context.semantic.pageBackground,
        title: Text(l10n.codespacesTitle),
        leading: IconButton(
          onPressed: widget.onNavigateBack ?? () => Navigator.of(context).maybePop(),
          tooltip: l10n.back,
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/credentials'),
            tooltip: l10n.codespacesManageCredentials,
            icon: const Icon(LucideIcons.keyRound),
          ),
          if (state.token.isNotEmpty)
            IconButton(
              onPressed: state.creating ? null : _createCodespace,
              tooltip: l10n.codespacesNew,
              icon: const Icon(LucideIcons.plus),
            ),
          if (state.token.isNotEmpty)
            IconButton(
              onPressed: state.loading ? null : _controller.refresh,
              tooltip: l10n.codespacesRefresh,
              icon: const Icon(LucideIcons.refreshCw),
            ),
        ],
      ),
      body: !state.initialized
          ? const Center(child: CircularProgressIndicator())
          : state.token.isEmpty
              ? _buildLogin(context, state)
              : _buildList(context, state),
    );
  }

  /// 未在 Git 凭据里找到令牌时的引导卡片:Codespaces 与 Git 共用同一条令牌,不在这里单独输入。
  Widget _buildLogin(BuildContext context, CodespacesUiState state) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(Spacing.xl),
          decoration: BoxDecoration(
            color: context.semantic.cardSurface,
            borderRadius: BorderRadius.circular(Radii.xl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(Radii.mdLarge),
                    ),
                    child: Icon(LucideIcons.github, size: 26, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.codespacesNeedCredentialTitle,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          l10n.codespacesNeedCredentialDesc,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (state.error != null) ...[
                const SizedBox(height: Spacing.md),
                Text(
                  state.error!,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: Spacing.lg),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: () => context.push('/credentials'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.mdLarge),
                    ),
                  ),
                  child: Text(l10n.codespacesGoToCredentials),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: state.loading ? null : _controller.load,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.mdLarge),
                    ),
                  ),
                  child: state.loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.codespacesRefresh),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context, CodespacesUiState state) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final target = ref.watch(executionTargetProvider);
    final readiness = ref.watch(codespacesReadinessProvider);
    if (state.loading && state.codespaces.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.sm, Spacing.lg, Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.error != null) ...[
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.alertTriangle, size: 18, color: theme.colorScheme.error),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (state.errorSuggestsCredentials || state.errorSuggestsGhOrConnection) ...[
                    const SizedBox(height: Spacing.sm),
                    Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.xs,
                      children: [
                        if (state.errorSuggestsCredentials)
                          OutlinedButton(
                            onPressed: () => context.push('/credentials'),
                            child: Text(l10n.codespacesGoToCredentials),
                          ),
                        if (state.errorSuggestsGhOrConnection)
                          OutlinedButton(
                            onPressed: () => openWorkbench(
                              context,
                              ref,
                              WorkbenchPaneKind.terminal,
                              isWideLayout(context),
                            ),
                            child: Text(l10n.codespacesOpenTerminal),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
          ],
          readiness.when(
            data: (r) => Container(
              margin: const EdgeInsets.only(bottom: Spacing.md),
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: context.semantic.cardSurface,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.codespacesReadinessTitle,
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    r.hasGitHubCredential
                        ? l10n.codespacesReadinessCredOk
                        : l10n.codespacesReadinessCredMissing,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: r.hasGitHubCredential ? context.semantic.success : theme.colorScheme.error,
                    ),
                  ),
                  Text(
                    r.hasGh ? l10n.codespacesReadinessGhOk : l10n.codespacesReadinessGhMissing,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: r.hasGh ? context.semantic.success : theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    l10n.codespacesDeploySyncHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          SettingsGroupHeader(text: l10n.codespacesAccount),
          SettingsGroup(
            children: [
              SettingsRow(
                icon: LucideIcons.github,
                title: state.login,
                subtitle: codespacesHost,
              ),
              const SettingsDivider(),
              SettingsRow(
                icon: target.isRemote ? LucideIcons.cloud : LucideIcons.hardDrive,
                title: l10n.codespacesExecutionEnv,
                subtitle: target.isRemote
                    ? '${l10n.codespacesEnvCodespace} · ${target.label}'
                    : '本地执行环境',
                trailing: target.isRemote
                    ? TextButton(
                        onPressed: _disconnect,
                        child: Text(l10n.codespacesDisconnect),
                      )
                    : null,
              ),
            ],
          ),

          const SizedBox(height: Spacing.lg),
          if (state.codespaces.isEmpty)
            _EmptyCodespaces(onCreate: _openCreatePage)
          else ...[
            SettingsGroupHeader(text: l10n.codespacesCount(state.codespaces.length)),
            SettingsGroup(
              children: [
                for (var i = 0; i < state.codespaces.length; i++) ...[
                  if (i > 0) const SettingsDivider(),
                  _CodespaceRow(
                    codespace: state.codespaces[i],
                    busy: state.busyNames.contains(state.codespaces[i].name),
                    enabled: !state.busyNames.contains(state.codespaces[i].name),
                    active: target is CodespaceExecutionTarget &&
                        target.name == state.codespaces[i].name,
                    onConnect: () => _connect(state.codespaces[i]),
                    onDisconnect: _disconnect,
                    onRename: () => _rename(state.codespaces[i]),
                    onChangeMachine: () => _changeMachine(state.codespaces[i]),
                    onPorts: () => showPortsDialog(context, codespaceName: state.codespaces[i].name),
                    onRebuild: () => _rebuild(state.codespaces[i]),
                    rebuilding: _rebuilding == state.codespaces[i].name,
                    onOpenBrowser: () => _openInBrowser(state.codespaces[i]),
                    onOpenTerminal: _openTerminalForCodespace,
                    onOpenGit: _openGitSync,
                    onStart: () => _controller.start(state.codespaces[i].name),
                    onStop: () => _controller.stop(state.codespaces[i].name),
                    onDelete: () => _confirmDelete(state.codespaces[i]),
                  ),
                ],
              ],
            ),
            const SizedBox(height: Spacing.xl),
          ],
        ],
      ),
    );
  }

  Future<void> _createCodespace() async {
    if (await showCreateCodespaceDialog(context)) {
      await _controller.refresh();
    }
  }

  Future<void> _rename(Codespace codespace) async {
    final name = await showCodespaceNameDialog(context, initial: codespace.displayName);
    if (name == null) return;
    await _controller.rename(codespace.name, name);
  }

  Future<void> _changeMachine(Codespace codespace) async {
    final machine = await showMachinePickerDialog(context, codespaceName: codespace.name);
    if (machine == null) return;
    await _controller.changeMachine(codespace.name, machine);
  }

  /// 重建容器:v 不会丢代码,但容器内环境会重来,所以先确认。
  Future<void> _rebuild(Codespace codespace) async {
    final l10n = AppLocalizations.of(context);
    var full = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('重建环境'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('重建会重新创建执行环境，代码与未提交改动保留，环境内已安装的工具与运行状态会丢失。'),
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  const Expanded(child: Text('完全重建（同时清除缓存，更慢）')),
                  Switch(
                    value: full,
                    onChanged: (value) => setDialogState(() => full = value),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('重建环境'),
            ),
          ],
        ),
      ),
    );
    if (!(confirmed ?? false)) return;
    if (!mounted) return;

    setState(() => _rebuilding = codespace.name);
    try {
      final service = await ref.read(codespacesGhServiceProvider.future);
      await service.rebuild(codespace.name, full: full);
      if (!mounted) return;
      await _controller.refresh();
    } on CodespacesGhException {
      if (!mounted) return;
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _rebuilding = null);
    }
  }

  Future<void> _connect(Codespace codespace) async {
    ref.read(executionTargetProvider.notifier).useCodespace(
          codespace.name,
          repository: codespace.repository,
        );
  }


  Future<void> _disconnect() async {
    ref.read(executionTargetProvider.notifier).useLocal();
  }

  void _openTerminalForCodespace() {
    openWorkbench(context, ref, WorkbenchPaneKind.terminal, isWideLayout(context));
  }

  void _openGitSync() {
    openWorkbench(context, ref, WorkbenchPaneKind.git, isWideLayout(context));
  }

  Future<void> _openCreatePage() =>
      launchUrl(Uri.parse('https://github.com/codespaces'), mode: LaunchMode.externalApplication);

  Future<void> _openInBrowser(Codespace codespace) async {
    final target = codespace.webUrl.isNotEmpty
        ? codespace.webUrl
        : 'https://github.com/codespaces/${codespace.name}';
    await launchUrl(Uri.parse(target), mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmDelete(Codespace codespace) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.codespacesDelete),
        content: Text(l10n.codespacesDeleteConfirm(codespace.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.delete,
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await _controller.delete(codespace.name);
  }


}

/// 单个 Codespace 行:仓库名 + 状态胶囊 + 机器/最近使用,右侧主操作按钮与更多菜单。
class _CodespaceRow extends StatelessWidget {
  const _CodespaceRow({
    required this.codespace,
    required this.busy,
    required this.enabled,
    required this.active,
    required this.onConnect,
    required this.onDisconnect,
    required this.onRename,
    required this.onChangeMachine,
    required this.onPorts,
    required this.onRebuild,
    required this.rebuilding,
    required this.onOpenBrowser,
    required this.onOpenTerminal,
    required this.onOpenGit,
    required this.onStart,
    required this.onStop,
    required this.onDelete,
  });

  final Codespace codespace;
  final bool busy;
  final bool enabled;

  /// 当前执行环境是否就是这个 Codespace。
  final bool active;

  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onRename;
  final VoidCallback onChangeMachine;
  final VoidCallback onPorts;
  final VoidCallback onRebuild;

  /// 该行是否正在重建(重建期间禁用其它操作)。
  final bool rebuilding;
  final VoidCallback onOpenBrowser;
  final VoidCallback onOpenTerminal;
  final VoidCallback onOpenGit;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onDelete;

  /// 状态胶囊文案与配色。
  (String, Color) _stateChip(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semantic = context.semantic;
    if (codespace.isAvailable) return (l10n.codespacesStateAvailable, semantic.success);
    if (codespace.isStarting) return (l10n.codespacesStateStarting, semantic.warning);
    if (codespace.isStopped) {
      return (l10n.codespacesStateStopped, Theme.of(context).colorScheme.onSurfaceVariant);
    }
    return (
      codespace.state.isEmpty ? l10n.codespacesStateUnknown : codespace.state,
      Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  String _relativeTime(BuildContext context, DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    return '${diff.inDays} 天前';
  }

  /// 主操作:停机→启动;运行中→连接(已连接的则是断开);启动中无主操作。
  (String?, VoidCallback?) _primaryAction(AppLocalizations l10n) {
    if (codespace.isStopped) return (l10n.codespacesStart, onStart);
    if (codespace.isAvailable) {
      return active
          ? (l10n.codespacesDisconnect, onDisconnect)
          : (l10n.codespacesConnect, onConnect);
    }
    return (null, null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final (stateLabel, stateColor) = _stateChip(context);
    final busyAny = busy || rebuilding;
    final lastUsed = codespace.lastUsedAt;
    final subtitleParts = [
      stateLabel,
      if (codespace.machineDisplay.isNotEmpty) codespace.machineDisplay,
      if (lastUsed != null) l10n.codespacesLastUsed(_relativeTime(context, lastUsed)),
    ];
    return InkWell(
      onLongPress: enabled ? () => _openMenu(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(LucideIcons.cloud, size: 22, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          codespace.repository.isEmpty
                              ? l10n.codespacesNoRepo
                              : codespace.repository,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(width: Spacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: stateColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                        child: Text(
                          stateLabel,
                          maxLines: 1,
                          style: theme.textTheme.labelSmall?.copyWith(color: stateColor),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    subtitleParts.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (codespace.hasUncommittedChanges)
                    Text(
                      l10n.codespacesUncommitted,
                      style: theme.textTheme.labelSmall?.copyWith(color: semantic.warning),
                    ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            if (busyAny)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              TextButton(
                onPressed: enabled ? _primaryAction(l10n).$2 : null,
                child: Text(
                  _primaryAction(l10n).$1 ?? l10n.codespacesStop,
                  style: active ? TextStyle(color: semantic.success) : null,
                ),
              ),
            IconButton(
              onPressed: enabled ? () => _openMenu(context) : null,
              tooltip: l10n.codespacesMoreActions,
              icon: Icon(
                LucideIcons.moreVertical,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMenu(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (codespace.isAvailable)
              ListTile(
                leading: Icon(active ? LucideIcons.unplug : LucideIcons.plug),
                title: Text(active ? l10n.codespacesDisconnect : l10n.codespacesConnect),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  if (active) {
                    onDisconnect();
                  } else {
                    onConnect();
                  }
                },
              ),
            if (codespace.isStopped)
              ListTile(
                leading: const Icon(LucideIcons.play),
                title: Text(l10n.codespacesStart),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onStart();
                },
              )
            else if (codespace.isAvailable)
              ListTile(
                leading: const Icon(LucideIcons.square),
                title: Text(l10n.codespacesStop),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onStop();
                },
              ),
            ListTile(
              leading: const Icon(LucideIcons.pencil),
              title: Text(l10n.codespacesRename),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onRename();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.cpu),
              title: Text(l10n.codespacesChangeMachine),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onChangeMachine();
              },
            ),
            if (codespace.isAvailable)
              ListTile(
                leading: const Icon(LucideIcons.refreshCcw),
                title: const Text('重建环境'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onRebuild();
                },
              ),
            ListTile(
              leading: const Icon(LucideIcons.network),
              title: Text(l10n.codespacesPorts),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onPorts();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.terminal),
              title: Text(l10n.codespacesOpenTerminal),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onOpenTerminal();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.gitBranch),
              title: Text(l10n.codespacesOpenGit),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onOpenGit();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.externalLink),
              title: Text(l10n.codespacesOpenInBrowser),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onOpenBrowser();
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.trash2, color: Theme.of(sheetContext).colorScheme.error),
              title: Text(
                l10n.codespacesDelete,
                style: TextStyle(color: Theme.of(sheetContext).colorScheme.error),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 空列表引导:去 github.com 新建 Codespace。
class _EmptyCodespaces extends StatelessWidget {
  const _EmptyCodespaces({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        color: context.semantic.cardSurface,
        borderRadius: BorderRadius.circular(Radii.xl),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Radii.mdLarge),
            ),
            child: Icon(LucideIcons.cloud, size: 26, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            l10n.codespacesEmptyTitle,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            l10n.codespacesEmptyDesc,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: onCreate,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.mdLarge),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.externalLink, size: 16),
                  const SizedBox(width: Spacing.sm),
                  Text(l10n.codespacesCreateOnWeb, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
