import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'capture_models.dart';
import 'capture_store.dart';
import 'certificate_authority.dart';

/// 本地 HTTP(S) 代理（原始 TCP）。
/// MVP: HTTP 明文代理 + CONNECT 后对 HTTP/1.1 尝试 MITM。
/// 限制：仅覆盖经代理流量；证书锁定/不信任 CA 的 HTTPS 无法解密；HTTP/2/非 HTTP 协议不完整支持。
class CaptureProxyServer {
  CaptureProxyServer({
    required this.ca,
    required this.store,
    this.onChanged,
  });

  final CaptureCertificateAuthority ca;
  final CaptureStore store;
  final void Function()? onChanged;
  ServerSocket? _server;
  final Set<Socket> _sockets = {};
  bool get running => _server != null;
  int get port => _server?.port ?? 0;

  static const int _maxBodyBytes = 1024 * 1024;

  Future<int> start({int port = 8888, InternetAddress? address}) async {
    if (_server != null) return _server!.port;
    // 不再在这里 await CA:首次生成 2048 位 RSA 要数秒,会让「启动」明显卡住。
    // 明文请求不靠 CA,可立即拓;HTTPS 的 serverContextForHost 会自己 await 初始化。
    unawaited(ca.warmUp());
    final bindAddr = address ?? InternetAddress.anyIPv4;
    try {
      _server = await ServerSocket.bind(bindAddr, port, shared: false);
    } catch (_) {
      _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, port, shared: false);
    }
    _server!.listen(_handleClient, onError: (_) {});
    return _server!.port;
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    for (final s in _sockets.toList()) {
      try {
        s.destroy();
      } catch (_) {}
    }
    _sockets.clear();
    await server?.close();
  }

  Future<void> _handleClient(Socket client) async {
    _sockets.add(client);
    try {
      final conn = _Conn(client);
      final head = await conn.readHead(timeout: const Duration(seconds: 15));
      if (head == null) {
        await _close(client);
        return;
      }
      if (head.method.toUpperCase() == 'CONNECT') {
        await _handleConnect(conn, head);
      } else {
        await _handleHttpProxy(conn, head);
      }
    } catch (_) {
      await _close(client);
    } finally {
      _sockets.remove(client);
    }
  }

  Future<void> _handleHttpProxy(_Conn conn, _Head head) async {
    final client = conn.socket;
    final started = DateTime.now();
    final id = '${started.microsecondsSinceEpoch}-${head.target.hashCode.abs()}-${conn.hashCode}';
    Uri uri;
    try {
      uri = Uri.parse(head.target.startsWith('http')
          ? head.target
          : 'http://${head.headers['host'] ?? 'localhost'}${head.target}');
    } catch (_) {
      uri = Uri.parse('http://${head.headers['host'] ?? 'localhost'}/');
    }
    final host = uri.host.isNotEmpty ? uri.host : (head.headers['host']?.split(':').first ?? '');
    final targetPort = uri.hasPort ? uri.port : 80;
    final body = await conn.readBody(head.headers, limit: _maxBodyBytes);
    final flow = CaptureFlow(
      id: id,
      startedAt: started,
      method: head.method,
      url: uri.toString(),
      host: host,
      path: uri.path.isEmpty ? '/' : uri.path,
      scheme: 'http',
      requestHeaders: head.headers,
      requestBody: body.text,
      bodyTruncated: body.truncated,
    );
    store.add(flow);
    onChanged?.call();
    Socket? upstream;
    try {
      upstream = await Socket.connect(host, targetPort, timeout: const Duration(seconds: 15));
      _sockets.add(upstream);
      final remote = '${upstream.remoteAddress.address}:$targetPort';
      final path = uri.hasQuery ? '${uri.path}?${uri.query}' : (uri.path.isEmpty ? '/' : uri.path);
      final sb = StringBuffer('${head.method} $path HTTP/1.1\r\n');
      var wroteHost = false;
      head.headers.forEach((k, v) {
        final lk = k.toLowerCase();
        if (lk == 'proxy-connection' || lk == 'connection' || lk == 'keep-alive' || lk == 'content-length') return;
        if (lk == 'host') {
          wroteHost = true;
          sb.write('Host: ${uri.hasPort ? '${uri.host}:${uri.port}' : uri.host}\r\n');
        } else {
          sb.write('${_capHeader(k)}: $v\r\n');
        }
      });
      if (!wroteHost) sb.write('Host: ${uri.hasPort ? '$host:$targetPort' : host}\r\n');
      sb.write('Connection: close\r\n');
      sb.write('Content-Length: ${body.bytes.length}\r\n\r\n');
      upstream.add(utf8.encode(sb.toString()));
      if (body.bytes.isNotEmpty) upstream.add(body.bytes);
      await upstream.flush();
      final resp = await _readAll(upstream, limit: _maxBodyBytes * 2, timeout: const Duration(seconds: 30));
      client.add(resp);
      await client.flush();
      final parsed = _parseHttpResponse(resp);
      store.update(CaptureFlow(
        id: id,
        startedAt: started,
        endedAt: DateTime.now(),
        method: head.method,
        url: uri.toString(),
        host: host,
        path: uri.path.isEmpty ? '/' : uri.path,
        scheme: 'http',
        protocolVersion: parsed.version,
        requestHeaders: head.headers,
        requestBody: body.text,
        requestBytes: body.bytes.length,
        statusCode: parsed.status,
        responseHeaders: parsed.headers,
        responseBody: parsed.body,
        responseBytes: resp.length,
        remoteAddress: remote,
        bodyTruncated: body.truncated || parsed.truncated,
      ));
    } catch (e) {
      store.update(CaptureFlow(
        id: id,
        startedAt: started,
        endedAt: DateTime.now(),
        method: head.method,
        url: uri.toString(),
        host: host,
        path: uri.path.isEmpty ? '/' : uri.path,
        scheme: 'http',
        requestHeaders: head.headers,
        requestBody: body.text,
        error: '$e',
        bodyTruncated: body.truncated,
      ));
      try {
        client.add(utf8.encode('HTTP/1.1 502 Bad Gateway\r\nContent-Length: 0\r\nConnection: close\r\n\r\n'));
        await client.flush();
      } catch (_) {}
    }
    onChanged?.call();
    await _close(upstream);
    await _close(client);
  }

  Future<void> _handleConnect(_Conn conn, _Head head) async {
    final client = conn.socket;
    final started = DateTime.now();
    final hp = _splitHostPort(head.target, 443);
    final host = hp.$1;
    final targetPort = hp.$2;
    final id = 'connect-${started.microsecondsSinceEpoch}-$host:$targetPort';
    store.add(CaptureFlow(
      id: id, startedAt: started, method: 'CONNECT', url: '$host:$targetPort',
      host: host, path: '/', scheme: 'https', tls: true,
    ));
    onChanged?.call();
    try {
      client.add(utf8.encode('HTTP/1.1 200 Connection Established\r\n\r\n'));
      await client.flush();

      // 用一对回环 socket 做桥:SecureSocket.secureServer 需要一个从未被监听过的
      // socket,而 client 已被 _Conn 订阅。旧代码先 dispose() 再接管 client,
      // 会把接收端关掉(单订阅流),必然报 Transport endpoint is not connected,
      // 然后再 destroy client 相当于对所有 HTTPS 域名直接断网。
      final bridge = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final accepted = bridge.first;
      final bridgeClient = await Socket.connect(
        InternetAddress.loopbackIPv4,
        bridge.port,
        timeout: const Duration(seconds: 5),
      );
      // 拿到这一条连接后就可以关掉监听,不影响已建立的 socket。
      final bridgeServer = await accepted;
      unawaited(bridge.close());

      // client 剩下的字节全部转给 bridgeClient,由它喂给 SecureSocket。
      conn.forwardTo(bridgeClient);

      SecureSocket secureClient;
      try {
        final context = await ca.serverContextForHost(host);
        secureClient = await SecureSocket.secureServer(bridgeServer, context);
      } catch (e) {
        store.update(CaptureFlow(
          id: id, startedAt: started, endedAt: DateTime.now(), method: 'CONNECT',
          url: '$host:$targetPort', host: host, path: '/', scheme: 'https', tls: true,
          error: 'TLS MITM 失败: $e。请安装并信任 CA；证书锁定/非 HTTP 流量无法解密。',
        ));
        onChanged?.call();
        try { bridgeClient.destroy(); } catch (_) {}
        try { client.destroy(); } catch (_) {}
        return;
      }
      _sockets.add(secureClient);
      await _mitmOne(secureClient, host: host, targetPort: targetPort);
      _sockets.remove(secureClient);
      try { bridgeClient.destroy(); } catch (_) {}
    } catch (e) {
      store.update(CaptureFlow(
        id: id, startedAt: started, endedAt: DateTime.now(), method: 'CONNECT',
        url: '$host:$targetPort', host: host, path: '/', scheme: 'https', tls: true,
        error: '$e',
      ));
      onChanged?.call();
      try { client.destroy(); } catch (_) {}
    }
  }

  Future<void> _mitmOne(SecureSocket client, {required String host, required int targetPort}) async {
    final conn = _Conn(client);
    final head = await conn.readHead(timeout: const Duration(seconds: 20));
    if (head == null) {
      await _close(client);
      return;
    }
    final started = DateTime.now();
    final body = await conn.readBody(head.headers, limit: _maxBodyBytes);
    final url = 'https://$host${head.target}';
    final flowId = '${started.microsecondsSinceEpoch}-${head.method}-${head.target.hashCode.abs()}';
    store.add(CaptureFlow(
      id: flowId, startedAt: started, method: head.method, url: url, host: host,
      path: head.target.split('?').first, scheme: 'https', requestHeaders: head.headers,
      requestBody: body.text, requestBytes: body.bytes.length,
      bodyTruncated: body.truncated, tls: true,
    ));
    onChanged?.call();
    SecureSocket? upstream;
    try {
      upstream = await SecureSocket.connect(host, targetPort, timeout: const Duration(seconds: 15));
      _sockets.add(upstream);
      final remote = '${upstream.remoteAddress.address}:$targetPort';
      final sb = StringBuffer('${head.method} ${head.target} HTTP/1.1\r\n');
      head.headers.forEach((k, v) {
        final lk = k.toLowerCase();
        if (lk == 'proxy-connection' || lk == 'content-length') return;
        if (lk == 'connection') { sb.write('Connection: close\r\n'); return; }
        sb.write('${_capHeader(k)}: $v\r\n');
      });
      if (!head.headers.keys.any((k) => k.toLowerCase() == 'connection')) sb.write('Connection: close\r\n');
      sb.write('Content-Length: ${body.bytes.length}\r\n\r\n');
      upstream.add(utf8.encode(sb.toString()));
      if (body.bytes.isNotEmpty) upstream.add(body.bytes);
      await upstream.flush();
      final resp = await _readAll(upstream, limit: _maxBodyBytes * 2, timeout: const Duration(seconds: 30));
      client.add(resp);
      await client.flush();
      final parsed = _parseHttpResponse(resp);
      store.update(CaptureFlow(
        id: flowId, startedAt: started, endedAt: DateTime.now(), method: head.method, url: url,
        host: host, path: head.target.split('?').first, scheme: 'https',
        protocolVersion: parsed.version,
        requestHeaders: head.headers, requestBody: body.text,
        requestBytes: body.bytes.length,
        statusCode: parsed.status,
        responseHeaders: parsed.headers, responseBody: parsed.body,
        responseBytes: resp.length, remoteAddress: remote,
        bodyTruncated: body.truncated || parsed.truncated, tls: true,
      ));
    } catch (e) {
      store.update(CaptureFlow(
        id: flowId, startedAt: started, endedAt: DateTime.now(), method: head.method, url: url,
        host: host, path: head.target.split('?').first, scheme: 'https', tls: true, error: '$e',
      ));
      try {
        client.add(utf8.encode('HTTP/1.1 502 Bad Gateway\r\nContent-Length: 0\r\nConnection: close\r\n\r\n'));
        await client.flush();
      } catch (_) {}
    }
    onChanged?.call();
    await _close(upstream);
    await _close(client);
  }

  (String, int) _splitHostPort(String target, int defaultPort) {
    if (target.startsWith('[')) {
      final end = target.indexOf(']');
      if (end > 0) {
        final host = target.substring(1, end);
        final rest = target.substring(end + 1);
        if (rest.startsWith(':')) return (host, int.tryParse(rest.substring(1)) ?? defaultPort);
        return (host, defaultPort);
      }
    }
    final idx = target.lastIndexOf(':');
    if (idx > 0) return (target.substring(0, idx), int.tryParse(target.substring(idx + 1)) ?? defaultPort);
    return (target, defaultPort);
  }

  String _capHeader(String k) => k.split('-').map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}').join('-');

  Future<void> _close(Socket? s) async {
    if (s == null) return;
    _sockets.remove(s);
    try { await s.flush(); } catch (_) {}
    try { await s.close(); } catch (_) { try { s.destroy(); } catch (_) {} }
  }

  _ParsedResp _parseHttpResponse(Uint8List data) {
    final idx = _indexOfBytes(data, const [13, 10, 13, 10]);
    if (idx < 0) return _ParsedResp(null, const {}, '', false, 'HTTP/1.1');
    final head = utf8.decode(data.sublist(0, idx), allowMalformed: true);
    final lines = const LineSplitter().convert(head).toList();
    int? status;
    var version = 'HTTP/1.1';
    if (lines.isNotEmpty) {
      final parts = lines.first.split(' ');
      if (parts.length >= 2) {
        version = parts.first;
        status = int.tryParse(parts[1]);
      }
    }
    final headers = <String, String>{};
    for (final line in lines.skip(1)) {
      final i = line.indexOf(':');
      if (i <= 0) continue;
      final name = line.substring(0, i).trim().toLowerCase();
      final value = line.substring(i + 1).trim();
      // Set-Cookie 会重复出现且必须逐条保留:丢掉任何一条都会让 Cookies 页少一项。
      final existing = headers[name];
      headers[name] = existing == null ? value : '$existing\n$value';
    }
    final (body, trunc) = _decodeBody(Uint8List.fromList(data.sublist(idx + 4)));
    return _ParsedResp(status, headers, body, trunc, version);
  }

  int _indexOfBytes(List<int> data, List<int> pattern) {
    outer:
    for (var i = 0; i <= data.length - pattern.length; i++) {
      for (var j = 0; j < pattern.length; j++) {
        if (data[i + j] != pattern[j]) continue outer;
      }
      return i;
    }
    return -1;
  }

  Future<Uint8List> _readAll(Socket socket, {required int limit, required Duration timeout}) async {
    final b = BytesBuilder(copy: false);
    try {
      await for (final chunk in socket.timeout(timeout, onTimeout: (sink) => sink.close())) {
        if (b.length < limit) {
          final remain = limit - b.length;
          b.add(chunk.length > remain ? chunk.sublist(0, remain) : chunk);
        }
      }
    } catch (_) {}
    return b.toBytes();
  }

  (String, bool) _decodeBody(Uint8List bytes) {
    if (bytes.isEmpty) return ('', false);
    var non = 0;
    final sample = bytes.length > 512 ? bytes.sublist(0, 512) : bytes;
    for (final x in sample) {
      if (x < 9 || (x > 13 && x < 32)) non++;
    }
    if (non > 32) {
      final b64 = base64.encode(bytes.length > 4096 ? bytes.sublist(0, 4096) : bytes);
      return ('[binary ${bytes.length} bytes, base64]\n$b64${bytes.length > 4096 ? '\n…truncated' : ''}', bytes.length > 4096);
    }
    final text = utf8.decode(bytes, allowMalformed: true);
    if (text.length > 200000) return ('${text.substring(0, 200000)}\n…truncated', true);
    return (text, false);
  }
}

class _Conn {
  _Conn(this.socket) {
    _sub = socket.listen(
      (d) {
        final target = _forwardTarget;
        if (target != null) {
          try { target.add(d); } catch (_) {}
        } else {
          _queue.add(d);
        }
      },
      onError: (_) => _queue.add(null),
      onDone: () {
        if (_forwardTarget != null) {
          try { _forwardTarget!.close(); } catch (_) {}
        } else {
          _queue.add(null);
        }
      },
    );
  }
  final Socket socket;
  late final StreamSubscription<List<int>> _sub;
  final List<List<int>?> _queue = [];
  final List<int> _buf = [];
  Completer<void>? _waiter;
  bool _done = false;

  /// 设为非空后,后续收到的字节直接转给这个 Socket 而不是进队列。
  /// 用于 CONNECT 之后把已订阅的客户端流交给新的处理方。
  Socket? _forwardTarget;

  /// 把已缓冲的数据和之后的所有字节都转给 [dest]。
  ///
  /// 不能在外部用「取消订阅 + 重新 listen」的方式接手 socket:
  /// Dart 的 Socket 是单订阅流,取消订阅会把接收端一并关掉,
  /// 之后 SecureSocket.secureServer 再接管就会报 Transport endpoint is not connected。
  void forwardTo(Socket dest) {
    if (_buf.isNotEmpty) {
      try { dest.add(Uint8List.fromList(_buf)); } catch (_) {}
      _buf.clear();
    }
    for (final item in _queue) {
      if (item == null) continue;
      try { dest.add(item); } catch (_) {}
    }
    _queue.clear();
    _forwardTarget = dest;
  }

  Future<void> _pump() async {
    while (true) {
      if (_done) return;
      if (_queue.isNotEmpty) {
        final item = _queue.removeAt(0);
        if (item == null) { _done = true; _waiter?.complete(); _waiter = null; return; }
        _buf.addAll(item);
        _waiter?.complete(); _waiter = null;
        return;
      }
      _waiter ??= Completer<void>();
      await _waiter!.future;
      _waiter = null;
    }
  }

  Future<bool> _ensure(int need, Duration timeout) async {
    final deadline = DateTime.now().add(timeout);
    while (_buf.length < need && !_done) {
      final remain = deadline.difference(DateTime.now());
      if (remain.isNegative) return false;
      _pump();
      if (_waiter == null) continue;
      await _waiter!.future.timeout(remain, onTimeout: () {});
    }
    return _buf.length >= need;
  }

  Future<_Head?> readHead({required Duration timeout}) async {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      final idx = _indexOfBytes(_buf, const [13, 10, 13, 10]);
      if (idx >= 0) {
        final headText = utf8.decode(_buf.sublist(0, idx), allowMalformed: true);
        final rest = _buf.sublist(idx + 4);
        _buf
          ..clear()
          ..addAll(rest);
        final lines = const LineSplitter().convert(headText).toList();
        if (lines.isEmpty) return null;
        final parts = lines.first.split(' ');
        if (parts.length < 2) return null;
        final headers = <String, String>{};
        for (final line in lines.skip(1)) {
          final i = line.indexOf(':');
          if (i <= 0) continue;
          headers[line.substring(0, i).trim().toLowerCase()] = line.substring(i + 1).trim();
        }
        return _Head(parts[0], parts[1], headers);
      }
      if (_done || DateTime.now().isAfter(deadline) || _buf.length > 1024 * 1024) return null;
      await _ensure(_buf.length + 1, deadline.difference(DateTime.now()));
    }
  }

  Future<_Body> readBody(Map<String, String> headers, {required int limit}) async {
    final cl = int.tryParse(headers['content-length'] ?? '') ?? 0;
    if (cl <= 0) return _Body(Uint8List(0), '', false);
    final want = cl.clamp(0, limit);
    final ok = await _ensure(want, const Duration(seconds: 20));
    final take = _buf.length >= want ? want : _buf.length;
    final bytes = Uint8List.fromList(_buf.sublist(0, take));
    _buf.removeRange(0, take);
    final (t, tr) = _decodeBody(bytes);
    return _Body(bytes, t, tr || cl > limit || (!ok && bytes.length < cl));
  }

  int _indexOfBytes(List<int> data, List<int> pattern) {
    outer:
    for (var i = 0; i <= data.length - pattern.length; i++) {
      for (var j = 0; j < pattern.length; j++) {
        if (data[i + j] != pattern[j]) continue outer;
      }
      return i;
    }
    return -1;
  }

  (String, bool) _decodeBody(Uint8List bytes) {
    if (bytes.isEmpty) return ('', false);
    var non = 0;
    final sample = bytes.length > 512 ? bytes.sublist(0, 512) : bytes;
    for (final x in sample) {
      if (x < 9 || (x > 13 && x < 32)) non++;
    }
    if (non > 32) {
      final b64 = base64.encode(bytes.length > 4096 ? bytes.sublist(0, 4096) : bytes);
      return ('[binary ${bytes.length} bytes, base64]\n$b64${bytes.length > 4096 ? '\n…truncated' : ''}', bytes.length > 4096);
    }
    final text = utf8.decode(bytes, allowMalformed: true);
    if (text.length > 200000) return ('${text.substring(0, 200000)}\n…truncated', true);
    return (text, false);
  }

  void dispose() {
    try { _sub.cancel(); } catch (_) {}
  }
}

class _ParsedResp {
  const _ParsedResp(this.status, this.headers, this.body, this.truncated, this.version);
  final int? status;
  final Map<String, String> headers;
  final String body;
  final bool truncated;
  final String version;
}

class _Head {
  const _Head(this.method, this.target, this.headers);
  final String method;
  final String target;
  final Map<String, String> headers;
}

class _Body {
  const _Body(this.bytes, this.text, this.truncated);
  final Uint8List bytes;
  final String text;
  final bool truncated;
}
