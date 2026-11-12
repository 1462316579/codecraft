import 'dart:convert';
import 'dart:io';

import 'package:codecraft/agent/models/model_metadata.dart';
import 'package:codecraft/data/model_api_service.dart';
import 'package:codecraft/data/model_metadata_store.dart';
import 'package:codecraft/data/providers/provider_config.dart';
import 'package:codecraft/features/settings/model_sheets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('拉取模型解析', () {
    test('OpenAI 兼容取 data[].id 并排序', () {
      final models = ModelApiService.parseModelsBody(
        jsonEncode({
          'data': [
            {'id': 'gpt-4o'},
            {'id': 'deepseek-chat'},
            {'id': '   '},
          ],
        }),
        ProviderType.openai,
      );
      expect(models, ['deepseek-chat', 'gpt-4o']);
    });

    test('Gemini 取 models[].name 并去掉 models/ 前缀', () {
      final models = ModelApiService.parseModelsBody(
        jsonEncode({
          'models': [
            {'name': 'models/gemini-2.5-pro'},
            {'name': 'models/gemini-2.5-flash'},
          ],
        }),
        ProviderType.gemini,
      );
      expect(models, ['gemini-2.5-flash', 'gemini-2.5-pro']);
    });

    test('结构不符返回 null', () {
      expect(ModelApiService.parseModelsBody('{}', ProviderType.openai), isNull);
      expect(ModelApiService.parseModelsBody('not json', ProviderType.openai), isNull);
      expect(ModelApiService.parseModelsBody('{"data":{}}', ProviderType.openai), isNull);
    });

    test('鉴权头按协议区分', () {
      expect(ModelApiService.authHeaders(ProviderType.openai, 'k'),
          {'Authorization': 'Bearer k'});
      expect(ModelApiService.authHeaders(ProviderType.anthropic, 'k'),
          {'x-api-key': 'k', 'anthropic-version': '2023-06-01'});
      expect(ModelApiService.authHeaders(ProviderType.gemini, 'k'), {'x-goog-api-key': 'k'});
    });
  });

  group('模型元数据', () {
    late Directory dir;
    late CustomModelMetadataStore store;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('model_meta');
      store = CustomModelMetadataStore(File(p.join(dir.path, 'model_metadata.json')));
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('按「提供商:模型」存取、覆盖与删除', () async {
      await store.put(
        'p1',
        'glm-4.6',
        const ModelMetadata(
          id: 'glm-4.6',
          contextTokens: 200000,
          outputTokens: 128000,
          supportsTools: true,
          inputCostUsdPerM: 0.6,
        ),
      );
      await store.put('p2', 'glm-4.6', const ModelMetadata(id: 'glm-4.6', contextTokens: 1000));

      var all = await store.all();
      expect(all.length, 2);
      expect(all[modelMetadataKey('p1', 'glm-4.6')]!.supportsTools, isTrue);
      expect(all[modelMetadataKey('p1', 'glm-4.6')]!.inputCostUsdPerM, 0.6);
      expect(all[modelMetadataKey('p2', 'glm-4.6')]!.contextTokens, 1000);

      await store.remove('p1', 'glm-4.6');
      all = await store.all();
      expect(all.keys, [modelMetadataKey('p2', 'glm-4.6')]);
    });

    test('合并:自定义优先,窗口未填时保留自动值', () {
      const custom = ModelMetadata(
        id: 'm',
        contextTokens: 0,
        supportsVision: true,
        inputCostUsdPerM: 1.5,
      );
      final base = const ModelMetadata(id: 'm', contextTokens: 128000, supportsTools: true);

      final merged = mergeModelMetadata('m', base, custom);
      expect(merged.contextTokens, 128000, reason: '自定义窗口为 0 时保留自动值');
      expect(merged.supportsVision, isTrue);
      expect(merged.inputCostUsdPerM, 1.5);
      expect(mergeModelMetadata('m', base, null).supportsTools, isTrue);
    });
  });

  group('标签格式化', () {
    test('上下文长度简写', () {
      expect(formatTokenLimit(512), '512');
      expect(formatTokenLimit(128000), '128k');
      expect(formatTokenLimit(1048576), '1M');
      expect(formatTokenLimit(1500000), '1.5M');
    });
  });
}