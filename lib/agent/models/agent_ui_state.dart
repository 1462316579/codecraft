import 'agent_attachment.dart';
import 'agent_message.dart';

/// 网络请求重试状态(仅用于 UI 实时展示「正在重试 (N/M)」)。
class RetryState {
  const RetryState({required this.attempt, required this.maxRetries, required this.error});

  final int attempt;
  final int maxRetries;
  final String error;
}

/// 聊天页可本地化的错误码;[ChatViewState.errorDetail] 携带技术细节。
enum ChatErrorCode {
  /// 未配置可用的供应商(无启用项或缺 Key)。
  noProvider,

  /// 供应商未选择模型。
  noModel,

  /// 模型返回了不可见的空白内容(零宽/填充字形)。
  emptyResponse,

  /// 其它错误,细节见 errorDetail。
  generic,
}

/// 待用户确认的工具调用(对齐上游 PendingToolPermission)。
class PendingPermission {
  const PendingPermission({
    required this.id,
    required this.toolName,
    required this.title,
    required this.summary,
    required this.details,
    this.argsPreview = '',
    this.rememberablePatterns = const [],
    this.rememberDisabledReason,
  });

  final String id;
  final String toolName;

  /// 卡片标题(如「确认执行工具」「确认调用 MCP 工具」)。
  final String title;
  final String summary;

  /// 等宽详情(默认是参数预览;工具可给更具体的上下文)。
  final String details;
  final String argsPreview;

  /// 「始终允许」将记忆的模式;空表示不可记忆(禁用「始终允许」)。
  final List<String> rememberablePatterns;
  final String? rememberDisabledReason;
}

/// 会话内聊天视图状态(由 ChatController 产出)。
class ChatViewState {
  const ChatViewState({
    this.sessionId,
    this.messages = const [],
    this.loaded = false,
    this.streaming = false,
    this.messageLimit = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.streamingText = '',
    this.streamingReasoning = '',
    this.retry,
    this.errorCode,
    this.errorDetail,
    this.pendingAttachments = const [],
    this.pendingPermission,
    this.runningToolName,
    this.rewindTargetMessageId,
    this.rewindConflicts = const [],
    this.compacting = false,
  });

  final String? sessionId;
  final List<AgentMessage> messages;
  final bool loaded;
  final bool streaming;

  /// 已加载的消息条数上限:0 = 全量加载;>0 = 只加载了最新的 N 条(可向上补载更早消息)。
  final int messageLimit;

  /// 是否还有更早的消息未加载(分页补载用)。
  final bool hasMore;

  /// 正在补载更早的消息(防止滚动重复触发)。
  final bool isLoadingMore;

  /// 正在流式接收的正文与思考过程(尚未落库)。
  final String streamingText;
  final String streamingReasoning;

  final RetryState? retry;
  final ChatErrorCode? errorCode;
  final String? errorDetail;

  /// 已附加、待随下一条消息发送的图片。
  final List<AgentAttachment> pendingAttachments;

  /// 正在等待用户确认的工具调用(非空时输入栏上方展示授权条)。
  final PendingPermission? pendingPermission;

  /// 正在执行的工具名(工具名在执行前就已确定,状态行据此说「正在整理待办」这类场景文案)。
  final String? runningToolName;

  /// 回退弹层当前选中的用户消息 id(非空时展示回退选项弹层)。
  final String? rewindTargetMessageId;

  /// 最近一次回滚因「存在本会话未见过的改动」而跳过的文件。
  /// 一次性状态:UI 展示后调 [clearRewindConflicts],避免重建时重复提示。
  final List<String> rewindConflicts;

  /// 正在执行上下文压缩(状态行提示用)。
  final bool compacting;

  ChatViewState copyWith({
    List<AgentMessage>? messages,
    bool? loaded,
    bool? streaming,
    int? messageLimit,
    bool? hasMore,
    bool? isLoadingMore,
    String? streamingText,
    String? streamingReasoning,
    RetryState? Function()? retry,
    ChatErrorCode? Function()? errorCode,
    String? Function()? errorDetail,
    List<AgentAttachment>? pendingAttachments,
    PendingPermission? Function()? pendingPermission,
    String? Function()? runningToolName,
    String? Function()? rewindTargetMessageId,
    List<String>? rewindConflicts,
    bool? compacting,
  }) {
    return ChatViewState(
      sessionId: sessionId,
      messages: messages ?? this.messages,
      loaded: loaded ?? this.loaded,
      streaming: streaming ?? this.streaming,
      messageLimit: messageLimit ?? this.messageLimit,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      streamingText: streamingText ?? this.streamingText,
      streamingReasoning: streamingReasoning ?? this.streamingReasoning,
      retry: retry == null ? this.retry : retry(),
      errorCode: errorCode == null ? this.errorCode : errorCode(),
      errorDetail: errorDetail == null ? this.errorDetail : errorDetail(),
      pendingAttachments: pendingAttachments ?? this.pendingAttachments,
      pendingPermission: pendingPermission == null ? this.pendingPermission : pendingPermission(),
      runningToolName: runningToolName == null ? this.runningToolName : runningToolName(),
      rewindTargetMessageId: rewindTargetMessageId == null
          ? this.rewindTargetMessageId
          : rewindTargetMessageId(),
      rewindConflicts: rewindConflicts ?? this.rewindConflicts,
      compacting: compacting ?? this.compacting,
    );
  }
}