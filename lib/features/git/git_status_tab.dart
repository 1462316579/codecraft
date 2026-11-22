import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agent/models/git_models.dart';
import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/git_controller.dart';
import '../../g11n/app_globalizations.dart';
import 'widgets/git_common.dart';
import 'widgets/git_sheets.dart';

/// 状态页:概览、提交、次级操作、冲突/合并横幅与三组文件改动。
class GitStatusTab extends ConsumerStatefulWidget {
  const GitStatusTab({super.key, required this.state, required this.controller});

  final GitUiState state;
  final GitController controller;

  @override
  ConsumerState<GitStatusTab> createState() => _GitStatusTabState();
}

class _GitStatusTabState extends ConsumerState<GitStatusTab> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  GitUiState get _state => widget.state;
  GitController get _controller => widget.controller;

  /// 未跟踪项展平:目录行 + 展开后的子文件行。
  List<_UntrackedItem> _untrackedItems() {
    final status = _state.status;
    if (status == null) return const [];
    final items = <_UntrackedItem>[];
    for (final path in status.untracked) {
      if (path.endsWith('/')) {
        items.add(_UntrackedDir(path));
        for (final child in _state.untrackedDirFiles[path] ?? const <String>[]) {
          items.add(_UntrackedChild(child, indent: true));
        }
      } else {
        items.add(_UntrackedChild(path, indent: false));
      }
    }
    return items;
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

  Future<void> _copyPath(String path) async {
    final g11n = AppGlobalizations.of(context);
    await Clipboard.setData(ClipboardData(text: path));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(g11n.gitPathCopied)));
  }

  Future<void> _openFileMenu(GitFileChange file, {required bool staged}) async {
    final g11n = AppGlobalizations.of(context);
    final deleted = file.statusCode.isNotEmpty && file.statusCode[0] == 'D';
    final actions = <FileMenuItem>[
      FileMenuItem(
        label: g11n.gitViewDiff,
        icon: Iconfont.fileText,
        onSelected: () => staged
            ? _controller.loadStagedDiff(file.path)
            : _controller.loadWorktreeDiff(file.path),
      ),
      if (staged)
        FileMenuItem(
          label: g11n.gitRevert,
          icon: Iconfont.rotateCcw,
          destructive: true,
          onSelected: () => _confirm(
            title: g11n.gitRevert,
            message: g11n.gitRevertConfirmHead(file.path),
            confirmLabel: g11n.gitRevert,
            onConfirm: () => _controller.revertFile(file.path, staged: true),
          ),
        )
      else
        FileMenuItem(
          label: deleted ? g11n.gitActionRestoreFile : g11n.gitRevert,
          icon: Iconfont.rotateCcw,
          destructive: !deleted,
          onSelected: () => _confirm(
            title: deleted ? g11n.gitActionRestoreFile : g11n.gitRevert,
            message: deleted
                ? g11n.gitRestoreFileConfirm(file.path)
                : g11n.gitRevertConfirmWorktree(file.path),
            confirmLabel: deleted ? g11n.gitActionRestoreFile : g11n.gitRevert,
            destructive: !deleted,
            onConfirm: () => _controller.revertFile(file.path),
          ),
        ),
      FileMenuItem(
        label: g11n.gitCopyPath,
        icon: Iconfont.copy,
        onSelected: () => _copyPath(file.path),
      ),
    ];
    if (!mounted) return;
    await showFileActionSheet(context, path: file.path, actions: actions);
  }

  Future<void> _openUntrackedFileMenu(String path) async {
    final g11n = AppGlobalizations.of(context);
    final slash = path.lastIndexOf('/');
    final name = slash < 0 ? path : path.substring(slash + 1);
    final dot = path.lastIndexOf('.');
    final ext = dot < 0 || dot < slash ? '' : path.substring(dot + 1);
    final actions = <FileMenuItem>[
      FileMenuItem(
        label: g11n.gitViewDiff,
        icon: Iconfont.fileText,
        onSelected: () => _controller.loadUntrackedDiff(path),
      ),
      FileMenuItem(
        label: g11n.gitIgnoreFile(name),
        icon: Iconfont.eyeOff,
        onSelected: () => _controller.addToGitignore('/$path'),
      ),
      if (ext.isNotEmpty)
        FileMenuItem(
          label: g11n.gitIgnoreExtension(ext),
          icon: Iconfont.eyeOff,
          onSelected: () => _controller.addToGitignore('*.$ext'),
        ),
      FileMenuItem(
        label: g11n.gitActionDeleteFile,
        icon: Iconfont.trash2,
        destructive: true,
        onSelected: () => _confirm(
          title: g11n.gitActionDeleteFile,
          message: g11n.gitDeleteUntrackedConfirm(path),
          confirmLabel: g11n.delete,
          onConfirm: () => _controller.deleteUntracked(path),
        ),
      ),
      FileMenuItem(
        label: g11n.gitCopyPath,
        icon: Iconfont.copy,
        onSelected: () => _copyPath(path),
      ),
    ];
    if (!mounted) return;
    await showFileActionSheet(context, path: path, actions: actions);
  }

  Future<void> _openUntrackedDirMenu(String path) async {
    final g11n = AppGlobalizations.of(context);
    final trimmed = path.endsWith('/') ? path.substring(0, path.length - 1) : path;
    final slash = trimmed.lastIndexOf('/');
    final name = slash < 0 ? trimmed : trimmed.substring(slash + 1);
    final actions = <FileMenuItem>[
      FileMenuItem(
        label: g11n.gitIgnoreDir(name),
        icon: Iconfont.eyeOff,
        onSelected: () => _controller.addToGitignore('/$trimmed/'),
      ),
      FileMenuItem(
        label: g11n.gitActionDeleteDir,
        icon: Iconfont.trash2,
        destructive: true,
        onSelected: () => _confirm(
          title: g11n.gitActionDeleteDir,
          message: g11n.gitDeleteUntrackedConfirm(path),
          confirmLabel: g11n.delete,
          onConfirm: () => _controller.deleteUntracked(path),
        ),
      ),
      FileMenuItem(
        label: g11n.gitCopyPath,
        icon: Iconfont.copy,
        onSelected: () => _copyPath(path),
      ),
    ];
    if (!mounted) return;
    await showFileActionSheet(context, path: path, actions: actions);
  }

  Future<void> _openStashSheet() async {
    final g11n = AppGlobalizations.of(context);
    _controller.loadStashes();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => StashSheet(
          stashes: _state.stashes,
          loading: _state.stashesLoading,
          hasChanges: _state.status?.hasChanges ?? false,
          busy: _state.busy,
          onSave: (message, includeUntracked) {
            _controller.stashSave(message: message, includeUntracked: includeUntracked);
            Navigator.of(sheetContext).pop();
          },
          onPop: (index) {
            _controller.stashPop(index);
            Navigator.of(sheetContext).pop();
          },
          onApply: (index) {
            _controller.stashApply(index);
            Navigator.of(sheetContext).pop();
          },
          onDrop: (index) => _confirm(
            title: g11n.gitStashDrop,
            message: g11n.gitStashDropConfirm(index),
            confirmLabel: g11n.delete,
            onConfirm: () => _controller.stashDrop(index),
          ),
          onClear: () => _confirm(
            title: g11n.gitStashClear,
            message: g11n.gitStashClearConfirm,
            confirmLabel: g11n.delete,
            onConfirm: _controller.stashClear,
          ),
        ),
      ),
    );
  }

  Future<void> _openCommitDialog() async {
    final result = await showDialog<(String, bool)>(
      context: context,
      builder: (dialogContext) => CommitDialog(
        isGenerating: _state.generatingCommitMessage,
        onGenerateAiMessage: _controller.generateCommitMessage,
      ),
    );
    if (result != null) {
      await _controller.commit(result.$1, amend: result.$2);
    }
  }

  Future<void> _confirmPull() async {
    final g11n = AppGlobalizations.of(context);
    if (_state.status?.hasChanges != true) {
      await _controller.pull();
      return;
    }
    await _confirm(
      title: g11n.gitPull,
      message: g11n.gitPullDirtyConfirm,
      confirmLabel: g11n.gitPullContinue,
      destructive: false,
      onConfirm: _controller.pull,
    );
  }

  Future<void> _push() async {
    final g11n = AppGlobalizations.of(context);
    await _controller.push(
      onPromptRenameMaster: () async {
        if (!mounted) return;
        final rename = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(g11n.gitPushMasterConfirmTitle),
            content: Text(g11n.gitPushMasterConfirmDesc),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(g11n.gitPushKeepMaster),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(g11n.gitPushRenameToMain),
              ),
            ],
          ),
        );
        if (rename ?? false) {
          await _controller.pushRenameMasterToMain();
        } else {
          await _controller.pushDirectly();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    final status = _state.status;
    final clean = status == null ||
        (status.staged.isEmpty &&
            status.unstaged.isEmpty &&
            status.untracked.isEmpty &&
            status.conflicted.isEmpty);
    final hasChanges = !clean;
    final commitEnabled = !_state.busy && (status?.staged.isNotEmpty ?? false) && _state.hasIdentity;
    final untrackedItems = _untrackedItems();

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, 70),
      children: [
        const SizedBox(height: Spacing.sm),
        _StatusOverview(status: status, clean: clean),

        // 主操作:提交。有已暂存改动且已配置署名才可用。
        Padding(
          padding: const EdgeInsets.only(top: Spacing.md),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: commitEnabled ? _openCommitDialog : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    disabledBackgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    disabledForegroundColor:
                        Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.mdLarge),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconfont.check, size: 17),
                      const SizedBox(width: Spacing.xs),
                      Flexible(
                        child: Text(
                          g11n.gitCommitChanges,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!_state.hasIdentity)
                Padding(
                  padding: const EdgeInsets.only(top: Spacing.xs),
                  child: Text(
                    g11n.gitCommitNeedsIdentity,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
            ],
          ),
        ),

        // 部署/同步（push/pull/remote）在本地执行环境中执行。
        Builder(builder: (context) {
          final theme = Theme.of(context);
          return Padding(
            padding: const EdgeInsets.only(top: Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Iconfont.hardDrive,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: Spacing.xs),
                    Expanded(
                      child: Text(
                        g11n.gitDeploySyncSection,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.xs),
                  child: Text(
                    '推送、拉取与远程操作在本地执行环境中执行',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: GitActionButton(
                        label: g11n.gitStageAll,
                        icon: Iconfont.plus,
                        enabled: !_state.busy && hasChanges,
                        onPressed: _controller.stageAll,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: GitActionButton(
                        label: g11n.gitTabStash,
                        icon: Iconfont.archive,
                        enabled: !_state.busy,
                        onPressed: _openStashSheet,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: GitActionButton(
                        label: g11n.gitPull,
                        icon: Iconfont.downloadCloud,
                        enabled: !_state.busy && _state.hasRemote,
                        onPressed: _confirmPull,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: GitActionButton(
                        label: g11n.gitPush,
                        icon: Iconfont.uploadCloud,
                        enabled: !_state.busy && _state.hasRemote,
                        onPressed: _push,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        if (status == null || clean)
          Padding(
            padding: const EdgeInsets.only(top: 96, bottom: 32),
            child: Center(
              child: Text(
                g11n.gitStatusClean,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          )
        else ...[
          if (status.conflicted.isNotEmpty) ...[
            GitSectionHeader(
              text: g11n.gitConflictedCount(status.conflicted.length),
              action: status.isMerging
                  ? TextButton(
                      onPressed: _state.busy
                          ? null
                          : () => _confirm(
                                title: g11n.gitActionAbortMerge,
                                message: g11n.gitAbortMergeConfirm,
                                confirmLabel: g11n.gitActionAbortMerge,
                                onConfirm: _controller.abortMerge,
                              ),
                      child: Text(
                        g11n.gitActionAbortMerge,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    )
                  : null,
            ),
            for (var i = 0; i < status.conflicted.length; i++)
              FileGroupRow(
                index: i,
                count: status.conflicted.length,
                child: GitFileRow(
                  file: status.conflicted[i],
                  actionIcon: Iconfont.plus,
                  actionTooltip: g11n.gitStage,
                  onAction: () => _controller.stage(status.conflicted[i].path),
                  enabled: !_state.busy,
                  onTap: () => _controller.loadWorktreeDiff(status.conflicted[i].path),
                  onLongPress: () => _openFileMenu(status.conflicted[i], staged: false),
                ),
              ),
          ] else if (status.isMerging) ...[
            const SizedBox(height: Spacing.md),
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: context.semantic.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Radii.mdLarge),
                border: Border.all(color: context.semantic.warning.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g11n.gitMergePendingTitle,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: context.semantic.warning,
                              ),
                        ),
                        Text(
                          g11n.gitMergePendingHint,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _state.busy
                        ? null
                        : () => _confirm(
                              title: g11n.gitActionAbortMerge,
                              message: g11n.gitAbortMergeConfirm,
                              confirmLabel: g11n.gitActionAbortMerge,
                              onConfirm: _controller.abortMerge,
                            ),
                    child: Text(
                      g11n.gitActionAbortMerge,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (status.staged.isNotEmpty) ...[
            GitSectionHeader(
              text: g11n.gitStagedCount(status.staged.length),
              action: TextButton(
                onPressed: _state.busy
                    ? null
                    : () => _confirm(
                          title: g11n.gitUnstageAll,
                          message: g11n.gitUnstageAllConfirm,
                          confirmLabel: g11n.gitUnstageAll,
                          destructive: false,
                          onConfirm: _controller.unstageAll,
                        ),
                child: Text(
                  g11n.gitUnstageAll,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
            for (var i = 0; i < status.staged.length; i++)
              FileGroupRow(
                index: i,
                count: status.staged.length,
                child: GitFileRow(
                  file: status.staged[i],
                  actionIcon: Iconfont.minus,
                  actionTooltip: g11n.gitUnstage,
                  onAction: () => _controller.unstage(status.staged[i].path),
                  enabled: !_state.busy,
                  onTap: () => _controller.loadStagedDiff(status.staged[i].path),
                  onLongPress: () => _openFileMenu(status.staged[i], staged: true),
                ),
              ),
          ],
          if (status.unstaged.isNotEmpty) ...[
            GitSectionHeader(
              text: g11n.gitModifiedCount(status.unstaged.length),
              action: TextButton(
                onPressed: _state.busy
                    ? null
                    : () => _confirm(
                          title: g11n.gitActionRevertAll,
                          message: g11n.gitRevertAllConfirm(status.unstaged.length),
                          confirmLabel: g11n.gitActionRevertAll,
                          onConfirm: _controller.revertAllUnstaged,
                        ),
                child: Text(
                  g11n.gitActionRevertAll,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
            for (var i = 0; i < status.unstaged.length; i++)
              FileGroupRow(
                index: i,
                count: status.unstaged.length,
                child: GitFileRow(
                  file: status.unstaged[i],
                  actionIcon: Iconfont.plus,
                  actionTooltip: g11n.gitStage,
                  onAction: () => _controller.stage(status.unstaged[i].path),
                  enabled: !_state.busy,
                  onTap: () => _controller.loadWorktreeDiff(status.unstaged[i].path),
                  onLongPress: () => _openFileMenu(status.unstaged[i], staged: false),
                ),
              ),
          ],
          if (status.untracked.isNotEmpty) ...[
            GitSectionHeader(text: g11n.gitUntrackedCount(status.untracked.length)),
            for (var i = 0; i < untrackedItems.length; i++)
              FileGroupRow(
                index: i,
                count: untrackedItems.length,
                child: switch (untrackedItems[i]) {
                  _UntrackedDir(:final path) => UntrackedDirRow(
                      path: path,
                      childCount: _state.untrackedDirFiles[path]?.length,
                      expanded: _state.untrackedDirFiles.containsKey(path),
                      loading: _state.untrackedDirLoading == path,
                      enabled: !_state.busy,
                      onTap: () => _controller.toggleUntrackedDir(path),
                      onLongPress: () => _openUntrackedDirMenu(path),
                      onStage: () => _controller.stage(path),
                      stageTooltip: g11n.gitStage,
                    ),
                  _UntrackedChild(:final path, :final indent) => GitFileRow(
                      file: GitFileChange(path: path, statusCode: '?', staged: false),
                      actionIcon: Iconfont.plus,
                      actionTooltip: g11n.gitStage,
                      onAction: () => _controller.stage(path),
                      enabled: !_state.busy,
                      indent: indent ? Spacing.lg : 0,
                      onTap: () => _controller.loadUntrackedDiff(path),
                      onLongPress: () => _openUntrackedFileMenu(path),
                    ),
                },
              ),
          ],
        ],
      ],
    );
  }
}

/// 状态页未跟踪分组的展平项:目录行,或(展开目录后的)子文件行。
sealed class _UntrackedItem {
  const _UntrackedItem(this.path);

  final String path;
}

class _UntrackedDir extends _UntrackedItem {
  const _UntrackedDir(super.path);
}

class _UntrackedChild extends _UntrackedItem {
  const _UntrackedChild(super.path, {required this.indent});

  final bool indent;
}

/// 概览卡:分支/上游/分离头指针 + 领先落后胶囊 + 四格统计。
class _StatusOverview extends StatelessWidget {
  const _StatusOverview({required this.status, required this.clean});

  final GitStatus? status;
  final bool clean;

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    final theme = Theme.of(context);
    final staged = status?.staged.length ?? 0;
    final modified = status?.unstaged.length ?? 0;
    final untracked = status?.untracked.length ?? 0;
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
                      clean ? g11n.gitClean : g11n.gitHasChanges,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      status?.branch ?? g11n.gitNoBranch,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontFamily: 'monospace'),
                    ),
                    if (status?.isDetached == true)
                      Text(
                        g11n.gitDetachedHeadLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      )
                    else if (status?.upstream != null)
                      Text(
                        g11n.gitTrackingBranch(status!.upstream!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else if (status != null)
                      Text(
                        g11n.gitNoUpstream,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (status != null && (status!.ahead > 0 || status!.behind > 0)) ...[
                const SizedBox(width: Spacing.sm),
                _SyncPill(ahead: status!.ahead, behind: status!.behind),
              ],
            ],
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              if (status != null && status!.conflicted.isNotEmpty) ...[
                Expanded(
                  child: StatusMetric(
                    label: g11n.gitConflictedLabel,
                    count: status!.conflicted.length,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
              ],
              Expanded(
                child: StatusMetric(
                  label: g11n.gitStagedLabel,
                  count: staged,
                  color: context.semantic.success,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: StatusMetric(
                  label: g11n.gitModifiedLabel,
                  count: modified,
                  color: context.semantic.warning,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: StatusMetric(
                  label: g11n.gitUntrackedLabel,
                  count: untracked,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 领先/落后远程的同步状态胶囊。
class _SyncPill extends StatelessWidget {
  const _SyncPill({required this.ahead, required this.behind});

  final int ahead;
  final int behind;

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    final text = [
      if (ahead > 0) g11n.gitAheadCount(ahead),
      if (behind > 0) g11n.gitBehindCount(behind),
    ].join('  ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
      decoration: BoxDecoration(
        color: context.semantic.mutedSurface,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontFamily: 'monospace',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}