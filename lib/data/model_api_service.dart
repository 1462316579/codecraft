import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/models/model_metadata.dart';
import '../agent/protocols/http_transport.dart';
import '../agent/protocols/url_utils.dart';
import 'providers/provider_config.dart';

/// 拉取模型列表的结果(对齐上游 FetchModelsResult):模型列表 + 完整调试信息。
class FetchModelsResult {
  const FetchModelsResult(this.models, this.debugInfo, {this.metadata = const {}});

  final List<String> models;
  final ModelTestResult debugInfo;

  /// 服务端在 `/models` 里声明的窗口与能力(只含真正返回了信息的模型)。
  ///
  /// 聚合类供应商(OpenRouter 等)会带 `context_length` / `max_completion_tokens`,
  /// 有这些就能显示真实上下文,而不是兜底默认值。
  final Map<String, ModelMetadata> metadata;
}

/// 模型连通性测试 / 拉取模型的调试信息(对齐上游 ModelTestResult)。
class ModelTestResult {
  const ModelTestResult({
    required this.success,
    required this.latencyMs,
    required this.message,
    this.requestUrl = '',
    this.requestHeaders = const {},
    this.requestBody = '',
    this.responseCode = 0,
    this.responseHeaders = const {},
    this.responseBody = '',
    this.errorDetail = '',
  });

  final bool success;
  final int latencyMs;
  final String message;
  final String requestUrl;
  final Map<String, String> requestHeaders;
  final String requestBody;
  final int responseCode;
  final Map<String, String> responseHeaders;
  final String responseBody;
  final String errorDetail;
}

class FetchModelsException implements Exception {
  const FetchModelsException(this.message, this.debugInfo);

  final String message;
  final ModelTestResult? debugInfo;

  @override
  String toString() => message;
}

/// 直接调用提供商的 REST 接口拉取模型列表 / 测试连通性,
/// 与聊天用的 SSE 通道相互独立(对齐上游 ModelApiService)。
class ModelApiService {
  ModelApiService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              responseType: ResponseType.plain,
              // 没有超时的请求会无限等:拉取模型的弹层会永远停在骨架屏。
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
            ));

  final Dio _dio;

  /// 拉取模型列表:OpenAI 兼容与 Anthropic 走 `v1/models`,Gemini 走 `v1beta/models`。
  Future<FetchModelsResult> fetchModels({
    required ProviderConfig provider,
    required String apiKey,
    String messageForKeyMissing = '请先填写 API Key',
    String messageMissingFields = '响应缺少列表字段',
    String messageFailed = '拉取模型失败',
  }) async {
    final start = DateTime.now();
    if (apiKey.trim().isEmpty) {
      throw FetchModelsException(messageForKeyMissing, null);
    }
    final path = provider.type == ProviderType.gemini ? 'v1beta/models' : 'v1/models';
    final url = provider.useFullUrl ? provider.baseUrl : joinUrl(provider.baseUrl, path);
    final headers = {
      ...authHeaders(provider.type, apiKey),
      ...provider.resolvedHeaders(),
    };
    try {
      final response = await _dio.get<String>(
        url,
        options: Options(
          headers: headers,
          validateStatus: (_) => true,
          responseType: ResponseType.plain,
        ),
      );
      final latency = DateTime.now().difference(start).inMilliseconds;
      final body = response.data ?? '';
      final code = response.statusCode ?? 0;
      final debugBase = ModelTestResult(
        success: code >= 200 && code < 300,
        latencyMs: latency,
        message: '',
        requestUrl: url,
        requestHeaders: _maskHeaders(headers),
        responseCode: code,
        responseHeaders: _responseHeaders(response),
        responseBody: body,
      );
      if (code < 200 || code >= 300) {
        throw FetchModelsException(
          'HTTP $code: ${_take(body, 200)}',
          ModelTestResult(
            success: false,
            latencyMs: latency,
            message: 'HTTP $code: ${_take(body, 160)}',
            requestUrl: url,
            requestHeaders: debugBase.requestHeaders,
            responseCode: code,
            responseHeaders: debugBase.responseHeaders,
            responseBody: body,
            errorDetail: body,
          ),
        );
      }

      final models = parseModelsBody(body, provider.type);
      if (models == null) {
        throw FetchModelsException(
          messageMissingFields,
          ModelTestResult(
            success: false,
            latencyMs: latency,
            message: messageMissingFields,
            requestUrl: url,
            requestHeaders: debugBase.requestHeaders,
            responseCode: code,
            responseHeaders: debugBase.responseHeaders,
            responseBody: body,
            errorDetail: '$messageMissingFields: ${_take(body, 300)}',
          ),
        );
      }
      return FetchModelsResult(
        models,
        ModelTestResult(
          success: true,
          latencyMs: latency,
          message: '成功拉取到 ${models.length} 个模型 · ${latency}ms',
          requestUrl: url,
          requestHeaders: debugBase.requestHeaders,
          responseCode: code,
          responseHeaders: debugBase.responseHeaders,
          responseBody: body,
        ),
        metadata: parseModelsMetadata(body, provider.type),
      );
    } on FetchModelsException {
      rethrow;
    } on DioException catch (error) {
      final latency = DateTime.now().difference(start).inMilliseconds;
      throw FetchModelsException(
        HttpTransport.dioMessage(error),
        ModelTestResult(
          success: false,
          latencyMs: latency,
          message: HttpTransport.dioMessage(error),
          requestUrl: url,
          requestHeaders: _maskHeaders(headers),
          errorDetail: '$error',
        ),
      );
    }
  }

  /// 发送一条极短请求验证 Key + 模型 + 端点是否可用(对齐上游 testModel)。
  Future<ModelTestResult> testModel({
    required ProviderConfig provider,
    required String apiKey,
    required String model,
    String messageForKeyMissing = '请先填写 API Key',
  }) async {
    final start = DateTime.now();
    if (apiKey.trim().isEmpty) {
      return ModelTestResult(
        success: false,
        latencyMs: 0,
        message: messageForKeyMissing,
      );
    }
    final (url, payload) = _testRequest(provider, model);
    final headers = {
      ...authHeaders(provider.type, apiKey),
      'Content-Type': 'application/json',
      ...provider.resolvedHeaders(),
    };
    try {
      final response = await _dio.post<String>(
        url,
        data: payload,
        options: Options(
          headers: headers,
          validateStatus: (_) => true,
          responseType: ResponseType.plain,
        ),
      );
      final latency = DateTime.now().difference(start).inMilliseconds;
      final body = response.data ?? '';
      final code = response.statusCode ?? 0;
      final success = code >= 200 && code < 300;
      return ModelTestResult(
        success: success,
        latencyMs: latency,
        message: success ? '连接正常 · ${latency}ms' : 'HTTP $code: ${_take(body, 160)}',
        requestUrl: url,
        requestHeaders: _maskHeaders(headers),
        requestBody: payload,
        responseCode: code,
        responseHeaders: _responseHeaders(response),
        responseBody: body,
        errorDetail: success ? '' : body,
      );
    } on DioException catch (error) {
      final message = HttpTransport.dioMessage(error);
      return ModelTestResult(
        success: false,
        latencyMs: DateTime.now().difference(start).inMilliseconds,
        message: message,
        requestUrl: url,
        requestHeaders: _maskHeaders(headers),
        requestBody: payload,
        errorDetail: '$error',
      );
    } catch (error) {
      return ModelTestResult(
        success: false,
        latencyMs: DateTime.now().difference(start).inMilliseconds,
        message: '$error',
        requestUrl: url,
        requestHeaders: _maskHeaders(headers),
        requestBody: payload,
        errorDetail: '$error',
      );
    }
  }

  /// 各家协议的最小可用请求(对齐上游 testModel 的请求体构造)。
  (String, String) _testRequest(ProviderConfig provider, String model) {
    final jsonModel = jsonEncode(model);
    return switch (provider.type) {
      ProviderType.anthropic => (
          provider.useFullUrl ? provider.baseUrl : joinUrl(provider.baseUrl, 'v1/messages'),
          '{"model":$jsonModel,"max_tokens":1,"messages":[{"role":"user","content":"hi"}]}',
        ),
      ProviderType.gemini => (
          provider.baseUrl.replaceAll(RegExp(r'/+$'), '').endsWith(model)
              ? '${provider.baseUrl.replaceAll(RegExp(r'/+$'), '')}:generateContent'
              : provider.useFullUrl
                  ? provider.baseUrl
                  : joinUrl(provider.baseUrl, 'v1beta/models/$model:generateContent'),
          '{"contents":[{"role":"user","parts":[{"text":"hi"}]}]}',
        ),
      ProviderType.openai => (
          provider.useFullUrl
              ? provider.baseUrl
              : joinUrl(provider.baseUrl, 'v1/chat/completions'),
          '{"model":$jsonModel,"max_completion_tokens":1,"messages":[{"role":"user","content":"hi"}]}',
        ),
    };
  }

  /// 各协议的鉴权头(自定义请求头在其后覆盖同名项)。
  static Map<String, String> authHeaders(ProviderType type, String apiKey) => switch (type) {
        ProviderType.anthropic => {'x-api-key': apiKey, 'anthropic-version': '2023-06-01'},
        ProviderType.gemini => {'x-goog-api-key': apiKey},
        ProviderType.openai => {'Authorization': 'Bearer $apiKey'},
      };

  /// 从响应体解析模型 id;结构不符返回 null。
  /// OpenAI 兼容取 `data[].id`,Gemini 取 `models[].name` 并去掉 `models/` 前缀。
  static List<String>? parseModelsBody(String body, ProviderType type) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      final list = type == ProviderType.gemini ? decoded['models'] : decoded['data'];
      if (list is! List) return null;
      final models = <String>[];
      for (final item in list) {
        if (item is! Map) continue;
        final raw = type == ProviderType.gemini ? item['name'] : item['id'];
        if (raw is! String) continue;
        final name = type == ProviderType.gemini ? raw.replaceFirst('models/', '') : raw;
        if (name.trim().isNotEmpty) models.add(name.trim());
      }
      models.sort();
      return models;
    } catch (_) {
      return null;
    }
  }

  /// 从 `/models` 响应体里解析上下文窗口与最大输出;只收录服务端真正返回了数值的模型。
  ///
  /// 兼容常见的几种写法:
  /// - 聚合站(OpenRouter 等):`context_length`、`top_provider.max_completion_tokens`
  /// - 通用:`context_window` / `max_context_length` / `max_output_tokens` / `limit.context`
  /// - Gemini:`inputTokenLimit` / `outputTokenLimit`
  ///
  /// 只取窗口数字,能力标签仍交给内置目录判断——避免把「服务端没声明」误当成「不支持」。
  static Map<String, ModelMetadata> parseModelsMetadata(String body, ProviderType type) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return const {};
      final list = type == ProviderType.gemini ? decoded['models'] : decoded['data'];
      if (list is! List) return const {};
      final result = <String, ModelMetadata>{};
      for (final item in list) {
        if (item is! Map) continue;
        final raw = type == ProviderType.gemini ? item['name'] : item['id'];
        if (raw is! String) continue;
        final name =
            (type == ProviderType.gemini ? raw.replaceFirst('models/', '') : raw).trim();
        if (name.isEmpty) continue;
        final topProvider = item['top_provider'];
        final limit = item['limit'];
        final context = _positiveInt(item['context_length']) ??
            _positiveInt(item['context_window']) ??
            _positiveInt(item['max_context_length']) ??
            _positiveInt(item['inputTokenLimit']) ??
            _positiveInt(limit is Map ? limit['context'] : null) ??
            _positiveInt(topProvider is Map ? topProvider['context_length'] : null);
        final output = _positiveInt(item['max_completion_tokens']) ??
            _positiveInt(item['max_output_tokens']) ??
            _positiveInt(item['outputTokenLimit']) ??
            _positiveInt(limit is Map ? limit['output'] : null) ??
            _positiveInt(topProvider is Map ? topProvider['max_completion_tokens'] : null);
        if (context == null && output == null) continue;
        result[name] = ModelMetadata(
          id: name,
          contextTokens: context ?? 0,
          inputTokens: context,
          outputTokens: output,
        );
      }
      return result;
    } catch (_) {
      return const {};
    }
  }

  static int? _positiveInt(Object? value) =>
      value is num && value > 0 ? value.toInt() : null;

  static Map<String, String> _maskHeaders(Map<String, String> headers) => {
        for (final entry in headers.entries)
          entry.key: switch (entry.key.toLowerCase()) {
            'authorization' || 'x-api-key' => entry.value.length > 12
                ? '${entry.value.substring(0, 7)}...${entry.value.substring(entry.value.length - 4)}'
                : '***',
            _ => entry.value,
          },
      };

  static Map<String, String> _responseHeaders(Response<String> response) => {
        for (final entry in response.headers.map.entries) entry.key: entry.value.join(', '),
      };

  static String _take(String value, int max) =>
      value.length <= max ? value : '${value.substring(0, max)}…';
}

final modelApiProvider = Provider<ModelApiService>((ref) => ModelApiService());