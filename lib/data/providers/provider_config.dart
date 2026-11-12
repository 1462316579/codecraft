import 'dart:convert';

/// 供应商协议类型(对齐原仓库 ProviderType)。
enum ProviderType {
  openai,
  anthropic,
  gemini;

  String get defaultBaseUrl => switch (this) {
        ProviderType.openai => 'https://api.openai.com/',
        ProviderType.anthropic => 'https://api.anthropic.com/',
        ProviderType.gemini => 'https://generativelanguage.googleapis.com/',
      };

  String get label => switch (this) {
        ProviderType.openai => 'OpenAI 兼容',
        ProviderType.anthropic => 'Anthropic Messages',
        ProviderType.gemini => 'Gemini',
      };

  /// 短标签(上游 providerTypeLabel):列表行内 pill 用。
  String get shortLabel => switch (this) {
        ProviderType.openai => 'OpenAI',
        ProviderType.anthropic => 'Anthropic',
        ProviderType.gemini => 'Gemini',
      };

  static ProviderType parse(String? value) =>
      values.firstWhere((t) => t.name == value, orElse: () => ProviderType.openai);
}

/// 多 Key 取用策略(对齐上游 KeyRotationStrategy)。
enum KeyRotationStrategy {
  /// 顺序:始终用第一个未冷却的 Key,失败命中切换状态码才前移。
  sequential,

  /// 轮询:新会话轮流分配起始 Key;同一会话内粘住同一个 Key 以保住服务端缓存。
  roundRobin;

  static KeyRotationStrategy parse(String? value) =>
      values.firstWhere((strategy) => strategy.name == value, orElse: () => KeyRotationStrategy.sequential);
}

/// 多 Key 模式下的一条候选 Key:值 + 调度权重(≤ 0 表示保留但不参与调度)。
class ProviderKey {
  const ProviderKey(this.value, {this.weight = 1});

  final String value;
  final int weight;

  Map<String, Object?> toJson() => {'value': value, 'weight': weight};

  static ProviderKey fromJson(Map<String, Object?> map) => ProviderKey(
        (map['value'] as String?) ?? '',
        weight: (map['weight'] as num?)?.toInt() ?? 1,
      );
}

/// 默认的「命中即切 Key」状态码(上游 DEFAULT_KEY_SWITCH_STATUS_CODES)。
const List<int> defaultKeySwitchStatusCodes = [401, 402, 403, 429];

/// 供应商配置。字段取原仓库 AIProviderConfig 的子集
/// (不含代理、自定义面板等,这些属后续阶段)。
class ProviderConfig {
  const ProviderConfig({
    required this.id,
    required this.name,
    required this.type,
    this.apiKey = '',
    String? baseUrl,
    this.defaultModel = '',
    this.models = const [],
    this.selectedModel = '',
    this.isEnabled = true,
    this.useFullUrl = false,
    this.customHeaders = const {},
    this.multiKeyEnabled = false,
    this.apiKeys = const [],
    this.keyRotationStrategy = KeyRotationStrategy.sequential,
    this.keyCooldownMinutes = 5,
    this.keySwitchStatusCodes = const [],
  }) : _baseUrl = baseUrl;

  final String id;
  final String name;
  final ProviderType type;
  final String apiKey;
  final String? _baseUrl;
  final String defaultModel;
  final List<String> models;
  final String selectedModel;
  final bool isEnabled;

  /// true 时 baseUrl 视为完整端点 URL。
  final bool useFullUrl;

  /// 自定义请求头(Header 名 → 值),同名默认头被完全覆盖;
  /// 值支持占位符 `{{SESSION_ID}}`(会话 id)与 `{{API_KEY}}`(本次实际取用的 Key)。
  /// 列表排序序号由数据库列维护,不放在配置里。
  final Map<String, String> customHeaders;

  /// 多 Key 模式开关:开启后从 [apiKeys] 轮换取用,关闭时只用 [apiKey]。
  final bool multiKeyEnabled;

  /// 多 Key 模式下的候选 Key(按列表顺序优先,各条自带调度权重)。
  final List<ProviderKey> apiKeys;

  final KeyRotationStrategy keyRotationStrategy;

  /// 被切走的 Key 冷却多少分钟后重新纳入候选;0 表示不冷却。
  final int keyCooldownMinutes;

  /// 命中即触发多 Key 自动切换的 HTTP 状态码;留空时回退 [defaultKeySwitchStatusCodes]。
  final List<int> keySwitchStatusCodes;

  String get baseUrl => _baseUrl?.isNotEmpty == true ? _baseUrl! : type.defaultBaseUrl;

  /// 实际生效的模型:优先 selectedModel,其次 defaultModel。
  String get effectiveModel => selectedModel.trim().isEmpty ? defaultModel : selectedModel;

  bool get hasUsableApiKey => effectiveApiKeys.isNotEmpty;

  /// 实际可用的 Key 列表:多 Key 开启且列表非空时用 [apiKeys],否则退回单 [apiKey]。
  List<ProviderKey> get effectiveApiKeys {
    final entries = multiKeyEnabled
        ? apiKeys.where((key) => key.value.trim().isNotEmpty).toList()
        : [if (apiKey.trim().isNotEmpty) ProviderKey(apiKey)];
    return entries;
  }

  /// 实际生效的切换状态码;留空回退默认集合。
  Set<int> get effectiveKeySwitchStatusCodes {
    final codes = keySwitchStatusCodes.where((code) => code >= 100 && code <= 599).toSet();
    return codes.isEmpty ? defaultKeySwitchStatusCodes.toSet() : codes;
  }

  /// 无会话上下文的请求(拉取模型、连通性测试)用第一个可用 Key。
  String get firstUsableApiKey =>
      effectiveApiKeys.isEmpty ? '' : effectiveApiKeys.first.value;

  /// 自定义请求头(替换占位符后);值为空或 Header 名为空的条目丢弃。
  Map<String, String> resolvedHeaders({String sessionId = ''}) => {
        for (final entry in customHeaders.entries)
          if (entry.key.trim().isNotEmpty)
            entry.key.trim(): entry.value
                .replaceAll('{{API_KEY}}', apiKey)
                .replaceAll('{{SESSION_ID}}', sessionId),
      };

  ProviderConfig copyWith({
    String? name,
    ProviderType? type,
    String? apiKey,
    String? baseUrl,
    String? defaultModel,
    List<String>? models,
    String? selectedModel,
    bool? isEnabled,
    bool? useFullUrl,
    Map<String, String>? customHeaders,
    bool? multiKeyEnabled,
    List<ProviderKey>? apiKeys,
    KeyRotationStrategy? keyRotationStrategy,
    int? keyCooldownMinutes,
    List<int>? keySwitchStatusCodes,
  }) {
    return ProviderConfig(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? _baseUrl,
      defaultModel: defaultModel ?? this.defaultModel,
      models: models ?? this.models,
      selectedModel: selectedModel ?? this.selectedModel,
      isEnabled: isEnabled ?? this.isEnabled,
      useFullUrl: useFullUrl ?? this.useFullUrl,
      customHeaders: customHeaders ?? this.customHeaders,
      multiKeyEnabled: multiKeyEnabled ?? this.multiKeyEnabled,
      apiKeys: apiKeys ?? this.apiKeys,
      keyRotationStrategy: keyRotationStrategy ?? this.keyRotationStrategy,
      keyCooldownMinutes: keyCooldownMinutes ?? this.keyCooldownMinutes,
      keySwitchStatusCodes: keySwitchStatusCodes ?? this.keySwitchStatusCodes,
    );
  }

  /// 清洗手填/粘贴的配置:API Key 与 URL 去掉一切空白(对齐原仓库 sanitized())。
  ProviderConfig sanitized() => copyWith(
        name: name.trim(),
        apiKey: apiKey.replaceAll(RegExp(r'\s+'), ''),
        baseUrl: baseUrl.replaceAll(RegExp(r'\s+'), ''),
        defaultModel: defaultModel.trim(),
        models: models.map((m) => m.trim()).where((m) => m.isNotEmpty).toSet().toList(),
        selectedModel: selectedModel.trim(),
        apiKeys: [
          for (final key in apiKeys)
            if (key.value.replaceAll(RegExp(r'\s+'), '').isNotEmpty)
              ProviderKey(
                key.value.replaceAll(RegExp(r'\s+'), ''),
                weight: key.weight.clamp(0, 1000000),
              ),
        ],
        keySwitchStatusCodes: keySwitchStatusCodes
            .where((code) => code >= 100 && code <= 599)
            .toSet()
            .toList(),
      );

  Map<String, Object?> toJsonMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'apiKey': apiKey,
        'baseUrl': baseUrl,
        'defaultModel': defaultModel,
        'models': models,
        'selectedModel': selectedModel,
        'isEnabled': isEnabled,
        'useFullUrl': useFullUrl,
        'customHeaders': customHeaders,
        'multiKeyEnabled': multiKeyEnabled,
        'apiKeys': [for (final key in apiKeys) key.toJson()],
        'keyRotationStrategy': keyRotationStrategy.name,
        'keyCooldownMinutes': keyCooldownMinutes,
        'keySwitchStatusCodes': keySwitchStatusCodes,
      };

  String toJson() => jsonEncode(toJsonMap());

  static ProviderConfig fromJson(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return ProviderConfig(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '',
      type: ProviderType.parse(map['type'] as String?),
      apiKey: (map['apiKey'] as String?) ?? '',
      baseUrl: map['baseUrl'] as String?,
      defaultModel: (map['defaultModel'] as String?) ?? '',
      models: ((map['models'] as List?) ?? const []).cast<String>(),
      selectedModel: (map['selectedModel'] as String?) ?? '',
      isEnabled: (map['isEnabled'] as bool?) ?? true,
      useFullUrl: (map['useFullUrl'] as bool?) ?? false,
      customHeaders: ((map['customHeaders'] as Map?) ?? const {})
          .map((key, value) => MapEntry('$key', '$value')),
      multiKeyEnabled: (map['multiKeyEnabled'] as bool?) ?? false,
      apiKeys: [
        for (final entry in (map['apiKeys'] as List?) ?? const [])
          if (entry is Map) ProviderKey.fromJson(entry.cast<String, Object?>()),
      ],
      keyRotationStrategy:
          KeyRotationStrategy.parse(map['keyRotationStrategy'] as String?),
      keyCooldownMinutes: (map['keyCooldownMinutes'] as int?) ?? 5,
      keySwitchStatusCodes: [
        for (final code in (map['keySwitchStatusCodes'] as List?) ?? const [])
          if (code is num) code.toInt(),
      ],
    );
  }
}