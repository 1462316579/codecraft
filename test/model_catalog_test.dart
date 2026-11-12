import 'dart:io';

import 'package:codecraft/agent/models/model_metadata.dart';
import 'package:codecraft/data/model_catalog.dart';
import 'package:codecraft/data/providers/provider_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// 内置模型目录(models.dev 快照):费用统计与 Auto 路由的价格/能力来源。
void main() {
  late ModelCatalog catalog;

  setUpAll(() {
    // 直接读资产文件(测试里不走 AssetBundle,避免与 app 绑定耦合)。
    final raw = File('assets/models/api.official.json').readAsStringSync();
    catalog = ModelCatalog.parse(raw);
  });

  group('解析内置快照', () {
    test('能解析出供应商与模型', () {
      expect(catalog.allModels, isNotEmpty);
      expect(catalog.modelsOf('deepseek'), isNotEmpty);
    });

    test('模型带价格(费用统计的前提)', () {
      final meta = catalog.find('deepseek', 'deepseek-v4-pro');
      expect(meta, isNotNull);
      expect(meta!.inputCostUsdPerM, isNotNull, reason: '没有输入价就算不出费用');
      expect(meta.inputCostUsdPerM, greaterThan(0));
      expect(meta.outputCostUsdPerM, isNotNull);
    });

    test('模型带能力标记(Auto 路由的前提)', () {
      final meta = catalog.find('deepseek', 'deepseek-v4-pro');
      expect(meta!.supportsTools, isTrue);
      expect(meta.supportsReasoning, isTrue);
      expect(meta.contextTokens, greaterThan(0));
    });

    test('绝大多数模型都有输入价(否则统计页会大量显示「—」)', () {
      final withCost = catalog.allModels.where((m) => m.inputCostUsdPerM != null).length;
      expect(withCost, greaterThan(catalog.allModels.length ~/ 2));
    });
  });

  group('查找', () {
    test('大小写不敏感', () {
      expect(catalog.find('deepseek', 'DeepSeek-V4-Pro'), isNotNull);
    });

    test('剥离 models/ 前缀(Gemini 风格 id)', () {
      final direct = catalog.find('google', 'gemini-2.5-pro');
      final prefixed = catalog.find('google', 'models/gemini-2.5-pro');
      expect(prefixed, isNotNull);
      if (direct != null) expect(prefixed!.id, direct.id);
    });

    test('供应商对不上时跨供应商兜底找同名模型', () {
      // 用户自建供应商配了官方模型名。
      expect(catalog.find('my-custom-provider', 'deepseek-v4-pro'), isNotNull);
    });

    test('找不到返回 null;空模型名返回 null', () {
      expect(catalog.find('deepseek', 'no-such-model-xyz'), isNull);
      expect(catalog.find('deepseek', ''), isNull);
      expect(catalog.find('deepseek', null), isNull);
    });

    test('后缀剥离(-preview 等)后仍能命中目录', () {
      expect(catalog.find('anthropic', 'claude-sonnet-4-6-preview'), isNotNull);
    });

    test('剥离 vendor 前缀后跨供应商命中', () {
      expect(catalog.find('my-relay', 'z-ai/deepseek-v4-pro'), isNotNull);
    });

    test('去掉最后一个连字符后缀一次', () {
      expect(catalog.find('openai', 'gpt-4o-mini-xyz'), isNotNull);
    });

    test('未知供应商的 modelsOf 返回空列表', () {
      expect(catalog.modelsOf('nope'), isEmpty);
    });
  });

  group('元数据合并顺序', () {
    test('自定义元数据优先于内置目录', () {
      const custom = {
        'deepseek:deepseek-v4-pro': ModelMetadata(
          id: 'deepseek-v4-pro',
          providerId: 'deepseek',
          inputCostUsdPerM: 99,
        ),
      };
      final resolved = resolveModelMetadata(
        catalog,
        custom,
        providerId: 'deepseek',
        model: 'deepseek-v4-pro',
      );
      expect(resolved.inputCostUsdPerM, 99, reason: '用户手工填的价格应覆盖内置');
    });

    test('自定义没有时用内置目录', () {
      final resolved = resolveModelMetadata(
        catalog,
        const {},
        providerId: 'deepseek',
        model: 'deepseek-v4-pro',
      );
      expect(resolved.inputCostUsdPerM, isNotNull);
    });

    test('裸模型名键也认(不带 providerId 前缀)', () {
      const custom = {
        'deepseek-v4-pro': ModelMetadata(id: 'deepseek-v4-pro', inputCostUsdPerM: 7),
      };
      final resolved = resolveModelMetadata(
        catalog,
        custom,
        providerId: 'deepseek',
        model: 'deepseek-v4-pro',
      );
      expect(resolved.inputCostUsdPerM, 7);
    });

    test('自定义元数据为全默认值时仍保留目录的窗口与能力(模型行标签不丢)', () {
      const custom = {
        'deepseek:deepseek-v4-pro': ModelMetadata(id: 'deepseek-v4-pro'),
      };
      final resolved = resolveModelMetadata(
        catalog,
        custom,
        providerId: 'deepseek',
        model: 'deepseek-v4-pro',
      );
      expect(resolved.contextTokens, greaterThan(0), reason: '窗口应来自目录,而不是被 0 覆盖');
      expect(resolved.inputCostUsdPerM, isNotNull, reason: '价格应来自目录');
    });

    test('自定义显式填的窗口与能力覆盖目录', () {
      const custom = {
        'deepseek:deepseek-v4-pro': ModelMetadata(
          id: 'deepseek-v4-pro',
          contextTokens: 32000,
          supportsVision: true,
        ),
      };
      final resolved = resolveModelMetadata(
        catalog,
        custom,
        providerId: 'deepseek',
        model: 'deepseek-v4-pro',
      );
      expect(resolved.contextTokens, 32000);
      expect(resolved.supportsVision, isTrue);
    });

    test('目录与自定义都没有时回退推断默认值(模型行始终有标签)', () {
      final resolved = resolveModelMetadata(
        ModelCatalog.empty,
        const {},
        providerId: 'p',
        model: 'unknown',
      );
      expect(resolved.contextTokens, 128000);
      expect(resolved.inputTokens, 128000);
      expect(resolved.outputTokens, 64000);
      expect(resolved.supportsTools, isTrue);
      expect(resolved.supportsVision, isFalse);
    });

    test('按协议类型偏好目录供应商查找', () {
      final resolved = resolveModelMetadata(
        catalog,
        const {},
        providerId: 'my-relay',
        model: 'deepseek-v4-pro',
        type: ProviderType.openai,
      );
      expect(resolved.contextTokens, greaterThan(0));
    });
  });
}