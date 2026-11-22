import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../data/providers/provider_config.dart';
import '../../g11n/app_globalizations.dart';

/// 多 Key 管理页(对齐上游 ProviderKeysPage):候选 Key 列表(掩码预览、权重、删除)、
/// 追加 Key、轮换策略、冷却时长与「命中即切换」状态码。
class ProviderKeysPage extends StatefulWidget {
  const ProviderKeysPage({super.key, required this.initial});

  final ProviderConfig initial;

  @override
  State<ProviderKeysPage> createState() => _ProviderKeysPageState();
}

class _ProviderKeysPageState extends State<ProviderKeysPage> {
  late final List<ProviderKey> _keys = [
    for (final key in widget.initial.effectiveApiKeys) ProviderKey(key.value, weight: key.weight),
  ];
  late final List<TextEditingController> _keyInputs = [
    for (final key in _keys) TextEditingController(text: key.value),
  ];
  late KeyRotationStrategy _strategy = widget.initial.keyRotationStrategy;
  late int _cooldown = widget.initial.keyCooldownMinutes;
  late final TextEditingController _codes = TextEditingController(
    text: widget.initial.keySwitchStatusCodes.isEmpty
        ? ''
        : widget.initial.keySwitchStatusCodes.join(', '),
  );

  @override
  void dispose() {
    _codes.dispose();
    for (final controller in _keyInputs) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(g11n.providerMultiKeyManage),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              widget.initial.copyWith(
                apiKeys: _keys,
                keyRotationStrategy: _strategy,
                keyCooldownMinutes: _cooldown,
                keySwitchStatusCodes: _parseCodes(),
              ),
            ),
            child: Text(g11n.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.xxl),
        children: [
          SettingsGroupHeader(text: g11n.providerMultiKeyList),
          SettingsGroup(
            children: [
              for (var index = 0; index < _keys.length; index++) ...[
                if (index > 0) const SettingsDivider(),
                _keyRow(context, g11n, index),
              ],
            ],
          ),
          const SizedBox(height: Spacing.sm),
          TextButton.icon(
            onPressed: () => setState(() {
              _keys.add(const ProviderKey(''));
              _keyInputs.add(TextEditingController());
            }),
            icon: const Icon(Icons.add, size: 18),
            label: Text(g11n.providerMultiKeyAdd),
          ),
          SettingsGroupHeader(text: g11n.providerMultiKeyStrategy),
          SettingsGroup(
            children: [
              SettingsRow(
                title: g11n.providerMultiKeyStrategy,
                subtitle: g11n.providerMultiKeyWeightHint,
                trailing: Text(
                  _strategy == KeyRotationStrategy.sequential
                      ? g11n.providerMultiKeyStrategySequential
                      : g11n.providerMultiKeyStrategyRoundRobin,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                onTap: _pickStrategy,
              ),
              const SettingsDivider(),
              _stepperRow(
                context,
                g11n.providerMultiKeyCooldown,
                _cooldown,
                (value) => setState(() => _cooldown = value.clamp(0, 1440)),
                suffix: ' 分钟',
              ),
              const SettingsDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g11n.providerMultiKeyStatusCodes,
                        style: Theme.of(context).textTheme.bodyLarge),
                    Text(
                      g11n.providerMultiKeyStatusCodesHint,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: context.semantic.subtleText),
                    ),
                    const SizedBox(height: Spacing.sm),
                    TextField(
                      controller: _codes,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: defaultKeySwitchStatusCodes.join(', '),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<int> _parseCodes() => [
        for (final part in _codes.text.split(RegExp(r'[^0-9]+')))
          if (int.tryParse(part) != null) int.parse(part),
      ];

  Widget _keyRow(BuildContext context, AppGlobalizations g11n, int index) {
    final theme = Theme.of(context);
    final key = _keys[index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm),
      child: Row(
        children: [
          Icon(Iconfont.key, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: TextField(
              controller: _keyInputs[index],
              obscureText: true,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'sk-…',
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (value) => _keys[index] = ProviderKey(value, weight: key.weight),
            ),
          ),
          // 权重步进器(对齐上游 StepperRow)
          IconButton(
            onPressed: key.weight <= 0
                ? null
                : () => setState(
                    () => _keys[index] = ProviderKey(key.value, weight: key.weight - 1)),
            iconSize: 18,
            icon: const Icon(Iconfont.minus),
          ),
          Text(
            '${key.weight}',
            style: theme.textTheme.labelLarge?.copyWith(color: context.semantic.subtleText),
          ),
          IconButton(
            onPressed: () => setState(
                () => _keys[index] = ProviderKey(key.value, weight: key.weight + 1)),
            iconSize: 18,
            icon: const Icon(Iconfont.plus),
          ),
          IconButton(
            tooltip: g11n.delete,
            onPressed: () => setState(() {
              _keys.removeAt(index);
              _keyInputs.removeAt(index).dispose();
            }),
            iconSize: 18,
            color: theme.colorScheme.error,
            icon: const Icon(Iconfont.trash2),
          ),
        ],
      ),
    );
  }

  Widget _stepperRow(
    BuildContext context,
    String title,
    int value,
    ValueChanged<int> onChanged, {
    String suffix = '',
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
          IconButton(
            onPressed: value <= 0 ? null : () => onChanged(value - 1),
            iconSize: 18,
            icon: const Icon(Iconfont.minus),
          ),
          Text('$value$suffix',
              style: theme.textTheme.labelLarge?.copyWith(color: context.semantic.subtleText)),
          IconButton(
            onPressed: () => onChanged(value + 1),
            iconSize: 18,
            icon: const Icon(Iconfont.plus),
          ),
        ],
      ),
    );
  }

  Future<void> _pickStrategy() async {
    final g11n = AppGlobalizations.of(context);
    final selected = await showModalBottomSheet<KeyRotationStrategy>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(g11n.providerMultiKeyStrategySequential),
              subtitle: Text(g11n.providerMultiKeyStrategySequentialDesc),
              trailing: _strategy == KeyRotationStrategy.sequential
                  ? const Icon(Icons.check, size: 20)
                  : null,
              onTap: () => Navigator.pop(sheetContext, KeyRotationStrategy.sequential),
            ),
            ListTile(
              title: Text(g11n.providerMultiKeyStrategyRoundRobin),
              subtitle: Text(g11n.providerMultiKeyStrategyRoundRobinDesc),
              trailing: _strategy == KeyRotationStrategy.roundRobin
                  ? const Icon(Icons.check, size: 20)
                  : null,
              onTap: () => Navigator.pop(sheetContext, KeyRotationStrategy.roundRobin),
            ),
            const SizedBox(height: Spacing.xl),
          ],
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _strategy = selected);
  }
}
