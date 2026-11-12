/// 提交拓扑图领域模型(对照上游 `domain/model/GitGraphModels.kt`)。
///
/// 由 [GitGraphBuilder] 从 `git log`(带 `%P` 父哈希)与 `git for-each-ref` 输出解析、
/// 计算泳道布局后产出,供提交页用 Canvas 绘制 IDE 风格的分支彩色连线。
library;

/// 一条提交记录(拓扑图用)。在提交列表字段之外增加 [parents]:一个为普通提交、
/// 两个为合并提交、空为根提交;泳道分配依赖此字段。
class GraphCommit {
  const GraphCommit({
    required this.hash,
    required this.shortHash,
    required this.author,
    required this.date,
    required this.message,
    this.body = '',
    this.parents = const [],
  });

  final String hash;
  final String shortHash;
  final String author;
  final String date;
  final String message;

  /// 提交正文(message 之后的段落,无正文时为空串)。
  final String body;

  /// 父提交完整哈希列表(按 git 输出顺序,第一父为主线)。
  final List<String> parents;

  /// 是否为合并提交(≥2 个父提交),用于绘制合并节点。
  bool get isMerge => parents.length >= 2;

  @override
  bool operator ==(Object other) =>
      other is GraphCommit &&
      other.hash == hash &&
      other.shortHash == shortHash &&
      other.author == author &&
      other.date == date &&
      other.message == message &&
      other.body == body &&
      _listEquals(other.parents, parents);

  @override
  int get hashCode => Object.hash(hash, shortHash, author, date, message, body, Object.hashAll(parents));
}

/// 指向某提交的一个引用(分支或标签),用于在拓扑图节点旁标注并对分支着色。
class GitGraphRef {
  const GitGraphRef({
    required this.name,
    required this.isBranch,
    required this.isCurrent,
    required this.isRemote,
  });

  final String name;

  /// true=本地/远程分支,false=标签。
  final bool isBranch;

  /// 是否为当前 HEAD 所在分支(仅本地分支可能为 true)。
  final bool isCurrent;

  /// 是否为远程分支(refs/remotes 下)。
  final bool isRemote;

  @override
  bool operator ==(Object other) =>
      other is GitGraphRef &&
      other.name == name &&
      other.isBranch == isBranch &&
      other.isCurrent == isCurrent &&
      other.isRemote == isRemote;

  @override
  int get hashCode => Object.hash(name, isBranch, isCurrent, isRemote);
}

/// 一条连线:从 [fromLane] 所在泳道连到 [toLane] 所在泳道,对应相邻两个提交之间的父子关系。
class GraphEdge {
  const GraphEdge({
    required this.fromLane,
    required this.toLane,
    required this.lane,
    required this.isMergeIn,
  });

  final int fromLane;
  final int toLane;

  /// 该边所属泳道号(决定颜色):出边取 [fromLane],入边取 [toLane]。
  final int lane;

  /// true=合并入边(父支线从下方汇入本提交);false=出边(本提交向父分叉)。
  final bool isMergeIn;

  @override
  bool operator ==(Object other) =>
      other is GraphEdge &&
      other.fromLane == fromLane &&
      other.toLane == toLane &&
      other.lane == lane &&
      other.isMergeIn == isMergeIn;

  @override
  int get hashCode => Object.hash(fromLane, toLane, lane, isMergeIn);

  @override
  String toString() => 'GraphEdge($fromLane -> $toLane, lane: $lane, mergeIn: $isMergeIn)';
}

/// 拓扑图整体视图(字段语义同上游 `GitGraph`)。
class GitGraph {
  const GitGraph({
    required this.commits,
    required this.refs,
    required this.lanes,
    required this.edges,
    required this.activeTopLanes,
    required this.activeBottomLanes,
    required this.activeLanes,
    required this.maxLane,
    required this.hasMore,
  });

  /// 按时间从新到旧排列的提交列表。
  final List<GraphCommit> commits;

  /// 每个提交哈希 → 指向它的引用列表(分支/标签)。
  final Map<String, List<GitGraphRef>> refs;

  /// 每个提交哈希 → 其所在泳道列号(0 起)。
  final Map<String, int> lanes;

  /// 相邻提交之间的所有连线(含分叉/合并的跨泳道边)。
  final List<GraphEdge> edges;

  /// 每个提交哈希 → 该行上半段需要贯穿的活跃泳道列号。
  final Map<String, List<int>> activeTopLanes;

  /// 每个提交哈希 → 该行下半段需要贯穿的活跃泳道列号。
  final Map<String, List<int>> activeBottomLanes;

  /// 每个提交哈希 → 该行全部活跃泳道列号(含本提交所在列)。
  final Map<String, List<int>> activeLanes;

  /// 最大泳道列号,决定 Canvas 宽度。
  final int maxLane;

  /// 是否还有更旧的提交可分页加载。
  final bool hasMore;

  static const GitGraph empty = GitGraph(
    commits: [],
    refs: {},
    lanes: {},
    edges: [],
    activeTopLanes: {},
    activeBottomLanes: {},
    activeLanes: {},
    maxLane: 0,
    hasMore: false,
  );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}