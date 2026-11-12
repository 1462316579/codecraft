/// 模型元数据(对齐上游 ModelMetadata 的子集):上下文窗口、价格与能力标签。
class ModelMetadata {
  const ModelMetadata({
    required this.id,
    this.providerId,
    String? displayName,
    this.contextTokens = 0,
    this.inputTokens,
    this.outputTokens,
    this.supportsTools = false,
    this.supportsVision = false,
    this.supportsReasoning = false,
    this.supportsImageOutput = false,
    this.reasoningCanDisable = false,
    this.reasoningEffortOptions,
    this.inputCostUsdPerM,
    this.outputCostUsdPerM,
    this.cacheReadCostUsdPerM,
    this.cacheWriteCostUsdPerM,
  }) : displayName = displayName ?? id;

  final String id;
  final String? providerId;
  final String displayName;
  final int contextTokens;
  final int? inputTokens;
  final int? outputTokens;
  final bool supportsTools;
  final bool supportsVision;
  final bool supportsReasoning;
  final bool supportsImageOutput;

  /// 思考是否可关闭(models.dev reasoning_options 的 toggle 声明,或用户手工标注)。
  final bool reasoningCanDisable;

  /// models.dev 的思考强度档位(`reasoning_options` 里 effort 类型的 values,
  /// 如 `['low','high','max']`)。null/空 = 该模型无档位信息,界面回退到全部档位。
  final List<String>? reasoningEffortOptions;

  /// 单价(USD / 1M tokens)。
  final double? inputCostUsdPerM;
  final double? outputCostUsdPerM;
  final double? cacheReadCostUsdPerM;
  final double? cacheWriteCostUsdPerM;

  Map<String, Object?> toJson() => {
        'id': id,
        'providerId': providerId,
        'displayName': displayName,
        'contextTokens': contextTokens,
        'inputTokens': inputTokens,
        'outputTokens': outputTokens,
        'supportsTools': supportsTools,
        'supportsVision': supportsVision,
        'supportsReasoning': supportsReasoning,
        'supportsImageOutput': supportsImageOutput,
        'reasoningCanDisable': reasoningCanDisable,
        'reasoningEffortOptions': reasoningEffortOptions,
        'inputCostUsdPerM': inputCostUsdPerM,
        'outputCostUsdPerM': outputCostUsdPerM,
        'cacheReadCostUsdPerM': cacheReadCostUsdPerM,
        'cacheWriteCostUsdPerM': cacheWriteCostUsdPerM,
      };

  static ModelMetadata fromJson(String id, Map<String, Object?> map) => ModelMetadata(
        id: id,
        providerId: map['providerId'] as String?,
        displayName: map['displayName'] as String?,
        contextTokens: (map['contextTokens'] as num?)?.toInt() ?? 0,
        inputTokens: (map['inputTokens'] as num?)?.toInt(),
        outputTokens: (map['outputTokens'] as num?)?.toInt(),
        supportsTools: (map['supportsTools'] as bool?) ?? false,
        supportsVision: (map['supportsVision'] as bool?) ?? false,
        supportsReasoning: (map['supportsReasoning'] as bool?) ?? false,
        supportsImageOutput: (map['supportsImageOutput'] as bool?) ?? false,
        reasoningCanDisable: (map['reasoningCanDisable'] as bool?) ?? false,
        reasoningEffortOptions: (map['reasoningEffortOptions'] as List?)
            ?.map((value) => '$value')
            .toList(),
        inputCostUsdPerM: (map['inputCostUsdPerM'] as num?)?.toDouble(),
        outputCostUsdPerM: (map['outputCostUsdPerM'] as num?)?.toDouble(),
        cacheReadCostUsdPerM: (map['cacheReadCostUsdPerM'] as num?)?.toDouble(),
        cacheWriteCostUsdPerM: (map['cacheWriteCostUsdPerM'] as num?)?.toDouble(),
      );
}

/// 元数据键:不能只按模型名索引——单价按「提供商ID:模型名」存储。
String modelMetadataKey(String providerId, String model) => '$providerId:$model';

/// 合并自定义元数据与自动解析元数据,自定义优先;窗口未填时保留自动值。
ModelMetadata mergeModelMetadata(String model, ModelMetadata? base, ModelMetadata? custom) {
  final a = base ??
      ModelMetadata(id: model, displayName: model);
  final c = custom;
  if (c == null) return a;
  return ModelMetadata(
    id: model,
    displayName: model,
    providerId: c.providerId ?? a.providerId,
    contextTokens: c.contextTokens > 0 ? c.contextTokens : a.contextTokens,
    inputTokens: c.inputTokens ?? a.inputTokens,
    outputTokens: c.outputTokens ?? a.outputTokens,
    supportsTools: c.supportsTools,
    supportsVision: c.supportsVision,
    supportsReasoning: c.supportsReasoning,
    supportsImageOutput: c.supportsImageOutput,
    reasoningCanDisable: c.reasoningCanDisable || a.reasoningCanDisable,
    // 思考档位:自定义显式填了就以自定义为准(中转站改名后可自行纠正),未填沿用目录识别值。
    reasoningEffortOptions:
        (c.reasoningEffortOptions != null && c.reasoningEffortOptions!.isNotEmpty)
            ? c.reasoningEffortOptions
            : a.reasoningEffortOptions,
    inputCostUsdPerM: c.inputCostUsdPerM ?? a.inputCostUsdPerM,
    outputCostUsdPerM: c.outputCostUsdPerM ?? a.outputCostUsdPerM,
    cacheReadCostUsdPerM: c.cacheReadCostUsdPerM ?? a.cacheReadCostUsdPerM,
    cacheWriteCostUsdPerM: c.cacheWriteCostUsdPerM ?? a.cacheWriteCostUsdPerM,
  );
}