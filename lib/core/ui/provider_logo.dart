import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/providers/provider_config.dart';

/// 品牌 logo(对齐上游 ProviderLogo.kt):
/// 品牌 key 先按名称识别、未命中再按协议类型兜底;logo 资产由上游 vector drawable 转成 SVG。
const Map<String, String> _brandLogos = {
  'doubao': 'assets/logos/doubao.svg',
  'minimax': 'assets/logos/minimax.svg',
  'moonshot': 'assets/logos/moonshot.svg',
  'zhipu': 'assets/logos/zhipu.svg',
  'alibaba': 'assets/logos/qwen.svg',
  'deepseek': 'assets/logos/deepseek.svg',
  'grok': 'assets/logos/grok.svg',
  'groq': 'assets/logos/groq.svg',
  'anthropic': 'assets/logos/anthropic.svg',
  'google': 'assets/logos/gemini.svg',
  'hunyuan': 'assets/logos/hunyuan.svg',
  'openrouter': 'assets/logos/openrouter.svg',
  'perplexity': 'assets/logos/perplexity.svg',
  'siliconflow': 'assets/logos/siliconflow.svg',
  'ollama': 'assets/logos/ollama.svg',
  'meta': 'assets/logos/meta.svg',
  'mistral': 'assets/logos/mistral.svg',
  'openai': 'assets/logos/openai.svg',
};

/// 供应商最终命中的品牌 key:优先按名称识别,未命中再按协议类型兜底。
String? providerBrandKey(ProviderConfig? provider) {
  if (provider == null) return null;
  final nameKey = modelBrandKey(provider.name);
  if (_brandLogos.containsKey(nameKey)) return nameKey;
  return switch (provider.type) {
    ProviderType.openai => 'openai',
    ProviderType.anthropic => 'anthropic',
    ProviderType.gemini => 'google',
  };
}

/// 按名称推断品牌 key(对齐上游 modelBrandKey 的匹配顺序)。
String modelBrandKey(String modelName) {
  final target = modelName.toLowerCase();
  if (target.contains('doubao') || target.contains('豆包')) return 'doubao';
  // minimax 必须排在 grok 之前:minimaxai 等名称含 "xai",否则会被 grok 规则误匹配
  if (target.contains('minimax') || target.contains('abab')) return 'minimax';
  if (target.contains('moonshot') || target.contains('kimi')) return 'moonshot';
  if (target.contains('zhipu') ||
      target.contains('智谱') ||
      target.contains('bigmodel') ||
      target.contains('glm')) {
    return 'zhipu';
  }
  if (target.contains('qwen') ||
      target.contains('通义') ||
      target.contains('alibaba') ||
      target.contains('aliyun') ||
      target.contains('dashscope')) {
    return 'alibaba';
  }
  if (target.contains('deepseek') || target.contains('deep-seek')) return 'deepseek';
  if (target.contains('grok') || target.contains('xai')) return 'grok';
  if (target.contains('groq')) return 'groq';
  if (target.contains('claude') || target.contains('anthropic')) return 'anthropic';
  if (target.contains('google') || target.contains('gemini') || target.contains('gemma')) {
    return 'google';
  }
  if (target.contains('hunyuan') ||
      target.contains('混元') ||
      target.contains('tencent') ||
      target.contains('hy')) {
    return 'hunyuan';
  }
  if (target.contains('openrouter')) return 'openrouter';
  if (target.contains('perplexity')) return 'perplexity';
  if (target.contains('siliconflow') || target.contains('硅基')) return 'siliconflow';
  // ollama 必须在 meta 之前:ollama 名称含 "llama",否则会被 meta 规则误匹配
  if (target.contains('ollama')) return 'ollama';
  if (target.contains('meta') || target.contains('llama')) return 'meta';
  if (target.contains('mistral')) return 'mistral';
  if (target.contains('gpt') ||
      target.contains('o1') ||
      target.contains('o3') ||
      target.contains('o4') ||
      target.contains('openai') ||
      target.contains('chatgpt') ||
      target.contains('dall-e')) {
    return 'openai';
  }
  return 'other';
}

/// 是否给 logo 施加主题色 tint;保留原色的品牌(如 hunyuan/siliconflow 多色 logo)不在此列。
bool _shouldTint(String key) =>
    const {'grok', 'groq', 'moonshot', 'openai', 'openrouter', 'perplexity', 'ollama', 'meta', 'mistral'}
        .contains(key);

/// 供应商行的品牌 logo;未匹配时显示云图标。
class ProviderLogoIcon extends StatelessWidget {
  const ProviderLogoIcon({super.key, required this.provider, this.size = 22});

  final ProviderConfig? provider;
  final double size;

  @override
  Widget build(BuildContext context) {
    return BrandLogoIcon(
      brandKey: providerBrandKey(provider),
      semanticLabel: provider?.name ?? '',
      fallbackIcon: LucideIcons.cloud,
      size: size,
    );
  }
}

/// 模型行的品牌 logo;未匹配时显示芯片图标。
class ModelLogoIcon extends StatelessWidget {
  const ModelLogoIcon({super.key, required this.modelName, this.size = 22});

  final String modelName;
  final double size;

  @override
  Widget build(BuildContext context) {
    return BrandLogoIcon(
      brandKey: modelBrandKey(modelName),
      semanticLabel: modelName,
      fallbackIcon: LucideIcons.cpu,
      size: size,
    );
  }
}

/// 品牌 key → logo 图标(无资产时回退图标)。
class BrandLogoIcon extends StatelessWidget {
  const BrandLogoIcon({
    super.key,
    required this.brandKey,
    this.semanticLabel = '',
    required this.fallbackIcon,
    this.size = 22,
  });

  final String? brandKey;
  final String semanticLabel;
  final IconData fallbackIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = brandKey == null ? null : _brandLogos[brandKey];
    if (asset == null) {
      return Icon(
        fallbackIcon,
        size: size,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        semanticLabel: semanticLabel.isEmpty ? null : semanticLabel,
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = isDark ? Colors.white : Colors.black;
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: brandKey != null && _shouldTint(brandKey!)
          ? ColorFilter.mode(tint, BlendMode.srcIn)
          : null,
      semanticsLabel: semanticLabel.isEmpty ? null : semanticLabel,
    );
  }
}