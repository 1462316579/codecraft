import 'dart:math' as math;

import 'models/model_metadata.dart';

/// 上下文窗口与 token 预算策略(对齐上游 ModelContextPolicy)。
class ContextPolicy {
  const ContextPolicy._();

  static const int defaultContextTokens = 128000;
  static const int minPreserveRecentTokens = 2000;
  static const int maxPreserveRecentTokens = 128000;
  static const int charsPerToken = 4;

  /// 压缩分块预算的保守口径:代码/JSON 等内容的真实 token 密度高于自然语言,
  /// 4 字符/token 会低估,改用 3 并叠加 budgetRatio,避免摘要请求超上游窗口。
  static const int compactionCharsPerToken = 3;
  static const double compactionBudgetRatio = 0.8;

  /// 压缩时原样保留的最近上下文按窗口大小取(1/8),上下限兜底,避免大窗口只留固定 20K。
  static int preserveRecentTokens(int usableTokens) =>
      (usableTokens ~/ 8).clamp(minPreserveRecentTokens, maxPreserveRecentTokens);

  static int estimateTokens(int chars, [int charsPerToken = charsPerToken]) =>
      chars ~/ charsPerToken + (chars % charsPerToken == 0 ? 0 : 1);

  /// ASCII 按字符密度估算,CJK 等非 ASCII 每字 1 token(与上游同口径)。
  static int estimateTextTokens(String text, [int charsPerToken = charsPerToken]) {
    var ascii = 0;
    var other = 0;
    for (final ch in text.runes) {
      if (ch < 128) {
        ascii++;
      } else {
        other++;
      }
    }
    return estimateTokens(ascii, charsPerToken) + other;
  }

  /// 为输出预留的 token:窗口的 1/10,夹在 1K 到 8K 之间且不超过窗口 1/4;
  /// 模型声明了输出上限时取更小值。
  static int outputReserveTokens(ModelMetadata metadata) {
    final context = metadata.contextTokens > 0 ? metadata.contextTokens : defaultContextTokens;
    var reserve = (context ~/ 10).clamp(1024, 8192);
    reserve = math.min(reserve, context ~/ 4);
    final output = metadata.outputTokens;
    return (output != null && output > 0) ? math.min(output, reserve) : reserve;
  }

  /// 输入预算 = 窗口减去输出预留;模型声明了输入上限时取更小值。
  static int effectiveInputBudget(ModelMetadata metadata) {
    final context = metadata.contextTokens > 0 ? metadata.contextTokens : defaultContextTokens;
    final shared = math.max(context - outputReserveTokens(metadata), 1);
    final input = metadata.inputTokens;
    return (input != null && input > 0) ? math.min(input, shared) : shared;
  }
}
