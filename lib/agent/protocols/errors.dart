/// 协议层统一错误类型与判定。
class LlmHttpException implements Exception {
  LlmHttpException(this.statusCode, this.body) : message = 'HTTP $statusCode';

  final int statusCode;
  final String body;
  final String message;
}

class LlmNetworkException implements Exception {
  LlmNetworkException(this.message);

  final String message;
}

/// 面向 UI 的错误摘要(截断、去换行)。
String describeError(Object error) {
  final raw = switch (error) {
    LlmHttpException e => '${e.message} ${_snippet(e.body)}',
    LlmNetworkException e => e.message,
    _ => error.toString(),
  };
  return _snippet(raw);
}

String _snippet(String text, {int max = 220}) {
  final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return flat.length <= max ? flat : '${flat.substring(0, max)}…';
}

/// 是否值得重试:网络异常与 408/429/5xx;其余 4xx(鉴权、参数错误等)不重试。
/// 流内错误(SSE 的 `error` 事件):携带上游错误码,用于区分是否值得重试。
///
/// 上游用 `StreamApiException(code)` 交给重试策略按码分类;不区分码的话,
/// `invalid_request_error`、`context_window_exceeded` 这类永远不可能成功的错误会被重试到上限。
class LlmStreamApiException implements Exception {
  const LlmStreamApiException(this.code, this.message);

  /// 上游错误码(如 `invalid_request_error`、`overloaded_error`),可能为空。
  final String? code;

  final String message;

  @override
  String toString() => message.isEmpty ? (code ?? 'stream error') : message;
}

/// 明确不可重试的流内错误码(对齐上游 `NON_RETRYABLE_STREAM_CODES` / Codex CLI 的 is_retryable)。
///
/// 限流类也在此列:上游让它们优先走多 Key 自动切换,单 Key 无候选时由调用方按限流退避处理;
/// 额度类不是瞬时限流,重试无益。
const Set<String> nonRetryableStreamCodes = {
  'cyber_policy',
  'invalid_request_error',
  'invalid_request',
  'context_window_exceeded',
  'quota_exceeded',
  'usage_not_included',
  'usage_limit_reached',
  'insufficient_quota',
  'rate_limit_exceeded',
  'rate_limit_error',
  'invalid_image_request',
  'response_too_large',
};

bool isRetryableError(Object error) {
  if (error is LlmStreamApiException) {
    return !nonRetryableStreamCodes.contains(error.code?.toLowerCase());
  }
  if (error is LlmNetworkException) return true;
  if (error is LlmHttpException) {
    final code = error.statusCode;
    return code == 408 || code == 429 || code >= 500;
  }
  return false;
}