import 'package:codecraft/data/model_api_service.dart';
import 'package:codecraft/data/providers/provider_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// 拉取模型 / 测试连通性的网络层行为。
///
/// 此前 Dio 没配超时,端点不可达时请求无限等,
/// 「拉取模型」弹层永远停在骨架屏——这里锁住超时行为。
void main() {
  const provider = ProviderConfig(
    id: 'p1',
    name: '测试',
    type: ProviderType.openai,
    baseUrl: 'https://10.255.255.1/v1',
  );

  test('连接不可达:fetchModels 在超时后报错,而不是永远等待', () async {
    final service = ModelApiService();
    final start = DateTime.now();
    await expectLater(
      service.fetchModels(provider: provider, apiKey: 'sk-test'),
      throwsA(isA<FetchModelsException>()),
    );
    final elapsed = DateTime.now().difference(start);
    expect(elapsed.inSeconds, lessThan(60), reason: '应在连接超时(15s)内结束,而不是无限等');
  });

  test('超时异常转成可读文案(连接超时),不是裸 DioException', () async {
    final service = ModelApiService();
    try {
      await service.fetchModels(provider: provider, apiKey: 'sk-test');
      fail('应抛出 FetchModelsException');
    } on FetchModelsException catch (error) {
      expect(error.message, contains('超时'));
      expect(error.debugInfo, isNotNull);
      expect(error.debugInfo!.requestUrl, 'https://10.255.255.1/v1/models');
    }
  });

  test('测试模型:不可达时返回失败结果而非挂死', () async {
    final service = ModelApiService();
    final result = await service.testModel(
      provider: provider,
      apiKey: 'sk-test',
      model: 'gpt-4o-mini',
    );
    expect(result.success, isFalse);
    expect(result.message, contains('超时'));
  });

  test('没配 Key:立即报错,不发请求', () async {
    final service = ModelApiService();
    await expectLater(
      service.fetchModels(provider: provider, apiKey: '  '),
      throwsA(
        isA<FetchModelsException>().having(
          (e) => e.message,
          'message',
          '请先填写 API Key',
        ),
      ),
    );
  });
}