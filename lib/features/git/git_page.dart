import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/floating_tab_bar.dart';
import '../../core/util/window_size.dart';
import '../../data/editor_target.dart';
import '../../data/git_controller.dart';
import '../../data/workbench.dart';
import '../../l10n/app_localizations.dart';
import 'diff_viewer.dart';
import 'git_branches_tab.dart';
import 'git_log_tab.dart';
import 'git_status_tab.dart';
import 'widgets/git_sheets.dart';

/// Git 页(对齐上游 `GitScreen`):顶栏 + 三 Tab 分页 + 底部悬浮标签栏。
///
/// [embedded] 为 true 时用于工作台右栏:返回按钮换成关闭图标。
class GitPage extends ConsumerStatefulWidget {
  const GitPage({
    super.key,
    this.embedded = false,
    this.onNavigateBack,
    this.onNavigateToCredentials,
    this.onOpenFile,
  });

  final bool embedded;
  final VoidCallback? onNavigateBack;
  final VoidCallback? onNavigateToCredentials;
  final void Function(String path)? onOpenFile;

  @override
  ConsumerState<GitPage> createState() => _GitPageState();
}

class _GitPageState extends ConsumerState<GitPage> {
  final _pageController = PageController();
  final _logScrollController = ScrollController();
  int _page = 0;
  String? _lastToast;
  bool _repoPickerOpen = false;

  @override
  void dispose() {
    _pageController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  /// 仓库选择弹层:控制器置位后弹出,关闭时复位。
  void _syncRepoPicker(GitUiState state) {
    if (state.repoPickerVisible == _repoPickerOpen) return;
    _repoPickerOpen = state.repoPickerVisible;
    if (!state.repoPickerVisible) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final controller = ref.read(gitControllerProvider.notifier);
      final current = ref.read(gitControllerProvider);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => RepoPickerSheet(
          workspaceRoot: current.workspaceRoot,
          subdirs: current.subdirs,
          repos: current.repos,
          currentRepo: current.repoPath,
          onSelect: (path) {
            Navigator.of(sheetContext).pop();
            controller.switchRepo(path);
          },
        ),
      );
      controller.hideRepoPicker();
      _repoPickerOpen = false;
    });
  }

  /// toast → SnackBar 一次性消费。
  void _consumeToast(GitUiState state) {
    final toast = state.toast;
    if (toast == null || toast == _lastToast) return;
    _lastToast = toast;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toast)));
      ref.read(gitControllerProvider.notifier).consumeToast();
      _lastToast = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(gitControllerProvider);
    final controller = ref.read(gitControllerProvider.notifier);
    _consumeToast(state);
    _syncRepoPicker(state);

    // 差异页:独立全屏,避免双层顶栏。
    if (state.diffVisible) {
      return DiffViewerScreen(
        diffData: state.diffData,
        filePath: state.diffPath,
        onBack: controller.clearDiff,
        onOpenInEditor: widget.onOpenFile ?? _openInEditor,
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.gitTitle),
            if (state.repoPath != null)
              InkWell(
                onTap: controller.showRepoPicker,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _repoDisplayName(state.repoPath!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    Icon(
                      Iconfont.chevronDown,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            _ExecutionEnvSubtitle(),
          ],
        ),
        leading: IconButton(
          onPressed: widget.onNavigateBack ?? () => Navigator.of(context).maybePop(),
          tooltip: widget.embedded ? l10n.close : l10n.back,
          icon: Icon(widget.embedded ? Iconfont.x : Iconfont.arrowLeft),
        ),
        actions: [
          if (widget.onNavigateToCredentials != null)
            IconButton(
              onPressed: widget.onNavigateToCredentials,
              tooltip: l10n.gitCredentialsAndIdentity,
              icon: const Icon(Iconfont.key),
            ),
          IconButton(
            onPressed: state.busy ? null : controller.refresh,
            tooltip: l10n.gitRefresh,
            icon: const Icon(Iconfont.refreshCw),
          ),
        ],
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
        child: switch (state) {
        _ when state.loading => const Center(child: CircularProgressIndicator()),
        _ when state.notARepo => _NotARepoState(controller: controller, busy: state.busy),
        _ => Stack(
            children: [
              PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  GitStatusTab(state: state, controller: controller),
                  GitBranchesTab(state: state, controller: controller),
                  GitLogTab(
                    state: state,
                    controller: controller,
                    scrollController: _logScrollController,
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: FloatingTabBar(
                  controller: _pageController,
                  page: _page,
                  items: [
                    FloatingTabItem(icon: Iconfont.activity, label: l10n.gitTabStatus),
                    FloatingTabItem(icon: Iconfont.gitBranch, label: l10n.gitTabBranches),
                    FloatingTabItem(icon: Iconfont.gitCommit, label: l10n.gitTabCommits),
                  ],
                  maskColor: context.semantic.pageBackground,
                  onSelect: (index) => _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
            ],
          ),
      },
      ),
    );
  }

  /// 差异页的「在编辑器中打开」:记下目标后按宽窄屏分流(工作台右栏 / 整屏路由)。
  void _openInEditor(String path) {
    ref.read(editorTargetProvider.notifier).open(path);
    openWorkbench(context, ref, WorkbenchPaneKind.editor, isWideLayout(context));
  }

  /// 仓库路径 → 显示名(最后一段路径)。
  String _repoDisplayName(String path) {
    final trimmed = path.endsWith('/') ? path.substring(0, path.length - 1) : path;
    final slash = trimmed.lastIndexOf('/');
    final name = slash < 0 ? trimmed : trimmed.substring(trimmed.lastIndexOf('/') + 1);
    return name.isEmpty ? path : name;
  }
}

/// 非仓库态:文案 + 「初始化 Git 仓库」/「克隆远程仓库」/「选择已有仓库」按钮。
class _NotARepoState extends StatelessWidget {
  const _NotARepoState({required this.controller, required this.busy});

  final GitController controller;
  final bool busy;

  Future<void> _clone(BuildContext context) async {
    final url = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const CloneRepoDialog(),
    );
    if (url != null) await controller.cloneRepo(url);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final subtle = theme.colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.gitNotARepo, style: theme.textTheme.bodyMedium?.copyWith(color: subtle)),
            const SizedBox(height: Spacing.md),
            Text(
              l10n.gitInitDescPrimary,
              style: theme.textTheme.bodySmall?.copyWith(color: subtle),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              l10n.gitInitDescSecondary,
              style: theme.textTheme.bodySmall?.copyWith(color: subtle),
            ),
            if (busy) ...[
              const SizedBox(height: Spacing.sm),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                l10n.gitCloningHint,
                style: theme.textTheme.bodySmall?.copyWith(color: subtle),
              ),
            ] else ...[
              const SizedBox(height: Spacing.md),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.tonal(
                    onPressed: controller.initRepo,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconfont.gitBranch, size: 18),
                        const SizedBox(width: Spacing.xs),
                        Text(l10n.gitInitRepo),
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  FilledButton.tonal(
                    onPressed: () => _clone(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconfont.download, size: 18),
                        const SizedBox(width: Spacing.xs),
                        Text(l10n.gitCloneRepo),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              OutlinedButton(
                onPressed: controller.showRepoPicker,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconfont.folder, size: 18),
                    const SizedBox(width: Spacing.xs),
                    Text(l10n.gitPickExistingRepo),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExecutionEnvSubtitle extends StatelessWidget {
  const _ExecutionEnvSubtitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconfont.hardDrive,
            size: 12,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '本地执行环境',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
