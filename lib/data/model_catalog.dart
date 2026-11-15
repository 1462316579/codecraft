import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/models/model_metadata.dart';
import 'providers/provider_config.dart';

/// 内置模型目录(models.dev 快照,随包发布)。
///
/// 用途:给「费用统计」与「Auto Model 路由」提供模型能力与价格。
/// 之前只读用户自定义元数据,没填价格就一律显示「—」——这是费用统计不工作的根因。
///
/// 取值优先级(与上游一致):**用户自定义元数据 > 内置目录 > 空**。
/// 自定义覆盖内置,所以用户仍可手工纠正某个模型的价格或能力。
class ModelCatalog {
  const ModelCatalog(this._byProvider);

  /// providerId → (小写模型名 → 元数据)。
  final Map<String, Map<String, ModelMetadata>> _byProvider;

  static const String assetPath = 'assets/models/api.official.json';

  static const ModelCatalog empty = ModelCatalog({});

  /// 从打包资产加载;资产缺失或解析失败时返回空目录(不抛,统计页照常显示)。
  static Future<ModelCatalog> loadFromAssets(AssetBundle bundle) async {
    try {
      final raw = await bundle.loadString(assetPath);
      return ModelCatalog.parse(raw);
    } catch (_) {
      return empty;
    }
  }

  /// 解析 models.dev 快照。providerId 用快照里的顶层键(如 `deepseek`、`anthropic`)。
  static ModelCatalog parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return empty;
    final byProvider = <String, Map<String, ModelMetadata>>{};
    for (final entry in decoded.entries) {
      final providerId = '${entry.key}';
      final provider = entry.value;
      if (provider is! Map) continue;
      final models = provider['models'];
      if (models is! Map) continue;
      final parsed = <String, ModelMetadata>{};
      for (final modelEntry in models.entries) {
        final modelId = '${modelEntry.key}';
        final model = modelEntry.value;
        if (model is! Map) continue;
        final metadata = _parseModel(providerId, modelId, model);
        if (metadata != null) parsed[modelId.toLowerCase()] = metadata;
      }
      if (parsed.isNotEmpty) byProvider[providerId] = parsed;
    }
    return ModelCatalog(byProvider);
  }

  static ModelMetadata? _parseModel(String providerId, String modelId, Map model) {
    final id = '${model['id'] ?? modelId}';
    if (id.trim().isEmpty) return null;
    final limit = model['limit'];
    final cost = model['cost'];
    final modalities = model['modalities'];
    final inputModalities = modalities is Map && modalities['input'] is List
        ? (modalities['input'] as List).map((e) => '$e').toSet()
        : const <String>{};
    final outputModalities = modalities is Map && modalities['output'] is List
        ? (modalities['output'] as List).map((e) => '$e').toSet()
        : const <String>{};
    return ModelMetadata(
      id: id,
      providerId: providerId,
      displayName: '${model['name'] ?? id}',
      contextTokens: _int(limit is Map ? limit['context'] : null) ?? 0,
      inputTokens: _int(limit is Map ? limit['input'] : null),
      outputTokens: _int(limit is Map ? limit['output'] : null),
      supportsTools: model['tool_call'] == true,
      supportsVision: inputModalities.contains('image') ||
          inputModalities.contains('video') ||
          inputModalities.contains('pdf'),
      supportsReasoning: model['reasoning'] == true,
      supportsImageOutput: outputModalities.contains('image') ||
          id.toLowerCase().endsWith('-image'),
      reasoningCanDisable: _parseCanDisable(model['reasoning_options']),
      reasoningEffortOptions: _parseEffortOptions(model['reasoning_options']),
      inputCostUsdPerM: _double(cost is Map ? cost['input'] : null),
      outputCostUsdPerM: _double(cost is Map ? cost['output'] : null),
      cacheReadCostUsdPerM: _double(cost is Map ? cost['cache_read'] : null),
      cacheWriteCostUsdPerM: _double(cost is Map ? cost['cache_write'] : null),
    );
  }

  /// models.dev 的 reasoning_options 是否声明思考可开关(`toggle` 类型)。
  static bool _parseCanDisable(Object? raw) {
    if (raw is! List) return false;
    for (final option in raw) {
      if (option is! Map) continue;
      if ('${option['type']}'.toLowerCase() == 'toggle') return true;
    }
    return false;
  }

  /// 从 models.dev 的 `reasoning_options` 里取 effort 类型的档位 values。
  ///
  /// 结构形如 `[{"type":"toggle"},{"type":"effort","values":["low","high","max"]}]`:
  /// 只有 effort 那一项带档位;toggle 只表示「可开关」,不产生档位。
  static List<String>? _parseEffortOptions(Object? raw) {
    if (raw is! List) return null;
    for (final option in raw) {
      if (option is! Map) continue;
      if ('${option['type']}'.toLowerCase() != 'effort') continue;
      final values = option['values'];
      if (values is! List) continue;
      final parsed = [for (final value in values) '$value'.toLowerCase()];
      if (parsed.isNotEmpty) return parsed;
    }
    return null;
  }

  static int? _int(Object? value) => value is num ? value.toInt() : null;

  static double? _double(Object? value) => value is num ? value.toDouble() : null;

  /// 按供应商与模型名查找(对齐上游 ModelMetadataService.findMetadata):
  /// 完整名称(忽略大小写)优先于已知后缀候选,再逐级剥离 vendor 前缀重试;
  /// 所有候选落空后才去掉最后一个连字符后缀一次,每次查找都先偏好供应商,再退到全目录。
  ModelMetadata? find(String? providerId, String? model, {List<String>? preferredProviders}) {
    if (model == null || model.trim().isEmpty) return null;
    final normalized = _stripModelsPrefix(model.trim().toLowerCase());
    final names = _withSeparatorVariants([
      normalized,
      ..._vendorStrippedCandidates(normalized),
    ]);
    for (final name in names) {
      final hit = _lookup(name, providerId, preferredProviders);
      if (hit != null) return hit;
      for (final candidate in _withSeparatorVariants(_strippedCandidates(name).skip(1))) {
        final candidateHit = _lookup(candidate, providerId, preferredProviders);
        if (candidateHit != null) return candidateHit;
      }
    }
    for (final name in names) {
      final lastDash = name.lastIndexOf('-');
      if (lastDash <= name.lastIndexOf('/') + 1) continue;
      for (final candidate
          in _withSeparatorVariants([name.substring(0, lastDash)])) {
        final hit = _lookup(candidate, providerId, preferredProviders);
        if (hit != null) return hit;
      }
    }
    return null;
  }

  ModelMetadata? _lookup(String name, String? providerId, List<String>? preferredProviders) {
    if (providerId != null) {
      final direct = _byProvider[providerId.toLowerCase()]?[name];
      if (direct != null) return direct;
    }
    if (preferredProviders != null) {
      for (final provider in preferredProviders) {
        final hit = _byProvider[provider]?[name];
        if (hit != null) return hit;
      }
    }
    // 供应商对不上时(用户自建供应商配了官方模型名)跨供应商兜底找同名模型。
    for (final models in _byProvider.values) {
      final hit = models[name];
      if (hit != null) return hit;
    }
    return null;
  }

  /// 某供应商下的全部模型(Auto Model 路由用)。
  List<ModelMetadata> modelsOf(String providerId) =>
      _byProvider[providerId]?.values.toList() ?? const [];

  /// 目录里全部模型。
  List<ModelMetadata> get allModels => [
        for (final models in _byProvider.values) ...models.values,
      ];
}

/// 内置模型目录(启动时加载一次,之后常驻)。
final modelCatalogProvider = FutureProvider<ModelCatalog>((ref) async {
  return ModelCatalog.loadFromAssets(rootBundle);
});

/// Gemini 风格的模型 id 前缀(`models/gemini-2.5-pro`),匹配前剥离,忽略大小写。
const _modelsPrefix = 'models/';

/// 兜底模糊匹配:依次尝试剥离的模型 id 后缀。
const _modelSuffixes = [
  '-thinking', '-preview', '-high', '-low',
  '(thinking)', '(xhigh)', '(high)', '(low)',
];

/// 目录匹配不到模型时的兜底窗口(对齐上游 ModelMetadataService.default)。
const _defaultContextTokens = 128000;
const _defaultOutputTokens = 64000;

/// 目录匹配不到模型时的兜底元数据(对齐上游 ModelMetadataService.default):
/// 统一视为文本模型——128k 输入 / 64k 输出、支持工具调用,
/// 保证模型行始终渲染能力标签,与上游「全部模型都有标签」一致。
ModelMetadata inferredModelMetadata(String model) => ModelMetadata(
      id: model,
      displayName: model,
      contextTokens: _defaultContextTokens,
      inputTokens: _defaultContextTokens,
      outputTokens: _defaultOutputTokens,
      supportsTools: true,
      estimated: true,
    );

/// 按协议类型偏好的目录供应商顺序(对齐上游 ModelMetadataService.preferredProviders)。
List<String> preferredCatalogProviders(ProviderType type) => switch (type) {
      ProviderType.openai => const [
          'openai', 'openrouter', 'deepseek', 'groq', 'xai', 'mistral',
          'togetherai', 'alibaba', 'moonshot', 'github-copilot',
        ],
      ProviderType.anthropic => const ['anthropic', 'google-vertex-anthropic'],
      ProviderType.gemini => const ['google', 'google-vertex'],
    };

String _stripModelsPrefix(String name) =>
    name.startsWith(_modelsPrefix) ? name.substring(_modelsPrefix.length) : name;

/// 把一组候选名扩展成「原样 + 分隔符变体」,并按出现顺序去重。
List<String> _withSeparatorVariants(Iterable<String> names) {
  final result = <String>[];
  for (final name in names) {
    if (name.isEmpty || result.contains(name)) continue;
    result.add(name);
    final variant = _separatorVariants(name);
    if (variant != null && !result.contains(variant)) result.add(variant);
  }
  return result;
}

/// 版本号分隔符差异:`claude-opus-4.6`(聚合站命名)与目录里的 `claude-opus-4-5` 写法不同,
/// 仅 `.` / `-` 不同时应视为同一模型——否则这些模型匹配不到目录,只能显示兜底标签。
///
/// 返回 null 表示没有另一种写法。两个方向都试:
/// 点号转连字符(`4.6` → `4-6`),以及数字间的连字符转点号(`gpt-5-5` → `gpt-5.5`)。
String? _separatorVariants(String name) {
  if (name.contains('.')) return name.replaceAll('.', '-');
  if (!RegExp(r'\d-\d').hasMatch(name)) return null;
  return name.replaceAllMapped(RegExp(r'(\d)-(\d)'), (m) => '${m[1]}.${m[2]}');
}

/// 逐级剥离 vendor 前缀后的候选(`z-ai/glm-5.3-flash` → `glm-5.3-flash`,
/// `@cf/zai-org/glm-5.3-flash` → `zai-org/glm-5.3-flash` → `glm-5.3-flash`)。
List<String> _vendorStrippedCandidates(String modelId) {
  final candidates = <String>[];
  var current = modelId;
  while (true) {
    final slash = current.indexOf('/');
    if (slash < 0 || slash == current.length - 1) break;
    current = current.substring(slash + 1);
    candidates.add(current);
  }
  return candidates;
}

/// 生成匹配候选:原始 id 在前,随后迭代剥离常见后缀(-thinking/-preview/-high/-low 及括号形式),可连续剥离多层。
List<String> _strippedCandidates(String modelId) {
  final candidates = <String>[modelId];
  var current = modelId;
  var changed = true;
  while (changed) {
    changed = false;
    for (final suffix in _modelSuffixes) {
      if (current.length > suffix.length && current.endsWith(suffix)) {
        current = current.substring(0, current.length - suffix.length);
        candidates.add(current);
        changed = true;
        break;
      }
    }
  }
  return candidates;
}

/// 合并「自定义元数据」与「内置目录」:逐字段合并,自定义优先
/// (与上游 ProviderModelRow 的 mergeModelMetadata 同序)。
///
/// 命中自定义时不能整份替换:添加模型弹层写入的是全默认值(窗口 0、能力 false),
/// 整份替换会把目录识别出的窗口与价格一起抹掉,模型行的 ↑/↓ 标签因此消失。
///
/// 目录匹配不到时回退到推断默认值(对齐上游 ModelMetadataService.resolve:
/// 128k 输入 / 64k 输出 / 支持工具),保证所有模型行都渲染能力标签。
ModelMetadata resolveModelMetadata(
  ModelCatalog catalog,
  Map<String, ModelMetadata> custom, {
  String? providerId,
  required String model,
  ProviderType? type,
}) {
  final byProvider = providerId == null ? null : custom['$providerId:$model'];
  final customHit = byProvider ?? custom[model];
  final base = catalog.find(
        providerId,
        model,
        preferredProviders: type == null ? null : preferredCatalogProviders(type),
      ) ??
      inferredModelMetadata(model);
  if (customHit == null) return base;
  return mergeModelMetadata(model, base, customHit);
}