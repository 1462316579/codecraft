import 'dart:async';
import 'dart:ui' show Brightness, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/commit_message_generator.dart';
import '../agent/models/git_models.dart';
import '../l10n/app_localizations.dart';
import 'git/container_git.dart';
import 'git/diff_data.dart';
import 'git/git_error_message.dart';
import 'git/git_graph_models.dart';
import 'git/git_runner.dart';
import 'settings/app_settings.dart';
import 'workspaces.dart';

/// Git 页的 UI 状态(对齐上游 `GitViewModel.GitUiState`)。
class GitUiState {
  const GitUiState({
    this.loading = true,
    this.notARepo = false,
    this.busy = false,
    this.repoPath,
    this.workspaceRoot = '',
    this.repos = const [],
    this.subdirs = const [],
    this.status,
    this.branches = const [],
    this.branchesLoading = false,
    this.branchesLoaded = false,
    this.tags = const [],
    this.log = const [],
    this.graph = GitGraph.empty,
    this.graphLoadingMore = false,
    this.repoPickerVisible = false,
    this.checkoutLoading,
    this.commitDetailHash,
    this.commitFiles = const {},
    this.loadingCommit,
    this.diffVisible = false,
    this.diffData,
    this.diffPath,
    this.toast,
    this.hasIdentity = false,
    this.hasRemote = false,
    this.untrackedDirFiles = const {},
    this.untrackedDirLoading,
    this.stashes = const [],
    this.stashesLoading = false,
    this.generatingCommitMessage = false,
  });

  final bool loading;

  /// 工作区里没有找到任何 Git 仓库(且不在加载中)。
  final bool notARepo;

  final bool busy;

  /// 当前仓库绝对路径;null 表示未选中。
  final String? repoPath;
  final String workspaceRoot;

  /// 工作区里发现的仓库(根 + 一层子目录)。
  final List<String> repos;

  /// 工作区根的一层直接子目录(仓库选择弹窗展示扫描范围)。
  final List<String> subdirs;

  final GitStatus? status;
  final List<GitBranch> branches;
  final bool branchesLoading;

  /// 是否已至少加载过一次分支(区分「首次加载」与「确实没有分支」)。
  final bool branchesLoaded;
  final List<GitTag> tags;
  final List<GitCommit> log;

  /// 提交拓扑图(提交页的泳道连线、引用胶囊与卡片分组都靠它)。
  final GitGraph graph;

  /// 是否正在分页加载更早的提交(不置 busy,不挡写操作)。
  final bool graphLoadingMore;

  /// 仓库选择弹层是否可见。
  final bool repoPickerVisible;

  /// 正在切换的引用(分支名),供行内转圈。
  final String? checkoutLoading;

  /// 提交详情弹层的提交哈希;null 表示未打开。
  final String? commitDetailHash;

  /// 各提交的改动文件缓存(按 hash)。
  final Map<String, List<GitFileChange>> commitFiles;

  /// 正在加载改动文件的提交哈希。
  final String? loadingCommit;

  /// 差异页是否可见。
  final bool diffVisible;

  /// 差异数据(由文件内容 + 行差异 + 高亮算出,见 [DiffPipeline])。
  final DiffData? diffData;
  final String? diffPath;

  final String? toast;

  /// 仓库里是否配了提交署名(user.name 非空)。未配置时禁止提交。
  final bool hasIdentity;

  /// 仓库是否配置了 remote(供拉取/推送按钮启用)。
  final bool hasRemote;

  /// 已展开的未跟踪目录 → 其中的未跟踪文件(键为 `dir/`)。
  final Map<String, List<String>> untrackedDirFiles;
  final String? untrackedDirLoading;

  final List<GitStash> stashes;
  final bool stashesLoading;

  /// 正在生成提交信息。
  final bool generatingCommitMessage;

  GitUiState copyWith({
    bool? loading,
    bool? notARepo,
    bool? busy,
    String? Function()? repoPath,
    String? workspaceRoot,
    List<String>? repos,
    List<String>? subdirs,
    GitStatus? Function()? status,
    List<GitBranch>? branches,
    bool? branchesLoading,
    bool? branchesLoaded,
    List<GitTag>? tags,
    List<GitCommit>? log,
    GitGraph? graph,
    bool? graphLoadingMore,
    bool? repoPickerVisible,
    String? Function()? checkoutLoading,
    String? Function()? commitDetailHash,
    Map<String, List<GitFileChange>>? commitFiles,
    String? Function()? loadingCommit,
    bool? diffVisible,
    DiffData? Function()? diffData,
    String? Function()? diffPath,
    String? Function()? toast,
    bool? hasIdentity,
    bool? hasRemote,
    Map<String, List<String>>? untrackedDirFiles,
    String? Function()? untrackedDirLoading,
    List<GitStash>? stashes,
    bool? stashesLoading,
    bool? generatingCommitMessage,
  }) =>
      GitUiState(
        loading: loading ?? this.loading,
        notARepo: notARepo ?? this.notARepo,
        busy: busy ?? this.busy,
        repoPath: repoPath == null ? this.repoPath : repoPath(),
        workspaceRoot: workspaceRoot ?? this.workspaceRoot,
        repos: repos ?? this.repos,
        subdirs: subdirs ?? this.subdirs,
        status: status == null ? this.status : status(),
        branches: branches ?? this.branches,
        branchesLoading: branchesLoading ?? this.branchesLoading,
        branchesLoaded: branchesLoaded ?? this.branchesLoaded,
        tags: tags ?? this.tags,
        log: log ?? this.log,
        graph: graph ?? this.graph,
        graphLoadingMore: graphLoadingMore ?? this.graphLoadingMore,
        repoPickerVisible: repoPickerVisible ?? this.repoPickerVisible,
        checkoutLoading: checkoutLoading == null ? this.checkoutLoading : checkoutLoading(),
        commitDetailHash:
            commitDetailHash == null ? this.commitDetailHash : commitDetailHash(),
        commitFiles: commitFiles ?? this.commitFiles,
        loadingCommit: loadingCommit == null ? this.loadingCommit : loadingCommit(),
        diffVisible: diffVisible ?? this.diffVisible,
        diffData: diffData == null ? this.diffData : diffData(),
        diffPath: diffPath == null ? this.diffPath : diffPath(),
        toast: toast == null ? this.toast : toast(),
        hasIdentity: hasIdentity ?? this.hasIdentity,
        hasRemote: hasRemote ?? this.hasRemote,
        untrackedDirFiles: untrackedDirFiles ?? this.untrackedDirFiles,
        untrackedDirLoading:
            untrackedDirLoading == null ? this.untrackedDirLoading : untrackedDirLoading(),
        stashes: stashes ?? this.stashes,
        stashesLoading: stashesLoading ?? this.stashesLoading,
        generatingCommitMessage: generatingCommitMessage ?? this.generatingCommitMessage,
      );
}

/// 一次仓库快照:并发拉取 status/graph/remote(+可选 identity)的结果。
class _RepoSnapshot {
  const _RepoSnapshot({
    required this.status,
    required this.graph,
    required this.hasRemote,
    this.hasIdentity = false,
    this.untrackedDirFiles = const {},
  });

  final GitStatus status;
  final GitGraph graph;
  final bool hasRemote;
  final bool hasIdentity;
  final Map<String, List<String>> untrackedDirFiles;
}

/// Git 页编排(对齐上游 GitViewModel):刷新、仓库切换、暂存/提交/分支/远端等操作。
///
/// 每个写操作执行后自动刷新并通过 [GitUiState.toast] 反馈;[GitUiState.busy] 守卫防止
/// 并发写操作相互踩踏。读操作(分支/提交分页/差异/提交详情)不置 busy。
class GitController extends StateNotifier<GitUiState> {
  GitController(this._ref)
      : super(GitUiState(workspaceRoot: _ref.read(currentWorkspaceProvider).rootPath)) {
    refresh();
  }

  final Ref _ref;

  /// 提交页每页拉取的提交条数(与 [GitRunner.graphPageSize] 一致)。
  static const int pageSize = GitRunner.graphPageSize;

  ContainerGit get _cgit => _ref.read(containerGitProvider);

  String get _root => _ref.read(currentWorkspaceProvider).rootPath;

  /// 刷新:先确认容器就绪,再发现仓库并并发拉取快照,最后后台加载全量分支。
  Future<void> refresh() async {
    if (state.busy) return;
    final hint = await _cgit.notReadyHint();
    if (hint != null) {
      state = state.copyWith(loading: false, toast: () => hint);
      return;
    }
    state = state.copyWith(loading: true, toast: () => null);
    final l10n = _ref.read(appLocalizationsProvider);
    try {
      final root = _root;
      final repos = await _cgit.discoverRepos(root).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('发现 Git 仓库超时'),
      );
      final subdirs = _cgit.listSubdirectories(root);
      final current = state.repoPath;
      final repoPath = current != null && repos.contains(current)
          ? current
          : (repos.isEmpty ? null : repos.first);

      if (repoPath == null) {
        state = state.copyWith(
          loading: false,
          notARepo: true,
          repoPath: () => null,
          repos: repos,
          subdirs: subdirs,
          workspaceRoot: root,
          status: () => null,
        );
        return;
      }

      final snapshot = await _loadSnapshot(repoPath, includeIdentity: true).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('加载 Git 状态超时'),
      );
      state = state.copyWith(
        loading: false,
        notARepo: false,
        repoPath: () => repoPath,
        repos: repos,
        subdirs: subdirs,
        workspaceRoot: root,
        status: () => snapshot.status,
        log: _commitsOf(snapshot.graph),
        graph: snapshot.graph,
        hasRemote: snapshot.hasRemote,
        hasIdentity: snapshot.hasIdentity,
        untrackedDirFiles: snapshot.untrackedDirFiles,
        // 切仓库/刷新后分支需重新拉取。
        branchesLoaded: false,
        branchesLoading: false,
        branches: const [],
        tags: const [],
      );
      loadBranches();
    } on GitException catch (error) {
      state = state.copyWith(
        loading: false,
        toast: () => l10n.gitToastRefreshFailed(GitErrorMessage.friendly(error.message)),
      );
    }
  }

  /// 并发拉取轻量快照:status + graph(本地 refs) + remote + 可选 identity。
  Future<_RepoSnapshot> _loadSnapshot(String repoPath, {required bool includeIdentity}) async {
    final localRefs = await _cgit.localRefsOnly(repoPath);
    final results = await Future.wait([
      _cgit.status(repoPath),
      _cgit.graph(repoPath, refs: localRefs),
      _cgit.hasRemote(repoPath),
      if (includeIdentity) _hasIdentity(repoPath) else Future.value(false),
    ]);
    final status = results[0] as GitStatus;
    return _RepoSnapshot(
      status: status,
      graph: results[1] as GitGraph,
      hasRemote: results[2] as bool,
      hasIdentity: includeIdentity && results[3] as bool,
      untrackedDirFiles: await _reloadExpandedUntrackedDirs(repoPath, status),
    );
  }

  /// 刷新后重查已展开的未跟踪目录,保住展开态;已不在未跟踪列表里的目录丢掉。
  Future<Map<String, List<String>>> _reloadExpandedUntrackedDirs(
    String repoPath,
    GitStatus status,
  ) async {
    final dirs = state.untrackedDirFiles.keys.where(status.untracked.contains).toList();
    if (dirs.isEmpty) return const {};
    final result = <String, List<String>>{};
    for (final dir in dirs) {
      try {
        result[dir] = await _cgit.untrackedFilesIn(repoPath, dir);
      } catch (_) {
        // 单个目录读失败就丢弃它的展开态。
      }
    }
    return result;
  }

  List<GitCommit> _commitsOf(GitGraph graph) => graph.commits
      .map((commit) => GitCommit(
            hash: commit.hash,
            author: commit.author,
            date: commit.date,
            message: commit.message,
            parents: commit.parents,
            body: commit.body,
          ))
      .toList();

  /// 加载全量分支/标签(refresh 成功后即触发);已加载过则跳过。
  Future<void> loadBranches() async {
    if (state.branchesLoading || state.branchesLoaded) return;
    final repoPath = state.repoPath;
    if (repoPath == null) return;
    state = state.copyWith(branchesLoading: true);
    final l10n = _ref.read(appLocalizationsProvider);
    try {
      final allRefs = await _cgit.loadAllRefs(repoPath);
      final graph = await _cgit.graphAppend(
        repoPath,
        existingCommits: state.graph.commits,
        refs: allRefs.refsByCommit,
      );
      state = state.copyWith(
        branches: allRefs.branches,
        tags: allRefs.tags,
        graph: graph,
        log: _commitsOf(graph),
        branchesLoading: false,
        branchesLoaded: true,
      );
    } on GitException catch (error) {
      state = state.copyWith(
        branchesLoading: false,
        toast: () => l10n.gitToastLoadBranchesFailed(GitErrorMessage.friendly(error.message)),
      );
    }
  }

  /// 写操作后同步刷新已加载的分支/标签;未加载过则不主动拉。
  Future<void> _refreshBranchesIfLoaded() async {
    if (!state.branchesLoaded) return;
    final repoPath = state.repoPath;
    if (repoPath == null) return;
    try {
      final allRefs = await _cgit.loadAllRefs(repoPath);
      state = state.copyWith(branches: allRefs.branches, tags: allRefs.tags);
    } catch (_) {
      // 刷新分支失败不打扰用户:下一次 refresh 会纠正。
    }
  }

  /// 分页加载更旧的提交(滚动到底触发)。不置 busy。
  Future<void> loadMoreCommits() async {
    final repoPath = state.repoPath;
    if (repoPath == null || state.graphLoadingMore || !state.graph.hasMore) return;
    state = state.copyWith(graphLoadingMore: true);
    final l10n = _ref.read(appLocalizationsProvider);
    try {
      final graph = await _cgit.graphAppend(
        repoPath,
        existingCommits: state.graph.commits,
        refs: state.graph.refs,
      );
      state = state.copyWith(
        graph: graph,
        log: _commitsOf(graph),
        graphLoadingMore: false,
      );
    } on GitException catch (error) {
      state = state.copyWith(
        graphLoadingMore: false,
        toast: () => l10n.gitToastLoadMoreFailed(GitErrorMessage.friendly(error.message)),
      );
    }
  }

  void showRepoPicker() => state = state.copyWith(repoPickerVisible: true);

  void hideRepoPicker() => state = state.copyWith(repoPickerVisible: false);

  /// 切换到指定仓库:先校验目标确实是仓库,通过后设置并刷新。
  Future<void> switchRepo(String path) async {
    if (state.busy) return;
    state = state.copyWith(repoPickerVisible: false);
    final l10n = _ref.read(appLocalizationsProvider);
    try {
      if (!await _cgit.isRepository(path)) {
        state = state.copyWith(toast: () => l10n.gitToastNotRepo);
        return;
      }
      state = state.copyWith(repoPath: () => path);
      await refresh();
    } on GitException catch (error) {
      state = state.copyWith(
        toast: () => l10n.gitToastSwitchRepoFailed(GitErrorMessage.friendly(error.message)),
      );
    }
  }

  // ── 仓库操作 ──

  Future<void> initRepo() => _runAction(
        (l10n) => l10n.gitActionInit,
        () => _cgit.init(_root),
      );

  Future<void> cloneRepo(String url) => _runAction(
        (l10n) => l10n.gitActionClone,
        () => _cgit.clone(_root, url),
      );

  // ── 状态页操作 ──

  Future<void> stage(String path) =>
      _repoAction((l10n) => l10n.gitStage, (repo) => _cgit.stage(repo, path));

  Future<void> unstage(String path) =>
      _repoAction((l10n) => l10n.gitUnstage, (repo) => _cgit.unstage(repo, path));

  Future<void> stageAll() =>
      _repoAction((l10n) => l10n.gitActionStageAll, (repo) => _cgit.stageAll(repo));

  Future<void> unstageAll() =>
      _repoAction((l10n) => l10n.gitUnstageAll, (repo) => _cgit.unstageAll(repo));

  /// 回退单个文件的改动。[staged] 为 true 时连已暂存内容一起还原到上次提交,
  /// 否则只回退未暂存改动(被删除的文件由此取回)。
  Future<void> revertFile(String path, {bool staged = false}) => _repoAction(
        (l10n) => l10n.gitRevert,
        (repo) => staged
            ? _cgit.revertToHead(repo, path)
            : _cgit.revertWorktree(repo, path),
      );

  Future<void> revertAllUnstaged() => _repoAction(
        (l10n) => l10n.gitActionRevertAll,
        (repo) => _cgit.revertAllWorktree(repo),
      );

  Future<void> deleteUntracked(String path) => _repoAction(
        (l10n) => path.endsWith('/') ? l10n.gitActionDeleteDir : l10n.gitActionDeleteFile,
        (repo) => _cgit.deleteUntracked(repo, path),
      );

  Future<void> addToGitignore(String pattern) => _repoAction(
        (l10n) => l10n.gitAddToGitignore,
        (repo) => _cgit.addToGitignore(repo, pattern),
      );

  /// 展开/收起未跟踪目录(`git status` 把它折叠成 `dir/` 一行)。只读查询,不置 busy。
  Future<void> toggleUntrackedDir(String dir) async {
    if (state.untrackedDirFiles.containsKey(dir)) {
      state = state.copyWith(
        untrackedDirFiles:
            Map<String, List<String>>.from(state.untrackedDirFiles)..remove(dir),
      );
      return;
    }
    final repoPath = state.repoPath;
    if (repoPath == null || state.untrackedDirLoading != null) return;
    state = state.copyWith(untrackedDirLoading: () => dir);
    try {
      final files = await _cgit.untrackedFilesIn(repoPath, dir);
      state = state.copyWith(
        untrackedDirFiles: {...state.untrackedDirFiles, dir: files},
        untrackedDirLoading: () => null,
      );
    } on GitException catch (error) {
      state = state.copyWith(
        untrackedDirLoading: () => null,
        toast: () => GitErrorMessage.friendly(error.message),
      );
    }
  }

  Future<void> commit(String message, {bool amend = false}) => _repoAction(
        (l10n) => l10n.gitActionCommit,
        (repo) => _cgit.commit(repo, message, amend: amend),
      );

  /// 调用 AI 依据暂存差异生成提交信息;成功后回调结果供对话框填入。
  Future<void> generateCommitMessage(void Function(String) onResult) async {
    if (state.generatingCommitMessage) return;
    final repoPath = state.repoPath;
    if (repoPath == null) return;
    final l10n = _ref.read(appLocalizationsProvider);
    state = state.copyWith(generatingCommitMessage: true);
    try {
      final diff = await _cgit.diffForCommitMessage(repoPath);
      if (diff.trim().isEmpty) {
        state = state.copyWith(
          generatingCommitMessage: false,
          toast: () => l10n.gitToastNoDiffForCommit,
        );
        return;
      }
      final message = await _ref.read(commitMessageGeneratorProvider).generate(diff);
      state = state.copyWith(generatingCommitMessage: false);
      if (message != null && message.trim().isNotEmpty) {
        onResult(message);
      } else {
        state = state.copyWith(toast: () => l10n.gitToastGenerateCommitFailed);
      }
    } catch (_) {
      state = state.copyWith(
        generatingCommitMessage: false,
        toast: () => l10n.gitToastGenerateCommitFailed,
      );
    }
  }

  // ── 储藏 ──

  Future<void> loadStashes() async {
    final repoPath = state.repoPath;
    if (repoPath == null) return;
    state = state.copyWith(stashesLoading: true);
    try {
      final stashes = await _cgit.stashList(repoPath);
      state = state.copyWith(stashes: stashes, stashesLoading: false);
    } catch (_) {
      state = state.copyWith(stashes: const [], stashesLoading: false);
    }
  }

  Future<void> stashSave({String? message, bool includeUntracked = false}) =>
      _repoAction(
        (l10n) => l10n.gitActionStash,
        (repo) => _cgit.stashSave(repo, message: message, includeUntracked: includeUntracked),
        onDone: loadStashes,
      );

  Future<void> stashPop(String index) => _repoAction(
        (l10n) => l10n.gitStashPop,
        (repo) => _cgit.stashPop(repo, index: index),
        onDone: loadStashes,
      );

  Future<void> stashApply(String index) => _repoAction(
        (l10n) => l10n.gitStashApply,
        (repo) => _cgit.stashApply(repo, index: index),
        onDone: loadStashes,
      );

  Future<void> stashDrop(String index) => _repoAction(
        (l10n) => l10n.gitStashDrop,
        (repo) => _cgit.stashDrop(repo, index: index),
        onDone: loadStashes,
      );

  Future<void> stashClear() => _repoAction(
        (l10n) => l10n.gitStashClear,
        (repo) => _cgit.stashClear(repo),
        onDone: loadStashes,
      );

  // ── 差异(对齐上游 loadWorktreeDiff / loadStagedDiff / loadUntrackedDiff / loadCommitFileDiff)──

  /// 工作区改动:`HEAD:<path>` ↔ 工作区内容。
  Future<void> loadWorktreeDiff(String path) => _loadDiff(
        path,
        oldRef: 'HEAD',
        newRef: DiffPipeline.refWorktree,
        oldContent: (repo) => _cgit.showFileContent(repo, 'HEAD', path),
        newContent: (repo) => _cgit.worktreeFileContent(repo, path),
      );

  /// 已暂存改动:`HEAD:<path>` ↔ 暂存区内容。
  Future<void> loadStagedDiff(String path) => _loadDiff(
        path,
        oldRef: 'HEAD',
        newRef: DiffPipeline.refIndex,
        oldContent: (repo) => _cgit.showFileContent(repo, 'HEAD', path),
        newContent: (repo) => _cgit.indexFileContent(repo, path),
      );

  /// 未跟踪文件:空 ↔ 工作区内容(整份算新增)。
  Future<void> loadUntrackedDiff(String path) => _loadDiff(
        path,
        oldRef: DiffPipeline.refEmpty,
        newRef: DiffPipeline.refWorktree,
        oldContent: (repo) async => '',
        newContent: (repo) => _cgit.worktreeFileContent(repo, path),
      );

  /// 提交内单文件:`<hash>^:<path>` ↔ `<hash>:<path>`。
  Future<void> loadCommitFileDiff(String hash, String path) => _loadDiff(
        path,
        oldRef: '$hash^',
        newRef: hash,
        oldContent: (repo) => _cgit.showFileContent(repo, '$hash^', path),
        newContent: (repo) => _cgit.showFileContent(repo, hash, path),
      );

  Future<void> _loadDiff(
    String path, {
    required String oldRef,
    required String newRef,
    required Future<String> Function(String repoPath) oldContent,
    required Future<String> Function(String repoPath) newContent,
  }) async {
    final repoPath = state.repoPath;
    if (repoPath == null) return;
    // 已有差异页打开时忽略重复请求(对齐上游 openDiff)。
    if (state.diffVisible) return;
    state = state.copyWith(
      diffVisible: true,
      diffPath: () => path,
      diffData: () => null,
    );
    final l10n = _ref.read(appLocalizationsProvider);
    final dark = _isDarkTheme();
    try {
      final old = await oldContent(repoPath);
      final current = await newContent(repoPath);
      state = state.copyWith(
        diffData: () => DiffPipeline.build(
          path: path,
          oldRef: oldRef,
          newRef: newRef,
          oldContent: old,
          newContent: current,
          dark: dark,
        ),
      );
    } on GitOutputTooLargeException {
      state = state.copyWith(
        diffData: () => DiffData(
          filePath: path,
          oldRef: oldRef,
          newRef: newRef,
          isLarge: true,
        ),
      );
    } on GitException {
      state = state.copyWith(
        diffVisible: false,
        diffData: () => null,
        toast: () => l10n.gitToastDiffFailed,
      );
    }
  }

  void clearDiff() => state = state.copyWith(
        diffVisible: false,
        diffData: () => null,
        diffPath: () => null,
      );

  // ── 提交详情 ──

  Future<void> openCommitDetail(String hash) async {
    if (state.commitDetailHash == hash) return;
    state = state.copyWith(commitDetailHash: () => hash);
    if (state.commitFiles.containsKey(hash)) return;
    final repoPath = state.repoPath;
    if (repoPath == null) return;
    state = state.copyWith(loadingCommit: () => hash);
    try {
      final files = await _cgit.commitFiles(repoPath, hash);
      state = state.copyWith(
        commitFiles: {...state.commitFiles, hash: files},
        loadingCommit: () => null,
      );
    } on GitException {
      state = state.copyWith(
        commitFiles: {...state.commitFiles, hash: const []},
        loadingCommit: () => null,
      );
    }
  }

  void closeCommitDetail() => state = state.copyWith(commitDetailHash: () => null);

  // ── 分支 ──

  /// 切换到指定分支或标签。成功后刷新全量状态。
  Future<void> checkout(String ref, {bool isRemote = false}) async {
    if (state.busy || state.checkoutLoading != null) return;
    final repoPath = state.repoPath;
    if (repoPath == null) return;
    final l10n = _ref.read(appLocalizationsProvider);
    state = state.copyWith(checkoutLoading: () => ref, toast: () => null);
    String toast;
    try {
      await _cgit.checkout(repoPath, ref, isRemote: isRemote);
      toast = l10n.gitCheckoutSuccess(ref);
    } on GitException catch (error) {
      toast = l10n.gitToastCheckoutFailed(GitErrorMessage.friendly(error.message));
    }
    try {
      final snapshot = await _loadSnapshot(repoPath, includeIdentity: false);
      state = state.copyWith(
        checkoutLoading: () => null,
        status: () => snapshot.status,
        log: _commitsOf(snapshot.graph),
        graph: snapshot.graph,
        hasRemote: snapshot.hasRemote,
        notARepo: false,
        toast: () => toast,
      );
      await _refreshBranchesIfLoaded();
    } on GitException catch (error) {
      state = state.copyWith(
        checkoutLoading: () => null,
        toast: () => l10n.gitToastActionRefreshFailed(
          GitErrorMessage.friendly(error.message),
        ),
      );
    }
  }

  Future<void> createBranch(String name, {String? startPoint, bool checkoutAfter = true}) {
    if (name.trim().isEmpty) return Future.value();
    return _branchAction(
      (l10n) => l10n.gitActionCreateBranch,
      (repo) => _cgit.createBranch(
        repo,
        name,
        startPoint: startPoint,
        checkout: checkoutAfter,
      ),
    );
  }

  Future<void> deleteBranch(String name) {
    if (name.trim().isEmpty) return Future.value();
    return _branchAction(
      (l10n) => l10n.gitDeleteBranch,
      (repo) => _cgit.deleteBranch(repo, name),
    );
  }

  Future<void> deleteRemoteBranch(String name) {
    if (name.trim().isEmpty) return Future.value();
    return _branchAction(
      (l10n) => l10n.gitDeleteRemoteBranch,
      (repo) => _cgit.deleteRemoteBranch(repo, name),
    );
  }

  Future<void> renameBranch(String oldName, String newName) {
    if (oldName.trim().isEmpty || newName.trim().isEmpty) return Future.value();
    return _branchAction(
      (l10n) => l10n.gitRenameBranch,
      (repo) => _cgit.renameBranch(repo, oldName, newName),
    );
  }

  Future<void> createTag(String name, {String? commitHash}) {
    if (name.trim().isEmpty) return Future.value();
    return _branchAction(
      (l10n) => l10n.gitActionCreateTag,
      (repo) => _cgit.createTag(repo, name, commitHash: commitHash),
    );
  }

  Future<void> deleteTag(String name) {
    if (name.trim().isEmpty) return Future.value();
    return _branchAction(
      (l10n) => l10n.gitDeleteTag,
      (repo) => _cgit.deleteTag(repo, name),
    );
  }

  Future<void> mergeBranch(String name, {bool noFf = false}) {
    if (name.trim().isEmpty) return Future.value();
    return _branchAction(
      (l10n) => l10n.gitActionMerge,
      (repo) => _cgit.mergeBranch(repo, name, noFf: noFf),
    );
  }

  Future<void> abortMerge() => _repoAction(
        (l10n) => l10n.gitActionAbortMerge,
        (repo) => _cgit.abortMerge(repo),
      );

  /// 重置当前分支到指定提交。
  Future<void> resetToCommit(String hash, {String mode = 'mixed'}) {
    if (hash.trim().isEmpty) return Future.value();
    return _repoAction(
      (l10n) => l10n.gitResetToCommit,
      (repo) => _cgit.resetToCommit(repo, hash, mode: mode),
    );
  }

  // ── 远端 ──

  /// 拉取:凭据由容器 credential.helper 链注入,不在 app 侧预查。
  Future<void> pull() async {
    if (!state.hasRemote) {
      state = state.copyWith(toast: () => _ref.read(appLocalizationsProvider).gitNoRemotePull);
      return;
    }
    final repoPath = state.repoPath;
    if (repoPath == null) return;
    await _runAction(
      (l10n) => l10n.gitPull,
      () => _cgit.pull(repoPath),
      onDone: () async {
        await loadBranches();
      },
    );
  }

  /// 推送:首次推送 master 时先询问是否改名为 main。
  Future<void> push({void Function()? onPromptRenameMaster}) async {
    if (!state.hasRemote) {
      state = state.copyWith(toast: () => _ref.read(appLocalizationsProvider).gitNoRemotePush);
      return;
    }
    final repoPath = state.repoPath;
    if (repoPath == null) return;
    final isFirstMasterPush = await _cgit.isFirstPushOfMaster(repoPath);
    if (isFirstMasterPush && onPromptRenameMaster != null) {
      onPromptRenameMaster();
      return;
    }
    await pushDirectly();
  }

  /// 用户选择重命名为 main 并推送。
  Future<void> pushRenameMasterToMain() => _runAction(
        (l10n) => l10n.gitPush,
        () async {
          final repoPath = state.repoPath;
          if (repoPath != null) await _cgit.renameMasterToMainAndPush(repoPath);
        },
      );

  /// 用户选择保留 master 直接推送。
  Future<void> pushDirectly() => _runAction(
        (l10n) => l10n.gitPush,
        () async {
          final repoPath = state.repoPath;
          if (repoPath != null) await _cgit.push(repoPath);
        },
      );

  void consumeToast() => state = state.copyWith(toast: () => null);

  // ── 内部 ──

  /// 当前是否深色主题(AUTO 跟随系统),供差异页高亮选主题。
  bool _isDarkTheme() => switch (_ref.read(settingsProvider).themeMode) {
        AppThemeMode.dark => true,
        AppThemeMode.light => false,
        AppThemeMode.system =>
          PlatformDispatcher.instance.platformBrightness == Brightness.dark,
      };

  Future<bool> _hasIdentity(String repoPath) async {
    try {
      return (await _cgit.getUserName(repoPath)).trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// 仓库动作:执行 + 刷新状态,失败把 git 的报错经 GitErrorMessage 转成友好文案。
  Future<void> _repoAction(
    String Function(AppLocalizations l10n) name,
    FutureOr<void> Function(String repoPath) action, {
    Future<void> Function()? onDone,
  }) async {
    final repoPath = state.repoPath;
    if (repoPath == null) return;
    await _runAction(name, () async => action(repoPath), onDone: onDone);
  }

  /// 分支动作:执行后刷新分支与提交列表。
  Future<void> _branchAction(
    String Function(AppLocalizations l10n) name,
    FutureOr<void> Function(String repoPath) action,
  ) async {
    final repoPath = state.repoPath;
    if (repoPath == null) return;
    await _runAction(
      name,
      () async => action(repoPath),
      onDone: () async {
        state = state.copyWith(branchesLoaded: false);
        await loadBranches();
      },
    );
  }

  /// 执行一个写操作:置 busy → 跑命令 → 刷新 → toast 反馈。操作间互斥。
  Future<void> _runAction(
    String Function(AppLocalizations l10n) name,
    Future<void> Function() action, {
    Future<void> Function()? onDone,
  }) async {
    if (state.busy) return;
    final l10n = _ref.read(appLocalizationsProvider);
    final actionName = name(l10n);
    state = state.copyWith(busy: true, toast: () => null);
    String toast;
    try {
      await action();
      toast = l10n.gitActionDone(actionName);
    } on GitException catch (error) {
      toast = l10n.gitActionFailed(
        actionName,
        GitErrorMessage.friendly(error.message),
      );
    } catch (error) {
      toast = l10n.gitActionFailed(actionName, '$error');
    }
    // 刷新以反映新状态;失败也刷新,让 UI 与仓库一致。
    final repoPath = state.repoPath;
    try {
      if (repoPath != null && await _cgit.isRepository(repoPath)) {
        final snapshot = await _loadSnapshot(repoPath, includeIdentity: false);
        state = state.copyWith(
          busy: false,
          status: () => snapshot.status,
          log: _commitsOf(snapshot.graph),
          graph: snapshot.graph,
          hasRemote: snapshot.hasRemote,
          untrackedDirFiles: snapshot.untrackedDirFiles,
          notARepo: false,
          toast: () => toast,
        );
        await _refreshBranchesIfLoaded();
        await onDone?.call();
      } else {
        state = state.copyWith(busy: false, notARepo: true, toast: () => toast);
        await onDone?.call();
      }
    } on GitException catch (error) {
      state = state.copyWith(
        busy: false,
        toast: () => l10n.gitToastActionRefreshFailed(
          GitErrorMessage.friendly(error.message),
        ),
      );
    }
  }
}

final gitControllerProvider =
    StateNotifierProvider<GitController, GitUiState>((ref) => GitController(ref));