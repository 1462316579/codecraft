import 'package:codecraft/data/git/git_graph_builder.dart';
import 'package:codecraft/data/git/git_graph_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// 移植自上游 `app/src/test/java/com/codecraft/feature/git/domain/GitGraphBuilderTest.kt`。
void main() {
  group('parseGraphCommits 字段解析', () {
    test('完整行:含正文与两个父', () {
      const raw = 'a1b2c3d4e5f6\u001fa1b2c3d\u001fAlice\u001f2 days ago\u001ffix: 问题\u001fp1p2p3 q1q2q3\u001f正文第一行';
      final commits = GitGraphBuilder.parseGraphCommits(raw);
      expect(commits, hasLength(1));
      expect(
        commits[0],
        const GraphCommit(
          hash: 'a1b2c3d4e5f6',
          shortHash: 'a1b2c3d',
          author: 'Alice',
          date: '2 days ago',
          message: 'fix: 问题',
          body: '正文第一行',
          parents: ['p1p2p3', 'q1q2q3'],
        ),
      );
    });

    test('无 %b 段:正文为空串', () {
      const raw = 'a1b2c3d4e5f6\u001fa1b2c3d\u001fAlice\u001f2 days ago\u001ffix: 问题\u001fr1r2r3';
      final commits = GitGraphBuilder.parseGraphCommits(raw);
      expect(commits, hasLength(1));
      expect(commits[0].body, '');
      expect(commits[0].parents, ['r1r2r3']);
    });

    test('正文含 | 不影响其他字段', () {
      const raw = 'a1b2c3d4e5f6\u001fa1b2c3\u001fAlice\u001f2 days ago\u001ffix\u001f\u001fbody | with pipe';
      expect(GitGraphBuilder.parseGraphCommits(raw)[0].body, 'body | with pipe');
    });

    test('父为空:根提交', () {
      const raw = 'a1b2c3d4e5f6\u001fa1b2c3\u001fAlice\u001f2 days ago\u001ffix\u001f';
      final commits = GitGraphBuilder.parseGraphCommits(raw);
      expect(commits, hasLength(1));
      expect(commits[0].parents, isEmpty);
      expect(commits[0].isMerge, isFalse);
    });

    test('多行去尾部 \\r', () {
      const raw = 'a1b2c3\u001fa1b2c3\u001fAlice\u001f2 days ago\u001ffix: 1\u001f\r\n'
          'd4e5f6\u001fd4e5f6\u001fBob\u001f3 days ago\u001ffeat: 2\u001fr0r0r0\r\n';
      final commits = GitGraphBuilder.parseGraphCommits(raw);
      expect(commits, hasLength(2));
      expect(commits[0].hash, 'a1b2c3');
      expect(commits[1].hash, 'd4e5f6');
    });

    test('父列表多余空格被过滤', () {
      const raw = 'a1b2c3\u001fa1b2c3\u001fAlice\u001f2 days ago\u001fmerge\u001fp1  p2  \u001f';
      final commits = GitGraphBuilder.parseGraphCommits(raw);
      expect(commits[0].parents, ['p1', 'p2']);
      expect(commits[0].isMerge, isTrue);
    });

    test('少于 6 段整行丢弃', () {
      const raw = 'a1b2c3\u001fa1b2c3\u001fAlice\u001f2 days ago\u001ffix';
      expect(GitGraphBuilder.parseGraphCommits(raw), isEmpty);
    });

    test('空行跳过', () {
      const raw = 'a1b2c3\u001fa1b2c3\u001fAlice\u001f2 days ago\u001ffix\u001f\n\n';
      expect(GitGraphBuilder.parseGraphCommits(raw), hasLength(1));
    });

    test('空输入返回空', () {
      expect(GitGraphBuilder.parseGraphCommits(''), isEmpty);
    });

    test('提交信息含 | 时不误拆父(回归)', () {
      const raw = 'm1m2m3\u001fm1m2m3\u001fAlice\u001f2 days ago\u001ffix: merge | conflict\u001fp1p2p3 p4p5p6\u001f';
      final commits = GitGraphBuilder.parseGraphCommits(raw);
      expect(commits, hasLength(1));
      expect(commits[0].parents, ['p1p2p3', 'p4p5p6']);
      expect(commits[0].isMerge, isTrue);
    });

    test('信息含 | 的普通提交仍是单父', () {
      const raw = 'a1b2c3\u001fa1b2c3\u001fAlice\u001f2 days ago\u001fupdate a | b\u001fr0r0r0\u001f';
      final commits = GitGraphBuilder.parseGraphCommits(raw);
      expect(commits[0].parents, ['r0r0r0']);
      expect(commits[0].isMerge, isFalse);
    });
  });

  group('buildGraph', () {
    test('空提交返回空图', () {
      final graph = GitGraphBuilder.buildGraph(const [], const {}, hasMore: false);
      expect(graph.commits, isEmpty);
      expect(graph.lanes, isEmpty);
      expect(graph.maxLane, 0);
      expect(graph.hasMore, isFalse);
    });

    test('refs 过滤为已加载提交', () {
      const loaded = GraphCommit(
        hash: 'a1b2c3',
        shortHash: 'a1b2c3',
        author: 'Alice',
        date: 'd',
        message: 'fix',
      );
      final refs = {
        'a1b2c3': const [
          GitGraphRef(name: 'main', isBranch: true, isCurrent: true, isRemote: false),
        ],
        'unloaded1': const [
          GitGraphRef(name: 'other', isBranch: true, isCurrent: false, isRemote: false),
        ],
      };
      final graph = GitGraphBuilder.buildGraph([loaded], refs, hasMore: true);
      expect(graph.refs.keys.toSet(), {'a1b2c3'});
      expect(graph.refs['a1b2c3']![0].name, 'main');
    });

    test('refs 全部未加载时为空', () {
      const loaded = GraphCommit(
        hash: 'a1b2c3',
        shortHash: 'a1b2c3',
        author: 'Alice',
        date: 'd',
        message: 'fix',
      );
      final refs = {
        'unloaded1': const [
          GitGraphRef(name: 'x', isBranch: true, isCurrent: false, isRemote: false),
        ],
        'unloaded2': const [
          GitGraphRef(name: 'y', isBranch: true, isCurrent: false, isRemote: false),
        ],
      };
      expect(GitGraphBuilder.buildGraph([loaded], refs, hasMore: false).refs, isEmpty);
    });

    test('hasMore 透传', () {
      const loaded = GraphCommit(
        hash: 'a1b2c3',
        shortHash: 'a1b2c3',
        author: 'Alice',
        date: 'd',
        message: 'fix',
      );
      expect(GitGraphBuilder.buildGraph([loaded], const {}, hasMore: true).hasMore, isTrue);
      expect(GitGraphBuilder.buildGraph([loaded], const {}, hasMore: false).hasMore, isFalse);
    });
  });

  group('泳道布局', () {
    test('单链占一列', () {
      const head = GraphCommit(
        hash: 'h1h2h3',
        shortHash: 'h1h2h3',
        author: 'Alice',
        date: 'd',
        message: 'c2',
        parents: ['r0r0r0'],
      );
      const root = GraphCommit(
        hash: 'r0r0r0',
        shortHash: 'r0r0r0',
        author: 'Bob',
        date: 'd',
        message: 'c1',
      );
      final graph = GitGraphBuilder.buildGraph([head, root], const {}, hasMore: false);
      expect(graph.lanes, {'h1h2h3': 0, 'r0r0r0': 0});
      expect(
        graph.edges,
        [const GraphEdge(fromLane: 0, toLane: 0, lane: 0, isMergeIn: false)],
      );
      expect(graph.maxLane, 0);
    });

    test('根提交无连线', () {
      const root = GraphCommit(
        hash: 'r0r0r0',
        shortHash: 'r0r0r0',
        author: 'Alice',
        date: 'd',
        message: 'root',
      );
      final graph = GitGraphBuilder.buildGraph([root], const {}, hasMore: false);
      expect(graph.edges, isEmpty);
      expect(graph.lanes, {'r0r0r0': 0});
      expect(graph.maxLane, 0);
    });

    test('两子指向同一父产生跨列出边', () {
      const c1 = GraphCommit(
        hash: 'c1c1c1',
        shortHash: 'c1c1c1',
        author: 'Alice',
        date: 'd',
        message: 'branch A',
        parents: ['r0r0r0'],
      );
      const c2 = GraphCommit(
        hash: 'c2c2c2',
        shortHash: 'c2c2c2',
        author: 'Bob',
        date: 'd',
        message: 'branch B',
        parents: ['r0r0r0'],
      );
      const root = GraphCommit(
        hash: 'r0r0r0',
        shortHash: 'r0r0r0',
        author: 'Dan',
        date: 'd',
        message: 'root',
      );
      final graph = GitGraphBuilder.buildGraph([c1, c2, root], const {}, hasMore: false);
      expect(graph.lanes, {'c1c1c1': 0, 'c2c2c2': 1, 'r0r0r0': 0});
      expect(graph.edges, const [
        GraphEdge(fromLane: 0, toLane: 0, lane: 0, isMergeIn: false),
        GraphEdge(fromLane: 1, toLane: 0, lane: 1, isMergeIn: false),
      ]);
      expect(graph.maxLane, 1);
    });

    test('合并提交产生 isMergeIn 入边', () {
      const merge = GraphCommit(
        hash: 'm1m1m1',
        shortHash: 'm1m1m1',
        author: 'Alice',
        date: 'd',
        message: 'Merge',
        parents: ['p1p1p1', 'p2p2p2'],
      );
      const p1 = GraphCommit(
        hash: 'p1p1p1',
        shortHash: 'p1p1p1',
        author: 'Bob',
        date: 'd',
        message: 'feat x',
        parents: ['r0r0r0'],
      );
      const p2 = GraphCommit(
        hash: 'p2p2p2',
        shortHash: 'p2p2p2',
        author: 'Carol',
        date: 'd',
        message: 'feat y',
        parents: ['r0r0r0'],
      );
      const root = GraphCommit(
        hash: 'r0r0r0',
        shortHash: 'r0r0r0',
        author: 'Dan',
        date: 'd',
        message: 'root',
      );
      final graph = GitGraphBuilder.buildGraph([merge, p1, p2, root], const {}, hasMore: false);
      expect(graph.commits[0].isMerge, isTrue);
      expect(graph.lanes, {'m1m1m1': 0, 'p1p1p1': 0, 'p2p2p2': 1, 'r0r0r0': 0});
      expect(graph.edges, hasLength(4));
      expect(
        graph.edges.any((edge) =>
            edge.isMergeIn && edge.fromLane == 0 && edge.toLane == 1 && edge.lane == 1),
        isTrue,
      );
      expect(graph.maxLane, 1);
    });
  });
}