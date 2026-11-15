import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/iconfont.dart';
import '../../core/theme/tokens.dart';
import '../../data/terminal/terminal_settings.dart';

/// 终端设置面板
void showTerminalSettingsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const TerminalSettingsSheet(),
  );
}

class TerminalSettingsSheet extends ConsumerWidget {
  const TerminalSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(terminalSettingsProvider);
    final notifier = ref.read(terminalSettingsProvider.notifier);
    final theme = Theme.of(context);

    void update(TerminalSettings next) => notifier.update(next);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: Spacing.sm),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.lg,
                  Spacing.lg,
                  Spacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '终端设置',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: Spacing.lg),
                    _PreviewCard(settings: settings),
                    const SizedBox(height: Spacing.xl),
                    const _SectionTitle('配色主题'),
                    const SizedBox(height: Spacing.md),
                    Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.sm,
                      children: [
                        for (final preset in TerminalThemePreset.all)
                          _SettingChip(
                            label: preset.name,
                            selected: settings.theme.id == preset.id,
                            onTap: () =>
                                update(settings.copyWith(theme: preset)),
                          ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xl),
                    Row(
                      children: [
                        const _SectionTitle('字体大小'),
                        const Spacer(),
                        Text(
                          '${settings.fontSize.toStringAsFixed(0)} sp',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: settings.fontSize,
                      min: 8,
                      max: 24,
                      divisions: 16,
                      onChanged: (value) =>
                          update(settings.copyWith(fontSize: value)),
                    ),
                    const SizedBox(height: Spacing.md),
                    Row(
                      children: [
                        const _SectionTitle('终端字体'),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _importFont(context, ref, settings),
                          icon: const Icon(Iconfont.upload, size: 16),
                          label: const Text('导入'),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.sm,
                      children: [
                        _SettingChip(
                          label: '系统等宽',
                          selected: settings.fontFamily.family == 'monospace',
                          onTap: () => update(
                            settings.copyWith(
                              fontFamily: const TerminalFontFamily(
                                'monospace',
                                '系统等宽',
                              ),
                            ),
                          ),
                        ),
                        _SettingChip(
                          label: 'JetBrains Mono',
                          selected:
                              settings.fontFamily.family == 'JetBrainsMono',
                          onTap: () => update(
                            settings.copyWith(
                              fontFamily: const TerminalFontFamily(
                                'JetBrainsMono',
                                'JetBrains Mono',
                              ),
                            ),
                          ),
                        ),
                        if (settings.importedFontPath != null)
                          _SettingChip(
                            label: settings.fontFamily.family ==
                                    kImportedTerminalFontFamily
                                ? '导入字体'
                                : '导入字体（未启用）',
                            selected: settings.fontFamily.family ==
                                kImportedTerminalFontFamily,
                            onTap: () => update(
                              settings.copyWith(
                                fontFamily: const TerminalFontFamily(
                                  kImportedTerminalFontFamily,
                                  '导入字体',
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xl),
                    const _SectionTitle('光标样式'),
                    const SizedBox(height: Spacing.md),
                    Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.sm,
                      children: [
                        _SettingChip(
                          label: '方块',
                          selected:
                              settings.cursorStyle == TerminalCursorStyle.block,
                          onTap: () => update(
                            settings.copyWith(
                              cursorStyle: TerminalCursorStyle.block,
                            ),
                          ),
                        ),
                        _SettingChip(
                          label: '下划线',
                          selected: settings.cursorStyle ==
                              TerminalCursorStyle.underline,
                          onTap: () => update(
                            settings.copyWith(
                              cursorStyle: TerminalCursorStyle.underline,
                            ),
                          ),
                        ),
                        _SettingChip(
                          label: '竖线',
                          selected:
                              settings.cursorStyle == TerminalCursorStyle.bar,
                          onTap: () => update(
                            settings.copyWith(
                              cursorStyle: TerminalCursorStyle.bar,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFont(
    BuildContext context,
    WidgetRef ref,
    TerminalSettings settings,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: '字体', extensions: ['ttf', 'otf', 'ttc']),
      ],
    );
    if (picked == null) return;
    try {
      final bytes = await picked.readAsBytes();
      final name = picked.name;
      final dot = name.lastIndexOf('.');
      final extension = dot < 0 ? '.ttf' : name.substring(dot);
      final path = await saveImportedFontFile(bytes, extension);
      await loadImportedTerminalFont(path);
      await ref.read(terminalSettingsProvider.notifier).update(
            settings.copyWith(
              fontFamily: const TerminalFontFamily(
                kImportedTerminalFontFamily,
                '导入字体',
              ),
              importedFontPath: () => path,
            ),
          );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('字体导入失败：$e')));
    }
  }
}

/// 预览卡片：用当前主题/字体渲染几行示例内容。
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.settings});

  final TerminalSettings settings;

  @override
  Widget build(BuildContext context) {
    final background = settings.theme.backgroundFor(context);
    final foreground = settings.theme.foregroundFor(context);
    final cursorColor = settings.theme.cursorFor(context);
    final fontSize = settings.fontSize.clamp(10.0, 18.0);

    TextStyle style(Color color) => TextStyle(
          fontFamily: settings.fontFamily.family,
          fontSize: fontSize.toDouble(),
          height: 1.5,
          color: color,
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'root@aicode',
                  style: style(const Color(0xFF0DBC79)),
                ),
                TextSpan(text: ':~/workspace', style: style(foreground)),
                TextSpan(text: r'$ ', style: style(const Color(0xFF2472C8))),
                TextSpan(text: './gradlew build', style: style(foreground)),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                    text: '> Task :app:assembleDebug ',
                    style: style(foreground)),
                TextSpan(
                  text: 'SUCCESS',
                  style: style(const Color(0xFF0DBC79))
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              Text(r'$ ', style: style(const Color(0xFF2472C8))),
              Text('git status', style: style(foreground)),
              const SizedBox(width: 2),
              SizedBox(
                width: fontSize * 0.62,
                height: fontSize * 1.15,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cursorColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

/// 选项标签：选中时填充主题色底。
class _SettingChip extends StatelessWidget {
  const _SettingChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md + 2,
            vertical: Spacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
          ),
        ),
      ),
    );
  }
}
