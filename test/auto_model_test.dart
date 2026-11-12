import 'package:codecraft/agent/models/auto_model.dart';
import 'package:codecraft/agent/models/model_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

/// Auto Model 的路由规则:硬性能力优先,其次推理、成本、窗口。
void main() {
  AutoModelCandidate candidate(
    String model, {
    bool vision = false,
    bool tools = false,
    bool reasoning = false,
    int context = 128000,
    double? inputCost,
    String provider = 'p1',
  }) =>
      AutoModelCandidate(
        providerId: provider,
        model: model,
        metadata: ModelMetadata(
          id: model,
          providerId: provider,
          supportsVision: vision,
          supportsTools: tools,
          supportsReasoning: reasoning,
          contextTokens: context,
          inputCostUsdPerM: inputCost,
        ),
      );

  group('Auto 判定', () {
    test('null / 空串 / auto 都表示 Auto', () {
      expect(isAutoModel(null), isTrue);
      expect(isAutoModel(''), isTrue);
      expect(isAutoModel('  '), isTrue);
      expect(isAutoModel('auto'), isTrue);
      expect(isAutoModel('AUTO'), isTrue);
    });

    test('具体模型名不是 Auto', () {
      expect(isAutoModel('gpt-4o'), isFalse);
      expect(isAutoModel('auto-model'), isFalse);
    });
  });

  group('硬性能力', () {
    test('带图片时只选支持视觉的模型', () {
      final picked = AutoModelRouter.pick(
        [
          candidate('cheap-text', tools: true, inputCost: 0.1),
          candidate('vision-model', tools: true, vision: true, inputCost: 3),
        ],
        const AutoModelRequest(hasImages: true, needsTools: true),
      );
      expect(picked?.model, 'vision-model');
    });

    test('需要工具时只选支持工具的模型', () {
      final picked = AutoModelRouter.pick(
        [
          candidate('no-tools', inputCost: 0.1),
          candidate('with-tools', tools: true, inputCost: 3),
        ],
        const AutoModelRequest(needsTools: true),
      );
      expect(picked?.model, 'with-tools');
    });

    test('上下文装不下时排除', () {
      final picked = AutoModelRouter.pick(
        [
          candidate('small', tools: true, context: 8000, inputCost: 0.1),
          candidate('big', tools: true, context: 200000, inputCost: 5),
        ],
        const AutoModelRequest(needsTools: true, approxInputTokens: 50000),
      );
      expect(picked?.model, 'big');
    });

    test('元数据缺窗口(0)视为够用,不误排除', () {
      final picked = AutoModelRouter.pick(
        [candidate('unknown-window', tools: true, context: 0)],
        const AutoModelRequest(needsTools: true, approxInputTokens: 999999),
      );
      expect(picked?.model, 'unknown-window');
    });

    test('没有任何候选满足硬性能力时返回 null(由调用方回退默认模型)', () {
      final picked = AutoModelRouter.pick(
        [candidate('text-only', tools: true)],
        const AutoModelRequest(hasImages: true, needsTools: true),
      );
      expect(picked, isNull);
    });
  });

  group('排序', () {
    test('需要推理时优先支持 reasoning 的模型(即使更贵)', () {
      final picked = AutoModelRouter.pick(
        [
          candidate('cheap', tools: true, inputCost: 0.5),
          candidate('reasoner', tools: true, reasoning: true, inputCost: 9),
        ],
        const AutoModelRequest(needsTools: true, wantsReasoning: true),
      );
      expect(picked?.model, 'reasoner');
    });

    test('不需要推理时按成本选便宜的', () {
      final picked = AutoModelRouter.pick(
        [
          candidate('pricey', tools: true, inputCost: 9),
          candidate('cheap', tools: true, inputCost: 0.5),
        ],
        const AutoModelRequest(needsTools: true),
      );
      expect(picked?.model, 'cheap');
    });

    test('缺价格信息的排在有价格的后面', () {
      final picked = AutoModelRouter.pick(
        [
          candidate('no-price', tools: true),
          candidate('priced', tools: true, inputCost: 8),
        ],
        const AutoModelRequest(needsTools: true),
      );
      expect(picked?.model, 'priced');
    });

    test('同价时窗口更大的优先', () {
      final picked = AutoModelRouter.pick(
        [
          candidate('small-window', tools: true, context: 32000, inputCost: 1),
          candidate('large-window', tools: true, context: 200000, inputCost: 1),
        ],
        const AutoModelRequest(needsTools: true),
      );
      expect(picked?.model, 'large-window');
    });

    test('完全同分时按模型名稳定排序(同样输入总是同一结果)', () {
      final picked = AutoModelRouter.pick(
        [
          candidate('b-model', tools: true, inputCost: 1),
          candidate('a-model', tools: true, inputCost: 1),
        ],
        const AutoModelRequest(needsTools: true),
      );
      expect(picked?.model, 'a-model');
    });

    test('可以选中其它供应商的模型(路由跨供应商)', () {
      final picked = AutoModelRouter.pick(
        [
          candidate('own-model', tools: true, inputCost: 9, provider: 'p1'),
          candidate('other-model', tools: true, inputCost: 1, provider: 'p2'),
        ],
        const AutoModelRequest(needsTools: true),
      );
      expect(picked?.providerId, 'p2');
      expect(picked?.model, 'other-model');
    });
  });
}