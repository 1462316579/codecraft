import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/iconfont.dart';
import '../../data/terminal/terminal_settings.dart';

/// 终端设置页
void showTerminalSettingsSheet(BuildContext context, WidgetRef ref) {
  final settings = ref.read(terminalSettingsProvider);
  showModalBottomSheet(
    context: context,
    builder: (context) => TerminalSettingsSheet(settings: settings, ref: ref),
  );
}

class TerminalSettingsSheet extends ConsumerWidget {
  final TerminalSettings settings;
  final WidgetRef ref;

  const TerminalSettingsSheet({
    super.key,
    required this.settings,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(terminalSettingsProvider);
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '终端设置',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          ListTile(
            title: const Text('字体大小'),
            subtitle: Text('${settings.fontSize.toInt()} px'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    ref.read(terminalSettingsProvider.notifier).state =
                        settings.copyWith(
                          fontSize: (settings.fontSize - 1).clamp(8.0, 72.0),
                        );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    ref.read(terminalSettingsProvider.notifier).state =
                        settings.copyWith(
                          fontSize: (settings.fontSize + 1).clamp(8.0, 72.0),
                        );
                  },
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('光标样式'),
            trailing: DropdownButton<TerminalCursorStyle>(
              value: settings.cursorStyle,
              onChanged: (v) {
                if (v != null) {
                  ref.read(terminalSettingsProvider.notifier).state =
                      settings.copyWith(cursorStyle: v);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: TerminalCursorStyle.block,
                  child: Text('块光标'),
                ),
                DropdownMenuItem(
                  value: TerminalCursorStyle.underline,
                  child: Text('下划线'),
                ),
                DropdownMenuItem(
                  value: TerminalCursorStyle.bar,
                  child: Text('竖线'),
                ),
              ],
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            '字体族：${settings.fontFamily.displayName}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('字体族'),
            trailing: DropdownButton<TerminalFontFamily>(
              value: settings.fontFamily,
              onChanged: (v) {
                if (v != null) {
                  ref.read(terminalSettingsProvider.notifier).state =
                      settings.copyWith(fontFamily: v);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: TerminalFontFamily('monospace', 'Monospace'),
                  child: Text('系统 Monospace'),
                ),
                DropdownMenuItem(
                  value: TerminalFontFamily('JetBrainsMono', 'JetBrainsMono'),
                  child: Row(
                    children: [
                      Icon(Iconfont.code, size: 16),
                      const SizedBox(width: 8),
                      Text('JetBrainsMono'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: TerminalFontFamily('Iconfont', 'Iconfont'),
                  child: Row(
                    children: [
                      Icon(Iconfont.menu, size: 16),
                      const SizedBox(width: 8),
                      Text('阿里巴巴 iconfont'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 终端设置提供器
final terminalSettingsProvider = StateProvider<TerminalSettings>((ref) {
  return const TerminalSettings();
});
