import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../data/codespaces.dart';
import '../../data/codespaces_controller.dart';
import '../../data/codespaces_gh.dart';
import '../../data/codespaces_readiness.dart';
import '../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// 新建 Codespace 弹层(对齐 VS Code 的创建流程):选仓库 → 选分支 → 选机型 → 创建。
///
/// 返回 true 表示已创建(调用方据此刷新列表)。
Future<bool> showCreateCodespaceDialog(BuildContext context) async {
  final created = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => const _CreateCodespaceDialog(),
  );
  return created ?? false;
}

/// 改显示名弹层;返回新名字(未改动或取消返回 null)。
Future<String?> showCodespaceNameDialog(
  BuildContext context, {
  required String initial,
}) =>
    showDialog<String>(
      context: context,
      builder: (dialogContext) => _NameDialog(initial: initial),
    );

/// 机型选择弹层;返回选中的机型名(取消返回 null)。
Future<String?> showMachinePickerDialog(
  BuildContext context, {
  required String codespaceName,
}) =>
    showDialog<String>(
      context: context,
      builder: (dialogContext) => _MachineDialog(codespaceName: codespaceName),
    );

class _CreateCodespaceDialog extends ConsumerStatefulWidget {
  const _CreateCodespaceDialog();

  @override
  ConsumerState<_CreateCodespaceDialog> createState() => _CreateCodespaceDialogState();
}

class _CreateCodespaceDialogState extends ConsumerState<_CreateCodespaceDialog> {
  final _search = TextEditingController();
  final _branch = TextEditingController();

  GitHubRepo? _repo;
  String? _machine;
  bool _loadingRepos = true;
  bool _loadingMachines = false;
  List<CodespaceMachine> _machines = const [];

  @override
  void initState() {
    super.initState();
    _loadRepos();
  }

  @override
  void dispose() {
    _search.dispose();
    _branch.dispose();
    super.dispose();
  }

  CodespacesController get _controller => ref.read(codespacesProvider.notifier);

  Future<void> _loadRepos() async {
    await _controller.loadRepos();
    if (mounted) setState(() => _loadingRepos = false);
  }

  Future<void> _selectRepo(GitHubRepo repo) async {
    setState(() {
      _repo = repo;
      _machine = null;
      _branch.text = repo.defaultBranch;
      _loadingMachines = true;
      _machines = const [];
    });
    final machines = await _controller.loadMachinesForRepo(repo.fullName);
    if (!mounted) return;
    setState(() {
      _machines = machines;
      _loadingMachines = false;
    });
  }

  Future<void> _submit() async {
    final repo = _repo;
    if (repo == null) return;
    final created = await _controller.create(CodespaceCreateSpec(
      repository: repo.fullName,
      ref: _branch.text,
      machine: _machine,
      devcontainerPath: '.devcontainer/devcontainer.json',
    ));
    if (!mounted) return;
    Navigator.of(context).pop(created != null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(codespacesProvider);
    final query = _search.text.trim().toLowerCase();
    final repos = query.isEmpty
        ? state.repos
        : state.repos
            .where((repo) =>
                repo.fullName.toLowerCase().contains(query) ||
                repo.description.toLowerCase().contains(query))
            .toList();

    return AlertDialog(
      title: Text(l10n.codespacesNew),
      content: SizedBox(
        width: 420,
        height: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsGroupHeader(text: l10n.codespacesRepoTab),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.codespacesRepoSearchHint,
                prefixIcon: const Icon(Iconfont.search, size: 16),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: Spacing.xs),
            if (_loadingRepos)
              const Padding(
                padding: EdgeInsets.all(Spacing.sm),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (repos.isEmpty)
              Padding(
                padding: const EdgeInsets.all(Spacing.sm),
                child: Text(
                  l10n.codespacesLoadFailed,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: repos.length > 30 ? 30 : repos.length,
                  itemBuilder: (context, index) {
                    final repo = repos[index];
                    final selected = _repo?.fullName == repo.fullName;
                    return ListTile(
                      dense: true,
                      selected: selected,
                      leading: Icon(
                        repo.private ? Iconfont.lock : Iconfont.github,
                        size: 16,
                      ),
                      title: Text(repo.fullName, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => _selectRepo(repo),
                    );
                  },
                ),
              ),
            const SizedBox(height: Spacing.sm),
            TextField(
              controller: _branch,
              decoration: InputDecoration(
                isDense: true,
                labelText: l10n.codespacesBranch,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            SettingsGroupHeader(text: l10n.codespacesMachine),
            if (_loadingMachines)
              const Padding(
                padding: EdgeInsets.all(Spacing.sm),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    RadioListTile<String?>(
                      dense: true,
                      value: null,
                      groupValue: _machine,
                      onChanged: (value) => setState(() => _machine = value),
                      title: Text(l10n.codespacesMachineDefault),
                    ),
                    for (final machine in _machines)
                      RadioListTile<String?>(
                        dense: true,
                        value: machine.name,
                        groupValue: _machine,
                        onChanged: (value) => setState(() => _machine = value),
                        title: Text(machine.displayName),
                      ),
                    if (_repo != null && !_loadingMachines && _machines.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(Spacing.sm),
                        child: Text(
                          l10n.codespacesNoMachines,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.creating ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _repo == null || state.creating ? null : _submit,
          child: state.creating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.codespacesCreate),
        ),
      ],
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.codespacesRename),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l10n.codespacesRenameTitle,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _MachineDialog extends ConsumerStatefulWidget {
  const _MachineDialog({required this.codespaceName});

  final String codespaceName;

  @override
  ConsumerState<_MachineDialog> createState() => _MachineDialogState();
}

class _MachineDialogState extends ConsumerState<_MachineDialog> {
  bool _loading = true;
  List<CodespaceMachine> _machines = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final machines = await ref
        .read(codespacesProvider.notifier)
        .loadMachinesForCodespace(widget.codespaceName);
    if (!mounted) return;
    setState(() {
      _machines = machines;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.codespacesChangeMachine),
      content: SizedBox(
        width: 360,
        height: 260,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  for (final machine in _machines)
                    ListTile(
                      dense: true,
                      title: Text(machine.displayName),
                      subtitle: Text(
                        machine.name,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontFamily: 'monospace',
                          color: context.semantic.subtleText,
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(machine.name),
                    ),
                  if (_machines.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(Spacing.sm),
                      child: Text(l10n.codespacesNoMachines),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

/// 转发端口面板(对齐 VS Code Codespaces 扩展的 Ports 面板):
/// 列出端口与可见性,可就地切换可见性、在浏览器打开。
Future<void> showPortsDialog(BuildContext context, {required String codespaceName}) =>
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _PortsDialog(codespaceName: codespaceName),
    );

class _PortsDialog extends ConsumerStatefulWidget {
  const _PortsDialog({required this.codespaceName});

  final String codespaceName;

  @override
  ConsumerState<_PortsDialog> createState() => _PortsDialogState();
}

class _PortsDialogState extends ConsumerState<_PortsDialog> {
  bool _loading = true;
  String? _error;
  List<CodespacePort> _ports = const [];
  int? _busyPort;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<CodespacesGhService> _service() =>
      ref.read(codespacesGhServiceProvider.future);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ports = await (await _service()).listPorts(widget.codespaceName);
      if (!mounted) return;
      setState(() {
        _ports = ports;
        _loading = false;
      });
    } on CodespacesGhException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  Future<void> _setVisibility(CodespacePort port, PortVisibility visibility) async {
    setState(() => _busyPort = port.sourcePort);
    try {
      await (await _service())
          .setPortVisibility(widget.codespaceName, port.sourcePort, visibility);
      if (!mounted) return;
      setState(() => _busyPort = null);
      await _load();
    } on CodespacesGhException catch (error) {
      if (!mounted) return;
      setState(() {
        _busyPort = null;
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busyPort = null;
        _error = '$error';
      });
    }
  }

  String _visibilityLabel(AppLocalizations l10n, String visibility) => switch (visibility) {
        'public' => l10n.codespacesPortPublic,
        'org' => l10n.codespacesPortOrg,
        _ => l10n.codespacesPortPrivate,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          Text(l10n.codespacesPorts),
          const Spacer(),
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: l10n.codespacesRefresh,
            icon: const Icon(Iconfont.refreshCw, size: 18),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        height: 320,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Spacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _error!,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.error),
                          ),
                          if (codespacesErrorSuggestsCredentials(_error))
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                context.push('/credentials');
                              },
                              child: Text(l10n.codespacesGoToCredentials),
                            ),
                          if (codespacesErrorSuggestsGhOrConnection(_error))
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                l10n.codespacesReadinessGhMissing,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (_ports.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(Spacing.sm),
                      child: Text(
                        l10n.codespacesPortsEmpty,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        itemCount: _ports.length,
                        itemBuilder: (context, index) {
                          final port = _ports[index];
                          final busy = _busyPort == port.sourcePort;
                          return ListTile(
                            dense: true,
                            title: Text(
                              '${port.sourcePort}${port.label.isEmpty ? '' : ' · ${port.label}'}',
                            ),
                            subtitle: Text(
                              _visibilityLabel(l10n, port.visibility),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: context.semantic.subtleText,
                              ),
                            ),
                            trailing: busy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      PopupMenuButton<PortVisibility>(
                                        tooltip: l10n.codespacesPortVisibility,
                                        icon: const Icon(Iconfont.shield, size: 18),
                                        onSelected: (value) => _setVisibility(port, value),
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: PortVisibility.private,
                                            child: Text(l10n.codespacesPortPrivate),
                                          ),
                                          PopupMenuItem(
                                            value: PortVisibility.org,
                                            child: Text(l10n.codespacesPortOrg),
                                          ),
                                          PopupMenuItem(
                                            value: PortVisibility.public,
                                            child: Text(l10n.codespacesPortPublic),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        tooltip: l10n.codespacesPortOpen,
                                        onPressed: port.browseUrl.isEmpty
                                            ? null
                                            : () => launchUrl(
                                                  Uri.parse(port.browseUrl),
                                                  mode: LaunchMode.externalApplication,
                                                ),
                                        icon: const Icon(Iconfont.externalLink, size: 18),
                                      ),
                                    ],
                                  ),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
