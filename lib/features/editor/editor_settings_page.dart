import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../data/settings/editor_settings.dart';
import '../../g11n/app_globalizations.dart';

/// 编辑器设置页(对齐上游 EditorSettingsScreen):字号滑杆 + 自动换行、
/// 缩进参考线、换行箭头、空白符号四个开关。改动即时生效并持久化。
class EditorSettingsPage extends ConsumerWidget {
  const EditorSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g11n = AppGlobalizations.of(context);
    final settings = ref.watch(editorSettingsProvider);
    final notifier = ref.read(editorSettingsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: context.semantic.pageBackground,
      appBar: AppBar(
        title: Text(g11n.editorSettings),
        backgroundColor: context.semantic.pageBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, Spacing.xxl),
        children: [
          SettingsGroup(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.md,
                  Spacing.lg,
                  Spacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(g11n.editorFontSize, style: theme.textTheme.bodyLarge),
                        ),
                        Text(
                          g11n.editorFontSizeValue(settings.fontSizeSp),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: context.semantic.subtleText,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: settings.fontSizeSp.toDouble(),
                      min: EditorSettings.minFontSizeSp.toDouble(),
                      max: EditorSettings.maxFontSizeSp.toDouble(),
                      divisions:
                          EditorSettings.maxFontSizeSp - EditorSettings.minFontSizeSp,
                      onChanged: (value) => notifier.setFontSize(value.round()),
                    ),
                  ],
                ),
              ),
              const SettingsDivider(indent: Spacing.lg),
              SettingsRow(
                title: g11n.editorWordWrap,
                trailing: Switch(
                  value: settings.wordWrap,
                  onChanged: notifier.setWordWrap,
                ),
              ),
              const SettingsDivider(indent: Spacing.lg),
              SettingsRow(
                title: g11n.editorShowIndentGuide,
                trailing: Switch(
                  value: settings.showIndentGuide,
                  onChanged: notifier.setShowIndentGuide,
                ),
              ),
              const SettingsDivider(indent: Spacing.lg),
              SettingsRow(
                title: g11n.editorShowWhitespace,
                trailing: Switch(
                  value: settings.showWhitespace,
                  onChanged: notifier.setShowWhitespace,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}