import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/provider_config.dart';
import 'settings/app_settings.dart';

/// 多 Key 轮换调度(对齐上游多 Key 语义):
/// - 顺序策略:始终用第一个未冷却的 Key,命中切换状态码后前移;
/// - 轮询策略:新会话轮流分配起始 Key,同一会话内粘住同一个 Key(保住服务端 prompt 缓存);
/// - 被切走的 Key 进入冷却(分钟数由供应商配置),冷却结束自动回到候选。
class KeyRotator {
  KeyRotator(this._prefs);

  final SharedPreferences _prefs;

  static const String _cooldownKey = 'keyCooldown';
  static const String _sessionKey = 'keySession';

  /// 为一次请求挑选 Key;无多 Key 配置时返回空串(由调用方退回单 Key)。
  String pick(ProviderConfig provider, String sessionId) {
    final keys = provider.effectiveApiKeys;
    final scheduled = keys.where((key) => key.weight > 0).toList();
    final candidates = scheduled.isEmpty ? keys : scheduled;
    if (candidates.isEmpty) return '';
    if (candidates.length == 1) return candidates.first.value;

    final cooldowns = _readCooldowns(provider.id);
    final now = DateTime.now().millisecondsSinceEpoch;
    final available = [
      for (final key in candidates)
        if ((cooldowns[key.value] ?? 0) <= now) key.value,
    ];
    if (available.isEmpty) {
      // 全部冷却中:用冷却最早结束的那把,避免直接不可用。
      final sorted = candidates.toList()
        ..sort((a, b) => (cooldowns[a.value] ?? 0).compareTo(cooldowns[b.value] ?? 0));
      return sorted.first.value;
    }

    if (provider.keyRotationStrategy == KeyRotationStrategy.sequential) {
      return available.first;
    }

    // 轮询:同一会话粘住原 Key;新会话按累计计数在可用 Key 间轮流。
    final sticky = _readSessionKeys()[sessionId];
    if (sticky != null && available.contains(sticky)) return sticky;
    final counter = (_prefs.getInt('keyRoundRobinCounter') ?? 0) + 1;
    final picked = available[counter % available.length];
    _writeSessionKey(sessionId, picked);
    return picked;
  }

  /// 上报一次请求结果:命中切换状态码时把该 Key 打入冷却。
  void reportStatus(ProviderConfig provider, String apiKey, int statusCode) {
    if (apiKey.isEmpty) return;
    if (provider.effectiveApiKeys.length < 2) return;
    if (!provider.effectiveKeySwitchStatusCodes.contains(statusCode)) return;
    if (provider.keyCooldownMinutes <= 0) return;

    final cooldowns = _readCooldowns(provider.id);
    cooldowns[apiKey] =
        DateTime.now().millisecondsSinceEpoch + provider.keyCooldownMinutes * 60 * 1000;
    _prefs.setString('$_cooldownKey.${provider.id}', jsonEncode(cooldowns));
  }

  Map<String, int> _readCooldowns(String providerId) {
    final raw = _prefs.getString('$_cooldownKey.$providerId');
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          if (entry.value is num) '${entry.key}': (entry.value as num).toInt(),
      };
    } catch (_) {
      return {};
    }
  }

  Map<String, String> _readSessionKeys() {
    final raw = _prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {for (final entry in decoded.entries) '${entry.key}': '${entry.value}'};
    } catch (_) {
      return {};
    }
  }

  void _writeSessionKey(String sessionId, String key) {
    final map = Map<String, String>.of(_readSessionKeys());
    map[sessionId] = key;
    _prefs.setString(_sessionKey, jsonEncode(map));
    _prefs.setInt('keyRoundRobinCounter', (_prefs.getInt('keyRoundRobinCounter') ?? 0) + 1);
  }
}

final keyRotatorProvider = Provider<KeyRotator>(
  (ref) => KeyRotator(ref.watch(sharedPreferencesProvider)),
);
