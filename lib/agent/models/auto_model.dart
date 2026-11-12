import 'model_metadata.dart';

/// 「Auto Model」要处理的请求特征,用于挑选合适的模型。
class AutoModelRequest {
  const AutoModelRequest({
    this.hasImages = false,
    this.needsTools = false,
    this.wantsReasoning = false,
    this.approxInputTokens = 0,
  });

  /// 本轮带图片附件(需要视觉能力)。
  final bool hasImages;

  /// 本轮需要调用工具(agent 循环几乎总是需要)。
  final bool needsTools;

  /// 用户显式选了思考强度,或任务偏推理。
  final bool wantsReasoning;

  /// 估算的输入 token 量(上下文占用 + 本轮消息)。
  final int approxInputTokens;
}

/// 一个候选模型(某供应商下的某个模型名 + 它的元数据)。
class AutoModelCandidate {
  const AutoModelCandidate({
    required this.providerId,
    required this.model,
    required this.metadata,
  });

  final String providerId;
  final String model;
  final ModelMetadata metadata;

  /// 上下文窗口是否够用(元数据缺失时按「够用」处理,避免把信息不全的模型全排除)。
  bool fits(AutoModelRequest request) =>
      metadata.contextTokens <= 0 || metadata.contextTokens >= request.approxInputTokens;
}

/// 按任务特征挑选模型的纯函数(Auto Model 的核心规则)。
///
/// 排序思路(越靠前越优先):
/// 1. **硬性能力**:带图片必须支持视觉;需要工具必须支持工具;窗口装不下直接排除;
/// 2. **推理需求**:需要推理时优先支持 reasoning 的模型;
/// 3. **成本**:同等条件下选输入单价更低的(缺价格信息视为最贵,避免盲选贵模型);
/// 4. **上下文窗口**:更大者优先(同价时更能扛长对话)。
///
/// 没有任何候选满足硬性能力时返回 null,由调用方回退到当前供应商的默认模型
/// ——宁可退化也不要因为元数据缺失把请求打挂。
class AutoModelRouter {
  AutoModelRouter._();

  static AutoModelCandidate? pick(
    List<AutoModelCandidate> candidates,
    AutoModelRequest request,
  ) {
    final viable = [
      for (final candidate in candidates)
        if (_meetsHardRequirements(candidate.metadata, request)) candidate,
    ];
    if (viable.isEmpty) return null;

    viable.sort((a, b) => _compare(a, b, request));
    return viable.first;
  }

  static bool _meetsHardRequirements(ModelMetadata metadata, AutoModelRequest request) {
    if (request.hasImages && !metadata.supportsVision) return false;
    if (request.needsTools && !metadata.supportsTools) return false;
    if (metadata.contextTokens > 0 && metadata.contextTokens < request.approxInputTokens) {
      return false;
    }
    return true;
  }

  static int _compare(AutoModelCandidate a, AutoModelCandidate b, AutoModelRequest request) {
    // 1) 需要推理时,支持 reasoning 的优先。
    if (request.wantsReasoning && a.metadata.supportsReasoning != b.metadata.supportsReasoning) {
      return a.metadata.supportsReasoning ? -1 : 1;
    }
    // 2) 输入单价低者优先;缺价格的排后面。
    final costA = a.metadata.inputCostUsdPerM;
    final costB = b.metadata.inputCostUsdPerM;
    if (costA != null && costB != null && costA != costB) {
      return costA.compareTo(costB);
    }
    if (costA == null && costB != null) return 1;
    if (costA != null && costB == null) return -1;
    // 3) 上下文窗口大者优先。
    if (a.metadata.contextTokens != b.metadata.contextTokens) {
      return b.metadata.contextTokens.compareTo(a.metadata.contextTokens);
    }
    // 4) 稳定兜底:按模型名排序,保证同样输入总是选同一个。
    return a.model.compareTo(b.model);
  }
}

/// 「Auto Model」在会话里存的值:模型字段为 null/空时表示交给 Auto 路由。
///
/// 用哨兵常量而不是 null 语义扩散到全链路:UI 与存储都只认一个字符串。
const String autoModelSentinel = 'auto';

/// 该模型值是否代表 Auto。
bool isAutoModel(String? model) {
  final value = model?.trim().toLowerCase();
  return value == null || value.isEmpty || value == autoModelSentinel;
}