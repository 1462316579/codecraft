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

/// DeepSeek Messages API 流式客户端。文本子集移植自原仓库 AnthropicAdapter.kt:
/// - 端点 `v1/messages`,鉴权 `x-api-key` + `anthropic-version: 2023-06-01`;
/// - 事件流按 `type` 分派(message_start / content_block_start / content_block_delta /
///   message_delta / message_stop / error);
/// - 未收到 message_stop 即视为断流,抛错以触发重试与错误日志。
///
/// Phase 1 不含:extended thinking 的 budget/签名回传、工具调用、显式缓存断点。
/// 总输入 token = 未命中缓存的 input + 缓存读 + 缓存写(对齐上游 `totalInputTokens`)。
int totalInputTokens(int input, int cacheRead, int cacheCreation) =>
    input + cacheRead + cacheCreation;

class DeepSeekClient extends LlmClient {
  DeepSeekClient(super.config, super.transport);

  static const String _apiVersion = '2023-06-01';
  static const int _defaultMaxTokens = 8192;

  @override
  Stream<AiStreamChunk> attemptStream({
    required String systemPrompt,
    required List<AgentMessage> messages,
    List<AgentTool> tools = const [],
    ReasoningEffort? effort,
    required void Function() onContent,
    CancelToken? cancelToken,
  }) {
    final url = config.useFullUrl ? config.baseUrl : joinUrl(config.baseUrl, 'v1/messages');
    final maxTokens =
        (config.maxOutputTokens ?? 0) > 0 ? config.maxOutputTokens! : _defaultMaxTokens;
    final body = <String, dynamic>{
      'model': config.model,
      'max_tokens': maxTokens,
      'messages': _buildMessages(messages),
      if (systemPrompt.trim().isNotEmpty) 'system': systemPrompt,
      if (config.temperature != null) 'temperature': config.temperature,
      if (tools.isNotEmpty)
        'tools': [
          for (final tool in tools)
            {
              'name': tool.name,
              'description': tool.description,
              'input_schema': tool.toJsonSchema(),
            },
        ],
      'stream': true,
    };

    final text = StringBuffer();
    final toolAccumulators = <int, _ToolUseAcc>{};
    String? stopReason;
    var inputTokens = 0;
    var outputTokens = 0;
    var cachedInputTokens = 0;
    var cacheCreationTokens = 0;
    var sawStop = false;

    AiResponse buildResponse() => AiResponse(
          content: text.toString(),
          toolCalls: [
            for (final acc in toolAccumulators.values)
              if (acc.name.isNotEmpty) acc.toToolCall(),
          ],
          stopReason: stopReason,
          // 该协议的 input_tokens 只算未命中缓存的部分,总输入要加上 cache_read/cache_creation,
          // 才能与 OpenAI(prompt_tokens 已含 cached_tokens)、Gemini(promptTokenCount)口径一致。
          // 上下文占用、压缩触发、费用与缓存命中率都按总输入算。
          inputTokens: totalInputTokens(inputTokens, cachedInputTokens, cacheCreationTokens),
          outputTokens: outputTokens,
          cachedInputTokens: cachedInputTokens,
          cacheCreationTokens: cacheCreationTokens,
        );

    final source = sseDataEvents(transport.postSseLines(
      url: url,
      body: body,
      headers: {
        'x-api-key': config.apiKey,
        'anthropic-version': _apiVersion,
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
        final obj = _decodeObject(payload);
        if (obj == null) return ForwardAction.next;

        final type = obj['type'];
        if (type == 'error') {
          final error = obj['error'];
          final code = error is Map ? error['type'] : null;
          final message = error is Map ? (error['message'] ?? '未知错误') : '未知错误';
          throw LlmStreamApiException(
                code,
                '流内错误${code == null ? '' : '[$code]'}:$message',
              );
        }
        if (type == 'message_stop') {
          sawStop = true;
          emit(FinalChunk(buildResponse()));
          return ForwardAction.finish;
        }

        try {
          switch (type) {
            case 'message_start':
              final message = obj['message'];
              final usage = message is Map ? message['usage'] : null;
              if (usage is Map) {
                inputTokens = _intOr(usage['input_tokens'], 0);
                cachedInputTokens = _intOr(usage['cache_read_input_tokens'], 0);
                cacheCreationTokens = _intOr(usage['cache_creation_input_tokens'], 0);
              }
            case 'content_block_start':
              final index = obj['index'];
              final block = obj['content_block'];
              if (index is int && block is Map && block['type'] == 'tool_use') {
                onContent();
                final acc = toolAccumulators.putIfAbsent(index, _ToolUseAcc.new);
                final id = block['id'];
                if (id is String && id.isNotEmpty) acc.id = id;
                final name = block['name'];
                if (name is String && name.isNotEmpty) acc.name = name;
              }
            case 'content_block_delta':
              final delta = obj['delta'];
              if (delta is! Map) break;
              switch (delta['type']) {
                case 'text_delta':
                  final value = delta['text'];
                  if (value is String && value.isNotEmpty) {
                    onContent();
                    text.write(value);
                    emit(TextDelta(value));
                  }
                case 'thinking_delta':
                  final value = delta['thinking'];
                  if (value is String && value.isNotEmpty) {
                    onContent();
                    emit(ReasoningDelta(value));
                  }
                case 'input_json_delta':
                  final index = obj['index'];
                  final partial = delta['partial_json'];
                  if (index is int && partial is String) {
                    toolAccumulators.putIfAbsent(index, _ToolUseAcc.new).arguments.write(partial);
                  }
                case 'signature_delta':
                  // Phase 1 不处理签名回传
                  break;
              }
            case 'message_delta':
              final delta = obj['delta'];
              if (delta is Map && delta['stop_reason'] is String) {
                stopReason = delta['stop_reason'] as String;
              }
              final usage = obj['usage'];
              if (usage is Map) {
                inputTokens = _intOr(usage['input_tokens'], inputTokens);
                outputTokens = _intOr(usage['output_tokens'], outputTokens);
                cachedInputTokens = _intOr(usage['cache_read_input_tokens'], cachedInputTokens);
                cacheCreationTokens =
                    _intOr(usage['cache_creation_input_tokens'], cacheCreationTokens);
              }
          }
        } catch (_) {
          // 跳过无法解析的该行
        }
        return ForwardAction.next;
      },
      onDone: (emit) {
        if (!sawStop) {
          throw LlmNetworkException('SSE 流被中断:未收到 message_stop 结束标记(疑似网络断开)');
        }
        emit(FinalChunk(buildResponse()));
      },
    );
  }

  List<Map<String, dynamic>> _buildMessages(List<AgentMessage> messages) => [
        for (final message in messages)
          if (message.role == MessageRole.user)
            _userMessage(message)
          else if (message.role == MessageRole.assistant)
            _assistantMessage(message)
          else if (message.role == MessageRole.tool)
            {
              'role': 'user',
              'content': [
                {
                  'type': 'tool_result',
                  'tool_use_id': message.toolCallId ?? message.id,
                  'content': message.content,
                  if (message.isError) 'is_error': true,
                },
              ],
            },
      ];

  /// 助手消息:带工具调用时输出 tool_use 内容块。
  Map<String, dynamic> _assistantMessage(AgentMessage message) {
    final toolCalls = ToolCall.decodeList(message.toolCallsJson);
    if (toolCalls.isEmpty) {
      return {'role': 'assistant', 'content': message.content};
    }
    return {
      'role': 'assistant',
      'content': [
        if (message.content.trim().isNotEmpty) {'type': 'text', 'text': message.content},
        for (final call in toolCalls)
          {
            'type': 'tool_use',
            'id': call.id,
            'name': call.name,
            'input': call.arguments,
          },
      ],
    };
  }

  /// 用户消息:有图片时内容为 blocks(文本块 + image 块,上游语义)。
  Map<String, dynamic> _userMessage(AgentMessage message) {
    final images = message.attachments.where((a) => a.isImage).toList();
    if (images.isEmpty) return {'role': 'user', 'content': message.content};
    final blocks = <Map<String, dynamic>>[];
    if (message.content.trim().isNotEmpty) {
      blocks.add({'type': 'text', 'text': message.content});
    }
    for (final image in images) {
      final payload = attachmentPayload(image);
      if (payload == null) continue;
      blocks.add({
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': payload.mimeType,
          'data': payload.base64,
        },
      });
    }
    return {'role': 'user', 'content': blocks};
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

/// 流式聚合中的一次 tool_use(按 content block index 累积)。
class _ToolUseAcc {
  String id = '';
  String name = '';
  final arguments = StringBuffer();

  ToolCall toToolCall() => ToolCall(
        id: id.isEmpty ? 'toolu' : id,
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