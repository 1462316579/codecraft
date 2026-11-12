import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/log/ai_logger.dart';
import 'errors.dart';

/// 流式传输抽象:便于客户端单测注入假实现。
abstract class SseTransport {
  Stream<String> postSseLines({
    required String url,
    required Map<String, dynamic> body,
    required Map<String, String> headers,
    Duration? idleTimeout,
    CancelToken? cancelToken,
  });
}

/// HTTP 流式传输:单次尝试的 SSE 行流(重试策略由上层组合)。
///
/// 与原仓库 RetryPolicy 相比做了简化:这里只负责「发请求 + 按行读出响应体」,
/// 空闲/首字节超时由 dio 的 receiveTimeout 统一承担,重试只在尚未产出任何内容时进行
/// (见 llm_client.dart 的 runWithRetry)。
class HttpTransport implements SseTransport {
  HttpTransport([Dio? dio]) : _dio = dio ?? Dio();

  final Dio _dio;

  /// 发起流式 POST,返回按行切分的响应体流。非 2xx 时读取响应体并抛 [LlmHttpException]。
  @override
  Stream<String> postSseLines({
    required String url,
    required Map<String, dynamic> body,
    required Map<String, String> headers,
    Duration? idleTimeout,
    CancelToken? cancelToken,
  }) async* {
    // AI 请求日志:URL + 请求体(不含 API Key,密钥只在 headers)与原始响应流。
    final logSession = AiLog.currentSessionId;
    final startedAt = DateTime.now();
    if (logSession != null) {
      AiLog.request(sessionId: logSession, url: url, body: body);
    }

    late final Response<ResponseBody> response;
    try {
      response = await _dio.post<ResponseBody>(
        url,
        data: jsonEncode(body),
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            ...headers,
            'Content-Type': 'application/json',
            // 手动保留响应体原样:SSE 不需要压缩,避免流式解压带来的边界问题
            'Accept-Encoding': 'identity',
          },
          receiveTimeout: idleTimeout,
          sendTimeout: const Duration(seconds: 60),
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      final message = dioMessage(e);
      if (logSession != null) {
        AiLog.error(
          sessionId: logSession,
          message: message,
          upstreamBody: e.response?.data is String ? e.response!.data as String : null,
        );
      }
      throw LlmNetworkException(message);
    }

    final status = response.statusCode ?? 0;
    final byteStream = response.data!.stream;
    if (status < 200 || status >= 300) {
      final errorBody = await _readAll(byteStream);
      if (logSession != null) {
        AiLog.response(
          sessionId: logSession,
          statusCode: status,
          rawText: errorBody,
          elapsedMs: DateTime.now().difference(startedAt).inMilliseconds,
        );
      }
      throw LlmHttpException(status, errorBody);
    }

    // 原始 SSE 也落盘:诊断流式解析问题时这是唯一可回看的东西。
    final raw = StringBuffer();
    await for (final line in byteStream
        .map<List<int>>((chunk) => chunk)
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())) {
      if (logSession != null) {
        raw.write(line);
        raw.write('\n');
      }
      yield line;
    }
    if (logSession != null) {
      AiLog.response(
        sessionId: logSession,
        statusCode: status,
        rawText: raw.toString(),
        elapsedMs: DateTime.now().difference(startedAt).inMilliseconds,
      );
    }
  }

  static Future<String> _readAll(Stream<List<int>> stream) async {
    final buffer = StringBuffer();
    await for (final chunk in stream) {
      buffer.write(const Utf8Decoder(allowMalformed: true).convert(chunk));
      if (buffer.length > 8192) break;
    }
    return buffer.toString();
  }

  static String dioMessage(DioException e) {
    final inner = e.error;
    return switch (e.type) {
      DioExceptionType.connectionTimeout => '连接超时',
      DioExceptionType.sendTimeout => '发送超时',
      DioExceptionType.receiveTimeout => '接收超时(长时间无数据)',
      DioExceptionType.badCertificate => '证书校验失败',
      DioExceptionType.connectionError => '网络连接失败${inner == null ? '' : ':$inner'}',
      _ => '网络错误:${e.message ?? e.type.name}',
    };
  }
}