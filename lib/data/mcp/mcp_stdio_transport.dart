import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'mcp_transport.dart';

/// MCP「stdio」传输(对齐上游 StdioTransport):把 MCP server 作为长驻进程跑起来，
/// 用换行分隔的 JSON-RPC 与它的 stdin/stdout 通信。
///
/// server 直接在宿主 Termux 环境中启动，不再依赖 PRoot 容器。
class McpStdioTransport implements McpTransport {
  McpStdioTransport({
    required this.command,
    this.arguments = const [],
    this.extraEnv = const {},
    this.requestTimeout = const Duration(seconds: 30),
  });

  final String command;
  final List<String> arguments;
  final Map<String, String> extraEnv;
  final Duration requestTimeout;

  Process? _process;
  StreamSubscription<String>? _subscription;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  int _nextId = 0;

  /// 启动 server 进程并接上管道。
  Future<void> start({String? projectPath}) async {
    final shell = 'sh';
    final args = ['-c', '$command ${arguments.join(' ')}'];
    final env = {
      'PATH': '/data/data/com.termux/files/usr/bin:/system/bin:/system/xbin:/bin',
      'HOME': '/data/data/com.termux/files/home',
      'TERM': 'xterm-256color',
      'LANG': 'C.UTF-8',
      ...extraEnv,
    };
    final process = await Process.start(
      shell,
      args,
      environment: env,
      workingDirectory: projectPath,
    );
    _process = process;
    _subscription = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_onLine, onDone: _onDone, onError: (_) => _onDone());
  }

  void _onLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return;
    Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } catch (_) {
      return; // 非 JSON 行(server 自己的日志)忽略
    }
    if (decoded is! Map) return;
    final id = decoded['id'];
    final key = switch (id) {
      final int value => value,
      final num value => value.toInt(),
      _ => null,
    };
    if (key == null) return; // 通知或其它消息
    final completer = _pending.remove(key);
    if (completer != null && !completer.isCompleted) {
      completer.complete(decoded.cast<String, dynamic>());
    }
  }

  void _onDone() {
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(const McpException('MCP stdio server 已退出'));
      }
    }
    _pending.clear();
  }

  @override
  Future<Map<String, dynamic>?> request(String method, [Map<String, dynamic>? params]) async {
    final process = _process;
    if (process == null) throw const McpException('MCP stdio 传输未启动');
    final id = ++_nextId;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    process.stdin.writeln(jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    }));
    await process.stdin.flush();
    final response = await completer.future.timeout(
      requestTimeout,
      onTimeout: () {
        _pending.remove(id);
        throw McpException('调用 $method 超时(${requestTimeout.inSeconds}s)');
      },
    );
    final error = response['error'];
    if (error is Map) {
      final map = error.cast<String, dynamic>();
      throw McpException(
        '$method 返回错误:${map['message'] ?? '未知错误'}',
        rpcCode: switch (map['code']) {
          final int code => code,
          final num code => code.toInt(),
          _ => null,
        },
      );
    }
    final result = response['result'];
    return result is Map ? result.cast<String, dynamic>() : null;
  }

  @override
  Future<void> notify(String method, [Map<String, dynamic>? params]) async {
    final process = _process;
    if (process == null) return;
    try {
      process.stdin.writeln(jsonEncode({
        'jsonrpc': '2.0',
        'method': method,
        if (params != null) 'params': params,
      }));
      await process.stdin.flush();
    } catch (_) {}
  }

  @override
  void close() {
    _subscription?.cancel();
    _subscription = null;
    _process?.kill(ProcessSignal.sigkill);
    _process = null;
    _onDone();
  }
}
