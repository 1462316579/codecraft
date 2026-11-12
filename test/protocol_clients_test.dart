import 'dart:io';

import 'package:codecraft/agent/models/agent_attachment.dart';
import 'package:codecraft/agent/models/agent_message.dart';
import 'package:codecraft/agent/models/chat_session.dart';
import 'package:codecraft/agent/protocols/deepseek_client.dart';
import 'package:codecraft/agent/protocols/errors.dart';
import 'package:codecraft/agent/protocols/gemini_client.dart';
import 'package:codecraft/agent/protocols/http_transport.dart';
import 'package:codecraft/agent/protocols/llm_client.dart';
import 'package:codecraft/agent/protocols/openai_client.dart';
import 'package:codecraft/agent/tools/tool.dart';
import 'package:codecraft/core/util/blank_glyph.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_test/flutter_test.dart';

class FakeTransport implements SseTransport {
  FakeTransport(this.lines, {this.error});

  final List<String> lines;
  final Object? error;
  String? lastUrl;
  Map<String, dynamic>? lastBody;
  Map<String, String>? lastHeaders;

  @override
  Stream<String> postSseLines({
    required String url,
    required Map<String, dynamic> body,
    required Map<String, String> headers,
    Duration? idleTimeout,
    CancelToken? cancelToken,
  }) async* {
    lastUrl = url;
    lastBody = body;
    lastHeaders = headers;
    if (error != null) throw error!;
    for (final line in lines) {
      yield line;
    }
  }
}

LlmClientConfig config({
  String baseUrl = 'https://api.test',
  String model = 'test-model',
  bool useFullUrl = false,
  int maxRetries = 0,
}) =>
    LlmClientConfig(
      apiKey: 'sk-test',
      baseUrl: baseUrl,
      model: model,
      useFullUrl: useFullUrl,
      maxRetries: maxRetries,
    );

List<AgentMessage> history({String? assistantReasoning}) => [
      AgentMessage(
        id: 'u1',
        sessionId: 's1',
        role: MessageRole.user,
        content: '你好',
        timestamp: 1,
      ),
      if (assistantReasoning != null)
        AgentMessage(
          id: 'a1',
          sessionId: 's1',
          role: MessageRole.assistant,
          content: '在',
          timestamp: 2,
          reasoning: assistantReasoning,
        ),
    ];

Future<AiResponse> pump(LlmClient client) async {
  AiResponse? finalResponse;
  await for (final chunk in client.completeStream(systemPrompt: 'sys', messages: const [])) {
    if (chunk is FinalChunk) finalResponse = chunk.response;
  }
  return finalResponse!;
}

void main() {
  group('OpenAI 客户端', () {
    test('文本/思考/用量/结束原因与请求体', () async {
      final transport = FakeTransport([
        'data: {"choices":[{"delta":{"content":"你"}}]}',
        '',
        'data: {"choices":[{"delta":{"reasoning_content":"想"}}]}',
        '',
        'data: {"choices":[{"delta":{"content":"好"},"finish_reason":"stop"}]}',
        '',
        'data: {"choices":[],"usage":{"prompt_tokens":10,"completion_tokens":5,"prompt_tokens_details":{"cached_tokens":3}}}',
        '',
        'data: [DONE]',
        '',
      ]);
      final client = OpenAiClient(
        config(model: 'deepseek-chat'),
        transport,
      );
      final chunks = await client
          .completeStream(systemPrompt: 'sys', messages: history(assistantReasoning: '旧思考'))
          .toList();

      expect(chunks.whereType<TextDelta>().map((c) => c.text).join(), '你好');
      expect(chunks.whereType<ReasoningDelta>().map((c) => c.text).join(), '想');
      final finalChunk = chunks.whereType<FinalChunk>().single;
      expect(finalChunk.response.content, '你好');
      expect(finalChunk.response.stopReason, 'stop');
      expect(finalChunk.response.inputTokens, 10);
      expect(finalChunk.response.outputTokens, 5);
      expect(finalChunk.response.cachedInputTokens, 3);

      expect(transport.lastUrl, 'https://api.test/v1/chat/completions');
      expect(transport.lastHeaders!['Authorization'], 'Bearer sk-test');
      final messages = (transport.lastBody!['messages'] as List).cast<Map>();
      expect(messages.first['role'], 'system');
      // DeepSeek 模型:assistant 必须携带 reasoning_content
      expect(messages.last['reasoning_content'], '旧思考');
      expect(transport.lastBody!['stream'], true);
      expect(transport.lastBody!['stream_options'], {'include_usage': true});
    });

    test('缺 [DONE] 视为断流', () async {
      final transport = FakeTransport([
        'data: {"choices":[{"delta":{"content":"半"}}]}',
        '',
      ]);
      final client = OpenAiClient(config(), transport);
      await expectLater(
        client.completeStream(systemPrompt: 'sys', messages: const []).toList(),
        throwsA(isA<LlmNetworkException>()),
      );
    });

    test('CRLF 与坏行容错', () async {
      final transport = FakeTransport([
        'data: {"choices":[{"delta":{"content":"A"}}]}\r',
        '\r',
        'data: 这不是JSON\r',
        '\r',
        'data: [DONE]\r',
        '\r',
      ]);
      final client = OpenAiClient(config(), transport);
      final response = await pump(client);
      expect(response.content, 'A');
    });

    test('重试:网络错误先重试一次再成功', () async {
      var attempts = 0;
      final client = _FlakyClient(
        () {
          attempts++;
          if (attempts == 1) {
            return Stream<AiStreamChunk>.error(LlmNetworkException('boom'));
          }
          return Stream.value(const FinalChunk(AiResponse(content: 'ok')));
        },
        LlmClientConfig(
          apiKey: 'k',
          baseUrl: 'https://x',
          model: 'm',
          maxRetries: 2,
          baseRetryDelay: const Duration(milliseconds: 1),
        ),
      );
      final chunks = await client.completeStream(systemPrompt: '', messages: const []).toList();
      expect(attempts, 2);
      expect(chunks.whereType<Retrying>().length, 1);
      expect(chunks.whereType<FinalChunk>().single.response.content, 'ok');
    });
  });

  group('DeepSeek 客户端', () {
    test('事件序列解析', () async {
      final transport = FakeTransport([
        'data: {"type":"message_start","message":{"usage":{"input_tokens":12,"cache_read_input_tokens":4}}}',
        '',
        'data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"嗨"}}',
        '',
        'data: {"type":"content_block_delta","delta":{"type":"thinking_delta","thinking":"嗯"}}',
        '',
        'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":7}}',
        '',
        'data: {"type":"message_stop"}',
        '',
      ]);
      final client = DeepSeekClient(config(baseUrl: 'https://api.deepseek.com/'), transport);
      final chunks =
          await client.completeStream(systemPrompt: 'sys', messages: history()).toList();
      final finalChunk = chunks.whereType<FinalChunk>().single;
      expect(finalChunk.response.content, '嗨');
      expect(finalChunk.response.stopReason, 'end_turn');
      // 总输入 = input_tokens 12 + cache_read 4:该协议的 input_tokens 只算未命中缓存部分,
      // 上层(上下文占用/费用/命中率)按总输入算,故客户端必须聚合(对齐上游 totalInputTokens)。
      expect(finalChunk.response.inputTokens, 16);
      expect(finalChunk.response.outputTokens, 7);
      expect(finalChunk.response.cachedInputTokens, 4);
      expect(chunks.whereType<ReasoningDelta>().single.text, '嗯');
      expect(transport.lastUrl, 'https://api.deepseek.com/v1/messages');
      expect(transport.lastHeaders!['anthropic-version'], '2023-06-01');
    });

    test('缺 message_stop 视为断流', () async {
      final transport = FakeTransport(['data: {"type":"message_start"}', '']);
      final client = DeepSeekClient(config(), transport);
      await expectLater(
        client.completeStream(systemPrompt: 'sys', messages: const []).toList(),
        throwsA(isA<LlmNetworkException>()),
      );
    });

    test('流内 error 事件抛错且带错误码(供重试分类)', () async {
      final transport = FakeTransport([
        'data: {"type":"error","error":{"type":"overloaded_error","message":"忙"}}',
        '',
      ]);
      final client = DeepSeekClient(config(), transport);
      await expectLater(
        client.completeStream(systemPrompt: 'sys', messages: const []).toList(),
        throwsA(isA<LlmStreamApiException>()
            .having((e) => e.code, 'code', 'overloaded_error')),
      );
    });
  });

  group('Gemini 客户端', () {
    test('parts/用量/finishReason 与请求体', () async {
      final transport = FakeTransport([
        'data: {"candidates":[{"content":{"parts":[{"text":"思","thought":true}]}}]}',
        '',
        'data: {"candidates":[{"content":{"parts":[{"text":"好"}]}}]}',
        '',
        'data: {"candidates":[{"content":{"parts":[]},"finishReason":"STOP"}],"usageMetadata":{"promptTokenCount":9,"candidatesTokenCount":6,"cachedContentTokenCount":2}}',
        '',
      ]);
      final client = GeminiClient(config(baseUrl: 'https://generativelanguage.googleapis.com/'), transport);
      final chunks =
          await client.completeStream(systemPrompt: 'sys', messages: history()).toList();
      final finalChunk = chunks.whereType<FinalChunk>().single;
      expect(finalChunk.response.content, '好');
      expect(finalChunk.response.stopReason, 'STOP');
      expect(finalChunk.response.inputTokens, 9);
      expect(finalChunk.response.outputTokens, 6);
      expect(finalChunk.response.cachedInputTokens, 2);
      expect(chunks.whereType<ReasoningDelta>().single.text, '思');
      expect(
        transport.lastUrl,
        'https://generativelanguage.googleapis.com/v1beta/models/test-model:streamGenerateContent?alt=sse',
      );
      expect(transport.lastHeaders!['x-goog-api-key'], 'sk-test');
      expect(transport.lastBody!['systemInstruction'], isNotNull);
      final contents = (transport.lastBody!['contents'] as List).cast<Map>();
      expect(contents.single['role'], 'user');
    });

    test('缺 finishReason 视为断流', () async {
      final transport = FakeTransport([
        'data: {"candidates":[{"content":{"parts":[{"text":"半"}]}}]}',
        '',
      ]);
      final client = GeminiClient(config(), transport);
      await expectLater(
        client.completeStream(systemPrompt: 'sys', messages: const []).toList(),
        throwsA(isA<LlmNetworkException>()),
      );
    });
  });

    test('图片附件编入请求体(三协议各自的图片块)', () async {
      final dir = Directory.systemTemp.createTempSync('att');
      final file = File('${dir.path}/a.png')..writeAsBytesSync([1, 2, 3]);
      final attachment = AgentAttachment(
        fileName: 'a.png',
        localPath: file.path,
        mimeType: 'image/png',
        sizeBytes: 3,
      );
      final message = AgentMessage(
        id: 'u1',
        sessionId: 's1',
        role: MessageRole.user,
        content: '',
        timestamp: 1,
        attachmentsJson: AgentAttachment.encodeList([attachment]),
      );

      // OpenAI:content 变为 parts(图片块 image_url data URL)
      final openaiTransport = FakeTransport(['data: [DONE]', '']);
      await OpenAiClient(config(), openaiTransport)
          .completeStream(systemPrompt: 'sys', messages: [message])
          .toList();
      final openaiContent =
          (openaiTransport.lastBody!['messages'] as List).last['content'] as List;
      expect(openaiContent.single['type'], 'image_url');
      expect(
        ((openaiContent.single as Map)['image_url'] as Map)['url'],
        'data:image/png;base64,AQID',
      );

      // Anthropic:content 变为 blocks(image + source.base64)
      final anthropicTransport = FakeTransport(['data: {"type":"message_stop"}', '']);
      await DeepSeekClient(config(), anthropicTransport)
          .completeStream(systemPrompt: 'sys', messages: [message])
          .toList();
      final blocks = (anthropicTransport.lastBody!['messages'] as List).last['content'] as List;
      expect(blocks.single['type'], 'image');
      expect((blocks.single as Map)['source']['type'], 'base64');
      expect((blocks.single as Map)['source']['media_type'], 'image/png');
      expect((blocks.single as Map)['source']['data'], 'AQID');

      // Gemini:parts 里是 inlineData
      final geminiTransport = FakeTransport([
        'data: {"candidates":[{"content":{"parts":[]},"finishReason":"STOP"}]}',
        '',
      ]);
      await GeminiClient(config(), geminiTransport)
          .completeStream(systemPrompt: 'sys', messages: [message])
          .toList();
      final parts = ((geminiTransport.lastBody!['contents'] as List).last['parts'] as List);
      expect((parts.single as Map)['inlineData']['mimeType'], 'image/png');
      expect((parts.single as Map)['inlineData']['data'], 'AQID');

      dir.deleteSync(recursive: true);
    });

  group('空白字形过滤(hasVisibleContent)', () {
    test('零宽与填充字符不算可见', () {
      expect(hasVisibleContent(''), false);
      expect(hasVisibleContent('   \n\t'), false);
      expect(hasVisibleContent('ㅤ'), false); // U+3164
      expect(hasVisibleContent('\u200b\u200c'), false);
      expect(hasVisibleContent('a'), true);
      expect(hasVisibleContent('你好'), true);
      expect(hasVisibleContent('😀'), true); // 合法代理对
      expect(hasVisibleContent('\ud83d'), false); // 孤立高代理
    });
  });
}

class _FlakyClient extends LlmClient {
  _FlakyClient(this._attempt, LlmClientConfig config) : super(config, _NoopTransport.instance);

  final Stream<AiStreamChunk> Function() _attempt;

  @override
  Stream<AiStreamChunk> attemptStream({
    required String systemPrompt,
    required List<AgentMessage> messages,
    List<AgentTool> tools = const [],
    ReasoningEffort? effort,
    required void Function() onContent,
    CancelToken? cancelToken,
  }) =>
      _attempt();
}

class _NoopTransport implements SseTransport {
  static final instance = _NoopTransport();

  @override
  Stream<String> postSseLines({
    required String url,
    required Map<String, dynamic> body,
    required Map<String, String> headers,
    Duration? idleTimeout,
    CancelToken? cancelToken,
  }) =>
      const Stream.empty();
}