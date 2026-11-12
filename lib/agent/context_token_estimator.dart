import 'dart:convert';
import 'dart:math' as math;

import 'context_policy.dart';
import 'models/agent_message.dart';
import 'tools/tool.dart';

/// 上下文 token 估算器(对齐上游 ContextTokenEstimator):
/// 系统提示词 + 工具定义(名+描述+schema,各带固定开销)+ 逐消息估算。
class ContextTokenEstimator {
  const ContextTokenEstimator._();

  static int estimate(
    String systemPrompt,
    List<AgentMessage> messages,
    List<AgentTool> tools, [
    int charsPerToken = ContextPolicy.charsPerToken,
  ]) {
    var total = ContextPolicy.estimateTextTokens(systemPrompt, charsPerToken);
    for (final tool in tools) {
      total += ContextPolicy.estimateTextTokens(
            '${tool.name}${tool.description}${jsonEncode(tool.toJsonSchema())}',
            charsPerToken,
          ) +
          16;
    }
    for (final message in messages) {
      total += estimateMessage(message, charsPerToken);
    }
    return math.min(total, 0x7FFFFFFF);
  }

  static int estimateMessage(
    AgentMessage message, [
    int charsPerToken = ContextPolicy.charsPerToken,
  ]) {
    var text = '';
    switch (message.role) {
      case MessageRole.user:
        text = message.content;
      case MessageRole.assistant:
        final toolCalls = StringBuffer();
        for (final call in ToolCall.decodeList(message.toolCallsJson)) {
          toolCalls
            ..write(call.name)
            ..write(jsonEncode(call.arguments));
        }
        text = '${message.content}${message.reasoning ?? ''}$toolCalls';
      case MessageRole.tool:
        text = '${message.toolName ?? ''}${message.content}';
    }
    final images = message.attachments.where((attachment) => attachment.isImage).length;
    return math.min(
      ContextPolicy.estimateTextTokens(text, charsPerToken) + images * 4096 + 12,
      0x7FFFFFFF,
    );
  }

  /// 有上游实测用量时以它为锚点,只把锚点之后新增内容的估算增量叠上去;
  /// 不能再和整体估算取大——固定开销(系统提示词与工具定义)的估算偏高时,
  /// 取大会让真实 10k 的上下文被判成超预算(对齐上游 b1416cb4)。
  static int calibrated(int estimated, int baselineEstimate, int baselineUsage) {
    if (baselineUsage > 0) {
      return math.min(baselineUsage + math.max(estimated - baselineEstimate, 0), 0x7FFFFFFF);
    }
    return estimated;
  }
}
