import 'dart:async';

import 'package:codecraft/agent/models/agent_message.dart';
import 'package:codecraft/agent/models/chat_session.dart';
import 'package:codecraft/agent/protocols/errors.dart';
import 'package:codecraft/agent/protocols/http_transport.dart';
import 'package:codecraft/agent/protocols/llm_client.dart';
import 'package:codecraft/agent/protocols/stream_utils.dart';
import 'package:codecraft/agent/tools/tool.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_test/flutter_test.dart';

/// 永不产出事件的传输(首字节超时场景)。
class _SilentTransport implements SseTransport {
  @override
  Stream<String> postSseLines({
    required String url,
    required Map<String, dynamic> body,
    required Map<String, String> headers,
    Duration? idleTimeout,
    CancelToken? cancelToken,
  }) =>
      const Stream<String>.empty();
}

/// 请求发出后一直静默的客户端。
class _SilentClient extends LlmClient {
  _SilentClient(LlmClientConfig config) : super(config, _SilentTransport());

  @override
  Stream<AiStreamChunk> attemptStream({
    required String systemPrompt,
    required List<AgentMessage> messages,
    List<AgentTool> tools = const [],
    ReasoningEffort? effort,
    required void Function() onContent,
    CancelToken? cancelToken,
  }) =>
      StreamController<AiStreamChunk>().stream;
}

void main() {
  test('首个事件按时到达:照常转发,之后的静默不再受首字节超时约束', () async {
    final controller = StreamController<int>();
    final stream = firstByteTimeoutStream(
      source: controller.stream,
      timeout: const Duration(milliseconds: 30),
      onTimeout: () => LlmNetworkException('超时'),
    );
    final received = <int>[];
    final done = Completer<void>();
    stream.listen(received.add, onError: done.completeError, onDone: done.complete);

    controller.add(1);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    controller.add(2);
    await controller.close();
    await done.future;

    expect(received, [1, 2], reason: '第一个事件到达后不应再被超时打断');
  });

  test('首个事件迟迟不来:以网络异常收尾(可被上层重试)', () async {
    final stream = firstByteTimeoutStream(
      source: StreamController<int>().stream,
      timeout: const Duration(milliseconds: 20),
      onTimeout: () => LlmNetworkException('等待首个响应块超时'),
    );

    await expectLater(stream, emitsError(isA<LlmNetworkException>()));
    expect(isRetryableError(LlmNetworkException('等待首个响应块超时')), isTrue);

    // 流内错误的可重试性按错误码分类(对齐上游 NON_RETRYABLE_STREAM_CODES):
    // 不分类的话 invalid_request_error / context_window_exceeded 会被重试到上限,
    // 而这些错误重试永远不会成功。
    expect(isRetryableError(const LlmStreamApiException('invalid_request_error', '参数不对')), isFalse);
    expect(isRetryableError(const LlmStreamApiException('context_window_exceeded', '太长')), isFalse);
    expect(isRetryableError(const LlmStreamApiException('quota_exceeded', '额度')), isFalse);
    expect(isRetryableError(const LlmStreamApiException('rate_limit_exceeded', '限流')), isFalse);
    expect(isRetryableError(const LlmStreamApiException('overloaded_error', '忙')), isTrue);
    expect(isRetryableError(const LlmStreamApiException('server_error', '服务端')), isTrue);
    expect(isRetryableError(const LlmStreamApiException(null, '未知码')), isTrue);
    // 码表大小写不敏感(上游按 lowercase 比对)。
    expect(isRetryableError(const LlmStreamApiException('Invalid_Request', 'x')), isFalse);
  });

  test('客户端按配置等待首字节:超时抛网络异常,重试耗尽后报错', () async {
    final client = _SilentClient(LlmClientConfig(
      apiKey: 'k',
      baseUrl: 'https://example.com',
      model: 'm',
      firstByteTimeout: const Duration(milliseconds: 20),
      maxRetries: 1,
      baseRetryDelay: const Duration(milliseconds: 1),
    ));

    final chunks = <AiStreamChunk>[];
    Object? failure;
    final done = Completer<void>();
    client
        .completeStream(systemPrompt: 's', messages: const [])
        .listen(chunks.add, onError: (Object e) => failure = e, onDone: done.complete);
    await done.future;

    expect(chunks.whereType<Retrying>().length, 1, reason: '首字节超时应触发一次重试');
    expect(failure, isA<LlmNetworkException>());
  });
}