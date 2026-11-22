import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../data/settings/general_settings.dart';
import '../../g11n/app_globalizations.dart';

/// 偏好设置页(逐项对齐上游 GeneralSettingsSection):集中放置不属于单个提供商配置、
/// 也不针对某个专用模型的全局偏好。五个分组依次为模型 / 会话 / 输入 / 网络 / 工具,
/// 数值项点击后用数值输入弹窗编辑,启动时会话用底部弹层二选一。
class GeneralPage extends ConsumerWidget {
  const GeneralPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g11n = AppGlobalizations.of(context);
    final settings = ref.watch(generalSettingsProvider);
    final notifier = ref.read(generalSettingsProvider.notifier);

    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(g11n.settingsGeneral),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsGroupHeader(text: g11n.settingsGeneralModels),
                SettingsGroup(
                  children: [
                    SettingsRow(
                      title: g11n.settingsAutoRemoveStaleModels,
                      subtitle: g11n.settingsAutoRemoveStaleModelsDesc,
                      trailing: Switch(
                        value: settings.autoRemoveStaleModels,
                        onChanged: notifier.setAutoRemoveStaleModels,
                      ),
                    ),
                    const SettingsDivider(),
                    SettingsRow(
                      title: g11n.settingsCompactionThreshold,
                      subtitle: g11n.settingsCompactionThresholdDesc,
                      trailing: _trailingValue(
                        context,
                        g11n.settingsPercentValue(settings.compactionThresholdPercent),
                      ),
                      onTap: () => _editNumber(
                        context,
                        title: g11n.settingsCompactionThreshold,
                        initialValue: settings.compactionThresholdPercent,
                        hint: g11n.settingsCompactionThresholdInputHint,
                        minValue: 1,
                        maxValue: 100,
                        onConfirm: notifier.setCompactionThresholdPercent,
                      ),
                    ),
                  ],
                ),
                SettingsGroupHeader(text: g11n.settingsGeneralSession),
                SettingsGroup(
                  children: [
                    SettingsRow(
                      title: g11n.settingsStartupSession,
                      trailing: _trailingValue(
                        context,
                        _startupSessionLabel(g11n, settings.startupSessionMode),
                      ),
                      onTap: () => _pickStartupSession(
                        context,
                        current: settings.startupSessionMode,
                        onSelect: notifier.setStartupSessionMode,
                      ),
                    ),
                    const SettingsDivider(),
                    SettingsRow(
                      title: g11n.settingsDeleteExternalWorkspaceSessions,
                      subtitle: g11n.settingsDeleteExternalWorkspaceSessionsDesc,
                      trailing: Switch(
                        value: settings.deleteExternalWorkspaceSessions,
                        onChanged: notifier.setDeleteExternalWorkspaceSessions,
                      ),
                    ),
                  ],
                ),
                SettingsGroupHeader(text: g11n.settingsGeneralInput),
                SettingsGroup(
                  children: [
                    SettingsRow(
                      title: g11n.settingsEnterToSend,
                      subtitle: g11n.settingsEnterToSendDesc,
                      trailing: Switch(
                        value: settings.enterToSend,
                        onChanged: notifier.setEnterToSend,
                      ),
                    ),
                  ],
                ),
                SettingsGroupHeader(text: g11n.settingsGeneralNetwork),
                SettingsGroup(
                  children: [
                    SettingsRow(
                      title: g11n.settingsFirstByteTimeout,
                      subtitle: g11n.settingsFirstByteTimeoutDesc,
                      trailing: _trailingValue(
                        context,
                        _timeoutLabel(g11n, settings.firstByteTimeoutSec),
                      ),
                      onTap: () => _editNumber(
                        context,
                        title: g11n.settingsFirstByteTimeout,
                        initialValue: settings.firstByteTimeoutSec,
                        hint: g11n.settingsTimeoutInputHint,
                        onConfirm: notifier.setFirstByteTimeoutSec,
                      ),
                    ),
                    const SettingsDivider(),
                    SettingsRow(
                      title: g11n.settingsStreamIdleTimeout,
                      subtitle: g11n.settingsStreamIdleTimeoutDesc,
                      trailing: _trailingValue(
                        context,
                        _timeoutLabel(g11n, settings.streamIdleTimeoutSec),
                      ),
                      onTap: () => _editNumber(
                        context,
                        title: g11n.settingsStreamIdleTimeout,
                        initialValue: settings.streamIdleTimeoutSec,
                        hint: g11n.settingsTimeoutInputHint,
                        onConfirm: notifier.setStreamIdleTimeoutSec,
                      ),
                    ),
                    const SettingsDivider(),
                    SettingsRow(
                      title: g11n.settingsMaxNetworkRetries,
                      subtitle: g11n.settingsMaxNetworkRetriesDesc,
                      trailing: _trailingValue(
                        context,
                        g11n.settingsRetriesCount(settings.maxNetworkRetries),
                      ),
                      onTap: () => _editNumber(
                        context,
                        title: g11n.settingsMaxNetworkRetries,
                        initialValue: settings.maxNetworkRetries,
                        hint: g11n.settingsRetriesInputHint,
                        onConfirm: notifier.setMaxNetworkRetries,
                      ),
                    ),
                  ],
                ),
                SettingsGroupHeader(text: g11n.settingsGeneralTools),
                SettingsGroup(
                  children: [
                    SettingsRow(
                      title: g11n.settingsSendfileMaxSize,
                      subtitle: g11n.settingsSendfileMaxSizeDesc,
                      trailing: _trailingValue(
                        context,
                        g11n.settingsMbValue(settings.sendFileMaxSizeMb),
                      ),
                      onTap: () => _editNumber(
                        context,
                        title: g11n.settingsSendfileMaxSize,
                        initialValue: settings.sendFileMaxSizeMb,
                        hint: g11n.settingsSendfileMaxSizeInputHint,
                        minValue: 1,
                        onConfirm: notifier.setSendFileMaxSizeMb,
                      ),
                    ),
                  ],
                ),
                SettingsGroupHeader(text: g11n.settingsGeneralGoal),
                SettingsGroup(
                  children: [
                    SettingsRow(
                      title: g11n.settingsGoalMaxTurns,
                      subtitle: g11n.settingsGoalMaxTurnsDesc,
                      trailing: _trailingValue(
                        context,
                        g11n.settingsTurnsValue(settings.goalMaxTurns),
                      ),
                      onTap: () => _editNumber(
                        context,
                        title: g11n.settingsGoalMaxTurns,
                        initialValue: settings.goalMaxTurns,
                        hint: g11n.settingsGoalMaxTurnsInputHint,
                        minValue: 1,
                        onConfirm: notifier.setGoalMaxTurns,
                      ),
                    ),
                    const SettingsDivider(),
                    SettingsRow(
                      title: g11n.settingsGoalMaxTokens,
                      subtitle: g11n.settingsGoalMaxTokensDesc,
                      trailing: _trailingValue(
                        context,
                        g11n.settingsTokensValue(settings.goalMaxTokens),
                      ),
                      onTap: () => _editNumber(
                        context,
                        title: g11n.settingsGoalMaxTokens,
                        initialValue: settings.goalMaxTokens,
                        hint: g11n.settingsGoalMaxTokensInputHint,
                        minValue: 1000,
                        onConfirm: notifier.setGoalMaxTokens,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _trailingValue(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: context.semantic.subtleText),
      );

  /// 超时值的行尾展示:0(或负数)视为不限制。
  String _timeoutLabel(AppGlobalizations g11n, int sec) =>
      sec <= 0 ? g11n.settingsTimeoutUnlimited : g11n.settingsTimeoutSeconds(sec);

  String _startupSessionLabel(AppGlobalizations g11n, StartupSessionMode mode) => switch (mode) {
        StartupSessionMode.newSession => g11n.settingsStartupSessionNew,
        StartupSessionMode.recentSession => g11n.settingsStartupSessionRecent,
      };

  Future<void> _editNumber(
    BuildContext context, {
    required String title,
    required int initialValue,
    required String hint,
    int minValue = 0,
    int maxValue = 1 << 31,
    required Future<void> Function(int) onConfirm,
  }) async {
    final value = await showDialog<int>(
      context: context,
      builder: (context) => _NumberInputDialog(
        title: title,
        initialValue: initialValue,
        hint: hint,
        minValue: minValue,
        maxValue: maxValue,
      ),
    );
    if (value != null) await onConfirm(value);
  }

  /// 启动时会话弹层(对齐上游 StartupSessionSheet):标题 + 两个选项(标题/说明 + 选中勾)。
  Future<void> _pickStartupSession(
    BuildContext context, {
    required StartupSessionMode current,
    required Future<void> Function(StartupSessionMode) onSelect,
  }) async {
    final g11n = AppGlobalizations.of(context);
    final theme = Theme.of(context);
    final selected = await showModalBottomSheet<StartupSessionMode>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.md),
              child: Text(
                g11n.settingsStartupSession,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            for (final mode in StartupSessionMode.values)
              InkWell(
                onTap: () => Navigator.pop(sheetContext, mode),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.lg,
                    vertical: Spacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _startupSessionLabel(g11n, mode),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: mode == current
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              mode == StartupSessionMode.newSession
                                  ? g11n.settingsStartupSessionNewDesc
                                  : g11n.settingsStartupSessionRecentDesc,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (mode == current)
                        Icon(Iconfont.check, size: 20, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: Spacing.xl),
          ],
        ),
      ),
    );
    if (selected != null) await onSelect(selected);
  }
}

/// 数值输入弹窗(对齐上游 NumberInputDialog):只接受非负整数,留空按 0 处理。
class _NumberInputDialog extends StatefulWidget {
  const _NumberInputDialog({
    required this.title,
    required this.initialValue,
    required this.hint,
    required this.minValue,
    required this.maxValue,
  });

  final String title;
  final int initialValue;
  final String hint;
  final int minValue;
  final int maxValue;

  @override
  State<_NumberInputDialog> createState() => _NumberInputDialogState();
}

class _NumberInputDialogState extends State<_NumberInputDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue > 0 ? '${widget.initialValue}' : '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _parsed => int.tryParse(_controller.text.trim());

  /// 留空按 [widget.minValue] 的语义处理:允许 0 的场景(超时/重试)视为不限制,否则视为未填。
  bool get _isValid {
    if (_controller.text.trim().isEmpty) return widget.minValue <= 0;
    final parsed = _parsed;
    return parsed != null && parsed >= widget.minValue && parsed <= widget.maxValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          isDense: true,
          border: const OutlineInputBorder(),
          enabledBorder: _isValid
              ? null
              : OutlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.error)),
          focusedBorder: _isValid
              ? null
              : OutlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.error)),
          helperText: widget.hint,
          helperStyle: _isValid ? null : TextStyle(color: theme.colorScheme.error),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppGlobalizations.of(context).cancel),
        ),
        TextButton(
          onPressed: _isValid ? () => Navigator.pop(context, _parsed ?? 0) : null,
          child: Text(AppGlobalizations.of(context).save),
        ),
      ],
    );
  }
}