import 'dart:async';

import 'package:dio/dio.dart';

import '../models/agent_message.dart';
import '../models/chat_session.dart';
import '../tools/tool.dart';
import 'errors.dart';
import 'http_transport.dart';
import 'stream_utils.dart';

/// 一轮补全的完整结果(流结束后由 Final 分块携带)。
class AiResponse {
  const AiResponse({
    required this.content,
    this.toolCalls = const [],
    this.reasoning,
    this.stopReason,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.cachedInputTokens = 0,
    this.cacheCreationTokens = 0,
  });

  final String content;

  /// 本轮模型请求的工具调用(tool/function calling)。
  final List<ToolCall> toolCalls;

  /// 本轮模型的完整思考过程(OpenAI 兼容协议的 reasoning_content 等)。
  final String? reasoning;

  /// 模型停止原因:Anthropic `end_turn`/`max_tokens`;OpenAI `stop`/`length`;Gemini `STOP` 等。
  final String? stopReason;

  final int inputTokens;
  final int outputTokens;

  /// 输入中命中服务端缓存的部分(cached_tokens / cache_read_input_tokens / cachedContentTokenCount)。
  final int cachedInputTokens;

  /// 写入服务端缓存的 token 数(Anthropic cache_creation_input_tokens)。
  final int cacheCreationTokens;

  bool get isTruncated =>
      stopReason == 'max_tokens' || stopReason == 'length' || stopReason == 'MAX_TOKENS';
}

/// 流式补全过程中向上游推送的分块(对应原仓库 AIStreamChunk,Phase 1 取文本子集)。
sealed class AiStreamChunk {
  const AiStreamChunk();
}

class TextDelta extends AiStreamChunk {
  const TextDelta(this.text);
  final String text;
}

/// 模型新吐出的一小段思考过程(增量,非累积);仅用于实时展示。
class ReasoningDelta extends AiStreamChunk {
  const ReasoningDelta(this.text);
  final String text;
}

/// 网络请求正在重试(仅用于 UI 提示)。
class Retrying extends AiStreamChunk {
  const Retrying({required this.attempt, required this.maxRetries, required this.error});
  final int attempt;
  final int maxRetries;
  final String error;
}

/// 本轮结束:聚合后的完整结果。
class FinalChunk extends AiStreamChunk {
  const FinalChunk(this.response);
  final AiResponse response;
}

/// 客户端运行配置(由 ChatController 依据供应商配置与会话设置装配)。
class LlmClientConfig {
  const LlmClientConfig({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    this.useFullUrl = false,
    this.maxOutputTokens,
    this.temperature,
    this.firstByteTimeout,
    this.idleTimeout,
    this.maxRetries = 6,
    this.baseRetryDelay = const Duration(seconds: 2),
    this.customHeaders = const {},
  });

  final String apiKey;
  final String baseUrl;
  final String model;

  /// 供应商自定义请求头(同名默认头被完全覆盖)。
  final Map<String, String> customHeaders;

  /// true 时 baseUrl 视为完整端点 URL,不再拼接协议默认路径。
  final bool useFullUrl;

  final int? maxOutputTokens;

  /// 采样温度;null 表示请求不带该字段(服务端默认)。
  final double? temperature;

  /// 等待首个响应块的最大时长;null 表示不限制。
  final Duration? firstByteTimeout;

  /// 相邻数据块之间的最大等待;null 表示不限制。
  final Duration? idleTimeout;

  /// 网络请求最大重试次数(不含首次)。
  final int maxRetries;

  final Duration baseRetryDelay;
}

/// 统一的流式补全客户端。三家协议各自实现 [attemptStream]。
abstract class LlmClient {
  LlmClient(this.config, this.transport);

  final LlmClientConfig config;
  final SseTransport transport;

  /// 单轮流式补全(含重试与取消)。
  Stream<AiStreamChunk> completeStream({
    required String systemPrompt,
    required List<AgentMessage> messages,
    List<AgentTool> tools = const [],
    ReasoningEffort? effort,
    CancelToken? cancelToken,
  }) {
    var emitted = false;
    return runWithRetry(
      attempt: () => _guardFirstByte(
        attemptStream(
          systemPrompt: systemPrompt,
          messages: messages,
          tools: tools,
          effort: effort,
          onContent: () => emitted = true,
          cancelToken: cancelToken,
        ),
      ),
      maxRetries: config.maxRetries,
      baseDelay: config.baseRetryDelay,
      hasEmitted: () => emitted,
    );
  }

  /// 首个响应块超时(可被上层重试):只约束第一个分块,之后的间隔交给空闲超时。
  Stream<AiStreamChunk> _guardFirstByte(Stream<AiStreamChunk> source) {
    final timeout = config.firstByteTimeout;
    if (timeout == null) return source;
    return firstByteTimeoutStream(
      source: source,
      timeout: timeout,
      onTimeout: () => LlmNetworkException('等待首个响应块超时(${timeout.inSeconds} 秒)'),
    );
  }

  /// 单次尝试:构造请求、解析 SSE、产出分块。内容真正产出时调用 [onContent](供重试判定)。
  Stream<AiStreamChunk> attemptStream({
    required String systemPrompt,
    required List<AgentMessage> messages,
    List<AgentTool> tools = const [],
    ReasoningEffort? effort,
    required void Function() onContent,
    CancelToken? cancelToken,
  });
}

/// 仅当尚未产出任何内容时重试的包装器:失败重试会先推 [Retrying] 提示,再指数退避重发。
///
/// 与 forwardStream 同理,不用 async* 实现:静默期取消必须能立即透传。
Stream<AiStreamChunk> runWithRetry({
  required Stream<AiStreamChunk> Function() attempt,
  required int maxRetries,
  required Duration baseDelay,
  required bool Function() hasEmitted,
}) {
  late StreamController<AiStreamChunk> controller;
  StreamSubscription<AiStreamChunk>? current;
  var cancelled = false;
  var finished = false;
  var attemptNo = 0;

  void emit(AiStreamChunk chunk) {
    if (!cancelled && !finished) controller.add(chunk);
  }

  void closeWithError(Object error, StackTrace stack) {
    if (cancelled || finished) return;
    finished = true;
    controller.addError(error, stack);
    unawaited(controller.close());
  }

  Future<void> retryOrFail(Object error, StackTrace stack, void Function() next) async {
    if (cancelled || finished) return;
    if (hasEmitted() || attemptNo >= maxRetries || !isRetryableError(error)) {
      closeWithError(error, stack);
      return;
    }
    attemptNo++;
    emit(Retrying(attempt: attemptNo, maxRetries: maxRetries, error: describeError(error)));
    await Future<void>.delayed(baseDelay * attemptNo);
    if (cancelled || finished) return;
    next();
  }

  void listenAttempt() {
    try {
      current = attempt().listen(
        emit,
        cancelOnError: true,
        onError: (Object error, StackTrace stack) {
          unawaited(retryOrFail(error, stack, listenAttempt));
        },
        onDone: () {
          if (cancelled || finished) return;
          finished = true;
          unawaited(controller.close());
        },
      );
    } catch (error, stack) {
      // 构造请求阶段就抛错的情况(attempt() 同步抛)也走重试/失败路径
      unawaited(retryOrFail(error, stack, listenAttempt));
    }
  }

  controller = StreamController<AiStreamChunk>(
    onListen: listenAttempt,
    onPause: () => current?.pause(),
    onResume: () => current?.resume(),
    onCancel: () async {
      cancelled = true;
      await current?.cancel();
    },
  );
  return controller.stream;
}