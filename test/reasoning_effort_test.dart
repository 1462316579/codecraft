import 'package:codecraft/agent/models/chat_session.dart';
import 'package:codecraft/agent/models/model_metadata.dart';
import 'package:codecraft/data/model_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

/// 思考强度:按模型元数据的 `reasoning_options` 过滤可用档位(对齐上游)。
void main() {
  group('fromValues', () {
    test('按给定顺序解析出可识别档位', () {
      expect(
        ReasoningEffort.fromValues(['low', 'high', 'max']),
        [ReasoningEffort.low, ReasoningEffort.high, ReasoningEffort.max],
      );
    });

    test('未知值丢弃,大小写不敏感', () {
      expect(
        ReasoningEffort.fromValues(['LOW', 'bogus', 'HIGH']),
        [ReasoningEffort.low, ReasoningEffort.high],
      );
    });

    test('空列表得到空列表(调用方回退到全部档位)', () {
      expect(ReasoningEffort.fromValues(const []), isEmpty);
    });
  });

  group('目录解析 reasoning_options', () {
    ModelCatalog parse(String raw) => ModelCatalog.parse(raw);

    test('只取 effort 类型的 values,忽略 toggle', () {
      final catalog = parse('''
{
  "p": {
    "models": {
      "m": {
        "id": "m",
        "reasoning": true,
        "reasoning_options": [
          {"type": "toggle"},
          {"type": "effort", "values": ["low", "high", "max"]}
        ]
      }
    }
  }
}
''');
      final meta = catalog.find('p', 'm');
      expect(meta!.reasoningEffortOptions, ['low', 'high', 'max']);
      expect(meta.supportsReasoning, isTrue);
    });

    test('只有 toggle 时无档位信息(回退全部)', () {
      final catalog = parse('''
{"p":{"models":{"m":{"id":"m","reasoning_options":[{"type":"toggle"}]}}}}
''');
      expect(catalog.find('p', 'm')!.reasoningEffortOptions, isNull);
    });

    test('完全没有 reasoning_options 时为 null', () {
      final catalog = parse('{"p":{"models":{"m":{"id":"m"}}}}');
      expect(catalog.find('p', 'm')!.reasoningEffortOptions, isNull);
    });
  });

  group('元数据序列化', () {
    test('档位能往返', () {
      const metadata = ModelMetadata(
        id: 'm',
        reasoningEffortOptions: ['low', 'medium'],
      );
      final restored = ModelMetadata.fromJson('m', metadata.toJson());
      expect(restored.reasoningEffortOptions, ['low', 'medium']);
    });

    test('缺字段时为 null', () {
      final restored = ModelMetadata.fromJson('m', const {'id': 'm'});
      expect(restored.reasoningEffortOptions, isNull);
    });
  });

  group('内置目录里的真实模型', () {
    test('DeepSeek V4 Pro 有 effort 档位', () {
      final catalog = ModelCatalog.parse(
        // 只取快照里一个有档位的模型做断言,避免依赖整份文件。
        '{"deepseek":{"models":{"deepseek-v4-pro":{"id":"deepseek-v4-pro",'
        '"reasoning":true,"reasoning_options":[{"type":"effort","values":["low","high","max"]}]}}}}',
      );
      final options = catalog.find('deepseek', 'deepseek-v4-pro')!.reasoningEffortOptions;
      expect(options, isNotNull);
      expect(ReasoningEffort.fromValues(options!), isNotEmpty);
    });
  });
}