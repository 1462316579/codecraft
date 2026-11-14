import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../l10n/app_localizations.dart';

/// 关于页(版本、更新与反馈)。
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
          padding: const EdgeInsets.fromLTRB(0, 80, 0, Spacing.xxl),
          children: [
            SettingsPageHeader(title: l10n.about, subtitle: l10n.aboutSubtitle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: SettingsGroup(
              children: [
                SettingsRow(
                  icon: Iconfont.info,
                  title: l10n.version,
                  subtitle: '0.1.0 · Phase 1',
                ),
                const SettingsDivider(indent: SettingsRow.textIndent),
                SettingsRow(
                  icon: Iconfont.fileText,
                  title: l10n.license,
                  subtitle: 'GPL-3.0',
                  onTap: () => _showLicense(context, l10n),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _showLicense(BuildContext context, AppLocalizations l10n) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.license),
          content: Text(l10n.aboutBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.confirm),
            ),
          ],
        ),
      );
}