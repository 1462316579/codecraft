import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';

import '../../agent/models/git_models.dart';
import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/git/git_graph_models.dart';
import '../../data/git_controller.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/git_common.dart';
import 'widgets/git_sheets.dart';

/// 泳道调色板(取自上游 `GitLanePalette`):按列号循环取色。
const List<Color> _lanePalette = [
  Color(0xFF2563EB), // 经典蓝
  Color(0xFF16A34A), // 翠绿
  Color(0xFFF59E0B), // 琥珀
  Color(0xFF8B5CF6), // 优雅紫
  Color(0xFF06B6D4), // 青蓝
  Color(0xFFEF4444), // 珊瑚红
  Color(0xFFEC4899), // 亮粉
  Color(0xFFEAB308), // 柠檬金
];

List<Color> _laneColors(int count) =>
    [for (var i = 0; i < count; i++) _lanePalette[i % _lanePalette.length]];

/// 把扁平有序的 edges 按来源提交索引分组(根提交无边,非根提交有 parents.size 条边)。
Map<int, List<GraphEdge>> _groupEdgesByCommit(GitGraph graph) {
  final result = <int, List<GraphEdge>>{};
  var edgeIndex = 0;
  for (var commitIndex = 0; commitIndex < graph.commits.length; commitIndex++) {
    final commit = graph.commits[commitIndex];
    final count = commit.parents.isEmpty ? 0 : commit.parents.length;
    final edges = <GraphEdge>[];
    for (var i = 0; i < count; i++) {
      if (edgeIndex < graph.edges.length) {
        edges.add(graph.edges[edgeIndex++]);
      }
    }
    result[commitIndex] = edges;
  }
  return result;
}

/// 提交页:搜索、提交数小标题、泳道图列表、页脚加载更多、提交详情弹层。
class GitLogTab extends StatefulWidget {
  const GitLogTab({
    super.key,
    required this.state,
    required this.controller,
    required this.scrollController,
  });

  final GitUiState state;
  final GitController controller;
  final ScrollController scrollController;

  @override
  State<GitLogTab> createState() => _GitLogTabState();
}

class _GitLogTabState extends State<GitLogTab> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_maybeLoadMore);
    _searchController.dispose();
    super.dispose();
  }

  /// 预拉取:滚动到距底部 20 项内且还有更多提交时提前加载。
  void _maybeLoadMore() {
    if (_query.isNotEmpty) return;
    final position = widget.scrollController.position;
    if (position.pixels < position.maxScrollExtent - 400) return;
    if (!widget.state.graph.hasMore || widget.state.graphLoadingMore) return;
    widget.controller.loadMoreCommits();
  }

  GitUiState get _state => widget.state;

  List<GraphCommit> get _filteredCommits {
    final all = _state.graph.commits;
    if (_query.trim().isEmpty) return all;
    final query = _query.trim().toLowerCase();
    return all
        .where((commit) =>
            commit.message.toLowerCase().contains(query) ||
            commit.author.toLowerCase().contains(query) ||
            commit.shortHash.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _openCommitDetail(GraphCommit commit) async {
    await widget.controller.openCommitDetail(commit.hash);
    if (!mounted) return;
    final gitCommit = GitCommit(
      hash: commit.hash,
      author: commit.author,
      date: commit.date,
      message: commit.message,
      parents: commit.parents,
      body: commit.body,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => CommitDetailSheet(
        commit: gitCommit,
        files: _state.commitFiles[commit.hash],
        loading: _state.loadingCommit == commit.hash && _state.commitFiles[commit.hash] == null,
        onFileDiff: (hash, path) {
          Navigator.of(sheetContext).pop();
          widget.controller.loadCommitFileDiff(hash, path);
        },
        onCreateBranch: (name) =>
            widget.controller.createBranch(name, startPoint: commit.hash, checkoutAfter: false),
        onCreateTag: (name) => widget.controller.createTag(name, commitHash: commit.hash),
        onReset: (mode) => widget.controller.resetToCommit(commit.hash, mode: mode),
        onDismiss: () {
          widget.controller.closeCommitDetail();
          Navigator.of(sheetContext).maybePop();
        },
      ),
    );
    widget.controller.closeCommitDetail();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final allCommits = _state.graph.commits;
    if (allCommits.isEmpty) {
      return Center(
        child: Text(
          l10n.gitNoCommits,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final commits = _filteredCommits;
    final searching = _query.isNotEmpty;
    final graph = _state.graph;
    final laneColors = _laneColors(graph.maxLane + 1);
    final edgesByCommit = _groupEdgesByCommit(graph);
    // 线性历史收紧泳道宽度,把空间让给提交信息;有分叉时每泳道 16dp。
    final laneWidth = graph.maxLane == 0 ? 10.0 : 16.0;
    final canvasWidth = laneWidth * (graph.maxLane + 1) + Spacing.xs * 2;
    const rowHeight = 72.0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.xs),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: l10n.gitSearchCommitsHint,
              isDense: true,
              prefixIcon: const Icon(Iconfont.search, size: 16),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Iconfont.x, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        GitSectionHeader(text: l10n.gitCommitCount(commits.length)),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, 70),
            itemCount: commits.length + 1,
            itemBuilder: (context, index) {
              if (index == commits.length) {
                return _buildFooter(context, graph);
              }
              final commit = commits[index];
              final radius = Radius.circular(Radii.lg);
              final isFirst = index == 0;
              final isLast = index == commits.length - 1 && (!graph.hasMore || searching);
              final shape = isFirst && isLast
                  ? BorderRadius.all(radius)
                  : isFirst
                      ? BorderRadius.vertical(top: radius)
                      : isLast
                          ? BorderRadius.vertical(bottom: radius)
                          : BorderRadius.zero;
              final originalIndex = allCommits.indexWhere((item) => item.hash == commit.hash);
              return Container(
                decoration: BoxDecoration(
                  color: context.semantic.cardSurface,
                  borderRadius: shape,
                ),
                child: _GraphCommitRow(
                  commit: commit,
                  lane: graph.lanes[commit.hash] ?? 0,
                  edges: searching ? const [] : edgesByCommit[originalIndex] ?? const [],
                  activeTopLanes:
                      searching ? const [] : graph.activeTopLanes[commit.hash] ?? const [],
                  activeBottomLanes:
                      searching ? const [] : graph.activeBottomLanes[commit.hash] ?? const [],
                  laneColors: laneColors,
                  canvasWidth: searching ? 0 : canvasWidth,
                  laneWidth: searching ? 0 : laneWidth,
                  rowHeight: rowHeight,
                  refs: graph.refs[commit.hash] ?? const [],
                  isTopTerminal: originalIndex == 0,
                  onTap: () => _openCommitDetail(commit),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, GitGraph graph) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      decoration: BoxDecoration(
        color: context.semantic.cardSurface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Radii.lg)),
      ),
      child: Center(
        child: _query.isNotEmpty
            ? const SizedBox.shrink()
            : graph.hasMore
                ? (_state.graphLoadingMore
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        l10n.gitLoadMoreCommits,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ))
                : Text(
                    l10n.gitNoMoreCommits,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
      ),
    );
  }
}

/// 单条提交行:左侧拓扑图 + 引用胶囊 + 提交信息 + 作者/时间。
class _GraphCommitRow extends StatelessWidget {
  const _GraphCommitRow({
    required this.commit,
    required this.lane,
    required this.edges,
    required this.activeTopLanes,
    required this.activeBottomLanes,
    required this.laneColors,
    required this.canvasWidth,
    required this.laneWidth,
    required this.rowHeight,
    required this.refs,
    required this.isTopTerminal,
    required this.onTap,
  });

  final GraphCommit commit;
  final int lane;
  final List<GraphEdge> edges;
  final List<int> activeTopLanes;
  final List<int> activeBottomLanes;
  final List<Color> laneColors;
  final double canvasWidth;
  final double laneWidth;
  final double rowHeight;
  final List<GitGraphRef> refs;
  final bool isTopTerminal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nodeColor = laneColors.length > lane ? laneColors[lane] : Colors.grey;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: rowHeight),
        // stretch 需要有限高度:ListView 子项高度无界,用 IntrinsicHeight 收紧后再撑满。
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            if (canvasWidth > 0)
              SizedBox(
                width: canvasWidth,
                child: CustomPaint(
                  painter: _GraphPainter(
                    edges: edges,
                    activeTopLanes: activeTopLanes,
                    activeBottomLanes: activeBottomLanes,
                    lane: lane,
                    isMerge: commit.isMerge,
                    laneColors: laneColors,
                    laneWidth: laneWidth,
                    suppressTopLane: isTopTerminal,
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, Spacing.sm, Spacing.lg, Spacing.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (refs.isNotEmpty) ...[
                      _RefPills(refs: refs),
                      const SizedBox(height: Spacing.xs),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Iconfont.chevronRight,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: Spacing.xs),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                commit.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Spacing.sm,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: nodeColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(Radii.pill),
                                    ),
                                    child: Text(
                                      commit.shortHash,
                                      maxLines: 1,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontFamily: 'monospace',
                                        color: nodeColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: Spacing.sm),
                                  Expanded(
                                    child: Text(
                                      commit.author,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    commit.date,
                                    maxLines: 1,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
          ),
        ),
    );
  }
}

/// 提交引用标签行:当前分支高亮 primary,其余按分支/标签分色。
class _RefPills extends StatelessWidget {
  const _RefPills({required this.refs});

  final List<GitGraphRef> refs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: Spacing.xs,
      runSpacing: 2,
      children: [
        for (final ref in refs)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
            decoration: BoxDecoration(
              color: ref.isCurrent
                  ? theme.colorScheme.primary
                  : ref.isBranch
                      ? theme.colorScheme.secondaryContainer
                      : theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(Radii.xs),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  ref.isRemote
                      ? Iconfont.cloud
                      : ref.isBranch
                          ? Iconfont.gitBranch
                          : Iconfont.tag,
                  size: 11,
                  color: ref.isCurrent
                      ? theme.colorScheme.onPrimary
                      : ref.isBranch
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: 2),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    ref.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: ref.isCurrent
                          ? theme.colorScheme.onPrimary
                          : ref.isBranch
                              ? theme.colorScheme.onSecondaryContainer
                              : theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 拓扑图绘制:分段竖线 + 跨列贝塞尔连线 + 节点圆点(合并提交为环形双圈)。
class _GraphPainter extends CustomPainter {
  _GraphPainter({
    required this.edges,
    required this.activeTopLanes,
    required this.activeBottomLanes,
    required this.lane,
    required this.isMerge,
    required this.laneColors,
    required this.laneWidth,
    required this.suppressTopLane,
  });

  final List<GraphEdge> edges;
  final List<int> activeTopLanes;
  final List<int> activeBottomLanes;
  final int lane;
  final bool isMerge;
  final List<Color> laneColors;
  final double laneWidth;
  final bool suppressTopLane;

  Color _color(int lane) =>
      laneColors.length > lane ? laneColors[lane] : Colors.grey;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = Spacing.xs;
    final centerY = size.height / 2;
    const stroke = 2.5;
    double laneX(int index) => index * laneWidth + laneWidth / 2 + pad;

    final allLanes = <int>{...activeTopLanes, ...activeBottomLanes, lane};

    // 跨列边在下半段画曲线;该列上半段无竖线时不再画下半段竖线,避免孤立半段。
    final crossEdgeToLanes =
        edges.where((edge) => edge.fromLane != edge.toLane).map((edge) => edge.toLane).toSet();
    final curveBottomLanes =
        crossEdgeToLanes.where((index) => !activeTopLanes.contains(index)).toSet();

    // 1. 分段竖线
    for (final index in allLanes) {
      final inTop = activeTopLanes.contains(index);
      final inBottom = activeBottomLanes.contains(index) && !curveBottomLanes.contains(index);
      final paint = Paint()
        ..color = _color(index)
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      final x = laneX(index);
      if (inTop && inBottom) {
        final startY = suppressTopLane ? centerY : 0.0;
        canvas.drawLine(Offset(x, startY), Offset(x, size.height), paint);
      } else if (inTop) {
        if (!suppressTopLane) {
          canvas.drawLine(Offset(x, 0), Offset(x, centerY), paint);
        }
      } else if (inBottom) {
        canvas.drawLine(Offset(x, centerY), Offset(x, size.height), paint);
      }
    }

    // 2. 跨列连线
    for (final edge in edges) {
      if (edge.fromLane == edge.toLane) continue;
      final fromX = laneX(edge.fromLane);
      final toX = laneX(edge.toLane);
      final midY = centerY + (size.height - centerY) * 0.5;
      final path = Path();
      if (edge.isMergeIn) {
        path.moveTo(toX, size.height);
        path.cubicTo(toX, midY, fromX, midY, fromX, centerY);
      } else {
        path.moveTo(fromX, centerY);
        path.cubicTo(fromX, midY, toX, midY, toX, size.height);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = _color(edge.lane)
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }

    // 3. 节点圆点
    final nodeColor = _color(lane);
    final center = Offset(laneX(lane), centerY);
    if (isMerge) {
      canvas.drawCircle(
        center,
        7,
        Paint()
          ..color = nodeColor
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(center, 3.5, Paint()..color = nodeColor);
    } else {
      canvas.drawCircle(center, 5, Paint()..color = nodeColor);
    }
  }

  @override
  bool shouldRepaint(_GraphPainter oldDelegate) =>
      oldDelegate.lane != lane ||
      oldDelegate.isMerge != isMerge ||
      oldDelegate.suppressTopLane != suppressTopLane ||
      oldDelegate.laneWidth != laneWidth ||
      oldDelegate.edges != edges ||
      oldDelegate.activeTopLanes != activeTopLanes ||
      oldDelegate.activeBottomLanes != activeBottomLanes;
}