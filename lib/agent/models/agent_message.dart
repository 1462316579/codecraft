import 'agent_attachment.dart';

/// 上下文压缩 marker:user 消息携带此内容时,其后紧跟的 assistant 消息是接手摘要
/// (对齐上游 CONTEXT_COMPACTION_MARKER)。
const String contextCompactionMarker = 'What did we do so far?';

/// 旧版摘要前缀(上游历史数据兼容识别用)。
const String contextSummaryLegacyPrefix = '【系统提示:早期的对话已被压缩,以下是之前的核心状态摘要】';

/// 消息角色(移植自原仓库 MessageRole)。
enum MessageRole {
  user,
  assistant,
  tool;

  static MessageRole parse(String? value) =>
      values.firstWhere((r) => r.name == value, orElse: () => MessageRole.user);
}

/// 一条聊天消息。字段对齐原仓库 AgentMessageEntity(含为后续工具循环预埋的 tool 字段)。
class AgentMessage {
  const AgentMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.toolCallsJson,
    this.toolCallId,
    this.toolName,
    this.toolArgs,
    this.isError = false,
    this.reasoning,
    this.signature,
    this.attachmentsJson,
    this.isCompacted = false,
    this.isContextSummary = false,
    this.isCompactionMarker = false,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.cachedInputTokens = 0,
    this.thinkingBlocksJson,
    this.isContextExcluded = false,
    this.compactedBySummaryId,
  });

  final String id;
  final String sessionId;
  final MessageRole role;
  final String content;
  final int timestamp;

  /// 仅 assistant:结构化的 tool_calls(Json 编码)。
  final String? toolCallsJson;

  /// 仅 tool:对应的 tool_call id。
  final String? toolCallId;

  /// 仅 tool:工具名。
  final String? toolName;

  /// 仅 tool:本次调用的参数(JSON 文本)。
  final String? toolArgs;

  /// 仅 tool:是否执行失败。
  final bool isError;

  /// 仅 assistant:本轮思考过程(供持久化展示与按需回传)。
  final String? reasoning;

  /// 仅 assistant:extended thinking 的加密签名。
  final String? signature;

  /// 仅 user:附件展示元数据(JSON)。
  final String? attachmentsJson;

  /// 解析后的附件列表(图片附件在发送时读盘转 base64)。
  List<AgentAttachment> get attachments => AgentAttachment.decodeList(attachmentsJson);

  final bool isCompacted;
  final bool isContextSummary;
  final bool isCompactionMarker;
  final int inputTokens;
  final int outputTokens;
  final int cachedInputTokens;
  final String? thinkingBlocksJson;
  final bool isContextExcluded;
  final String? compactedBySummaryId;

  AgentMessage copyWith({
    String? content,
    String? Function()? reasoning,
    int? inputTokens,
    int? outputTokens,
    int? cachedInputTokens,
    bool? isError,
  }) {
    return AgentMessage(
      id: id,
      sessionId: sessionId,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      toolCallsJson: toolCallsJson,
      toolCallId: toolCallId,
      toolName: toolName,
      toolArgs: toolArgs,
      isError: isError ?? this.isError,
      reasoning: reasoning == null ? this.reasoning : reasoning(),
      signature: signature,
      attachmentsJson: attachmentsJson,
      isCompacted: isCompacted,
      isContextSummary: isContextSummary,
      isCompactionMarker: isCompactionMarker,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      cachedInputTokens: cachedInputTokens ?? this.cachedInputTokens,
      thinkingBlocksJson: thinkingBlocksJson,
      isContextExcluded: isContextExcluded,
      compactedBySummaryId: compactedBySummaryId,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'sessionId': sessionId,
        'role': role.name,
        'content': content,
        'timestamp': timestamp,
        'toolCallsJson': toolCallsJson,
        'toolCallId': toolCallId,
        'toolName': toolName,
        'toolArgs': toolArgs,
        'isError': isError ? 1 : 0,
        'reasoning': reasoning,
        'signature': signature,
        'attachmentsJson': attachmentsJson,
        'isCompacted': isCompacted ? 1 : 0,
        'isContextSummary': isContextSummary ? 1 : 0,
        'isCompactionMarker': isCompactionMarker ? 1 : 0,
        'inputTokens': inputTokens,
        'outputTokens': outputTokens,
        'cachedInputTokens': cachedInputTokens,
        'thinkingBlocksJson': thinkingBlocksJson,
        'isContextExcluded': isContextExcluded ? 1 : 0,
        'compactedBySummaryId': compactedBySummaryId,
      };

  static AgentMessage fromMap(Map<String, Object?> map) => AgentMessage(
        id: map['id'] as String,
        sessionId: (map['sessionId'] as String?) ?? '',
        role: MessageRole.parse(map['role'] as String?),
        content: (map['content'] as String?) ?? '',
        timestamp: (map['timestamp'] as int?) ?? 0,
        toolCallsJson: map['toolCallsJson'] as String?,
        toolCallId: map['toolCallId'] as String?,
        toolName: map['toolName'] as String?,
        toolArgs: map['toolArgs'] as String?,
        isError: (map['isError'] as int? ?? 0) != 0,
        reasoning: map['reasoning'] as String?,
        signature: map['signature'] as String?,
        attachmentsJson: map['attachmentsJson'] as String?,
        isCompacted: (map['isCompacted'] as int? ?? 0) != 0,
        isContextSummary: (map['isContextSummary'] as int? ?? 0) != 0,
        isCompactionMarker: (map['isCompactionMarker'] as int? ?? 0) != 0,
        inputTokens: (map['inputTokens'] as int?) ?? 0,
        outputTokens: (map['outputTokens'] as int?) ?? 0,
        cachedInputTokens: (map['cachedInputTokens'] as int?) ?? 0,
        thinkingBlocksJson: map['thinkingBlocksJson'] as String?,
        isContextExcluded: (map['isContextExcluded'] as int? ?? 0) != 0,
        compactedBySummaryId: map['compactedBySummaryId'] as String?,
      );
}