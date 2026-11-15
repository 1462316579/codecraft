import 'capture_models.dart';

class CaptureStore {
  CaptureStore({this.maxFlows = 500});

  int maxFlows;
  final List<CaptureFlow> _flows = [];
  final Map<String, int> _index = {};
  final Map<String, int> _hostCounts = {};

  List<CaptureFlow> get flows => List.unmodifiable(_flows.reversed);
  int get count => _flows.length;

  Map<String, int> get hostCounts => Map.unmodifiable(_hostCounts);

  void add(CaptureFlow flow) {
    _index[flow.id] = _flows.length;
    _flows.add(flow);
    _hostCounts[flow.host] = (_hostCounts[flow.host] ?? 0) + 1;
    _trim();
  }

  void update(CaptureFlow flow) {
    final i = _index[flow.id];
    if (i == null || i < 0 || i >= _flows.length) {
      add(flow);
      return;
    }
    final oldHost = _flows[i].host;
    final newHost = flow.host;
    if (oldHost != newHost) {
      _hostCounts[oldHost] = (_hostCounts[oldHost] ?? 1) - 1;
      if (_hostCounts[oldHost]! <= 0) _hostCounts.remove(oldHost);
      _hostCounts[newHost] = (_hostCounts[newHost] ?? 0) + 1;
    }
    _flows[i] = flow;
  }

  CaptureFlow? get(String id) {
    final i = _index[id];
    if (i == null || i < 0 || i >= _flows.length) return null;
    return _flows[i];
  }

  List<CaptureFlow> search({String? query, String? host, int? limit}) {
    final q = query?.trim().toLowerCase() ?? '';
    final h = host?.trim().toLowerCase() ?? '';
    final out = <CaptureFlow>[];
    for (final flow in flows) {
      if (h.isNotEmpty && !flow.host.toLowerCase().contains(h)) continue;
      if (q.isNotEmpty) {
        final hay =
            '${flow.method} ${flow.url} ${flow.statusCode ?? ''} ${flow.requestBody} ${flow.responseBody}'
                .toLowerCase();
        if (!hay.contains(q)) continue;
      }
      out.add(flow);
      if (limit != null && out.length >= limit) break;
    }
    return out;
  }

  void clear() {
    _flows.clear();
    _index.clear();
    _hostCounts.clear();
  }

  void remove(String id) {
    final i = _index[id];
    if (i == null || i < 0 || i >= _flows.length) return;
    final removed = _flows.removeAt(i);
    // 删除时也要同步「域名列表」的计数,否则该域名的条数会一直是旧值。
    _hostCounts[removed.host] = (_hostCounts[removed.host] ?? 1) - 1;
    if (_hostCounts[removed.host]! <= 0) _hostCounts.remove(removed.host);
    _reindex();
  }

  void removeWhere(bool Function(CaptureFlow flow) test) {
    final toRemove = <String, int>{};
    for (final flow in _flows) {
      if (test(flow)) {
        toRemove[flow.host] = (toRemove[flow.host] ?? 0) + 1;
      }
    }
    _flows.removeWhere(test);
    toRemove.forEach((host, count) {
      _hostCounts[host] = (_hostCounts[host] ?? 0) - count;
      if (_hostCounts[host]! <= 0) _hostCounts.remove(host);
    });
    _reindex();
  }

  void _reindex() {
    _index
      ..clear()
      ..addEntries(
        [for (var i = 0; i < _flows.length; i++) MapEntry(_flows[i].id, i)],
      );
  }

  void _trim() {
    if (_flows.length <= maxFlows) return;
    // 原来每移除一条就 _reindex() 一次:满 500 条后每个新请求都会做 500 次
    // 建表操作,抓包高峰时 CPU/GC 抖动明显。统一移除后再重建一次索引。
    while (_flows.length > maxFlows) {
      final removed = _flows.removeAt(0);
      _hostCounts[removed.host] = (_hostCounts[removed.host] ?? 1) - 1;
      if (_hostCounts[removed.host]! <= 0) _hostCounts.remove(removed.host);
    }
    _reindex();
  }

  String exportHar({bool includeBodies = true}) {
    final entries = _flows.map((f) => {
          'startedDateTime': f.startedAt.toIso8601String(),
          'time': f.durationMs ?? 0,
          'request': {
            'method': f.method,
            'url': f.url,
            'headers': [
              for (final e in f.requestHeaders.entries) {'name': e.key, 'value': e.value}
            ],
            'postData': includeBodies ? {'text': f.requestBody} : null,
          },
          'response': {
            'status': f.statusCode ?? 0,
            'headers': [
              for (final e in f.responseHeaders.entries) {'name': e.key, 'value': e.value}
            ],
            'content': includeBodies ? {'text': f.responseBody} : null,
          },
          'comment': f.error,
        });
    return CaptureFlow.encodeList(_flows, includeBodies: includeBodies).isEmpty
        ? '{"log":{"version":"1.2","creator":{"name":"CodeCraft"},"entries":[]}}'
        : '{"log":{"version":"1.2","creator":{"name":"CodeCraft"},"entries":${_listJson(entries.toList())}}}';
  }

  static String _listJson(List<Object?> list) {
    final buf = StringBuffer('[');
    for (var i = 0; i < list.length; i++) {
      if (i > 0) buf.write(',');
      buf.write(_json(list[i]));
    }
    buf.write(']');
    return buf.toString();
  }

  static String _json(Object? v) {
    if (v == null) return 'null';
    if (v is String) return '"${v.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n').replaceAll('\r', '\\r')}"';
    if (v is num || v is bool) return '$v';
    if (v is List) return _listJson(v);
    if (v is Map) {
      final buf = StringBuffer('{');
      var first = true;
      v.forEach((k, val) {
        if (!first) buf.write(',');
        first = false;
        buf.write('${_json('$k')}:${_json(val)}');
      });
      buf.write('}');
      return buf.toString();
    }
    return _json('$v');
  }
}
