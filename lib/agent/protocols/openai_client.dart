import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/agent_message.dart';
import '../models/chat_session.dart';
import 'errors.dart';
import 'llm_client.dart';
import 'sse.dart';
import 'stream_utils.dart';
import 'url_utils.dart';
import 'attachment_payload.dart';
import '../tools/tool.dart';

/// OpenAI Chat Completions 流式客户端(同时服务 DeepSeek 等大量兼容服务)。
/// 文本子集移植自原仓库 OpenAIAdapter.kt 的 Chat Completions 分支:
/// - system 角色按模型前缀选 developer/system;
/// - reasoning_effort 归一化(none/minimal 跳过,xhigh/max 归到 high);
/// - DeepSeek 系模型要求 assistant 消息必须带 reasoning_content 字段(空串也带)。
class OpenAiClient extends LlmClient {
  OpenAiClient(super.config, super.transport);

  @override
  Stream<AiStreamChunk> attemptStream({
    required String systemPrompt,
    required List<AgentMessage> messages,
    List<AgentTool> tools = const [],
    ReasoningEffort? effort,
    required void Function() onContent,
    CancelToken? cancelToken,
  }) {
    final url =
        config.useFullUrl ? config.baseUrl : joinUrl(config.baseUrl, 'v1/chat/completions');
    final normalizedEffort = _normalizeEffort(effort);
    final body = <String, dynamic>{
      'model': config.model,
      'messages': _buildMessages(systemPrompt, messages),
      if (config.temperature != null) 'temperature': config.temperature,
      if (normalizedEffort != null) 'reasoning_effort': normalizedEffort,
      if (tools.isNotEmpty) 'tools': [for (final tool in tools) _toolSchema(tool)],
      if (tools.isNotEmpty) 'tool_choice': 'auto',
      'stream': true,
      'stream_options': {'include_usage': true},
    };

    final text = StringBuffer();
    final toolAccumulators = <int, _ToolCallAcc>{};
    String? finishReason;
    var inputTokens = 0;
    var outputTokens = 0;
    var cachedInputTokens = 0;
    var cacheCreationTokens = 0;
    var sawDone = false;

    AiResponse buildResponse() => AiResponse(
          content: text.toString(),
          toolCalls: [for (final acc in toolAccumulators.values) acc.toToolCall()]
              .where((c) => c.name.isNotEmpty)
              .toList(),
          stopReason: finishReason,
          inputTokens: inputTokens,
          outputTokens: outputTokens,
          cachedInputTokens: cachedInputTokens,
          cacheCreationTokens: cacheCreationTokens,
        );

    final source = sseDataEvents(transport.postSseLines(
      url: url,
      body: body,
      headers: {
        'Authorization': 'Bearer ${config.apiKey}',
        'Accept': 'text/event-stream',
        ...config.customHeaders,
      },
      idleTimeout: config.idleTimeout,
      cancelToken: cancelToken,
    ));

    return forwardStream<String, AiStreamChunk>(
      source: source,
      onEvent: (data, emit) {
        final payload = data.trim();
        if (payload.isEmpty) return ForwardAction.next;
        if (payload == '[DONE]') {
          sawDone = true;
          emit(FinalChunk(buildResponse()));
          return ForwardAction.finish;
        }
        final obj = _decodeObject(payload);
        if (obj == null) return ForwardAction.next;

        final error = obj['error'];
        if (error is Map) {
          final code = error['code'];
          final message = error['message'] ?? '未知错误';
          throw LlmStreamApiException(
                code,
                '流内错误${code == null ? '' : '[$code]'}:$message',
              );
        }

        // 单行解析失败只跳过该行,不中断整条流(容忍上游字段类型出入)。
        try {
          final usage = obj['usage'];
          if (usage is Map) {
            inputTokens = _intOr(usage['prompt_tokens'], inputTokens);
            outputTokens = _intOr(usage['completion_tokens'], outputTokens);
            final details = usage['prompt_tokens_details'];
            if (details is Map) {
              cachedInputTokens = _intOr(details['cached_tokens'], cachedInputTokens);
              cacheCreationTokens = _intOr(details['cache_write_tokens'], cacheCreationTokens);
            }
          }

          final choices = obj['choices'];
          if (choices is! List || choices.isEmpty) return ForwardAction.next;
          final choice = choices.first;
          if (choice is! Map) return ForwardAction.next;

          final reason = choice['finish_reason'];
          if (reason is String) finishReason = reason;

          final delta = choice['delta'];
          if (delta is! Map) return ForwardAction.next;

          final content = delta['content'];
          if (content is String && content.isNotEmpty) {
            onContent();
            text.write(content);
            emit(TextDelta(content));
          }

          // 工具调用增量:按 index 聚合 id/name/arguments 片段(后续增量 id/name 可能为空,不可覆盖)。
          final toolCalls = delta['tool_calls'];
          if (toolCalls is List && toolCalls.isNotEmpty) {
            onContent();
            for (final item in toolCalls) {
              if (item is! Map) continue;
              final index = (item['index'] as int?) ?? 0;
              final acc = toolAccumulators.putIfAbsent(index, _ToolCallAcc.new);
              final id = item['id'];
              if (id is String && id.isNotEmpty) acc.id = id;
              final function = item['function'];
              if (function is Map) {
                final functionName = function['name'];
                if (functionName is String && functionName.isNotEmpty) acc.name = functionName;
                final arguments = function['arguments'];
                if (arguments is String) acc.arguments.write(arguments);
              }
            }
          }

          final reasoning = _reasoningText(delta);
          if (reasoning != null && reasoning.isNotEmpty) {
            onContent();
            emit(ReasoningDelta(reasoning));
          }
        } catch (_) {
          // 跳过无法解析的该行
        }
        return ForwardAction.next;
      },
      onDone: (emit) {
        if (!sawDone) {
          throw LlmNetworkException('SSE 流被中断:未收到 [DONE] 结束标记(疑似网络断开)');
        }
        emit(FinalChunk(buildResponse()));
      },
    );
  }

  /// 工具声明(OpenAI function-calling 格式)。
  static Map<String, dynamic> _toolSchema(AgentTool tool) => {
        'type': 'function',
        'function': {
          'name': tool.name,
          'description': tool.description,
          'parameters': tool.toJsonSchema(),
        },
      };

  List<Map<String, dynamic>> _buildMessages(String systemPrompt, List<AgentMessage> messages) {
    final isDeepSeek = config.model.toLowerCase().contains('deepseek');
    final result = <Map<String, dynamic>>[];
    if (systemPrompt.trim().isNotEmpty) {
      result.add({'role': _systemRole(), 'content': systemPrompt});
    }
    for (final message in messages) {
      switch (message.role) {
        case MessageRole.user:
          final images = message.attachments.where((a) => a.isImage).toList();
          if (images.isEmpty) {
            result.add({'role': 'user', 'content': message.content});
          } else {
            // 上游语义:有图片时内容变为 parts 数组(文本块 + 图片块)
            final parts = <Map<String, dynamic>>[];
            if (message.content.trim().isNotEmpty) {
              parts.add({'type': 'text', 'text': message.content});
            }
            for (final image in images) {
              final payload = attachmentPayload(image);
              if (payload == null) continue;
              parts.add({
                'type': 'image_url',
                'image_url': {
                  'url': 'data:${payload.mimeType};base64,${payload.base64}',
                  'detail': 'auto',
                },
              });
            }
            result.add({'role': 'user', 'content': parts});
          }
        case MessageRole.assistant:
          final reasoning = message.reasoning;
          final reasoningContent = isDeepSeek
              ? (reasoning ?? '')
              : (reasoning != null && reasoning.isNotEmpty ? reasoning : null);
          final toolCalls = ToolCall.decodeList(message.toolCallsJson);
          result.add({
            'role': 'assistant',
            'content': message.content.isEmpty ? null : message.content,
            if (toolCalls.isNotEmpty)
              'tool_calls': [
                for (final call in toolCalls)
                  {
                    'id': call.id,
                    'type': 'function',
                    'function': {
                      'name': call.name,
                      'arguments': jsonEncode(call.arguments),
                    },
                  },
              ],
            if (reasoningContent != null) 'reasoning_content': reasoningContent,
          });
        case MessageRole.tool:
          // 工具结果回放:配对到发起调用的 assistant 消息
          result.add({
            'role': 'tool',
            'tool_call_id': message.toolCallId ?? message.id,
            'content': message.content,
          });
      }
    }
    return result;
  }

  /// o 系列与 gpt-5 系不接受 system role,须用 developer。
  String _systemRole() {
    final model = config.model.toLowerCase();
    if (model.startsWith('o') || model.startsWith('gpt-5')) return 'developer';
    return 'system';
  }

  String? _normalizeEffort(ReasoningEffort? effort) => switch (effort) {
        null => null,
        ReasoningEffort.none || ReasoningEffort.minimal => null,
        ReasoningEffort.xhigh || ReasoningEffort.max => 'high',
        _ => effort.apiValue,
      };

  static String? _reasoningText(Map<dynamic, dynamic> delta) {
    final direct = delta['reasoning_content'];
    if (direct is String) return direct;
    final fallback = delta['reasoning'];
    if (fallback is String) return fallback;
    final details = delta['reasoning_details'];
    if (details is List) {
      final buffer = StringBuffer();
      for (final item in details) {
        if (item is Map && item['text'] is String) buffer.write(item['text'] as String);
      }
      return buffer.toString();
    }
    return null;
  }

  static Map<String, dynamic>? _decodeObject(String data) {
    try {
      final decoded = jsonDecode(data);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static int _intOr(Object? value, int fallback) => value is int ? value : fallback;
}

/// 流式聚合中的一次工具调用(OpenAI delta.tool_calls 按 index 累积)。
class _ToolCallAcc {
  String id = '';
  String name = '';
  final arguments = StringBuffer();

  ToolCall toToolCall() => ToolCall(
        id: id.isEmpty ? 'call' : id,
        name: name,
        arguments: _parseArguments(arguments.toString()),
      );

  static Map<String, dynamic> _parseArguments(String raw) {
    if (raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? decoded.cast<String, dynamic>() : const {};
    } catch (_) {
      return const {};
    }
  }
}