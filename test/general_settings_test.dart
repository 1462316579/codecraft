import 'package:codecraft/data/settings/app_settings.dart';
import 'package:codecraft/data/settings/general_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用给定的初始值打开一个偏好设置容器(每次都是同一份 mock SharedPreferences)。
Future<ProviderContainer> openGeneral(Map<String, Object> stored) async {
  SharedPreferences.setMockInitialValues(stored);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

Future<GeneralSettings> readGeneral(Map<String, Object> stored) async =>
    (await openGeneral(stored)).read(generalSettingsProvider);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('未设置时全部回退到上游默认值', () async {
    final settings = await readGeneral({});
    expect(settings.autoRemoveStaleModels, isTrue);
    // 默认接着上次的对话(与上游默认「新开会话」不同,见枚举注释)。
    expect(settings.startupSessionMode, StartupSessionMode.recentSession);
    expect(settings.firstByteTimeoutSec, 300);
    expect(settings.streamIdleTimeoutSec, 300);
    expect(settings.maxNetworkRetries, 6);
    expect(settings.enterToSend, isFalse);
    expect(settings.compactionThresholdPercent, 90);
    expect(settings.sendFileMaxSizeMb, 100);
    expect(settings.deleteExternalWorkspaceSessions, isFalse);
  });

  test('写入后落盘,重新读取仍是新值', () async {
    final container = await openGeneral({});
    final notifier = container.read(generalSettingsProvider.notifier);
    await notifier.setAutoRemoveStaleModels(false);
    await notifier.setStartupSessionMode(StartupSessionMode.recentSession);
    await notifier.setFirstByteTimeoutSec(0);
    await notifier.setStreamIdleTimeoutSec(120);
    await notifier.setMaxNetworkRetries(3);
    await notifier.setEnterToSend(true);
    await notifier.setCompactionThresholdPercent(75);
    await notifier.setSendFileMaxSizeMb(20);
    await notifier.setDeleteExternalWorkspaceSessions(true);

    final reread = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
    ]);
    addTearDown(reread.dispose);
    final settings = reread.read(generalSettingsProvider);
    expect(settings.autoRemoveStaleModels, isFalse);
    expect(settings.startupSessionMode, StartupSessionMode.recentSession);
    expect(settings.firstByteTimeoutSec, 0);
    expect(settings.streamIdleTimeoutSec, 120);
    expect(settings.maxNetworkRetries, 3);
    expect(settings.enterToSend, isTrue);
    expect(settings.compactionThresholdPercent, 75);
    expect(settings.sendFileMaxSizeMb, 20);
    expect(settings.deleteExternalWorkspaceSessions, isTrue);
  });

  test('越界值按上游 coerce 规则收敛(写入与读盘都收敛)', () async {
    final container = await openGeneral({});
    final notifier = container.read(generalSettingsProvider.notifier);
    await notifier.setCompactionThresholdPercent(0);
    expect(notifier.state.compactionThresholdPercent, 1);
    await notifier.setCompactionThresholdPercent(500);
    expect(notifier.state.compactionThresholdPercent, 100);
    await notifier.setSendFileMaxSizeMb(0);
    expect(notifier.state.sendFileMaxSizeMb, 1);
    await notifier.setMaxNetworkRetries(-3);
    expect(notifier.state.maxNetworkRetries, 0);
    await notifier.setFirstByteTimeoutSec(-1);
    expect(notifier.state.firstByteTimeoutSec, 0);

    final clamped = await readGeneral({
      'general.compactionThresholdPercent': 0,
      'general.sendFileMaxSizeMb': -5,
      'general.maxNetworkRetries': -1,
    });
    expect(clamped.compactionThresholdPercent, 1);
    expect(clamped.sendFileMaxSizeMb, 1);
    expect(clamped.maxNetworkRetries, 0);
  });

  test('启动时会话枚举解析:未知值或旧值回退新开会话', () {
    expect(StartupSessionMode.parse('recentSession'), StartupSessionMode.recentSession);
    expect(StartupSessionMode.parse('bogus'), StartupSessionMode.recentSession);
    expect(StartupSessionMode.parse(null), StartupSessionMode.recentSession);
    expect(StartupSessionMode.parse('newSession'), StartupSessionMode.newSession);
  });
}