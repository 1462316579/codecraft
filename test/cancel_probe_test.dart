import 'dart:async';

import 'package:codecraft/agent/models/chat_session.dart';
import 'package:codecraft/agent/protocols/http_transport.dart';
import 'package:codecraft/agent/protocols/llm_client.dart';
import 'package:codecraft/agent/protocols/openai_client.dart';
import 'package:codecraft/agent/protocols/sse.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_test/flutter_test.dart';

Stream<String> heartbeat() async* {
  yield 'data: {"choices":[{"delta":{"content":"半"}}]}';
  yield '';
  while (true) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    yield ': ping';
  }
}

class HeartbeatTransport implements SseTransport {
  @override
  Stream<String> postSseLines({
    required String url,
    required Map<String, dynamic> body,
    required Map<String, String> headers,
    Duration? idleTimeout,
    CancelToken? cancelToken,
  }) =>
      heartbeat();
}

void main() {
  test('直接取消 heartbeat', () async {
    final sub = heartbeat().listen((_) {});
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await sub.cancel().timeout(const Duration(seconds: 2));
  });

  test('通过 sseDataEvents 取消', () async {
    final sub = sseDataEvents(heartbeat()).listen((_) {});
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await sub.cancel().timeout(const Duration(seconds: 2));
  });

  test('通过 OpenAiClient.completeStream 取消', () async {
    final client = OpenAiClient(
      const LlmClientConfig(apiKey: 'k', baseUrl: 'https://x', model: 'm'),
      HeartbeatTransport(),
    );
    final sub = client
        .completeStream(systemPrompt: 'sys', messages: const [], effort: ReasoningEffort.medium)
        .listen((_) {});
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await sub.cancel().timeout(const Duration(seconds: 3));
  });
}