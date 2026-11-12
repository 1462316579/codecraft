import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/models/model_metadata.dart';
import 'db/app_database.dart';
import 'db/daos.dart';
import 'db/llm_call_records.dart';
import 'model_catalog.dart';
import 'model_metadata_store.dart';

/// 统计周期(对齐上游 `TokenStatsPeriod`):今天从本地 0 点起算,全部为起点 0。
enum TokenStatsPeriod {
  today,
  last7Days,
  last30Days,
  all;

  int startMillis(DateTime now) => switch (this) {
        TokenStatsPeriod.today =>
          DateTime(now.year, now.month, now.day).millisecondsSinceEpoch,
        TokenStatsPeriod.last7Days => now.millisecondsSinceEpoch - 7 * 86400000,
        TokenStatsPeriod.last30Days => now.millisecondsSinceEpoch - 30 * 86400000,
        TokenStatsPeriod.all => 0,
      };
}

/// 费用估算(逐字对齐上游 `ModelCostCalculator`)。
class ModelCostCalculator {
  /// 缓存读价缺失时按输入价的折扣估算。
  static const double cacheReadDiscount = 0.1;

  /// 缓存写入单价缺失时相对输入价的倍率(Anthropic 官方为 1.25×)。
  static const double cacheWriteMarkup = 1.25;

  const ModelCostCalculator();

  /// 单价来自渠道自定义元数据;缺输入价时返回 null(界面显示「—」)。
  double? costUsd(
    ModelMetadata? meta, {
    required int inputTokens,
    required int cachedInputTokens,
    required int outputTokens,
    required int cacheCreationTokens,
  }) {
    final inputPrice = meta?.inputCostUsdPerM;
    if (inputPrice == null) return null;
    final outputPrice = meta?.outputCostUsdPerM ?? 0;
    final cachePrice = meta?.cacheReadCostUsdPerM ?? inputPrice * cacheReadDiscount;
    final cacheWritePrice =
        meta?.cacheWriteCostUsdPerM ?? inputPrice * cacheWriteMarkup;
    final uncached =
        (inputTokens - cachedInputTokens - cacheCreationTokens).clamp(0, 1 << 62);
    return (uncached * inputPrice +
            cachedInputTokens * cachePrice +
            cacheCreationTokens * cacheWritePrice +
            outputTokens * outputPrice) /
        1000000.0;
  }
}

/// Token 统计页状态(对齐上游 `TokenStatsUiState` 的展示所需子集)。
class TokenStatsState {
  const TokenStatsState({
    this.period = TokenStatsPeriod.last7Days,
    this.filterProviderId,
    this.filterModel,
    this.loading = true,
    this.summary = CallSummary.empty,
    this.totalCostUsd = 0,
    this.trend = const [],
    this.hourly = false,
    this.providers = const [],
    this.providerPage = 0,
    this.models = const [],
    this.modelPage = 0,
    this.calls = const [],
    this.callCosts = const {},
    this.callsPage = 0,
    this.callsTotal = 0,
    this.availableProviders = const [],
    this.availableModels = const [],
    this.providerKeyCounts = const {},
  });

  final TokenStatsPeriod period;
  final String? filterProviderId;
  final String? filterModel;
  final bool loading;
  final CallSummary summary;

  /// 周期内总费用(对齐上游 TokenStatsUiState.totalCostUsd 默认 0.0,无数据时显示 $0.00)。
  final double? totalCostUsd;
  final List<CallBucketStats> trend;

  /// 「今天」周期用小时粒度。
  final bool hourly;
  final List<ProviderCallStats> providers;
  final int providerPage;
  final List<ModelCallStats> models;
  final int modelPage;
  final List<LlmCallRecordRow> calls;
  final Map<int, double?> callCosts;
  final int callsPage;
  final int callsTotal;
  final List<String> availableProviders;
  final List<String> availableModels;

  /// 渠道 → 密钥数量(供应商统计行展示「N 个密钥」)。
  final Map<String, int> providerKeyCounts;

  /// 缓存命中率 = 缓存读 / 输入(输入为 0 时为 0)。
  double get cacheHitRate =>
      summary.inputTokens == 0 ? 0 : summary.cachedInputTokens / summary.inputTokens;

  static const int statsPageSize = 5;
  static const int callsPageSize = 10;

  int get providerPageCount =>
      providers.isEmpty ? 1 : ((providers.length + statsPageSize - 1) ~/ statsPageSize);

  int get modelPageCount =>
      models.isEmpty ? 1 : ((models.length + statsPageSize - 1) ~/ statsPageSize);

  int get callsPageCount =>
      callsTotal == 0 ? 1 : ((callsTotal + callsPageSize - 1) ~/ callsPageSize);

  TokenStatsState copyWith({
    TokenStatsPeriod? period,
    String? filterProviderId,
    bool clearFilterProvider = false,
    String? filterModel,
    bool clearFilterModel = false,
    bool? loading,
    CallSummary? summary,
    double? totalCostUsd,
    bool clearTotalCost = false,
    List<CallBucketStats>? trend,
    bool? hourly,
    List<ProviderCallStats>? providers,
    int? providerPage,
    List<ModelCallStats>? models,
    int? modelPage,
    List<LlmCallRecordRow>? calls,
    Map<int, double?>? callCosts,
    int? callsPage,
    int? callsTotal,
    List<String>? availableProviders,
    List<String>? availableModels,
    Map<String, int>? providerKeyCounts,
  }) =>
      TokenStatsState(
        period: period ?? this.period,
        filterProviderId:
            clearFilterProvider ? null : (filterProviderId ?? this.filterProviderId),
        filterModel: clearFilterModel ? null : (filterModel ?? this.filterModel),
        loading: loading ?? this.loading,
        summary: summary ?? this.summary,
        totalCostUsd: clearTotalCost ? null : (totalCostUsd ?? this.totalCostUsd),
        trend: trend ?? this.trend,
        hourly: hourly ?? this.hourly,
        providers: providers ?? this.providers,
        providerPage: providerPage ?? this.providerPage,
        models: models ?? this.models,
        modelPage: modelPage ?? this.modelPage,
        calls: calls ?? this.calls,
        callCosts: callCosts ?? this.callCosts,
        callsPage: callsPage ?? this.callsPage,
        callsTotal: callsTotal ?? this.callsTotal,
        availableProviders: availableProviders ?? this.availableProviders,
        availableModels: availableModels ?? this.availableModels,
        providerKeyCounts: providerKeyCounts ?? this.providerKeyCounts,
      );
}

/// 统计页控制器:按周期/筛选拉取汇总、趋势、渠道/模型分组与调用明细。
class TokenStatsController extends Notifier<TokenStatsState> {
  final ModelCostCalculator _calculator = const ModelCostCalculator();

  @override
  TokenStatsState build() => const TokenStatsState();

  int get _tzOffsetMillis => DateTime.now().timeZoneOffset.inMilliseconds;

  Future<void> selectPeriod(TokenStatsPeriod period) async {
    state = state.copyWith(period: period, callsPage: 0);
    await load();
  }

  Future<void> selectFilterProvider(String? providerId) async {
    state = providerId == null
        ? state.copyWith(clearFilterProvider: true, callsPage: 0)
        : state.copyWith(filterProviderId: providerId, callsPage: 0);
    await load();
  }

  Future<void> selectFilterModel(String? model) async {
    state = model == null
        ? state.copyWith(clearFilterModel: true, callsPage: 0)
        : state.copyWith(filterModel: model, callsPage: 0);
    await load();
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      clearFilterProvider: true,
      clearFilterModel: true,
      callsPage: 0,
    );
    await load();
  }

  Future<void> selectCallsPage(int page) async {
    state = state.copyWith(callsPage: page);
    await _loadCalls();
  }

  Future<void> selectProviderPage(int page) async {
    state = state.copyWith(providerPage: page);
  }

  Future<void> selectModelPage(int page) async {
    state = state.copyWith(modelPage: page);
  }

  /// 重置:清空全部调用记录(对齐上游 settings_token_stats_reset)。
  Future<void> reset() async {
    await ref.read(databaseProvider).llmCallDao.deleteAll();
    await load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true);
    try {
      await _loadAll();
    } catch (_) {
      // 查询异常不能把页面永远卡在加载中。
      state = state.copyWith(loading: false);
    }
  }

  Future<void> _loadAll() async {
    final dao = ref.read(databaseProvider).llmCallDao;
    final now = DateTime.now();
    final start = state.period.startMillis(now);
    final providerId = state.filterProviderId;
    final model = state.filterModel;
    final hourly = state.period == TokenStatsPeriod.today;

    final trend = hourly
        ? await dao.hourStats(
            start: start,
            tzOffsetMillis: _tzOffsetMillis,
            providerId: providerId,
            model: model,
          )
        : await dao.dayStats(
            start: start,
            tzOffsetMillis: _tzOffsetMillis,
            providerId: providerId,
            model: model,
          );
    final summary = await dao.summary(start: start, providerId: providerId, model: model);
    final providers =
        await dao.providerStats(start: start, providerId: providerId, model: model);
    final models = await dao.modelStats(start: start, providerId: providerId, model: model);
    final keyCounts = {
      for (final config in await ref.read(databaseProvider).providerDao.list())
        config.id: config.effectiveApiKeys.length,
    };

    final custom = await _loadCustomMetadata();
    final catalog = await _loadCatalog();
    final costGroups = await dao.providerModelCostStats(
      start: start,
      providerId: providerId,
      model: model,
    );
    final totalCost = costGroups.fold<double>(
      0,
      (sum, group) =>
          sum +
          (_calculator.costUsd(
                _metadataFor(group.providerId, group.model, custom, catalog),
                inputTokens: group.inputTokens,
                cachedInputTokens: group.cachedInputTokens,
                outputTokens: group.outputTokens,
                cacheCreationTokens: group.cacheCreationTokens,
              ) ??
              0),
    );
    final callsTotal = await dao.callsCount(start: start, providerId: providerId, model: model);

    state = state.copyWith(
      loading: false,
      trend: trend,
      hourly: hourly,
      summary: summary,
      totalCostUsd: totalCost,
      providers: providers,
      models: models,
      callsTotal: callsTotal,
      availableProviders: {
        for (final item in providers)
          if (item.providerId != null) item.providerId!,
      }.toList(),
      availableModels: {
        for (final item in models)
          if (item.model != null) item.model!,
      }.toList(),
      providerKeyCounts: keyCounts,
      providerPage: 0,
      modelPage: 0,
    );
    await _loadCalls();
  }

  Future<void> _loadCalls() async {
    final dao = ref.read(databaseProvider).llmCallDao;
    final start = state.period.startMillis(DateTime.now());
    final rows = await dao.recent(
      start: start,
      offset: state.callsPage * TokenStatsState.callsPageSize,
      limit: TokenStatsState.callsPageSize,
      providerId: state.filterProviderId,
      model: state.filterModel,
    );
    final custom = await _loadCustomMetadata();
    final catalog = await _loadCatalog();
    state = state.copyWith(
      calls: rows,
      callCosts: {
        for (final row in rows)
          row.record.id: _costOfRecord(row.record, custom, catalog),
      },
    );
  }

  /// 自定义模型元数据:读取失败时退化为空表(只是费用显示为—,不能因此让整页无数据)。
  Future<Map<String, ModelMetadata>> _loadCustomMetadata() async {
    try {
      return await ref.read(customModelMetadataProvider.future);
    } catch (_) {
      return const {};
    }
  }

  /// 内置模型目录(models.dev 快照,含价格);加载失败退化为空目录。
  Future<ModelCatalog> _loadCatalog() async {
    try {
      return await ref.read(modelCatalogProvider.future);
    } catch (_) {
      return ModelCatalog.empty;
    }
  }

  /// 元数据查找:自定义优先,其次内置目录。
  ///
  /// 只看自定义的话,用户没手工填价格时费用永远是「—」——这正是统计页不显示费用的原因。
  ModelMetadata? _metadataFor(
    String? providerId,
    String? model,
    Map<String, ModelMetadata> custom,
    ModelCatalog catalog,
  ) {
    if (model == null) return null;
    return resolveModelMetadata(
      catalog,
      custom,
      providerId: providerId,
      model: model,
    );
  }

  double? _costOfRecord(
    LlmCallRecord record,
    Map<String, ModelMetadata> custom,
    ModelCatalog catalog,
  ) =>
      _calculator.costUsd(
        _metadataFor(record.providerId, record.model, custom, catalog),
        inputTokens: record.inputTokens,
        cachedInputTokens: record.cachedInputTokens,
        outputTokens: record.outputTokens,
        cacheCreationTokens: record.cacheCreationTokens,
      );
}

final tokenStatsProvider =
    NotifierProvider<TokenStatsController, TokenStatsState>(TokenStatsController.new);

/// Token 数格式化(对齐上游 `formatTokenCount`)。
String formatTokenCount(int tokens) {
  if (tokens >= 1000000000) return '${(tokens / 1000000000).toStringAsFixed(1)}B';
  if (tokens >= 1000000) return '${(tokens / 1000000).toStringAsFixed(1)}M';
  if (tokens >= 1000) return '${(tokens / 1000).toStringAsFixed(1)}k';
  return '$tokens';
}

/// 费用格式化(对齐上游 `formatCostUsd`)。
String formatCostUsd(double? cost) {
  if (cost == null) return '—';
  if (cost <= 0) return '\$0.00';
  if (cost < 0.0001) return '<\$0.0001';
  if (cost < 0.01) return '\$${cost.toStringAsFixed(4)}';
  return '\$${cost.toStringAsFixed(2)}';
}