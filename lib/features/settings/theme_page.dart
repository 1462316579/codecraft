import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../data/settings/app_settings.dart';
import '../../l10n/app_localizations.dart';

/// 主题页(外观、背景与显示):主题模式与语言,行样式与设置首页一致。
class ThemePage extends ConsumerWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.light
                ? const [Color(0xFFEDE9FE), Color(0xFFDBEAFE), Color(0xFFFCE7F3)]
                : const [Color(0xFF1E1B4B), Color(0xFF1E3A8A), Color(0xFF4C1D95)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.only(top: 80, bottom: 140),
        children: [
          SettingsPageHeader(title: l10n.themeTitle, subtitle: l10n.themeSubtitle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: SettingsGroup(
              children: [
                SettingsRow(
                  icon: Iconfont.sunMoon,
                  title: l10n.themeMode,
                  trailing: _trailingValue(context, _themeModeLabel(l10n, settings.themeMode)),
                  onTap: () => _pickThemeMode(context, settings.themeMode, notifier.setThemeMode),
                ),
                const SettingsDivider(indent: SettingsRow.textIndent),
                SettingsRow(
                  icon: Iconfont.languages,
                  title: l10n.language,
                  trailing: _trailingValue(context, _localeLabel(l10n, settings.localeCode)),
                  onTap: () => _pickLocale(context, settings.localeCode, notifier.setLocale),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _trailingValue(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: context.semantic.subtleText),
      );

  String _themeModeLabel(AppLocalizations l10n, AppThemeMode mode) => switch (mode) {
        AppThemeMode.system => l10n.themeModeSystem,
        AppThemeMode.light => l10n.themeModeLight,
        AppThemeMode.dark => l10n.themeModeDark,
      };

  String _localeLabel(AppLocalizations l10n, String code) => switch (code) {
        '' => l10n.languageSystem,
        'zh' => '中文',
        _ => 'English',
      };

  Future<void> _pickThemeMode(
    BuildContext context,
    AppThemeMode current,
    Future<void> Function(AppThemeMode) onSelect,
  ) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in AppThemeMode.values)
              RadioListTile<AppThemeMode>(
                value: mode,
                groupValue: current,
                title: Text(_themeModeLabel(l10n, mode)),
                onChanged: (value) {
                  Navigator.pop(context);
                  if (value != null) onSelect(value);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLocale(
    BuildContext context,
    String current,
    Future<void> Function(String) onSelect,
  ) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in [
              ('', l10n.languageSystem),
              ('zh', '中文'),
              ('en', 'English'),
            ])
              RadioListTile<String>(
                value: entry.$1,
                groupValue: current,
                title: Text(entry.$2),
                onChanged: (value) {
                  Navigator.pop(context);
                  onSelect(value ?? '');
                },
              ),
          ],
        ),
      ),
    );
  }
}