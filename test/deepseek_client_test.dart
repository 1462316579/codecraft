import 'package:codecraft/agent/models/agent_message.dart';
import 'package:codecraft/agent/protocols/deepseek_client.dart';
import 'package:codecraft/agent/protocols/errors.dart';
import 'package:codecraft/agent/protocols/http_transport.dart';
import 'package:codecraft/agent/protocols/llm_client.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_test/flutter_test.dart';

/// 假传输:按预置行序列产出 SSE 行,不联网;记录最后一次请求的 url/body/headers。
class _FakeSseTransport implements SseTransport {
  _FakeSseTransport(this.lines);

  final List<String> lines;
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
    yield* Stream<String>.fromIterable(lines);
  }
}

LlmClientConfig _config({
  String baseUrl = 'https://api.deepseek.com',
  bool useFullUrl = false,
  int? maxOutputTokens,
  double? temperature,
}) =>
    LlmClientConfig(
      apiKey: 'sk-test',
      baseUrl: baseUrl,
      model: 'deepseek-chat',
      useFullUrl: useFullUrl,
      maxOutputTokens: maxOutputTokens,
      temperature: temperature,
      // 重试退避与协议解析无关:关掉重试,断言失败要立刻看到原因
      maxRetries: 0,
    );

const List<AgentMessage> _messages = [
  AgentMessage(id: 'u1', sessionId: 's1', role: MessageRole.user, content: '你好', timestamp: 1),
];

Future<AiResponse> _run(LlmClient client) async {
  AiResponse? response;
  await for (final chunk
      in client.completeStream(systemPrompt: '你是助手', messages: _messages)) {
    if (chunk is FinalChunk) response = chunk.response;
  }
  return response!;
}

void main() {
  group('DeepSeek Messages API 客户端', () {
    test('文本拼接、thinking 增量、用量与 stop_reason 进 FinalChunk', () async {
      final transport = _FakeSseTransport([
        'data: {"type":"message_start","message":{"usage":{"input_tokens":12,'
            '"cache_read_input_tokens":4,"cache_creation_input_tokens":2}}}',
        '',
        'data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}',
        '',
        'data: {"type":"content_block_delta","index":0,'
            '"delta":{"type":"text_delta","text":"你"}}',
        '',
        'data: {"type":"content_block_delta","index":0,'
            '"delta":{"type":"text_delta","text":"好"}}',
        '',
        'data: {"type":"content_block_delta","index":0,'
            '"delta":{"type":"thinking_delta","thinking":"嗯"}}',
        '',
        'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},'
            '"usage":{"output_tokens":7}}',
        '',
        'data: {"type":"message_stop"}',
        '',
      ]);

      final chunks = await DeepSeekClient(_config(), transport)
          .completeStream(systemPrompt: '你是助手', messages: _messages)
          .toList();

      expect(chunks.whereType<TextDelta>().map((c) => c.text).join(), '你好');
      expect(chunks.whereType<ReasoningDelta>().map((c) => c.text).join(), '嗯');

      final response = chunks.whereType<FinalChunk>().single.response;
      expect(response.content, '你好');
      expect(response.stopReason, 'end_turn');
      // 总输入 = input_tokens + cache_read + cache_creation(对齐上游 totalInputTokens)。
      expect(response.inputTokens, 18);
      expect(response.outputTokens, 7);
      expect(response.cachedInputTokens, 4);
      expect(response.cacheCreationTokens, 2);
      // 思考内容仅作实时展示,不累积进最终结果
      expect(response.reasoning, isNull);
      expect(response.isTruncated, isFalse);
    });

    test('端点、鉴权头与请求体(温度 / max_tokens 兜底)', () async {
      final transport = _FakeSseTransport(['data: {"type":"message_stop"}', '']);
      await _run(DeepSeekClient(_config(temperature: 0.3), transport));

      expect(transport.lastUrl, 'https://api.deepseek.com/v1/messages');
      expect(transport.lastHeaders!['x-api-key'], 'sk-test');
      expect(transport.lastHeaders!['anthropic-version'], '2023-06-01');

      final body = transport.lastBody!;
      expect(body['model'], 'deepseek-chat');
      expect(body['max_tokens'], 8192); // 未配置输出上限时的兜底
      expect(body['system'], '你是助手');
      expect(body['stream'], true);
      expect(body['temperature'], 0.3);
      final messages = (body['messages'] as List).cast<Map>();
      expect(messages.single['role'], 'user');
      expect(messages.single['content'], '你好');
    });

    test('useFullUrl 直用 baseUrl;无温度时省略该字段', () async {
      final transport = _FakeSseTransport(['data: {"type":"message_stop"}', '']);
      await _run(DeepSeekClient(
        _config(
          baseUrl: 'https://gateway.test/anthropic/v1/messages',
          useFullUrl: true,
          maxOutputTokens: 4096,
        ),
        transport,
      ));

      expect(transport.lastUrl, 'https://gateway.test/anthropic/v1/messages');
      expect(transport.lastBody!['max_tokens'], 4096);
      expect(transport.lastBody!.containsKey('temperature'), isFalse);
    });

    test('CRLF 行尾容忍', () async {
      final transport = _FakeSseTransport([
        'data: {"type":"message_start","message":{"usage":{"input_tokens":3}}}\r',
        '\r',
        'data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"A"}}\r',
        '\r',
        'data: {"type":"message_stop"}\r',
        '\r',
      ]);

      final response = await _run(DeepSeekClient(_config(), transport));
      expect(response.content, 'A');
      expect(response.inputTokens, 3);
    });

    test('流内 error 事件抛错', () async {
      final transport = _FakeSseTransport([
        'data: {"type":"error","error":{"type":"overloaded_error","message":"服务过载"}}',
        '',
      ]);

      await expectLater(
        DeepSeekClient(_config(), transport)
            .completeStream(systemPrompt: '你是助手', messages: _messages)
            .toList(),
        throwsA(isA<LlmStreamApiException>()
            .having((e) => e.code, 'code', 'overloaded_error')
            .having((e) => e.message, 'message', contains('overloaded_error'))),
      );
    });

    test('缺 message_stop 视为断流', () async {
      final transport = _FakeSseTransport([
        'data: {"type":"message_start","message":{"usage":{"input_tokens":3}}}',
        '',
      ]);

      await expectLater(
        DeepSeekClient(_config(), transport)
            .completeStream(systemPrompt: '你是助手', messages: _messages)
            .toList(),
        throwsA(isA<LlmNetworkException>()),
      );
    });

    test('内容真正产出时才调用 onContent', () async {
      var contentCalls = 0;
      final transport = _FakeSseTransport([
        'data: {"type":"message_start","message":{"usage":{"input_tokens":1}}}',
        '',
        'data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"A"}}',
        '',
        'data: {"type":"content_block_delta","delta":{"type":"thinking_delta","thinking":"想"}}',
        '',
        'data: {"type":"message_stop"}',
        '',
      ]);

      final chunks = await DeepSeekClient(_config(), transport)
          .attemptStream(
            systemPrompt: '你是助手',
            messages: _messages,
            onContent: () => contentCalls++,
          )
          .toList();

      expect(contentCalls, 2); // 1 次正文 + 1 次思考
      expect(chunks.whereType<FinalChunk>().single.response.content, 'A');

      var emptyCalls = 0;
      final empty = _FakeSseTransport([
        'data: {"type":"message_start","message":{"usage":{"input_tokens":1}}}',
        '',
        'data: {"type":"message_stop"}',
        '',
      ]);
      final emptyChunks = await DeepSeekClient(_config(), empty)
          .attemptStream(
            systemPrompt: '你是助手',
            messages: _messages,
            onContent: () => emptyCalls++,
          )
          .toList();

      expect(emptyCalls, 0);
      expect(emptyChunks.whereType<FinalChunk>().single.response.content, isEmpty);
    });
  });
}