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

/// Gemini generateContent 流式客户端。移植自原仓库 GeminiAdapter.kt 的
/// generateContent / streamGenerateContent 分支(不含 Interactions API):
/// - 端点 `v1beta/models/{model}:streamGenerateContent?alt=sse`(baseUrl 已以模型名结束时追加后缀);
/// - 鉴权头 `x-goog-api-key`;
/// - thought part → ReasoningDelta;正文 part → TextDelta;finishReason 出现即结束本轮。
///
/// Phase 1 不含:thoughtSignature 快照回传、函数调用、图片输出、thinkingConfig。
class GeminiClient extends LlmClient {
  GeminiClient(super.config, super.transport);

  @override
  Stream<AiStreamChunk> attemptStream({
    required String systemPrompt,
    required List<AgentMessage> messages,
    List<AgentTool> tools = const [],
    ReasoningEffort? effort,
    required void Function() onContent,
    CancelToken? cancelToken,
  }) {
    final url = _resolveUrl();
    final generationConfig = <String, dynamic>{
      if ((config.maxOutputTokens ?? 0) > 0) 'maxOutputTokens': config.maxOutputTokens,
      if (config.temperature != null) 'temperature': config.temperature,
    };
    final body = <String, dynamic>{
      'contents': _buildContents(messages),
      if (systemPrompt.trim().isNotEmpty)
        'systemInstruction': {
          'role': 'system',
          'parts': [
            {'text': systemPrompt}
          ],
        },
      if (generationConfig.isNotEmpty) 'generationConfig': generationConfig,
      if (tools.isNotEmpty)
        'tools': [
          {
            'functionDeclarations': [
              for (final tool in tools)
                {
                  'name': tool.name,
                  'description': tool.description,
                  'parameters': tool.toJsonSchema(),
                },
            ],
          },
        ],
    };

    final text = StringBuffer();
    final toolCalls = <ToolCall>[];
    String? finishReason;
    var inputTokens = 0;
    var outputTokens = 0;
    var cachedInputTokens = 0;

    AiResponse buildResponse() => AiResponse(
          content: text.toString(),
          toolCalls: toolCalls,
          stopReason: finishReason,
          inputTokens: inputTokens,
          outputTokens: outputTokens,
          cachedInputTokens: cachedInputTokens,
        );

    final source = sseDataEvents(transport.postSseLines(
      url: url,
      body: body,
      headers: {
        'x-goog-api-key': config.apiKey,
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

        try {
          final usage = obj['usageMetadata'];
          if (usage is Map) {
            inputTokens = _intOr(usage['promptTokenCount'], inputTokens);
            final candidateTokens = usage['candidatesTokenCount'];
            final thoughtTokens = usage['thoughtsTokenCount'];
            if (candidateTokens is int || thoughtTokens is int) {
              outputTokens = (candidateTokens as int? ?? 0) + (thoughtTokens as int? ?? 0);
            }
            cachedInputTokens = _intOr(usage['cachedContentTokenCount'], cachedInputTokens);
          }

          final candidates = obj['candidates'];
          if (candidates is! List || candidates.isEmpty) return ForwardAction.next;
          final candidate = candidates.first;
          if (candidate is! Map) return ForwardAction.next;

          final reason = candidate['finishReason'];
          if (reason is String && reason.isNotEmpty && reason != 'null') finishReason = reason;

          final content = candidate['content'];
          final parts = content is Map ? content['parts'] : null;
          if (parts is List) {
            for (final part in parts) {
              if (part is! Map) continue;
              // 函数调用 part:{functionCall: {name, args}}
              final functionCall = part['functionCall'];
              if (functionCall is Map) {
                final name = functionCall['name'];
                if (name is String && name.isNotEmpty) {
                  onContent();
                  final rawArgs = functionCall['args'];
                  toolCalls.add(ToolCall(
                    id: 'call_${toolCalls.length}',
                    name: name,
                    arguments: rawArgs is Map ? rawArgs.cast<String, dynamic>() : const {},
                  ));
                }
                continue;
              }
              final value = part['text'];
              if (value is! String || value.isEmpty) continue;
              final isThought = part['thought'] == true;
              onContent();
              if (isThought) {
                emit(ReasoningDelta(value));
              } else {
                text.write(value);
                emit(TextDelta(value));
              }
            }
          }
        } catch (_) {
          // 跳过无法解析的该行
        }

        if (finishReason != null) {
          emit(FinalChunk(buildResponse()));
          return ForwardAction.finish;
        }
        return ForwardAction.next;
      },
      onDone: (emit) {
        if (finishReason == null) {
          throw LlmNetworkException('SSE 流被中断(疑似网络断开)');
        }
        emit(FinalChunk(buildResponse()));
      },
    );
  }

  /// 与原仓库一致的端点解析:baseUrl 已以模型名结尾时只追加后缀。
  String _resolveUrl() {
    if (config.useFullUrl) return config.baseUrl;
    final base = config.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.endsWith(config.model)) {
      return '$base:streamGenerateContent?alt=sse';
    }
    return joinUrl(config.baseUrl, 'v1beta/models/${config.model}:streamGenerateContent?alt=sse');
  }

  List<Map<String, dynamic>> _buildContents(List<AgentMessage> messages) => [
        for (final message in messages)
          if (message.role == MessageRole.user)
            _userContent(message)
          else if (message.role == MessageRole.assistant)
            _assistantContent(message)
          else if (message.role == MessageRole.tool)
            {
              'role': 'user',
              'parts': [
                {
                  'functionResponse': {
                    'name': message.toolName ?? '',
                    'response': {'result': message.content},
                  },
                },
              ],
            },
      ];

  /// 助手内容:带工具调用时输出 functionCall parts。
  Map<String, dynamic> _assistantContent(AgentMessage message) {
    final calls = ToolCall.decodeList(message.toolCallsJson);
    return {
      'role': 'model',
      'parts': [
        if (message.content.trim().isNotEmpty) {'text': message.content},
        for (final call in calls)
          {
            'functionCall': {'name': call.name, 'args': call.arguments},
          },
      ],
    };
  }

  /// 用户内容:文本 part + 图片 inlineData part(上游语义)。
  Map<String, dynamic> _userContent(AgentMessage message) {
    final parts = <Map<String, dynamic>>[];
    if (message.content.trim().isNotEmpty) {
      parts.add({'text': message.content});
    }
    for (final image in message.attachments.where((a) => a.isImage)) {
      final payload = attachmentPayload(image);
      if (payload == null) continue;
      parts.add({
        'inlineData': {
          'mimeType': payload.mimeType,
          'data': payload.base64,
        },
      });
    }
    return {'role': 'user', 'parts': parts};
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