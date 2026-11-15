import 'package:codecraft/data/model_api_service.dart';
import 'package:codecraft/data/model_catalog.dart';
import 'package:codecraft/data/providers/provider_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// `/models` 响应里的窗口字段解析:聚合站返回 context_length 时要拿到真实窗口,
/// 没返回就不该造数据(否则所有模型都显示同一个 ↑128k ↓64k)。
void main() {
  test('OpenRouter 风格:context_length + top_provider 输出上限', () {
    final body = '''
{"data":[
  {"id":"nex-agi/nex-n2.5-pro","context_length":262144,
   "top_provider":{"context_length":262144,"max_completion_tokens":32768}},
  {"id":"unknown/model"}
]}
''';
    final metadata = ModelApiService.parseModelsMetadata(body, ProviderType.openai);

    expect(metadata.containsKey('unknown/model'), isFalse);
    final pro = metadata['nex-agi/nex-n2.5-pro']!;
    expect(pro.contextTokens, 262144);
    expect(pro.inputTokens, 262144);
    expect(pro.outputTokens, 32768);
  });

  test('Gemini 风格:inputTokenLimit / outputTokenLimit', () {
    final body = '''
{"models":[
  {"name":"models/gemini-3-pro","inputTokenLimit":1048576,"outputTokenLimit":65536}
]}
''';
    final metadata = ModelApiService.parseModelsMetadata(body, ProviderType.gemini);

    expect(metadata['gemini-3-pro']!.contextTokens, 1048576);
    expect(metadata['gemini-3-pro']!.outputTokens, 65536);
  });

  test('结构不符时返回空表,不抛异常', () {
    expect(
      ModelApiService.parseModelsMetadata('{"foo":1}', ProviderType.openai),
      isEmpty,
    );
    expect(ModelApiService.parseModelsMetadata('not json', ProviderType.openai), isEmpty);
  });

  // 聚合站多用 `claude-opus-4.6` 这种点号写法,目录里是 `claude-opus-4-6`;
  // 只差分隔符时匹配不到目录,模型行就只剩兜底的「工具」标签。
  test('目录匹配:版本号点号与连字符视为同一模型', () {
    final catalog = ModelCatalog.parse('''
{"anthropic":{"models":{"claude-opus-4-6":{
  "id":"claude-opus-4-6","name":"Claude Opus 4.6","tool_call":true,"reasoning":true,
  "limit":{"context":1000000,"output":128000},
  "modalities":{"input":["text","image"],"output":["text"]}}}}}
''');
    final dotted = resolveModelMetadata(
      catalog,
      const {},
      providerId: 'aggregator',
      model: 'anthropic/claude-opus-4.6',
      type: ProviderType.openai,
    );
    expect(dotted.supportsVision, isTrue);
    expect(dotted.supportsReasoning, isTrue);
    expect(dotted.contextTokens, 1000000);
    expect(dotted.estimated, isFalse);
  });
}
