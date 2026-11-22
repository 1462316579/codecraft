import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../g11n/app_globalizations.dart';

enum AppThemeMode {
  system,
  light,
  dark;

  ThemeMode get material => switch (this) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };

  static AppThemeMode parse(String? value) =>
      values.firstWhere((m) => m.name == value, orElse: () => AppThemeMode.system);
}

class AppSettings {
  const AppSettings({this.themeMode = AppThemeMode.system, this.localeCode = ''});

  final AppThemeMode themeMode;

  /// 空串表示跟随系统。
  final String localeCode;

  Locale? get locale => localeCode.isEmpty ? null : Locale(localeCode);

  AppSettings copyWith({AppThemeMode? themeMode, String? localeCode}) => AppSettings(
        themeMode: themeMode ?? this.themeMode,
        localeCode: localeCode ?? this.localeCode,
      );
}

/// 在 main() 中 override 为已加载的实例。
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('sharedPreferencesProvider 需在 ProviderScope.overrides 中注入'),
);

/// 当前语言下的文案(控制器等没有 BuildContext 的地方使用)。
final appGlobalizationsProvider = Provider<AppGlobalizations>((ref) {
  final locale = ref.watch(settingsProvider).locale ?? PlatformDispatcher.instance.locale;
  return lookupAppGlobalizations(Locale(locale.languageCode == 'zh' ? 'zh' : 'en'));
});

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._ref)
      : super(_read(_ref.read(sharedPreferencesProvider))) {
    _prefs = _ref.read(sharedPreferencesProvider);
  }

  static const _themeModeKey = 'settings.themeMode';
  static const _localeKey = 'settings.locale';

  final Ref _ref;
  late final SharedPreferences _prefs;

  static AppSettings _read(SharedPreferences prefs) => AppSettings(
        themeMode: AppThemeMode.parse(prefs.getString(_themeModeKey)),
        localeCode: prefs.getString(_localeKey) ?? '',
      );

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setLocale(String code) async {
    state = state.copyWith(localeCode: code);
    await _prefs.setString(_localeKey, code);
  }
}