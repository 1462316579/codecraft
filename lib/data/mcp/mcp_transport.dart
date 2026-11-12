import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

/// MCP / JSON-RPC 异常:携带 RPC 错误码(有的话)。
class McpException implements Exception {
  const McpException(this.message, {this.rpcCode});

  final String message;
  final int? rpcCode;

  @override
  String toString() => rpcCode == null ? message : '[$rpcCode] $message';
}

/// 服务器要求鉴权(HTTP 401):上层展示「需要登录」并由用户补自定义请求头。
class McpAuthRequiredException extends McpException {
  const McpAuthRequiredException(super.message);
}

/// MCP 传输层(对齐上游 McpTransport):一问一答的 JSON-RPC 收发 + 单向通知。
abstract class McpTransport {
  Future<Map<String, dynamic>?> request(String method, [Map<String, dynamic>? params]);

  Future<void> notify(String method, [Map<String, dynamic>? params]);

  void close();
}

/// MCP「Streamable HTTP」传输(对齐上游 StreamableHttpTransport):
/// 单一端点 POST JSON-RPC;响应可能是 `application/json`(单条)或 `text/event-stream`
/// (SSE,取第一个 data 负载即可,本传输不维持服务端推送通道)。
/// `initialize` 响应里的 `Mcp-Session-Id` 会被记下,之后每条请求都带上。
class McpHttpTransport implements McpTransport {
  McpHttpTransport({
    required this.endpoint,
    Map<String, String> headers = const {},
    String? Function()? authorizationProvider,
    Dio? dio,
    Duration requestTimeout = const Duration(seconds: 20),
    Duration connectTimeout = const Duration(seconds: 15),
  })  : _headers = headers,
        _authorizationProvider = authorizationProvider,
        _dio = dio ??
            Dio(BaseOptions(
              validateStatus: (_) => true,
              connectTimeout: connectTimeout,
              headers: const {'User-Agent': 'Codecraft'},
            )),
        _requestTimeout = requestTimeout;

  final String endpoint;
  final Map<String, String> _headers;

  /// OAuth 令牌提供者:用户显式配了 Authorization 头时不覆盖(对齐上游)。
  final String? Function()? _authorizationProvider;
  final Dio _dio;
  final Duration _requestTimeout;

  int _nextId = 0;
  String? _sessionId;

  @override
  Future<Map<String, dynamic>?> request(String method, [Map<String, dynamic>? params]) async {
    final id = ++_nextId;
    final payload = <String, dynamic>{
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    };
    final token = CancelToken();
    final response = await _post(jsonEncode(payload), token);
    _sessionId = response.headers.value('mcp-session-id')?.trim().isNotEmpty == true
        ? response.headers.value('mcp-session-id')!.trim()
        : _sessionId;

    if (response.statusCode == 401) {
      throw const McpAuthRequiredException('服务器要求登录授权(HTTP 401)');
    }
    if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
      throw McpException('HTTP ${response.statusCode} 调用 $method 失败');
    }

    final contentType = response.headers.value('content-type') ?? '';
    final isSse = contentType.toLowerCase().contains('text/event-stream');
    final raw = await _readPayload(response, token: token, isSse: isSse);
    if (raw.trim().isEmpty) throw McpException('$method 响应体为空');

    final decoded = _decodeJson(raw, method);
    final error = decoded['error'];
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
    final result = decoded['result'];
    return result is Map ? result.cast<String, dynamic>() : null;
  }

  @override
  Future<void> notify(String method, [Map<String, dynamic>? params]) async {
    final payload = <String, dynamic>{
      'jsonrpc': '2.0',
      'method': method,
      if (params != null) 'params': params,
    };
    try {
      // 通知按 spec 服务端通常返回 202 且无 body;失败不阻断流程。
      await _post(jsonEncode(payload), CancelToken());
    } catch (_) {}
  }

  @override
  void close() {
    _sessionId = null;
  }

  Future<Response<ResponseBody>> _post(String body, CancelToken token) {
    return _dio
        .post<ResponseBody>(
          endpoint,
          data: body,
          cancelToken: token,
          options: Options(
            responseType: ResponseType.stream,
            contentType: Headers.jsonContentType,
            // 同时接受两种响应,让 server 自行决定单条 JSON 还是 SSE。
            headers: {
              'Accept': 'application/json, text/event-stream',
              if (_sessionId != null) 'Mcp-Session-Id': _sessionId,
              // 用户显式配了 Authorization 时优先,不覆盖。
              if (!_headers.keys.any((key) => key.toLowerCase() == 'authorization'))
                if (_authorizationProvider?.call() case final token? when token.isNotEmpty)
                  'Authorization': 'Bearer $token',
              ..._headers,
            },
          ),
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw McpException('请求 $endpoint 超时(${_requestTimeout.inSeconds}s)'),
        );
  }

  /// 读取响应负载:JSON 读完整流;SSE 读到第一个完整事件(data 行)即返回。
  Future<String> _readPayload(
    Response<ResponseBody> response, {
    required CancelToken token,
    required bool isSse,
  }) async {
    final stream = response.data?.stream;
    if (stream == null) return '';
    final buffer = StringBuffer();
    await for (final chunk in stream.cast<List<int>>().transform(utf8.decoder)) {
      buffer.write(chunk);
      if (!isSse) continue;
      final payload = _firstSseData(buffer.toString());
      if (payload != null) {
        // 一问一答:拿到响应就断开,不维持服务端推送通道。
        if (!token.isCancelled) token.cancel('已取得响应');
        return payload;
      }
    }
    // 有些实现不发结束空行就关闭连接:这时也把已收到的 data 当作响应。
    if (isSse) return _firstSseData(buffer.toString(), allowUnterminated: true) ?? '';
    return buffer.toString();
  }

  /// 取 SSE 流里第一个事件的 data 负载(多行 data 属于同一事件,按规范以换行连接)。
  static String? _firstSseData(String text, {bool allowUnterminated = false}) {
    final lines = const LineSplitter().convert(text);
    final data = StringBuffer();
    for (final line in lines) {
      if (line.startsWith('data:')) {
        data.write(line.substring(5).trim());
        data.write('\n');
      } else if (line.trim().isEmpty && data.isNotEmpty) {
        return data.toString().trimRight();
      }
    }
    if (allowUnterminated && data.isNotEmpty) return data.toString().trimRight();
    return null;
  }

  Map<String, dynamic> _decodeJson(String raw, String method) {
    try {
      final decoded = jsonDecode(raw.trim());
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {}
    throw McpException('$method 响应不是合法 JSON-RPC 消息');
  }
}