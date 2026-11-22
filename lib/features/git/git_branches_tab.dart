import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';

import '../../agent/models/git_models.dart';
import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../data/git_controller.dart';
import '../../g11n/app_globalizations.dart';
import 'widgets/git_common.dart';
import 'widgets/git_sheets.dart';

/// 分支树节点:中间段为虚拟文件夹(branch 为空),叶子段承载 [GitBranch]。
class BranchNode {
  BranchNode(this.segment, this.fullPath, [this.branch]);

  final String segment;
  final String fullPath;
  GitBranch? branch;
  final List<BranchNode> children = [];
}

/// 按 `/` 切分分支名构建层级树。同层按段名字典序排序。
List<BranchNode> buildBranchTree(List<GitBranch> branches) {
  final root = BranchNode('', '');
  final sorted = [...branches]..sort((a, b) => a.name.compareTo(b.name));
  for (final branch in sorted) {
    final parts = branch.name.split('/');
    var current = root;
    final path = StringBuffer();
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (path.isNotEmpty) path.write('/');
      path.write(part);
      final isLeaf = i == parts.length - 1;
      final existing = current.children.where((node) => node.segment == part).firstOrNull;
      if (existing == null) {
        final node = BranchNode(part, path.toString(), isLeaf ? branch : null);
        current.children.add(node);
        current = node;
      } else {
        if (isLeaf) existing.branch = branch;
        current = existing;
      }
    }
  }
  _sortTree(root);
  return root.children;
}

void _sortTree(BranchNode node) {
  node.children.sort((a, b) => a.segment.toLowerCase().compareTo(b.segment.toLowerCase()));
  for (final child in node.children) {
    _sortTree(child);
  }
}

/// 分支页:概览、HEAD、本地/远程/标签三段(可折叠、按 `/` 分组)。
class GitBranchesTab extends StatefulWidget {
  const GitBranchesTab({super.key, required this.state, required this.controller});

  final GitUiState state;
  final GitController controller;

  @override
  State<GitBranchesTab> createState() => _GitBranchesTabState();
}

class _GitBranchesTabState extends State<GitBranchesTab> {
  final _expanded = <String, bool>{};
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (!widget.state.branchesLoaded && !widget.state.branchesLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.controller.loadBranches());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  GitUiState get _state => widget.state;
  GitController get _controller => widget.controller;

  bool _isExpanded(String key) => _expanded[key] ?? true;

  /// 分支行副标题:当前分支标记 + 跟踪关系 + 同步数量。
  String? _branchSubtitle(GitBranch branch) {
    final g11n = AppGlobalizations.of(context);
    final parts = <String>[];
    if (branch.current) parts.add(g11n.gitCheckedOut);
    final upstream = branch.upstream;
    if (upstream != null) {
      final sync = [
        if (branch.ahead > 0) g11n.gitAheadCount(branch.ahead),
        if (branch.behind > 0) g11n.gitBehindCount(branch.behind),
      ].join(' · ');
      parts.add(sync.isEmpty ? '$upstream ${g11n.gitBranchSynced}' : '$upstream $sync');
    } else {
      parts.add(g11n.gitNoUpstream);
    }
    return parts.join(' · ');
  }

  Future<void> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = true,
    required VoidCallback onConfirm,
  }) async {
    final g11n = AppGlobalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(g11n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              confirmLabel,
              style: destructive
                  ? TextStyle(color: Theme.of(dialogContext).colorScheme.error)
                  : null,
            ),
          ),
        ],
      ),
    );
    if (confirmed ?? false) onConfirm();
  }

  /// 检出确认:标签 → 分离头指针警告;远程分支 → 建跟踪分支;其余 → 普通切换确认。
  Future<void> _confirmCheckout(String ref, {required bool isRemote}) async {
    final g11n = AppGlobalizations.of(context);
    final isTag = _state.tags.any((tag) => tag.name == ref);
    await _confirm(
      title: g11n.gitSwitchBranch,
      message: isTag
          ? g11n.gitDetachedHeadWarning(ref)
          : isRemote
              ? g11n.gitCreateTrackingBranch(ref)
              : g11n.gitSwitchConfirm(ref),
      confirmLabel: g11n.switchLabel,
      destructive: false,
      onConfirm: () => _controller.checkout(ref, isRemote: isRemote),
    );
  }

  Future<void> _openRefMenu(GitBranch branch, {required bool isRemote}) async {
    final g11n = AppGlobalizations.of(context);
    final actions = <RefMenuItem>[
      if (isRemote) ...[
        RefMenuItem(
          label: g11n.switchLabel,
          icon: Iconfont.gitCommit,
          onSelected: () => _confirmCheckout(branch.name, isRemote: true),
        ),
        RefMenuItem(
          label: g11n.gitActionMerge,
          icon: Iconfont.gitMerge,
          onSelected: () => _confirmMerge(branch.name),
        ),
        RefMenuItem(
          label: g11n.delete,
          icon: Iconfont.trash2,
          destructive: true,
          onSelected: () => _confirm(
            title: g11n.gitDeleteRemoteBranch,
            message: g11n.gitDeleteRemoteBranchConfirm(branch.name),
            confirmLabel: g11n.delete,
            onConfirm: () => _controller.deleteRemoteBranch(branch.name),
          ),
        ),
      ] else ...[
        if (!branch.current) ...[
          RefMenuItem(
            label: g11n.switchLabel,
            icon: Iconfont.gitCommit,
            onSelected: () => _confirmCheckout(branch.name, isRemote: false),
          ),
          RefMenuItem(
            label: g11n.gitActionMerge,
            icon: Iconfont.gitMerge,
            onSelected: () => _confirmMerge(branch.name),
          ),
        ],
        RefMenuItem(
          label: g11n.rename,
          icon: Iconfont.pencil,
          onSelected: () => _promptRename(branch.name),
        ),
        if (!branch.current)
          RefMenuItem(
            label: g11n.delete,
            icon: Iconfont.trash2,
            destructive: true,
            onSelected: () => _confirm(
              title: g11n.gitDeleteBranch,
              message: g11n.gitDeleteLocalBranchConfirm(branch.name),
              confirmLabel: g11n.delete,
              onConfirm: () => _controller.deleteBranch(branch.name),
            ),
          ),
      ],
    ];
    if (!mounted) return;
    await showRefActionSheet(context, refName: branch.name, actions: actions);
  }

  Future<void> _confirmMerge(String branch) async {
    final g11n = AppGlobalizations.of(context);
    final current = _state.status?.branch ?? g11n.gitNoCheckedOutBranch;
    var noFf = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(g11n.gitActionMerge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(g11n.gitMergeConfirm(branch, current)),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      g11n.gitMergeNoFf,
                      style: Theme.of(dialogContext).textTheme.bodyMedium,
                    ),
                  ),
                  Switch(
                    value: noFf,
                    onChanged: (value) => setDialogState(() => noFf = value),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(g11n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(g11n.gitActionMerge),
            ),
          ],
        ),
      ),
    );
    if (confirmed ?? false) {
      await _controller.mergeBranch(branch, noFf: noFf);
    }
  }

  Future<void> _promptRename(String oldName) async {
    final g11n = AppGlobalizations.of(context);
    final controller = TextEditingController(text: oldName);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(g11n.gitRenameBranch),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(g11n.gitRenameTo(oldName)),
            const SizedBox(height: Spacing.sm),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: g11n.gitNewBranchName,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(g11n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(g11n.rename),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty && result != oldName) {
      await _controller.renameBranch(oldName, result);
    }
  }

  Future<void> _promptCreateBranch() async {
    final g11n = AppGlobalizations.of(context);
    final current = _state.status?.branch ?? '';
    final localNames = _state.branches.where((b) => !b.remote).map((b) => b.name).toList();
    final nameController = TextEditingController();
    var startPoint = localNames.contains(current) ? current : (localNames.firstOrNull ?? '');
    var checkoutAfter = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(g11n.gitNewBranch),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    labelText: g11n.gitBranchName,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: Spacing.md),
                DropdownButtonFormField<String>(
                  value: startPoint.isEmpty ? null : startPoint,
                  decoration: InputDecoration(
                    labelText: g11n.gitBaseBranch,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final name in localNames)
                      DropdownMenuItem(value: name, child: Text(name)),
                  ],
                  onChanged: (value) => setDialogState(() => startPoint = value ?? ''),
                ),
                const SizedBox(height: Spacing.sm),
                Row(
                  children: [
                    Expanded(child: Text(g11n.gitCreateAndSwitch)),
                    Switch(
                      value: checkoutAfter,
                      onChanged: (value) => setDialogState(() => checkoutAfter = value),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(g11n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(g11n.create),
            ),
          ],
        ),
      ),
    );
    final name = nameController.text.trim();
    nameController.dispose();
    if ((confirmed ?? false) && name.isNotEmpty) {
      await _controller.createBranch(
        name,
        startPoint: startPoint.isEmpty ? null : startPoint,
        checkoutAfter: checkoutAfter,
      );
    }
  }

  Future<void> _promptCreateTag() async {
    final g11n = AppGlobalizations.of(context);
    final current = _state.status?.branch ?? g11n.gitNoCheckedOutBranch;
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(g11n.gitCreateTagTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              g11n.gitCreateTagDesc(current),
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
            const SizedBox(height: Spacing.sm),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: g11n.gitTagName,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(g11n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(g11n.create),
          ),
        ],
      ),
    );
    final name = controller.text.trim();
    controller.dispose();
    if ((confirmed ?? false) && name.isNotEmpty) {
      await _controller.createTag(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    final theme = Theme.of(context);

    if (_state.branchesLoading ||
        (!_state.branchesLoaded && _state.branches.isEmpty && _state.tags.isEmpty)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              g11n.gitLoadingBranches,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    if (_state.branches.isEmpty && _state.tags.isEmpty) {
      return Center(
        child: Text(
          g11n.gitNoBranches,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final currentBranch = _state.branches.where((b) => b.current).firstOrNull?.name ??
        g11n.gitNoCheckedOutBranch;
    final hasCurrentBranch = _state.branches.any((b) => b.current);
    final localBranches = _state.branches.where((b) => !b.remote).toList();
    final remoteBranches = _state.branches.where((b) => b.remote).toList();
    final localTree = buildBranchTree(localBranches);
    final remoteTree = buildBranchTree(remoteBranches);

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, 70),
      children: [
        const SizedBox(height: Spacing.sm),
        _BranchesOverview(
          currentBranch: currentBranch,
          localCount: localBranches.length,
          remoteCount: remoteBranches.length,
          tagCount: _state.tags.length,
          hasCurrentBranch: hasCurrentBranch,
        ),
        const SizedBox(height: Spacing.md),
        RefSectionHeader(
          title: 'HEAD',
          expanded: _isExpanded('head'),
          onToggle: () => setState(() => _expanded['head'] = !_isExpanded('head')),
        ),
        if (_isExpanded('head'))
          SettingsGroup(
            children: [
              RefRow(
                name: currentBranch,
                subtitle: g11n.gitCheckedOut,
                icon: Iconfont.gitCommit,
                isCurrent: true,
              ),
            ],
          ),
        if (localBranches.isNotEmpty) ...[
          RefSectionHeader(
            title: '${g11n.commonLocal} (${localBranches.length})',
            expanded: _isExpanded('local'),
            onToggle: () => setState(() => _expanded['local'] = !_isExpanded('local')),
            onAdd: _promptCreateBranch,
            addTooltip: g11n.gitNewBranch,
          ),
          if (_isExpanded('local'))
            SettingsGroup(
              children: _renderTree(localTree, depth: 1, isRemote: false),
            ),
        ],
        if (remoteBranches.isNotEmpty) ...[
          RefSectionHeader(
            title: '${g11n.gitRemote} (${remoteBranches.length})',
            expanded: _isExpanded('remote'),
            onToggle: () => setState(() => _expanded['remote'] = !_isExpanded('remote')),
          ),
          if (_isExpanded('remote'))
            SettingsGroup(
              children: _renderTree(remoteTree, depth: 1, isRemote: true),
            ),
        ],
        if (_state.tags.isNotEmpty) ...[
          RefSectionHeader(
            title: '${g11n.gitTags} (${_state.tags.length})',
            expanded: _isExpanded('tags'),
            onToggle: () => setState(() => _expanded['tags'] = !_isExpanded('tags')),
            onAdd: _promptCreateTag,
            addTooltip: g11n.gitCreateTagTitle,
          ),
          if (_isExpanded('tags'))
            SettingsGroup(
              children: [
                for (var i = 0; i < _state.tags.length; i++) ...[
                  if (i > 0) const SettingsDivider(),
                  RefRow(
                    name: _state.tags[i].name,
                    subtitle: _state.tags[i].commitHash,
                    icon: Iconfont.tag,
                    isCurrent: false,
                    isLoading: _state.checkoutLoading == _state.tags[i].name,
                    onTap: () async {
                      final tag = _state.tags[i].name;
                      final actions = [
                        RefMenuItem(
                          label: g11n.switchLabel,
                          icon: Iconfont.gitCommit,
                          onSelected: () => _confirmCheckout(tag, isRemote: false),
                        ),
                        RefMenuItem(
                          label: g11n.delete,
                          icon: Iconfont.trash2,
                          destructive: true,
                          onSelected: () => _confirm(
                            title: g11n.gitDeleteTag,
                            message: g11n.gitDeleteTagConfirm(tag),
                            confirmLabel: g11n.delete,
                            onConfirm: () => _controller.deleteTag(tag),
                          ),
                        ),
                      ];
                      await showRefActionSheet(context, refName: tag, actions: actions);
                    },
                  ),
                ],
              ],
            ),
        ],
      ],
    );
  }

  /// 递归渲染分支树;文件夹节点可折叠,行间用分隔线。
  List<Widget> _renderTree(List<BranchNode> nodes, {required int depth, required bool isRemote}) {
    final widgets = <Widget>[];
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final isFolder = node.children.isNotEmpty;
      final isOpen = _isExpanded(node.fullPath);
      if (i > 0) widgets.add(const SettingsDivider());
      if (isFolder) {
        widgets.add(RefSectionHeader(
          title: node.segment,
          expanded: isOpen,
          indent: depth,
          onToggle: () => setState(() => _expanded[node.fullPath] = !isOpen),
        ));
        if (isOpen) {
          widgets.addAll(_renderTree(node.children, depth: depth + 1, isRemote: isRemote));
        }
      } else {
        final branch = node.branch;
        if (branch != null) {
          widgets.add(RefRow(
            name: node.segment,
            subtitle: isRemote ? null : _branchSubtitle(branch),
            icon: isRemote ? Iconfont.cloud : Iconfont.gitBranch,
            isCurrent: branch.current,
            isLoading: _state.checkoutLoading == branch.name,
            indent: depth,
            onTap: () => _openRefMenu(branch, isRemote: isRemote),
          ));
        }
      }
    }
    return widgets;
  }
}

/// 概览卡:当前分支 + 本地/远程/标签三格统计。
class _BranchesOverview extends StatelessWidget {
  const _BranchesOverview({
    required this.currentBranch,
    required this.localCount,
    required this.remoteCount,
    required this.tagCount,
    required this.hasCurrentBranch,
  });

  final String currentBranch;
  final int localCount;
  final int remoteCount;
  final int tagCount;
  final bool hasCurrentBranch;

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: context.semantic.cardSurface,
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconfont.gitBranch, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g11n.gitCurrentBranch,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      currentBranch,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontFamily: 'monospace'),
                    ),
                    if (!hasCurrentBranch)
                      Text(
                        g11n.gitDetachedHeadLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              Expanded(
                child: StatusMetric(
                  label: g11n.commonLocal,
                  count: localCount,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: StatusMetric(
                  label: g11n.gitRemote,
                  count: remoteCount,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: StatusMetric(
                  label: g11n.gitTags,
                  count: tagCount,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}