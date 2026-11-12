import 'package:codecraft/agent/models/model_metadata.dart';
import 'package:codecraft/data/token_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModelCostCalculator(对齐上游 ModelCostCalculator)', () {
    const calculator = ModelCostCalculator();

    test('缺输入价时返回 null', () {
      expect(
        calculator.costUsd(
          const ModelMetadata(id: 'm'),
          inputTokens: 1000,
          cachedInputTokens: 0,
          outputTokens: 100,
          cacheCreationTokens: 0,
        ),
        isNull,
      );
    });

    test('命中缓存按输入价折扣、写入按 1.25 倍、未缓存按原价', () {
      const meta = ModelMetadata(id: 'm', inputCostUsdPerM: 3, outputCostUsdPerM: 15);
      final cost = calculator.costUsd(
        meta,
        inputTokens: 1000000,
        cachedInputTokens: 400000,
        outputTokens: 100000,
        cacheCreationTokens: 100000,
      );
      // 未缓存 500k×3 + 缓存读 400k×0.3 + 缓存写 100k×3.75 + 输出 100k×15,再除以 1e6
      expect(cost, closeTo((500000 * 3 + 400000 * 0.3 + 100000 * 3.75 + 100000 * 15) / 1000000, 1e-9));
    });

    test('元数据显式给出缓存价时优先使用', () {
      const meta = ModelMetadata(
        id: 'm',
        inputCostUsdPerM: 3,
        outputCostUsdPerM: 15,
        cacheReadCostUsdPerM: 1,
        cacheWriteCostUsdPerM: 2,
      );
      final cost = calculator.costUsd(
        meta,
        inputTokens: 1000,
        cachedInputTokens: 1000,
        outputTokens: 0,
        cacheCreationTokens: 0,
      );
      expect(cost, closeTo(1000 * 1 / 1000000, 1e-12));
    });
  });

  group('格式化(对齐上游 formatTokenCount / formatCostUsd)', () {
    test('token 数分级', () {
      expect(formatTokenCount(999), '999');
      expect(formatTokenCount(1500), '1.5k');
      expect(formatTokenCount(2500000), '2.5M');
      expect(formatTokenCount(3000000000), '3.0B');
    });

    test('费用分级', () {
      expect(formatCostUsd(null), '—');
      expect(formatCostUsd(0), '\$0.00');
      expect(formatCostUsd(0.00005), '<\$0.0001');
      expect(formatCostUsd(0.005), '\$0.0050');
      expect(formatCostUsd(1.239), '\$1.24');
    });
  });

  group('TokenStatsPeriod 起点(对齐上游 TokenStatsPeriod)', () {
    test('今天从本地 0 点起算', () {
      final now = DateTime(2026, 3, 4, 15, 30);
      final start = DateTime.fromMillisecondsSinceEpoch(
        TokenStatsPeriod.today.startMillis(now),
      );
      expect(start, DateTime(2026, 3, 4));
    });

    test('7 天/30 天按毫秒回退,全部为 0', () {
      final now = DateTime(2026, 3, 4, 15, 30);
      expect(
        TokenStatsPeriod.last7Days.startMillis(now),
        now.millisecondsSinceEpoch - 7 * 86400000,
      );
      expect(
        TokenStatsPeriod.last30Days.startMillis(now),
        now.millisecondsSinceEpoch - 30 * 86400000,
      );
      expect(TokenStatsPeriod.all.startMillis(now), 0);
    });
  });
}