import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// AI 提供商「完整请求 / 响应」日志(对齐上游 `AILogger`):**每个会话一个文件**
/// `ai-logs/session-<id>.log`,逐次记录 URL、请求体与响应,便于没有抓包工具时离线诊断。
///
/// 与 `FileLogger`(按天分文件的通用日志)相互独立:这里按会话归档、体量更大、内容更全
/// (含完整对话历史、工具定义、原始 SSE 流),因此单独成文件、单独清理。
///
/// - 请求体不含 API Key(密钥在 HTTP 头),可安全留存;
/// - 超大 base64 媒体(图片等)按 JSON 结构脱敏为占位符,避免单行几 MB 撑爆文件;
/// - 单文件超过 [maxFileBytes] 时滚动归档为 `.1`、`.2`…,保留最近 [maxArchiveFiles] 份;
/// - 写入串行化到单条后台队列,不阻塞调用方。
class AiLogger {
  AiLogger({
    required this.dir,
    this.maxFileBytes = defaultMaxFileBytes,
    this.maxArchiveFiles = defaultMaxArchiveFiles,
  });

  final Directory dir;

  /// 单个会话文件上限(超过即滚动归档)与归档份数;测试可注入小值。
  static const int defaultMaxFileBytes = 20 * 1024 * 1024;
  static const int defaultMaxArchiveFiles = 3;

  final int maxFileBytes;
  final int maxArchiveFiles;

  /// 大字段(base64 媒体)超过该长度即脱敏。
  static const int redactThreshold = 4096;

  final Map<String, IOSink> _sinks = {};
  final Map<String, int> _written = {};
  Future<void> _queue = Future<void>.value();

  /// 记录一次调用的请求(URL + body)。
  void logRequest({
    required String sessionId,
    required String url,
    required Object? body,
    String? model,
  }) {
    _append(sessionId, {
      'ts': DateTime.now().toIso8601String(),
      'event': 'request',
      if (model != null) 'model': model,
      'url': url,
      'body': redact(body),
    });
  }

  /// 记录一次调用的响应(可含原始 SSE 文本)。
  void logResponse({
    required String sessionId,
    required int statusCode,
    Object? body,
    String? rawText,
    int? elapsedMs,
  }) {
    _append(sessionId, {
      'ts': DateTime.now().toIso8601String(),
      'event': 'response',
      'status': statusCode,
      if (elapsedMs != null) 'elapsedMs': elapsedMs,
      if (body != null) 'body': redact(body),
      if (rawText != null) 'raw': truncateText(rawText),
    });
  }

  /// 记录一次失败(含上游返回的原始错误响应体)。
  void logError({
    required String sessionId,
    required String message,
    String? upstreamBody,
  }) {
    _append(sessionId, {
      'ts': DateTime.now().toIso8601String(),
      'event': 'error',
      'message': message,
      if (upstreamBody != null) 'upstreamBody': truncateText(upstreamBody),
    });
  }

  void _append(String sessionId, Map<String, Object?> record) {
    final line = jsonEncode(record);
    _queue = _queue.then((_) => _write(sessionId, '$line\n'));
  }

  String filePath(String sessionId) {
    final safe = sessionId.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    return '${dir.path}/session-$safe.log';
  }

  Future<void> _write(String sessionId, String text) async {
    try {
      await dir.create(recursive: true);
      final path = filePath(sessionId);
      var sink = _sinks[sessionId];
      if (sink == null) {
        // 文件已存在时续写并累计已写字节,保证滚动归档判断准确。
        final file = File(path);
        _written[sessionId] = file.existsSync() ? file.lengthSync() : 0;
        sink = file.openWrite(mode: FileMode.append);
        _sinks[sessionId] = sink;
      }
      sink.write(text);
      await sink.flush();
      final size = (_written[sessionId] ?? 0) + utf8.encode(text).length;
      _written[sessionId] = size;
      if (size > maxFileBytes) await _roll(sessionId);
    } catch (_) {
      // 日志写入失败不影响业务。
    }
  }

  /// 滚动归档:`session-x.log` → `.1`(旧的依次后移),只留最近 [maxArchiveFiles] 份。
  Future<void> _roll(String sessionId) async {
    final path = filePath(sessionId);
    final sink = _sinks.remove(sessionId);
    try {
      await sink?.close();
      final oldest = File('$path.$maxArchiveFiles');
      if (oldest.existsSync()) oldest.deleteSync();
      for (var index = maxArchiveFiles - 1; index >= 1; index--) {
        final from = File('$path.$index');
        if (from.existsSync()) from.renameSync('$path.${index + 1}');
      }
      final current = File(path);
      if (current.existsSync()) current.renameSync('$path.1');
      _written[sessionId] = 0;
    } catch (_) {}
  }

  /// 按 JSON 结构脱敏:字符串值超长(base64 媒体等)替换为长度占位符。
  static Object? redact(Object? value) {
    if (value is String) return truncateText(value);
    if (value is List) return [for (final item in value) redact(item)];
    if (value is Map) {
      return {
        for (final entry in value.entries) entry.key: redact(entry.value),
      };
    }
    return value;
  }

  static String truncateText(String text) =>
      text.length <= redactThreshold ? text : '<已省略 ${text.length} 字符>';

  Future<void> close() async {
    await _queue;
    for (final sink in _sinks.values) {
      await sink.flush();
      await sink.close();
    }
    _sinks.clear();
  }
}

/// 全局 AI 日志入口;未初始化时为空操作(不改变原有行为)。
class AiLog {
  AiLog._();

  static AiLogger? _logger;

  static void init(AiLogger logger) => _logger = logger;

  static AiLogger? get instance => _logger;

  /// 当前正在流式请求的会话(传输层据此归档到对应会话文件)。
  ///
  /// 用「环境值」而不是层层透传:请求体在协议层内部拼装,传输层是最省事且唯一
  /// 能看到 URL + 体 + 原始响应的位置。同一时刻只跑一条流式请求,因此不冲突。
  static String? currentSessionId;

  /// 进入一次流式请求前设置,结束后务必清空(用 [withSession] 更安全)。
  static T withSession<T>(String sessionId, T Function() body) {
    final previous = currentSessionId;
    currentSessionId = sessionId;
    try {
      return body();
    } finally {
      currentSessionId = previous;
    }
  }

  static void request({
    required String sessionId,
    required String url,
    required Object? body,
    String? model,
  }) =>
      _logger?.logRequest(sessionId: sessionId, url: url, body: body, model: model);

  static void response({
    required String sessionId,
    required int statusCode,
    Object? body,
    String? rawText,
    int? elapsedMs,
  }) =>
      _logger?.logResponse(
        sessionId: sessionId,
        statusCode: statusCode,
        body: body,
        rawText: rawText,
        elapsedMs: elapsedMs,
      );

  static void error({
    required String sessionId,
    required String message,
    String? upstreamBody,
  }) =>
      _logger?.logError(
        sessionId: sessionId,
        message: message,
        upstreamBody: upstreamBody,
      );

  @visibleForTesting
  static void reset() {
    _logger = null;
    currentSessionId = null;
  }
}