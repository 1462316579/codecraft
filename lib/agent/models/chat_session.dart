/// Agent 工作模式:开发(默认,可改代码)与写作(文字工作)。
enum AgentMode {
  build,
  write;

  static AgentMode parse(String? value) =>
      values.firstWhere((m) => m.name == value, orElse: () => AgentMode.build);
}

enum ReasoningEffort {
  none('none'),
  minimal('minimal'),
  low('low'),
  medium('medium'),
  high('high'),
  xhigh('xhigh'),
  max('max');

  const ReasoningEffort(this.apiValue);

  /// 透传给 provider 的取值(与 models.dev reasoning_options 一致)。
  final String apiValue;

  static ReasoningEffort parse(String? value) =>
      values.firstWhere((e) => e.name == value, orElse: () => ReasoningEffort.medium);

  /// 把 models.dev 的 effort values 解析为可识别的档位(保持原顺序,未知值丢弃)。
  static List<ReasoningEffort> fromValues(List<String> options) => [
        for (final option in options)
          for (final effort in ReasoningEffort.values)
            if (effort.apiValue == option.toLowerCase()) effort,
      ];
}

/// 一次独立的聊天会话。字段对齐原仓库 ChatSessionEntity(Phase 1 不含 goal/子代理字段)。
class ChatSession {
  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.mode = AgentMode.build,
    this.reasoningEffort = ReasoningEffort.medium,
    this.providerId,
    this.model,
    this.totalInputTokens = 0,
    this.totalOutputTokens = 0,
    this.lastInputTokens = 0,
    this.isPinned = false,
    this.projectId,
    this.parentId,
    this.subagentType,
  });

  final String id;
  final String title;
  final int createdAt;
  final int updatedAt;
  final AgentMode mode;

  final ReasoningEffort reasoningEffort;
  final String? providerId;
  final String? model;
  final int totalInputTokens;
  final int totalOutputTokens;
  final int lastInputTokens;
  final bool isPinned;

  /// 所属项目;v5 迁移前的旧数据为 null(迁移时已补齐)。
  final String? projectId;

  /// 父会话 id:子代理会话专有(对齐上游 ChatSessionEntity.parentId);
  /// 主会话为 null。子代理会话不出现在主列表,只经子代理卡片「进入会话」打开。
  final String? parentId;

  /// 子代理类型标识:子代理会话专有。通用子代理为 "subagent",自定义定义为名称。
  final String? subagentType;

  ChatSession copyWith({
    String? title,
    int? updatedAt,
    AgentMode? mode,
    ReasoningEffort? reasoningEffort,
    String? Function()? providerId,
    String? Function()? model,
    int? totalInputTokens,
    int? totalOutputTokens,
    int? lastInputTokens,
    bool? isPinned,
    String? projectId,
    String? Function()? parentId,
    String? Function()? subagentType,
  }) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mode: mode ?? this.mode,
      reasoningEffort: reasoningEffort ?? this.reasoningEffort,
      providerId: providerId == null ? this.providerId : providerId(),
      model: model == null ? this.model : model(),
      totalInputTokens: totalInputTokens ?? this.totalInputTokens,
      totalOutputTokens: totalOutputTokens ?? this.totalOutputTokens,
      lastInputTokens: lastInputTokens ?? this.lastInputTokens,
      isPinned: isPinned ?? this.isPinned,
      projectId: projectId ?? this.projectId,
      parentId: parentId == null ? this.parentId : parentId(),
      subagentType: subagentType == null ? this.subagentType : subagentType(),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'mode': mode.name,
        'reasoningEffort': reasoningEffort.name,
        'providerId': providerId,
        'model': model,
        'totalInputTokens': totalInputTokens,
        'totalOutputTokens': totalOutputTokens,
        'lastInputTokens': lastInputTokens,
        'isPinned': isPinned ? 1 : 0,
        'projectId': projectId,
        'parentId': parentId,
        'subagentType': subagentType,
      };

  static ChatSession fromMap(Map<String, Object?> map) => ChatSession(
        id: map['id'] as String,
        title: (map['title'] as String?) ?? '',
        createdAt: (map['createdAt'] as int?) ?? 0,
        updatedAt: (map['updatedAt'] as int?) ?? 0,
        mode: AgentMode.parse(map['mode'] as String?),
        reasoningEffort: ReasoningEffort.parse(map['reasoningEffort'] as String?),
        providerId: map['providerId'] as String?,
        model: map['model'] as String?,
        totalInputTokens: (map['totalInputTokens'] as int?) ?? 0,
        totalOutputTokens: (map['totalOutputTokens'] as int?) ?? 0,
        lastInputTokens: (map['lastInputTokens'] as int?) ?? 0,
        isPinned: (map['isPinned'] as int? ?? 0) != 0,
        projectId: map['projectId'] as String?,
        parentId: map['parentId'] as String?,
        subagentType: map['subagentType'] as String?,
      );
}