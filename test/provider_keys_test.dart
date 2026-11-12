import 'package:codecraft/data/provider_keys.dart';
import 'package:codecraft/data/providers/provider_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProviderConfig providerWith({
  bool multiKey = true,
  List<ProviderKey> keys = const [],
  String apiKey = '',
  KeyRotationStrategy strategy = KeyRotationStrategy.sequential,
  int cooldownMinutes = 5,
  List<int> codes = const [],
}) =>
    ProviderConfig(
      id: 'p1',
      name: 'p1',
      type: ProviderType.openai,
      apiKey: apiKey,
      multiKeyEnabled: multiKey,
      apiKeys: keys,
      keyRotationStrategy: strategy,
      keyCooldownMinutes: cooldownMinutes,
      keySwitchStatusCodes: codes,
    );

void main() {
  late KeyRotator rotator;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    rotator = KeyRotator(await SharedPreferences.getInstance());
  });

  test('顺序策略始终取第一个未冷却的 Key', () {
    final provider = providerWith(keys: const [ProviderKey('k1'), ProviderKey('k2')]);
    expect(rotator.pick(provider, 's1'), 'k1');
    expect(rotator.pick(provider, 's2'), 'k1');

    // k1 命中切换状态码后进冷却,下一次改用 k2
    rotator.reportStatus(provider, 'k1', 401);
    expect(rotator.pick(provider, 's3'), 'k2');
  });

  test('冷却时长为 0 时不切换;状态码不在名单内也不切换', () {
    final noCooldown =
        providerWith(keys: const [ProviderKey('k1'), ProviderKey('k2')], cooldownMinutes: 0);
    rotator.reportStatus(noCooldown, 'k1', 401);
    expect(rotator.pick(noCooldown, 's1'), 'k1');

    final otherCodes = providerWith(
      keys: const [ProviderKey('k1'), ProviderKey('k2')],
      codes: const [418],
    );
    rotator.reportStatus(otherCodes, 'k1', 401);
    expect(rotator.pick(otherCodes, 's1'), 'k1');
    rotator.reportStatus(otherCodes, 'k1', 418);
    expect(rotator.pick(otherCodes, 's2'), 'k2');
  });

  test('轮询策略:新会话轮流起步,同一会话粘住同一把', () {
    final provider = providerWith(
      keys: const [ProviderKey('k1'), ProviderKey('k2')],
      strategy: KeyRotationStrategy.roundRobin,
    );
    final first = rotator.pick(provider, 's1');
    expect(rotator.pick(provider, 's1'), first, reason: '同一会话保持同一把 Key');
    final second = rotator.pick(provider, 's2');
    expect(second, isNot(first), reason: '新会话应轮到下一把');
    expect(rotator.pick(provider, 's2'), second);
  });

  test('权重 ≤ 0 的 Key 不参与调度;全部冷却时取最早解冻的一把', () {
    final provider = providerWith(keys: const [
      ProviderKey('k1', weight: 0),
      ProviderKey('k2'),
    ]);
    expect(rotator.pick(provider, 's1'), 'k2');

    final both = providerWith(keys: const [ProviderKey('k1'), ProviderKey('k2')]);
    rotator.reportStatus(both, 'k1', 429);
    rotator.reportStatus(both, 'k2', 429);
    expect(rotator.pick(both, 's1'), isIn(['k1', 'k2']));
  });

  test('未开启多 Key 时退回单 Key;默认状态码集合', () {
    final single = providerWith(multiKey: false, apiKey: 'only');
    expect(single.effectiveApiKeys.single.value, 'only');
    expect(rotator.pick(single, 's1'), 'only');
    expect(providerWith().effectiveKeySwitchStatusCodes, {401, 402, 403, 429});
    expect(
      providerWith(codes: const [500, 418]).effectiveKeySwitchStatusCodes,
      {500, 418},
    );
  });

  test('配置 JSON 往返保留多 Key 字段', () {
    final provider = providerWith(
      keys: const [ProviderKey('k1', weight: 3), ProviderKey('k2')],
      strategy: KeyRotationStrategy.roundRobin,
      cooldownMinutes: 12,
      codes: const [401, 429],
    );
    final restored = ProviderConfig.fromJson(provider.toJson());
    expect(restored.multiKeyEnabled, isTrue);
    expect(restored.apiKeys.map((key) => key.value), ['k1', 'k2']);
    expect(restored.apiKeys.first.weight, 3);
    expect(restored.keyRotationStrategy, KeyRotationStrategy.roundRobin);
    expect(restored.keyCooldownMinutes, 12);
    expect(restored.keySwitchStatusCodes, [401, 429]);
  });

  test('保存前清洗:Key 去空白、权重收敛、状态码过滤非法值', () {
    final dirty = providerWith(
      keys: const [ProviderKey(' k 1 ', weight: -5), ProviderKey('   ', weight: 2)],
      codes: const [99, 401, 700],
    ).sanitized();
    expect(dirty.apiKeys.length, 1);
    expect(dirty.apiKeys.single.value, 'k1');
    expect(dirty.apiKeys.single.weight, 0);
    expect(dirty.keySwitchStatusCodes, [401]);
  });
}