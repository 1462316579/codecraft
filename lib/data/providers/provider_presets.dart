import '../../core/util/ids.dart';
import 'provider_config.dart';

/// 内置供应商预设(对齐原仓库 data/providers.json 的全量条目)。
class ProviderPreset {
  const ProviderPreset({
    required this.id,
    required this.name,
    required this.type,
    required this.baseUrl,
    this.badge = '',
    this.tags = const [],
    this.websiteUrl = '',
    this.isRecommended = false,
  });

  final String id;
  final String name;
  final ProviderType type;
  final String baseUrl;
  final String badge;
  final List<String> tags;
  final String websiteUrl;
  final bool isRecommended;
}

const providerPresets = <ProviderPreset>[
  ProviderPreset(id: 'openai', name: 'OpenAI', type: ProviderType.openai,
      baseUrl: 'https://api.openai.com/'),
  ProviderPreset(id: 'anthropic', name: 'Anthropic', type: ProviderType.anthropic,
      baseUrl: 'https://api.anthropic.com/'),
  ProviderPreset(id: 'deepseek', name: 'DeepSeek', type: ProviderType.openai,
      baseUrl: 'https://api.deepseek.com/'),
  ProviderPreset(id: 'google', name: 'Google', type: ProviderType.gemini,
      baseUrl: 'https://generativelanguage.googleapis.com/'),
  ProviderPreset(id: 'xai', name: 'xAI (Grok)', type: ProviderType.openai,
      baseUrl: 'https://api.x.ai/'),
  ProviderPreset(id: 'alibaba', name: 'Qwen', type: ProviderType.openai,
      baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1'),
  ProviderPreset(id: 'zai', name: 'Z.AI (智谱)', type: ProviderType.openai,
      baseUrl: 'https://open.bigmodel.cn/api/paas/v4'),
  ProviderPreset(id: 'moonshotai', name: 'Kimi', type: ProviderType.openai,
      baseUrl: 'https://api.moonshot.cn/v1'),
  ProviderPreset(id: 'minimax', name: 'MiniMax', type: ProviderType.openai,
      baseUrl: 'https://api.minimax.io/'),
  ProviderPreset(
    id: 'xiaomi',
    name: 'MiMo',
    type: ProviderType.openai,
    baseUrl: 'https://api.xiaomimimo.com/v1',
    tags: ['注册送10元', '需实名'],
    websiteUrl: 'https://platform.xiaomimimo.com?ref=66QSUD',
  ),
  ProviderPreset(
    id: 'codecraft',
    name: 'Codecraft',
    type: ProviderType.openai,
    baseUrl: 'https://ai.murk.top/v1',
    tags: ['签到领额度'],
    websiteUrl: 'https://ai.murk.top',
    isRecommended: true,
  ),
  ProviderPreset(
    id: 'siliconflow',
    name: 'SiliconFlow',
    type: ProviderType.openai,
    baseUrl: 'https://api.siliconflow.cn/v1',
    tags: ['注册送16元', '需实名'],
    websiteUrl: 'https://cloud.siliconflow.cn/i/HNDIQWXd',
  ),
  ProviderPreset(
    id: 'qiniu',
    name: '七牛云 AI',
    type: ProviderType.openai,
    baseUrl: 'https://api.qnaigc.com/v1',
    tags: ['注册送300万Token'],
    websiteUrl: 'https://s.qiniu.com/vUryau',
  ),
];

ProviderConfig instantiatePreset(ProviderPreset preset) => ProviderConfig(
      id: newId(),
      name: preset.name,
      type: preset.type,
      baseUrl: preset.baseUrl,
    );

/// 「自定义」入口等价于一个空的 OpenAI 兼容供应商(对齐上游 provider_custom 项)。
ProviderConfig instantiateCustomProvider() =>
    ProviderConfig(id: newId(), name: '', type: ProviderType.openai);