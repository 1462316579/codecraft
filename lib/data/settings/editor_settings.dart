import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

/// 编辑器可持久化的显示设置(对齐上游 EditorSettings)。
class EditorSettings {
  const EditorSettings({
    this.fontSizeSp = defaultFontSizeSp,
    this.wordWrap = false,
    this.showIndentGuide = true,
    this.showWhitespace = false,
  });

  static const int minFontSizeSp = 10;
  static const int maxFontSizeSp = 28;
  static const int defaultFontSizeSp = 14;

  final int fontSizeSp;
  final bool wordWrap;
  final bool showIndentGuide;
  final bool showWhitespace;

  EditorSettings copyWith({
    int? fontSizeSp,
    bool? wordWrap,
    bool? showIndentGuide,
    bool? showWhitespace,
  }) =>
      EditorSettings(
        fontSizeSp: fontSizeSp ?? this.fontSizeSp,
        wordWrap: wordWrap ?? this.wordWrap,
        showIndentGuide: showIndentGuide ?? this.showIndentGuide,
        showWhitespace: showWhitespace ?? this.showWhitespace,
      );
}

final editorSettingsProvider =
    StateNotifierProvider<EditorSettingsNotifier, EditorSettings>(EditorSettingsNotifier.new);

class EditorSettingsNotifier extends StateNotifier<EditorSettings> {
  EditorSettingsNotifier(this._ref) : super(_read(_ref.read(sharedPreferencesProvider))) {
    _prefs = _ref.read(sharedPreferencesProvider);
  }

  static const String _fontSizeKey = 'editor.fontSizeSp';
  static const String _wordWrapKey = 'editor.wordWrap';
  static const String _showIndentGuideKey = 'editor.showIndentGuide';
  static const String _showWhitespaceKey = 'editor.showWhitespace';

  final Ref _ref;
  late final SharedPreferences _prefs;

  static EditorSettings _read(SharedPreferences prefs) => EditorSettings(
        fontSizeSp: (prefs.getInt(_fontSizeKey) ?? EditorSettings.defaultFontSizeSp)
            .clamp(EditorSettings.minFontSizeSp, EditorSettings.maxFontSizeSp),
        wordWrap: prefs.getBool(_wordWrapKey) ?? false,
        showIndentGuide: prefs.getBool(_showIndentGuideKey) ?? true,
        showWhitespace: prefs.getBool(_showWhitespaceKey) ?? false,
      );

  Future<void> setFontSize(int sp) async {
    final value = sp.clamp(EditorSettings.minFontSizeSp, EditorSettings.maxFontSizeSp);
    await _prefs.setInt(_fontSizeKey, value);
    state = state.copyWith(fontSizeSp: value);
  }

  Future<void> setWordWrap(bool enabled) async {
    await _prefs.setBool(_wordWrapKey, enabled);
    state = state.copyWith(wordWrap: enabled);
  }

  Future<void> setShowIndentGuide(bool enabled) async {
    await _prefs.setBool(_showIndentGuideKey, enabled);
    state = state.copyWith(showIndentGuide: enabled);
  }

  Future<void> setShowWhitespace(bool enabled) async {
    await _prefs.setBool(_showWhitespaceKey, enabled);
    state = state.copyWith(showWhitespace: enabled);
  }
}