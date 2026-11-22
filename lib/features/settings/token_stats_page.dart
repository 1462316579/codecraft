import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/settings_group.dart';
import '../../data/db/llm_call_records.dart';
import '../../data/token_stats.dart';
import '../../g11n/app_globalizations.dart';

/// Token 统计页(对照上游 `SettingsScreen` 的 `SettingsSection.TokenStats` / `TokenStatsSection.kt`):
/// 周期切换 → 汇总卡片 → 消耗趋势 → 供应商/模型统计 → 调用记录表。
class TokenStatsPage extends ConsumerStatefulWidget {
  const TokenStatsPage({super.key});

  @override
  ConsumerState<TokenStatsPage> createState() => _TokenStatsPageState();
}

class _TokenStatsPageState extends ConsumerState<TokenStatsPage> {
  /// 趋势图三条线的颜色(上游 TokenStatsPalette)。
  static const Color inputColor = Color(0xFF3B82F6);
  static const Color outputColor = Color(0xFFF59E0B);
  static const Color cacheColor = Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tokenStatsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final g11n = AppGlobalizations.of(context);
    final state = ref.watch(tokenStatsProvider);
    final controller = ref.read(tokenStatsProvider.notifier);
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(g11n.tokenStatsTitle),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: () => _confirmReset(context, g11n, controller),
            tooltip: g11n.tokenStatsReset,
            icon: const Icon(Iconfont.trash2, size: 20),
          ),
        ],
      ),
      body: Container(
        constraints: BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.light
                ? const [Color(0xFFEDE9FE), Color(0xFFDBEAFE), Color(0xFFFCE7F3)]
                : const [Color(0xFF1E1B4B), Color(0xFF1E3A8A), Color(0xFF4C1D95)],
          ),
        ),
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  Spacing.lg,
                  MediaQuery.of(context).padding.top + kToolbarHeight + Spacing.lg,
                  Spacing.lg,
                  140,
                ),
              children: [
                _periodSelector(context, g11n, state, controller),
                const SizedBox(height: Spacing.md),
                _filterBar(context, g11n, state, controller),
                const SizedBox(height: Spacing.md),
                _summaryCards(context, g11n, state),
                if (state.trend.length > 1) ...[
                  SettingsGroupHeader(text: g11n.tokenStatsTrend),
                  _trendCard(context, g11n, state),
                ],
                SettingsGroupHeader(text: g11n.tokenStatsProvider),
                _providerStats(context, g11n, state, controller),
                SettingsGroupHeader(text: g11n.tokenStatsModel),
                _modelStats(context, g11n, state, controller),
                SettingsGroupHeader(text: g11n.tokenStatsRecentCalls),
                _callsTable(context, g11n, state, controller),
              ],
            ),
        ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    AppGlobalizations g11n,
    TokenStatsController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(g11n.tokenStatsResetTitle),
        content: Text(g11n.tokenStatsResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(g11n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(g11n.confirm),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.reset();
  }

  Widget _periodSelector(
    BuildContext context,
    AppGlobalizations g11n,
    TokenStatsState state,
    TokenStatsController controller,
  ) {
    final labels = {
      TokenStatsPeriod.today: g11n.tokenStatsPeriodToday,
      TokenStatsPeriod.last7Days: g11n.tokenStatsPeriod7d,
      TokenStatsPeriod.last30Days: g11n.tokenStatsPeriod30d,
      TokenStatsPeriod.all: g11n.tokenStatsPeriodAll,
    };
    // 截图实测:四个按钮等宽(各 270px / 间距 28px),对应上游每个 chip 的 weight(1f)。
    // 用自绘胶囊而非 FilterChip:后者的 Material 3 点击区域会把高度压成 48dp 且边框不可控。
    return Row(
      children: [
        for (var index = 0; index < TokenStatsPeriod.values.length; index++) ...[
          Expanded(
            child: _PeriodChip(
              label: labels[TokenStatsPeriod.values[index]]!,
              selected: state.period == TokenStatsPeriod.values[index],
              onTap: () =>
                  controller.selectPeriod(TokenStatsPeriod.values[index]),
            ),
          ),
          if (index != TokenStatsPeriod.values.length - 1)
            const SizedBox(width: Spacing.sm),
        ],
      ],
    );
  }

  Widget _filterBar(
    BuildContext context,
    AppGlobalizations g11n,
    TokenStatsState state,
    TokenStatsController controller,
  ) {
    final hasFilter = state.filterProviderId != null || state.filterModel != null;
    return Row(
      children: [
        Expanded(
          child: _filterChip<String>(
            context,
            selectedValue: state.filterProviderId,
            label: state.filterProviderId == null
                ? g11n.tokenStatsFilterAllProviders
                : g11n.tokenStatsFilterProvider(
                    _providerName(state, state.filterProviderId!) ??
                        state.filterProviderId!),
            options: [
              (null, g11n.tokenStatsFilterAllProviders),
              for (final id in state.availableProviders)
                (id, _providerName(state, id) ?? id),
            ],
            onSelected: controller.selectFilterProvider,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _filterChip<String>(
            context,
            selectedValue: state.filterModel,
            label: state.filterModel == null
                ? g11n.tokenStatsFilterAllModels
                : g11n.tokenStatsFilterModel(state.filterModel!),
            options: [
              (null, g11n.tokenStatsFilterAllModels),
              for (final model in state.availableModels) (model, model),
            ],
            onSelected: controller.selectFilterModel,
          ),
        ),
        if (hasFilter) ...[
          const SizedBox(width: Spacing.xs),
          IconButton(
            onPressed: controller.clearFilters,
            tooltip: g11n.tokenStatsFilterClear,
            icon: const Icon(Iconfont.x, size: 18),
          ),
        ],
      ],
    );
  }

  /// 筛选下拉(对齐上游:FilterChip 触发 + DropdownMenu,选中项带对勾)。
  Widget _filterChip<T>(
    BuildContext context, {
    required T? selectedValue,
    required String label,
    required List<(T?, String)> options,
    required ValueChanged<T?> onSelected,
  }) {
    final theme = Theme.of(context);
    final selected = selectedValue != null;
    // 图片里是白底卡片:圆角 12、高度 44、1px 浅边框,与周期胶囊区分开。
    const radius = Radius.circular(Radii.mdLarge);
    return MenuAnchor(
      builder: (anchorContext, menu, _) => Material(
        color: selected
            ? theme.colorScheme.primaryContainer
            : (theme.brightness == Brightness.light ? Colors.white : context.semantic.cardSurface)
                .withValues(alpha: 0.35),
        borderRadius: const BorderRadius.all(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: menu.open,
          borderRadius: const BorderRadius.all(radius),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(radius),
              border: Border.all(
                color: selected ? theme.colorScheme.primary : context.semantic.subtleBorder,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: selected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Iconfont.chevronDown,
                  size: 16,
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
      menuChildren: [
        for (final (value, text) in options)
          MenuItemButton(
            onPressed: () => onSelected(value),
            trailingIcon: value == selectedValue
                ? const Icon(Iconfont.check, size: 16)
                : null,
            child: Text(text),
          ),
      ],
    );
  }

  String? _providerName(TokenStatsState state, String providerId) {
    for (final item in state.providers) {
      if (item.providerId == providerId) return item.providerName;
    }
    return null;
  }

  Widget _summaryCards(
    BuildContext context,
    AppGlobalizations g11n,
    TokenStatsState state,
  ) {
    final summary = state.summary;
    final hasData = summary.calls > 0;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                context,
                label: g11n.tokenStatsTotal,
                value: hasData ? formatTokenCount(summary.totalTokens) : '-',
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: _summaryCard(
                context,
                label: g11n.tokenStatsRequests,
                value: hasData ? '${summary.calls}' : '-',
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                context,
                label: g11n.tokenStatsCost,
                value: formatCostUsd(state.totalCostUsd),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: _summaryCard(
                context,
                label: g11n.tokenStatsCacheHitRate,
                value: hasData ? _formatCacheHitRate(summary) : '-',
                sub: hasData
                    ? _formatCache(
                        summary.cachedInputTokens,
                        summary.cacheCreationTokens,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 概览缓存命中率(对齐上游 `formatCacheHitRate`):取 1 位小数并 clamp 到 100%。
  String _formatCacheHitRate(CallSummary summary) {
    if (summary.inputTokens <= 0) return '-';
    final rate = (summary.cachedInputTokens * 100.0 / summary.inputTokens).clamp(0, 100);
    return '${rate.toStringAsFixed(1)}%';
  }

  /// 单次调用缓存命中率(对齐上游 `formatRecordCacheHitRate`)。
  String _formatRecordHitRate(LlmCallRecord record) {
    if (record.inputTokens <= 0) return '-';
    final rate =
        (record.cachedInputTokens * 100.0 / record.inputTokens).clamp(0, 100);
    return '${rate.toStringAsFixed(1)}%';
  }

  /// 缓存读写摘要(对齐上游 `formatCache`):两者都为 0 时为空串。
  String _formatCache(int cachedRead, int cachedWrite) =>
      (cachedRead > 0 || cachedWrite > 0)
          ? AppGlobalizations.of(context).tokenStatsCacheReadWrite(
              formatTokenCount(cachedRead),
              formatTokenCount(cachedWrite),
            )
          : '';

  /// 耗时/首字节(对齐上游 `formatDuration`)。
  String _formatDuration(int? millis) {
    if (millis == null) return '-';
    return millis >= 1000
        ? '${(millis / 1000).toStringAsFixed(1)}s'
        : '${millis}ms';
  }

  Widget _summaryCard(
    BuildContext context, {
    required String label,
    required String value,
    String? sub,
  }) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: (theme.brightness == Brightness.light ? Colors.white : context.semantic.cardSurface)
                .withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(
                sub,
                maxLines: 1,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ] else
              // 无副文本时占位,保持四张卡片等高(上游 2 + 16)。
              const SizedBox(height: 18),
          ],
        ),
      ),
    ),
  ),
  );
  }

  /// 趋势区(对齐上游):图在上(高 200dp,上内边距 md),分隔线后是图例行(h-lg / v-10)。
  Widget _trendCard(
    BuildContext context,
    AppGlobalizations g11n,
    TokenStatsState state,
  ) {
    final theme = Theme.of(context);
    return SettingsGroup(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: Spacing.md, right: Spacing.md),
          child: SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _TrendPainter(
                trend: state.trend,
                hourly: state.hourly,
                inputColor: inputColor,
                outputColor: outputColor,
                cacheColor: cacheColor,
                gridColor: theme.dividerColor,
                labelColor: theme.colorScheme.onSurfaceVariant,
                textStyle: const TextStyle(fontSize: 10),
                hourSuffix: g11n.tokenStatsHourSuffix,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SettingsDivider(),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: 10,
          ),
          child: Row(
            children: [
              _legendDot(context, inputColor, g11n.tokenStatsLegendInput),
              const SizedBox(width: Spacing.lg),
              _legendDot(context, outputColor, g11n.tokenStatsLegendOutput),
              const SizedBox(width: Spacing.lg),
              _legendDot(context, cacheColor, g11n.tokenStatsLegendCached),
            ],
          ),
        ),
      ],
    );
  }

  /// 图例点(对齐上游 LegendDot):10dp 圆点 + 6dp 间距 + bodySmall。
  Widget _legendDot(BuildContext context, Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      );

  Widget _providerStats(
    BuildContext context,
    AppGlobalizations g11n,
    TokenStatsState state,
    TokenStatsController controller,
  ) {
    if (state.providers.isEmpty) {
      return SettingsGroup(children: [_emptyPlaceholder(context, g11n)]);
    }
    final page = state.providerPage.clamp(0, state.providerPageCount - 1);
    final start = page * TokenStatsState.statsPageSize;
    final items = state.providers
        .skip(start)
        .take(TokenStatsState.statsPageSize)
        .toList();
    return SettingsGroup(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const SettingsDivider(),
          _providerRow(context, g11n, state, items[index], controller),
        ],
        if (state.providerPageCount > 1) ...[
          const SettingsDivider(),
          _pagination(context, g11n, page, state.providerPageCount,
              controller.selectProviderPage),
        ],
      ],
    );
  }

  /// 供应商统计行(对齐上游 ProviderStatsRow):渠道名 + 调用大字 + 密钥数/成功率 + 成功率细条,点击联动筛选。
  Widget _providerRow(
    BuildContext context,
    AppGlobalizations g11n,
    TokenStatsState state,
    ProviderCallStats stats,
    TokenStatsController controller,
  ) {
    final theme = Theme.of(context);
    final successRate = stats.calls > 0 ? (stats.calls - stats.errors) / stats.calls : 0.0;
    final successColor = successRate >= 0.95
        ? const Color(0xFF2E7D32)
        : const Color(0xFFE65100);
    final selected = state.filterProviderId != null &&
        state.filterProviderId == stats.providerId;
    final keyCount = stats.providerId == null
        ? null
        : state.providerKeyCounts[stats.providerId];
    return InkWell(
      onTap: () => controller.selectFilterProvider(
        selected ? null : stats.providerId,
      ),
      child: Container(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stats.providerName ??
                        stats.providerId ??
                        g11n.tokenStatsUnknown,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatThousands(stats.calls),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      g11n.tokenStatsRequestsUnit,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (keyCount != null) ...[
                  Flexible(
                    child: Text(
                      g11n.tokenStatsProviderKeys(keyCount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                ],
                Text(
                  '${(successRate * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: successColor,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    '↑${formatTokenCount(stats.inputTokens)} ↓${formatTokenCount(stats.outputTokens)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 4,
                child: Stack(
                  children: [
                    Container(color: context.semantic.subtleBorder),
                    FractionallySizedBox(
                      widthFactor: successRate.clamp(0.0, 1.0),
                      child: Container(color: successColor),
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

  /// 千分位(对齐上游 `%,d`)。
  String _formatThousands(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return value < 0 ? '-$buffer' : buffer.toString();
  }

  Widget _modelStats(
    BuildContext context,
    AppGlobalizations g11n,
    TokenStatsState state,
    TokenStatsController controller,
  ) {
    if (state.models.isEmpty) {
      return SettingsGroup(children: [_emptyPlaceholder(context, g11n)]);
    }
    final page = state.modelPage.clamp(0, state.modelPageCount - 1);
    final start = page * TokenStatsState.statsPageSize;
    final items =
        state.models.skip(start).take(TokenStatsState.statsPageSize).toList();
    return SettingsGroup(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const SettingsDivider(),
          _modelRow(context, g11n, state, items[index], controller),
        ],
        if (state.modelPageCount > 1) ...[
          const SettingsDivider(),
          _pagination(context, g11n, page, state.modelPageCount,
              controller.selectModelPage),
        ],
      ],
    );
  }

  Widget _modelRow(
    BuildContext context,
    AppGlobalizations g11n,
    TokenStatsState state,
    ModelCallStats stats,
    TokenStatsController controller,
  ) {
    final theme = Theme.of(context);
    final successRate = stats.calls > 0
        ? '${((stats.calls - stats.errors) * 100.0 / stats.calls).toStringAsFixed(1)}%'
        : '-';
    final selected =
        state.filterModel != null && state.filterModel == stats.model;
    return InkWell(
      onTap: () => controller.selectFilterModel(selected ? null : stats.model),
      child: Container(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stats.model ?? g11n.tokenStatsUnknown,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  '↑${formatTokenCount(stats.inputTokens)} ↓${formatTokenCount(stats.outputTokens)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  g11n.tokenStatsCallsSuffix2(stats.calls),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: Spacing.md),
                Text(
                  g11n.tokenStatsSuccessRate(successRate),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  flex: (stats.inputTokens + 1).clamp(1, 1 << 20),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: inputColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: (stats.outputTokens + 1).clamp(1, 1 << 20),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: outputColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _callsTable(
    BuildContext context,
    AppGlobalizations g11n,
    TokenStatsState state,
    TokenStatsController controller,
  ) {
    if (state.calls.isEmpty) {
      return SettingsGroup(children: [_emptyPlaceholder(context, g11n)]);
    }
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return SettingsGroup(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tableRow(
                context,
                [
                  _cell(g11n.tokenStatsColTime, muted, 120, medium: true),
                  _cell(g11n.tokenStatsColProvider, muted, 100, medium: true),
                  _cell(g11n.tokenStatsColModel, muted, 150, medium: true),
                  _cell(g11n.tokenStatsColReasoningEffort, muted, 72, medium: true),
                  _cell(g11n.tokenStatsColStatus, muted, 70, medium: true),
                  _cell(g11n.tokenStatsColInput, muted, 60, medium: true),
                  _cell(g11n.tokenStatsColOutput, muted, 60, medium: true),
                  _cell(g11n.tokenStatsColCachedRead, muted, 60, medium: true),
                  _cell(g11n.tokenStatsColCachedWrite, muted, 60, medium: true),
                  _cell(g11n.tokenStatsColCacheHitRate, muted, 60, medium: true),
                  _cell(g11n.tokenStatsColTtfb, muted, 62, medium: true),
                  _cell(g11n.tokenStatsColDuration, muted, 62, medium: true),
                  _cell(g11n.tokenStatsColCost, muted, 80, medium: true),
                ],
                vertical: 8,
              ),
              for (final row in state.calls)
                _tableRow(context, _cellsFor(context, g11n, state, row)),
            ],
          ),
        ),
        if (state.callsPageCount > 1) ...[
          const SettingsDivider(),
          _pagination(context, g11n, state.callsPage, state.callsPageCount,
              controller.selectCallsPage),
        ],
      ],
    );
  }

  List<Widget> _cellsFor(
    BuildContext context,
    AppGlobalizations g11n,
    TokenStatsState state,
    LlmCallRecordRow row,
  ) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final text = theme.colorScheme.onSurface;
    final record = row.record;
    // 状态色对齐上游:error #EF4444 / cancelled #94A3B8 / 其余 #22C55E。
    final statusColor = switch (record.status) {
      'error' => const Color(0xFFEF4444),
      'cancelled' => const Color(0xFF94A3B8),
      _ => const Color(0xFF22C55E),
    };
    return [
      _cell(_formatCallTime(record.createdAt), muted, 120),
      _cell(row.providerName ?? record.providerId ?? g11n.tokenStatsUnknown, text, 100),
      _cell(record.model ?? g11n.tokenStatsUnknown, text, 150),
      _cell(record.reasoningEffort ?? '-', muted, 72),
      _cell(record.status, statusColor, 70, medium: true),
      _cell('${record.inputTokens}', text, 60),
      _cell('${record.outputTokens}', text, 60),
      _cell('${record.cachedInputTokens}', text, 60),
      _cell('${record.cacheCreationTokens}', text, 60),
      _cell(_formatRecordHitRate(record), text, 60),
      _cell(_formatDuration(record.ttfbMillis), text, 62),
      _cell(_formatDuration(record.durationMillis), text, 62),
      _cell(formatCostUsd(state.callCosts[record.id]), muted, 80),
    ];
  }

  /// 调用时间(对齐上游 formatCallTime:yyyy/M/d HH:mm)。
  String _formatCallTime(int epochMillis) {
    final time = DateTime.fromMillisecondsSinceEpoch(epochMillis);
    return '${time.year}/${time.month}/${time.day} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _tableRow(
    BuildContext context,
    List<Widget> cells, {
    double vertical = 6,
  }) =>
      Padding(
        padding: EdgeInsets.symmetric(horizontal: Spacing.md, vertical: vertical),
        child: Row(children: cells),
      );

  Widget _cell(String text, Color color, double width, {bool medium = false}) => SizedBox(
        width: width,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: medium ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      );

  Widget _pagination(
    BuildContext context,
    AppGlobalizations g11n,
    int page,
    int pageCount,
    ValueChanged<int> onSelect,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: page > 0 ? () => onSelect(page - 1) : null,
              child: Text(g11n.tokenStatsPrevPage),
            ),
            Text(
              g11n.tokenStatsPage(page + 1, pageCount),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            TextButton(
              onPressed: page < pageCount - 1 ? () => onSelect(page + 1) : null,
              child: Text(g11n.tokenStatsNextPage),
            ),
          ],
        ),
      );

  Widget _emptyPlaceholder(BuildContext context, AppGlobalizations g11n) => SizedBox(
        width: double.infinity,
        height: 72,
        child: Center(
          child: Text(
            g11n.tokenStatsNoData,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
}

/// 周期选择胶囊(对照截图:白底 + 1px 浅边框 + 全圆角,选中为主色填充且无边框)。
class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primary
          : (theme.brightness == Brightness.light ? Colors.white : context.semantic.cardSurface)
              .withValues(alpha: 0.35),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(
              color: selected ? Colors.transparent : context.semantic.subtleBorder,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// 消耗趋势折线图(对照上游 Vico LineCartesianLayer 的视觉规格):
/// 左侧 y 轴按 k/M 缩写、底部 x 轴为「M/d」或「N时」、三条实线 + 18% 半透明面积填充。
class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.trend,
    required this.hourly,
    required this.inputColor,
    required this.outputColor,
    required this.cacheColor,
    required this.gridColor,
    required this.labelColor,
    required this.textStyle,
    required this.hourSuffix,
  });

  final List<CallBucketStats> trend;
  final bool hourly;
  final Color inputColor;
  final Color outputColor;
  final Color cacheColor;
  final Color gridColor;
  final Color labelColor;
  final TextStyle textStyle;
  final String hourSuffix;

  static const double _axisWidth = 34;
  static const double _axisHeight = 18;

  @override
  void paint(Canvas canvas, Size size) {
    if (trend.isEmpty) return;
    final plotWidth = size.width - _axisWidth;
    final plotHeight = size.height - _axisHeight - 4;
    final maxValue = trend.fold<int>(
      1,
      (max, item) => [
        max,
        item.inputTokens,
        item.outputTokens,
        item.cachedInputTokens,
      ].reduce((a, b) => a > b ? a : b),
    );

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (var i = 0; i <= 2; i++) {
      final y = plotHeight * i / 2;
      canvas.drawLine(Offset(_axisWidth, y), Offset(size.width, y), gridPaint);
    }

    // y 轴刻度:k/M 缩写(对齐上游 formatTokenCount)。
    for (var i = 0; i <= 2; i++) {
      final value = (maxValue * (1 - i / 2)).round();
      final painter = TextPainter(
        text: TextSpan(
          text: formatTokenCount(value),
          style: textStyle.copyWith(color: labelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(
          _axisWidth - 4 - painter.width,
          plotHeight * i / 2 - painter.height / 2,
        ),
      );
    }

    double xOf(int index) => trend.length == 1
        ? _axisWidth + plotWidth / 2
        : _axisWidth + plotWidth * index / (trend.length - 1);

    void drawSeries(int Function(CallBucketStats) pick, Color color) {
      final points = [
        for (var i = 0; i < trend.length; i++)
          Offset(xOf(i), plotHeight - plotHeight * (pick(trend[i]) / maxValue)),
      ];
      // 面积填充(上游 areaFill alpha 0.18)。
      final area = Path()..moveTo(points.first.dx, plotHeight);
      for (final point in points) {
        area.lineTo(point.dx, point.dy);
      }
      area.lineTo(points.last.dx, plotHeight);
      area.close();
      canvas.drawPath(area, Paint()..color = color.withValues(alpha: 0.18));

      final line = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        line.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        line,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    drawSeries((item) => item.inputTokens, inputColor);
    drawSeries((item) => item.outputTokens, outputColor);
    drawSeries((item) => item.cachedInputTokens, cacheColor);

    // x 轴标签:点数 <= 10 全部标注,否则抽稀(对齐上游 ItemPlacer 的取舍)。
    final step = trend.length <= 10 ? 1 : (trend.length / 5).ceil();
    for (var index = 0; index < trend.length; index += step) {
      final painter = TextPainter(
        text: TextSpan(
          text: _xLabel(trend[index].bucket),
          style: textStyle.copyWith(color: labelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = (xOf(index) - painter.width / 2)
          .clamp(_axisWidth, size.width - painter.width);
      painter.paint(canvas, Offset(x, plotHeight + 3));
    }
  }

  /// x 轴标签:小时粒度显示「N时」,按天显示「M/d」。
  String _xLabel(int bucket) {
    if (hourly) return '${bucket % 24}$hourSuffix';
    final date = DateTime.fromMillisecondsSinceEpoch(bucket * 86400000);
    return '${date.month}/${date.day}';
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) =>
      oldDelegate.trend != trend ||
      oldDelegate.hourly != hourly ||
      oldDelegate.gridColor != gridColor;
}
