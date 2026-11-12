import 'git_graph_models.dart';

/// 提交拓扑图的解析与泳道布局(逐行对照上游 `domain/GitGraphBuilder.kt`):
/// 输入 `git log`(带 `%P` 父哈希)与 refs 映射,输出 [GitGraph]。
class GitGraphBuilder {
  const GitGraphBuilder._();

  /// 解析 `git log --pretty=format:%H%x1f%h%x1f%an%x1f%ar%x1f%s%x1f%P%x1f%b` 输出。
  ///
  /// 字段用 0x1f 分隔:提交信息/作者名可能含 `|`,用 `|` 分隔会把 parents 解析成假父,
  /// 提交被误判为 merge 并产生幽灵泳道。
  static List<GraphCommit> parseGraphCommits(String raw) {
    final commits = <GraphCommit>[];
    for (final line in raw.split('\n')) {
      final trimmed = line.endsWith('\r') ? line.substring(0, line.length - 1) : line;
      final parts = trimmed.split('\u001f');
      if (parts.length < 6) continue;
      commits.add(GraphCommit(
        hash: parts[0],
        shortHash: parts[1],
        author: parts[2],
        date: parts[3],
        message: parts[4],
        parents: parts[5].split(' ').where((hash) => hash.isNotEmpty).toList(),
        body: parts.length > 6 ? parts[6] : '',
      ));
    }
    return commits;
  }

  /// 对完整提交列表重算泳道布局并组装 [GitGraph]。[refs] 为全量 refs-by-commit 映射,
  /// 过滤为只含已加载提交 hash 的条目,减少传给 UI 的数据量。
  static GitGraph buildGraph(
    List<GraphCommit> commits,
    Map<String, List<GitGraphRef>> refs, {
    required bool hasMore,
  }) {
    if (commits.isEmpty) return GitGraph.empty;
    final commitHashes = commits.map((commit) => commit.hash).toSet();
    final filteredRefs = <String, List<GitGraphRef>>{
      for (final entry in refs.entries)
        if (commitHashes.contains(entry.key)) entry.key: entry.value,
    };
    final layout = _computeLanes(commits);
    return GitGraph(
      commits: commits,
      refs: filteredRefs,
      lanes: layout.lanes,
      edges: layout.edges,
      activeTopLanes: layout.activeTopLanes,
      activeBottomLanes: layout.activeBottomLanes,
      activeLanes: layout.activeLanes,
      maxLane: layout.maxLane,
      hasMore: hasMore,
    );
  }

  /// 泳道分配算法(IDE 风格拓扑布局),逐行对照上游 `computeLanes`。
  static _GraphLayout _computeLanes(List<GraphCommit> commits) {
    final commitMap = {for (final commit in commits) commit.hash: commit};
    final lanes = <String, int>{};
    final edges = <GraphEdge>[];
    final activeTopLanes = <String, List<int>>{};
    final activeBottomLanes = <String, List<int>>{};
    final activeLanes = <String, List<int>>{};
    // 活跃泳道:槽位索引即列号,值为占据该列的提交哈希(null=空闲)。
    final active = <String?>[];
    var maxLane = 0;

    for (final commit in commits) {
      // 当前提交是否已被某子提交的父引用占位。
      var lane = active.indexOf(commit.hash);
      if (lane < 0) {
        lane = active.indexOf(null);
        if (lane < 0) {
          lane = active.length;
          active.add(commit.hash);
        } else {
          active[lane] = commit.hash;
        }
      }
      if (lane > maxLane) maxLane = lane;
      lanes[commit.hash] = lane;

      // 快照上半段:此时 active 反应进入本节点前上方的分支通道。
      activeTopLanes[commit.hash] = _snapshot(active);

      if (commit.parents.isEmpty) {
        // 根提交:释放当前泳道后快照下半段。
        active[lane] = null;
        final bottom = _snapshot(active);
        activeBottomLanes[commit.hash] = bottom;
        activeLanes[commit.hash] = bottom;
        continue;
      }

      // 第一父复用当前泳道(主线延续)。
      final firstParent = commit.parents[0];
      final firstParentLane = active.indexOf(firstParent);
      if (firstParentLane >= 0 && firstParentLane != lane) {
        edges.add(GraphEdge(
          fromLane: lane,
          toLane: firstParentLane,
          lane: lane,
          isMergeIn: false,
        ));
        active[lane] = null;
      } else {
        edges.add(GraphEdge(fromLane: lane, toLane: lane, lane: lane, isMergeIn: false));
        active[lane] = firstParent;
      }

      // 其余父(合并的第二个及以后):优先复用能继承该父的泳道,否则分配新泳道。
      for (var i = 1; i < commit.parents.length; i++) {
        final parent = commit.parents[i];
        final existing = active.indexOf(parent);
        int parentLane;
        if (existing >= 0) {
          parentLane = existing;
        } else {
          // active 中若已有占位提交 X(非当前列)的父引用包含 parent,
          // 说明 parent 是 X 的父,会在 X 处理完后自然继承该列,入边直接指向该列。
          final reuse = active.indexWhere((hash) =>
              hash != null &&
              active.indexOf(hash) != lane &&
              (commitMap[hash]?.parents.contains(parent) ?? false));
          if (reuse >= 0) {
            parentLane = reuse;
          } else {
            final free = active.indexOf(null);
            if (free < 0) {
              active.add(parent);
              parentLane = active.length - 1;
            } else {
              active[free] = parent;
              parentLane = free;
            }
          }
        }
        if (parentLane > maxLane) maxLane = parentLane;
        edges.add(GraphEdge(
          fromLane: lane,
          toLane: parentLane,
          lane: parentLane,
          isMergeIn: true,
        ));
      }

      // 快照下半段:父分配完毕后反应离开本节点向下的分支通道。
      final bottom = _snapshot(active);
      activeBottomLanes[commit.hash] = bottom;
      activeLanes[commit.hash] = bottom;
    }
    return _GraphLayout(
      lanes: lanes,
      edges: edges,
      activeTopLanes: activeTopLanes,
      activeBottomLanes: activeBottomLanes,
      activeLanes: activeLanes,
      maxLane: maxLane,
    );
  }

  static List<int> _snapshot(List<String?> active) {
    final lanes = <int>[];
    for (var index = 0; index < active.length; index++) {
      if (active[index] != null) lanes.add(index);
    }
    return lanes;
  }
}

/// [_computeLanes] 的输出。
class _GraphLayout {
  const _GraphLayout({
    required this.lanes,
    required this.edges,
    required this.activeTopLanes,
    required this.activeBottomLanes,
    required this.activeLanes,
    required this.maxLane,
  });

  final Map<String, int> lanes;
  final List<GraphEdge> edges;
  final Map<String, List<int>> activeTopLanes;
  final Map<String, List<int>> activeBottomLanes;
  final Map<String, List<int>> activeLanes;
  final int maxLane;
}