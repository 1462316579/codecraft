import 'package:codecraft/data/providers/provider_config.dart';
import 'package:codecraft/data/providers/provider_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 冷启动时序:`providersProvider` 要读数据库,未就绪时 `valueOrNull` 是 null。
///
/// 之前模型弹层用 `valueOrNull ?? []` 同步取值,冷启动会拿到空列表 → 显示「没有模型」,
/// 等数据加载完又恢复正常。这里钉住「await 之后一定拿得到已配置的模型」这个契约。
void main() {
  ProviderConfig provider({String id = 'p1', List<String> models = const []}) => ProviderConfig(
        id: id,
        name: 'Mock',
        type: ProviderType.openai,
        apiKey: 'sk-test',
        baseUrl: 'https://mock.local',
        defaultModel: 'mock-model',
        models: models,
      );

  test('未 await 时 valueOrNull 为 null(这就是冷启动误判的来源)', () {
    final container = ProviderContainer(
      overrides: [providersProvider.overrideWith(() => _FakeProviders([provider()]))],
    );
    addTearDown(container.dispose);

    // 首次读取:异步 notifier 还没跑完。
    expect(container.read(providersProvider).valueOrNull, isNull);
  });

  test('await future 之后能拿到已配置的供应商(弹层应走这条路)', () async {
    final container = ProviderContainer(
      overrides: [
        providersProvider.overrideWith(
          () => _FakeProviders([provider(models: const ['m1', 'm2'])]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final loaded = await container.read(providersProvider.future);
    expect(loaded, hasLength(1));
    expect(loaded.single.models, ['m1', 'm2']);
  });
}

/// 可控延迟的供应商 notifier:模拟「数据库读取尚未完成」的启动阶段。
class _FakeProviders extends ProvidersNotifier {
  _FakeProviders(this._configs);

  final List<ProviderConfig> _configs;

  @override
  Future<List<ProviderConfig>> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return _configs;
  }
}