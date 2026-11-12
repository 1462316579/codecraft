import 'dart:convert';

/// 单条抓包记录。
class CaptureFlow {
  CaptureFlow({
    required this.id,
    required this.startedAt,
    required this.method,
    required this.url,
    required this.host,
    required this.path,
    this.scheme = 'http',
    this.protocolVersion = 'HTTP/1.1',
    this.requestHeaders = const {},
    this.requestBody = '',
    this.requestBytes = 0,
    this.statusCode,
    this.responseHeaders = const {},
    this.responseBody = '',
    this.responseBytes = 0,
    this.remoteAddress,
    this.error,
    this.endedAt,
    this.bodyTruncated = false,
    this.tls = false,
  });

  final String id;
  final DateTime startedAt;
  final String method;
  final String url;
  final String host;
  final String path;
  final String scheme;
  final String protocolVersion;
  final Map<String, String> requestHeaders;
  final String requestBody;
  final int requestBytes;
  final int? statusCode;
  final Map<String, String> responseHeaders;
  final String responseBody;
  final int responseBytes;

  /// 「IP:端口」形式的上游地址;直连未建立时为 null。
  final String? remoteAddress;
  final String? error;
  final DateTime? endedAt;
  final bool bodyTruncated;
  final bool tls;

  int? get durationMs =>
      endedAt == null ? null : endedAt!.difference(startedAt).inMilliseconds;

  /// 响应体的 Content-Type(去掉参数),用于列表副标题与详情分区展示。
  String get contentType {
    final raw = responseHeaders['content-type'] ?? requestHeaders['content-type'] ?? '';
    return raw.split(';').first.trim().toLowerCase();
  }

  /// 响应头里的 Set-Cookie 列表(Cookies tab 用)。
  List<String> get responseCookies =>
      (responseHeaders['set-cookie'] ?? '')
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

  /// 请求头里的 Cookie 条目(Cookies tab 用)。
  List<String> get requestCookies =>
      (requestHeaders['cookie'] ?? '')
          .split(';')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

  Map<String, Object?> toJson({bool includeBodies = true}) => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'durationMs': durationMs,
        'method': method,
        'scheme': scheme,
        'protocolVersion': protocolVersion,
        'url': url,
        'host': host,
        'path': path,
        'tls': tls,
        'remoteAddress': remoteAddress,
        'requestHeaders': requestHeaders,
        'requestBytes': requestBytes,
        if (includeBodies) 'requestBody': requestBody,
        'statusCode': statusCode,
        'responseHeaders': responseHeaders,
        'responseBytes': responseBytes,
        if (includeBodies) 'responseBody': responseBody,
        'error': error,
        'bodyTruncated': bodyTruncated,
      };

  static String encodeList(List<CaptureFlow> flows, {bool includeBodies = true}) =>
      const JsonEncoder.withIndent('  ')
          .convert(flows.map((f) => f.toJson(includeBodies: includeBodies)).toList());
}

/// 域名汇总：该域名下的请求条数与最近一次请求时间。
class CaptureHostSummary {
  CaptureHostSummary({
    required this.host,
    required this.count,
    required this.lastAt,
  });

  final String host;
  int count;
  DateTime lastAt;
}
/// 抓包运行状态。
class CaptureState {
  const CaptureState({
    this.running = false,
    this.port = 0,
    this.flowCount = 0,
    this.caReady = false,
    this.caPath,
    this.error,
  });

  final bool running;
  final int port;
  final int flowCount;
  final bool caReady;
  final String? caPath;
  final String? error;

  CaptureState copyWith({
    bool? running,
    int? port,
    int? flowCount,
    bool? caReady,
    String? caPath,
    String? Function()? error,
  }) =>
      CaptureState(
        running: running ?? this.running,
        port: port ?? this.port,
        flowCount: flowCount ?? this.flowCount,
        caReady: caReady ?? this.caReady,
        caPath: caPath ?? this.caPath,
        error: error != null ? error() : this.error,
      );
}
