import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

/// App 启动(含切换工作区)时进入哪个会话。
///
/// 与上游的差异:上游默认 [newSession](每次启动开新会话),本项目默认 [recentSession]
/// ——重开 App 应该接着上次的对话,而不是又冒出一个空会话。用户仍可在
/// 「偏好设置 → 启动时会话」里改回新开会话。
enum StartupSessionMode {
  /// 新开会话:复用最近那个还没发过消息的空会话,否则新建。
  newSession,

  /// 打开最近会话:直接进入最近更新的会话。
  recentSession;

  static StartupSessionMode parse(String? value) => values.firstWhere(
        (mode) => mode.name == value,
        orElse: () => StartupSessionMode.recentSession,
      );
}

/// 「偏好设置」里的全局偏好:字段、默认值与取值约束对齐上游 GeneralSettingsRepository。
class GeneralSettings {
  const GeneralSettings({
    this.autoRemoveStaleModels = true,
    this.startupSessionMode = StartupSessionMode.recentSession,
    this.firstByteTimeoutSec = defaultFirstByteTimeoutSec,
    this.streamIdleTimeoutSec = defaultStreamIdleTimeoutSec,
    this.maxNetworkRetries = defaultMaxNetworkRetries,
    this.enterToSend = false,
    this.compactionThresholdPercent = defaultCompactionThresholdPercent,
    this.sendFileMaxSizeMb = defaultSendFileMaxSizeMb,
    this.deleteExternalWorkspaceSessions = false,
    this.goalMaxTurns = defaultGoalMaxTurns,
    this.goalMaxTokens = defaultGoalMaxTokens,
  });

  /// 首字超时默认 5 分钟,与原硬编码值一致。
  static const int defaultFirstByteTimeoutSec = 300;

  /// 数据块间隔超时默认 5 分钟:服务端静默时能自行断开并重试,避免本轮永久停在「执行中」。
  static const int defaultStreamIdleTimeoutSec = 300;

  /// 网络重试次数默认 6,与原硬编码值一致。
  static const int defaultMaxNetworkRetries = 6;

  /// 自动压缩阈值默认 90%,与原硬编码值一致。
  static const int defaultCompactionThresholdPercent = 90;

  /// sendFile 单个文件大小上限默认 100MB,与原硬编码值一致。
  static const int defaultSendFileMaxSizeMb = 100;

  /// 目标(goal)自主循环最大续跑轮数默认 50。
  static const int defaultGoalMaxTurns = 50;

  /// 目标(goal)累计 token 预算默认 50 万。
  static const int defaultGoalMaxTokens = 500000;

  final bool autoRemoveStaleModels;
  final StartupSessionMode startupSessionMode;

  /// 首字超时(秒);0 表示不限制。
  final int firstByteTimeoutSec;

  /// 流式响应相邻数据块间隔超时(秒);0 表示不限制。
  final int streamIdleTimeoutSec;

  /// 网络请求最大重试次数(不含首次请求);0 表示不重试。
  final int maxNetworkRetries;

  /// 回车键是否直接发送消息;默认关闭(回车换行,由发送按钮发送)。
  final bool enterToSend;

  /// 自动压缩触发阈值(上下文窗口的百分比),限定 1..100。
  final int compactionThresholdPercent;

  /// sendFile 单个文件大小上限(MB),下限 1。
  final int sendFileMaxSizeMb;

  /// 移除外部本地工作区时是否一并删除其聊天记录。
  final bool deleteExternalWorkspaceSessions;

  /// 目标自主循环最大续跑轮数,下限 1。
  final int goalMaxTurns;

  /// 目标自主循环累计 token 预算,下限 1000。
  final int goalMaxTokens;

  GeneralSettings copyWith({
    bool? autoRemoveStaleModels,
    StartupSessionMode? startupSessionMode,
    int? firstByteTimeoutSec,
    int? streamIdleTimeoutSec,
    int? maxNetworkRetries,
    bool? enterToSend,
    int? compactionThresholdPercent,
    int? sendFileMaxSizeMb,
    bool? deleteExternalWorkspaceSessions,
    int? goalMaxTurns,
    int? goalMaxTokens,
  }) =>
      GeneralSettings(
        autoRemoveStaleModels: autoRemoveStaleModels ?? this.autoRemoveStaleModels,
        startupSessionMode: startupSessionMode ?? this.startupSessionMode,
        firstByteTimeoutSec: firstByteTimeoutSec ?? this.firstByteTimeoutSec,
        streamIdleTimeoutSec: streamIdleTimeoutSec ?? this.streamIdleTimeoutSec,
        maxNetworkRetries: maxNetworkRetries ?? this.maxNetworkRetries,
        enterToSend: enterToSend ?? this.enterToSend,
        compactionThresholdPercent:
            compactionThresholdPercent ?? this.compactionThresholdPercent,
        sendFileMaxSizeMb: sendFileMaxSizeMb ?? this.sendFileMaxSizeMb,
        deleteExternalWorkspaceSessions:
            deleteExternalWorkspaceSessions ?? this.deleteExternalWorkspaceSessions,
        goalMaxTurns: goalMaxTurns ?? this.goalMaxTurns,
        goalMaxTokens: goalMaxTokens ?? this.goalMaxTokens,
      );
}

final generalSettingsProvider =
    StateNotifierProvider<GeneralSettingsNotifier, GeneralSettings>(GeneralSettingsNotifier.new);

class GeneralSettingsNotifier extends StateNotifier<GeneralSettings> {
  GeneralSettingsNotifier(this._ref)
      : super(_read(_ref.read(sharedPreferencesProvider))) {
    _prefs = _ref.read(sharedPreferencesProvider);
  }

  static const String _autoRemoveStaleModelsKey = 'general.autoRemoveStaleModels';
  static const String _startupSessionModeKey = 'general.startupSessionMode';
  static const String _firstByteTimeoutSecKey = 'general.firstByteTimeoutSec';
  static const String _streamIdleTimeoutSecKey = 'general.streamIdleTimeoutSec';
  static const String _maxNetworkRetriesKey = 'general.maxNetworkRetries';
  static const String _enterToSendKey = 'general.enterToSend';
  static const String _compactionThresholdPercentKey = 'general.compactionThresholdPercent';
  static const String _sendFileMaxSizeMbKey = 'general.sendFileMaxSizeMb';
  static const String _deleteExternalWorkspaceSessionsKey =
      'general.deleteExternalWorkspaceSessions';
  static const String _goalMaxTurnsKey = 'general.goalMaxTurns';
  static const String _goalMaxTokensKey = 'general.goalMaxTokens';

  final Ref _ref;
  late final SharedPreferences _prefs;

  /// 读盘时统一做下限收敛(与上游 coerceAtLeast 一致,不设上限)。
  static int _atLeast(int? value, int fallback, int min) {
    final raw = value ?? fallback;
    return raw < min ? min : raw;
  }

  static GeneralSettings _read(SharedPreferences prefs) => GeneralSettings(
        autoRemoveStaleModels: prefs.getBool(_autoRemoveStaleModelsKey) ?? true,
        startupSessionMode: StartupSessionMode.parse(prefs.getString(_startupSessionModeKey)),
        firstByteTimeoutSec: _atLeast(
          prefs.getInt(_firstByteTimeoutSecKey),
          GeneralSettings.defaultFirstByteTimeoutSec,
          0,
        ),
        streamIdleTimeoutSec: _atLeast(
          prefs.getInt(_streamIdleTimeoutSecKey),
          GeneralSettings.defaultStreamIdleTimeoutSec,
          0,
        ),
        maxNetworkRetries: _atLeast(
          prefs.getInt(_maxNetworkRetriesKey),
          GeneralSettings.defaultMaxNetworkRetries,
          0,
        ),
        enterToSend: prefs.getBool(_enterToSendKey) ?? false,
        compactionThresholdPercent: (prefs.getInt(_compactionThresholdPercentKey) ??
                GeneralSettings.defaultCompactionThresholdPercent)
            .clamp(1, 100),
        sendFileMaxSizeMb: _atLeast(
          prefs.getInt(_sendFileMaxSizeMbKey),
          GeneralSettings.defaultSendFileMaxSizeMb,
          1,
        ),
        deleteExternalWorkspaceSessions:
            prefs.getBool(_deleteExternalWorkspaceSessionsKey) ?? false,
        goalMaxTurns: _atLeast(
          prefs.getInt(_goalMaxTurnsKey),
          GeneralSettings.defaultGoalMaxTurns,
          1,
        ),
        goalMaxTokens: _atLeast(
          prefs.getInt(_goalMaxTokensKey),
          GeneralSettings.defaultGoalMaxTokens,
          1000,
        ),
      );

  Future<void> setAutoRemoveStaleModels(bool enabled) async {
    await _prefs.setBool(_autoRemoveStaleModelsKey, enabled);
    state = state.copyWith(autoRemoveStaleModels: enabled);
  }

  Future<void> setStartupSessionMode(StartupSessionMode mode) async {
    await _prefs.setString(_startupSessionModeKey, mode.name);
    state = state.copyWith(startupSessionMode: mode);
  }

  Future<void> setFirstByteTimeoutSec(int sec) async {
    final value = sec < 0 ? 0 : sec;
    await _prefs.setInt(_firstByteTimeoutSecKey, value);
    state = state.copyWith(firstByteTimeoutSec: value);
  }

  Future<void> setStreamIdleTimeoutSec(int sec) async {
    final value = sec < 0 ? 0 : sec;
    await _prefs.setInt(_streamIdleTimeoutSecKey, value);
    state = state.copyWith(streamIdleTimeoutSec: value);
  }

  Future<void> setMaxNetworkRetries(int count) async {
    final value = count < 0 ? 0 : count;
    await _prefs.setInt(_maxNetworkRetriesKey, value);
    state = state.copyWith(maxNetworkRetries: value);
  }

  Future<void> setEnterToSend(bool enabled) async {
    await _prefs.setBool(_enterToSendKey, enabled);
    state = state.copyWith(enterToSend: enabled);
  }

  Future<void> setCompactionThresholdPercent(int percent) async {
    final value = percent.clamp(1, 100);
    await _prefs.setInt(_compactionThresholdPercentKey, value);
    state = state.copyWith(compactionThresholdPercent: value);
  }

  Future<void> setSendFileMaxSizeMb(int mb) async {
    final value = mb < 1 ? 1 : mb;
    await _prefs.setInt(_sendFileMaxSizeMbKey, value);
    state = state.copyWith(sendFileMaxSizeMb: value);
  }

  Future<void> setDeleteExternalWorkspaceSessions(bool enabled) async {
    await _prefs.setBool(_deleteExternalWorkspaceSessionsKey, enabled);
    state = state.copyWith(deleteExternalWorkspaceSessions: enabled);
  }

  Future<void> setGoalMaxTurns(int turns) async {
    final value = turns < 1 ? 1 : turns;
    await _prefs.setInt(_goalMaxTurnsKey, value);
    state = state.copyWith(goalMaxTurns: value);
  }

  Future<void> setGoalMaxTokens(int tokens) async {
    final value = tokens < 1000 ? 1000 : tokens;
    await _prefs.setInt(_goalMaxTokensKey, value);
    state = state.copyWith(goalMaxTokens: value);
  }
}