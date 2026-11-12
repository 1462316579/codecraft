import 'package:sqflite/sqflite.dart';

/// 单次 LLM 调用记录(对齐上游 `LlmCallRecordEntity`):Token 统计页的数据源。
/// 由对话主循环与上下文压缩链路埋点写入,覆盖渠道、模型、输入/输出/缓存 tokens、
/// 首字延迟、耗时、成败与重试次数。
class LlmCallRecord {
  const LlmCallRecord({
    this.id = 0,
    this.sessionId,
    this.providerId,
    this.model,
    this.reasoningEffort,
    this.kind = 'chat',
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.cachedInputTokens = 0,
    this.cacheCreationTokens = 0,
    this.ttfbMillis,
    this.durationMillis,
    this.status = 'success',
    this.errorMessage,
    this.stopReason,
    this.retryCount = 0,
    required this.createdAt,
  });

  final int id;
  final String? sessionId;
  final String? providerId;
  final String? model;
  final String? reasoningEffort;

  /// 调用类型:chat(普通对话)/ compaction(上下文压缩)。
  final String kind;
  final int inputTokens;
  final int outputTokens;

  /// 输入中命中服务端缓存的部分。
  final int cachedInputTokens;

  /// 写入服务端缓存的 token 数。
  final int cacheCreationTokens;

  /// 首字延迟(毫秒):流式首个文本块到达 - 请求发出;非流式或失败为 null。
  final int? ttfbMillis;
  final int? durationMillis;

  /// success / error。
  final String status;
  final String? errorMessage;
  final String? stopReason;

  /// 本次交互底层网络重试次数。
  final int retryCount;
  final int createdAt;

  Map<String, Object?> toMap() => {
        if (id > 0) 'id': id,
        'sessionId': sessionId,
        'providerId': providerId,
        'model': model,
        'reasoningEffort': reasoningEffort,
        'kind': kind,
        'inputTokens': inputTokens,
        'outputTokens': outputTokens,
        'cachedInputTokens': cachedInputTokens,
        'cacheCreationTokens': cacheCreationTokens,
        'ttfbMillis': ttfbMillis,
        'durationMillis': durationMillis,
        'status': status,
        'errorMessage': errorMessage,
        'stopReason': stopReason,
        'retryCount': retryCount,
        'createdAt': createdAt,
      };
}

/// 按时间桶(天/小时)聚合的一行(对齐上游 `DayCallStats`)。
class CallBucketStats {
  const CallBucketStats({
    required this.bucket,
    required this.inputTokens,
    required this.outputTokens,
    required this.cachedInputTokens,
    required this.calls,
    required this.errors,
    this.avgTtfbMillis,
    this.avgDurationMillis,
    required this.retryCount,
  });

  /// 桶号:按天聚合为「本地日序号」,按小时聚合为「本地小时序号」。
  final int bucket;
  final int inputTokens;
  final int outputTokens;
  final int cachedInputTokens;
  final int calls;
  final int errors;
  final double? avgTtfbMillis;
  final double? avgDurationMillis;
  final int retryCount;

  int get totalTokens => inputTokens + outputTokens;
}

/// 按渠道聚合的一行(对齐上游 `ProviderCallStats`)。
class ProviderCallStats {
  const ProviderCallStats({
    this.providerId,
    this.providerName,
    required this.calls,
    required this.inputTokens,
    required this.outputTokens,
    required this.cachedInputTokens,
    required this.errors,
    required this.retryCount,
  });

  final String? providerId;
  final String? providerName;
  final int calls;
  final int inputTokens;
  final int outputTokens;
  final int cachedInputTokens;
  final int errors;
  final int retryCount;

  int get totalTokens => inputTokens + outputTokens;
}

/// 按模型聚合的一行(对齐上游 `ModelProviderCostStats` 的模型维度)。
class ModelCallStats {
  const ModelCallStats({
    this.model,
    required this.calls,
    required this.inputTokens,
    required this.outputTokens,
    required this.cachedInputTokens,
    required this.cacheCreationTokens,
    this.avgTtfbMillis,
    this.avgDurationMillis,
    required this.errors,
    required this.retryCount,
  });

  final String? model;
  final int calls;
  final int inputTokens;
  final int outputTokens;
  final int cachedInputTokens;
  final int cacheCreationTokens;
  final double? avgTtfbMillis;
  final double? avgDurationMillis;
  final int errors;
  final int retryCount;

  int get totalTokens => inputTokens + outputTokens;
}

/// 按渠道+模型聚合的 token 总量(对齐上游 `ModelProviderCostStats`):费用估算的输入。
class ProviderModelCostStats {
  const ProviderModelCostStats({
    this.providerId,
    this.model,
    required this.inputTokens,
    required this.cachedInputTokens,
    required this.outputTokens,
    required this.cacheCreationTokens,
  });

  final String? providerId;
  final String? model;
  final int inputTokens;
  final int cachedInputTokens;
  final int outputTokens;
  final int cacheCreationTokens;
}

/// 周期整体汇总(对齐上游 `CallSummary`,恒一行)。
class CallSummary {
  const CallSummary({
    required this.calls,
    required this.inputTokens,
    required this.outputTokens,
    required this.cachedInputTokens,
    required this.cacheCreationTokens,
    required this.errors,
    this.avgTtfbMillis,
    this.avgDurationMillis,
    required this.retryCount,
  });

  final int calls;
  final int inputTokens;
  final int outputTokens;
  final int cachedInputTokens;
  final int cacheCreationTokens;
  final int errors;
  final double? avgTtfbMillis;
  final double? avgDurationMillis;
  final int retryCount;

  int get totalTokens => inputTokens + outputTokens;

  static const empty = CallSummary(
    calls: 0,
    inputTokens: 0,
    outputTokens: 0,
    cachedInputTokens: 0,
    cacheCreationTokens: 0,
    errors: 0,
    retryCount: 0,
  );
}

/// 调用明细行(记录 + LEFT JOIN 到的渠道名)。
class LlmCallRecordRow {
  const LlmCallRecordRow({required this.record, this.providerName});

  final LlmCallRecord record;
  final String? providerName;
}

/// LLM 调用记录仓库(对齐上游 `LlmCallRecordDao`)。
class LlmCallRecordDao {
  LlmCallRecordDao(this._db);

  final Database _db;

  static const String _table = 'llm_call_records';

  Future<int> insert(LlmCallRecord record) => _db.insert(_table, record.toMap());

  Future<void> deleteAll() => _db.delete(_table);

  /// 渠道/模型过滤片段:两者都为 null 时不过滤(对齐上游 `(:x IS NULL OR ...)`)。
  static String _filter(String alias) {
    final prefix = alias.isEmpty ? '' : '$alias.';
    return ' AND (? IS NULL OR ${prefix}providerId = ?)'
        ' AND (? IS NULL OR ${prefix}model = ?)';
  }

  static List<Object?> _filterArgs(String? providerId, String? model) =>
      [providerId, providerId, model, model];

  String _bucketQuery(String divisor, {required String alias}) {
    final prefix = alias.isEmpty ? '' : '$alias.';
    return '''
SELECT (${prefix}createdAt + ?) / $divisor AS bucket,
       SUM(${prefix}inputTokens) AS inputTokens,
       SUM(${prefix}outputTokens) AS outputTokens,
       SUM(${prefix}cachedInputTokens) AS cachedInputTokens,
       COUNT(*) AS calls,
       SUM(CASE WHEN ${prefix}status = 'error' THEN 1 ELSE 0 END) AS errors,
       AVG(${prefix}ttfbMillis) AS avgTtfbMillis,
       AVG(${prefix}durationMillis) AS avgDurationMillis,
       SUM(${prefix}retryCount) AS retryCount
FROM $_table
WHERE ${prefix}createdAt >= ?${_filter(alias)}
GROUP BY bucket
ORDER BY bucket ASC''';
  }

  /// 按天聚合(本地时区:把 createdAt 平移 tzOffsetMillis 后按 86400000 取整切天)。
  Future<List<CallBucketStats>> dayStats({
    required int start,
    required int tzOffsetMillis,
    String? providerId,
    String? model,
  }) =>
      _bucket(
        _bucketQuery('86400000', alias: ''),
        [tzOffsetMillis, start, ..._filterArgs(providerId, model)],
      );

  /// 按小时聚合(「今天」周期用小时粒度展示趋势)。
  Future<List<CallBucketStats>> hourStats({
    required int start,
    required int tzOffsetMillis,
    String? providerId,
    String? model,
  }) =>
      _bucket(
        _bucketQuery('3600000', alias: ''),
        [tzOffsetMillis, start, ..._filterArgs(providerId, model)],
      );

  Future<List<CallBucketStats>> _bucket(String sql, List<Object?> args) async {
    final rows = await _db.rawQuery(sql, args);
    return rows.map((row) => CallBucketStats(
          bucket: (row['bucket'] as num?)?.toInt() ?? 0,
          inputTokens: (row['inputTokens'] as num?)?.toInt() ?? 0,
          outputTokens: (row['outputTokens'] as num?)?.toInt() ?? 0,
          cachedInputTokens: (row['cachedInputTokens'] as num?)?.toInt() ?? 0,
          calls: (row['calls'] as num?)?.toInt() ?? 0,
          errors: (row['errors'] as num?)?.toInt() ?? 0,
          avgTtfbMillis: (row['avgTtfbMillis'] as num?)?.toDouble(),
          avgDurationMillis: (row['avgDurationMillis'] as num?)?.toDouble(),
          retryCount: (row['retryCount'] as num?)?.toInt() ?? 0,
        )).toList();
  }

  /// 按渠道聚合,LEFT JOIN providers 取渠道名(渠道被删后记录仍显示)。
  /// 本仓库的 providers 表只存 (id, json),渠道名用 json_extract 从配置 JSON 取。
  Future<List<ProviderCallStats>> providerStats({
    required int start,
    String? providerId,
    String? model,
  }) async {
    final rows = await _db.rawQuery('''
SELECT r.providerId AS providerId,
       json_extract(p.json, '\$.name') AS providerName,
       COUNT(*) AS calls,
       SUM(r.inputTokens) AS inputTokens,
       SUM(r.outputTokens) AS outputTokens,
       SUM(r.cachedInputTokens) AS cachedInputTokens,
       SUM(CASE WHEN r.status = 'error' THEN 1 ELSE 0 END) AS errors,
       SUM(r.retryCount) AS retryCount
FROM $_table r
LEFT JOIN providers p ON p.id = r.providerId
WHERE r.createdAt >= ?${_filter('r')}
GROUP BY r.providerId
ORDER BY (SUM(r.inputTokens) + SUM(r.outputTokens)) DESC''',
        [start, ..._filterArgs(providerId, model)]);
    return rows.map((row) => ProviderCallStats(
          providerId: row['providerId'] as String?,
          providerName: row['providerName'] as String?,
          calls: (row['calls'] as num?)?.toInt() ?? 0,
          inputTokens: (row['inputTokens'] as num?)?.toInt() ?? 0,
          outputTokens: (row['outputTokens'] as num?)?.toInt() ?? 0,
          cachedInputTokens: (row['cachedInputTokens'] as num?)?.toInt() ?? 0,
          errors: (row['errors'] as num?)?.toInt() ?? 0,
          retryCount: (row['retryCount'] as num?)?.toInt() ?? 0,
        )).toList();
  }

  /// 按模型聚合。
  Future<List<ModelCallStats>> modelStats({
    required int start,
    String? providerId,
    String? model,
  }) async {
    final rows = await _db.rawQuery('''
SELECT r.model AS model,
       COUNT(*) AS calls,
       SUM(r.inputTokens) AS inputTokens,
       SUM(r.outputTokens) AS outputTokens,
       SUM(r.cachedInputTokens) AS cachedInputTokens,
       SUM(r.cacheCreationTokens) AS cacheCreationTokens,
       AVG(r.ttfbMillis) AS avgTtfbMillis,
       AVG(r.durationMillis) AS avgDurationMillis,
       SUM(CASE WHEN r.status = 'error' THEN 1 ELSE 0 END) AS errors,
       SUM(r.retryCount) AS retryCount
FROM $_table r
WHERE r.createdAt >= ?${_filter('r')}
GROUP BY r.model
ORDER BY (SUM(r.inputTokens) + SUM(r.outputTokens)) DESC''',
        [start, ..._filterArgs(providerId, model)]);
    return rows.map((row) => ModelCallStats(
          model: row['model'] as String?,
          calls: (row['calls'] as num?)?.toInt() ?? 0,
          inputTokens: (row['inputTokens'] as num?)?.toInt() ?? 0,
          outputTokens: (row['outputTokens'] as num?)?.toInt() ?? 0,
          cachedInputTokens: (row['cachedInputTokens'] as num?)?.toInt() ?? 0,
          cacheCreationTokens: (row['cacheCreationTokens'] as num?)?.toInt() ?? 0,
          avgTtfbMillis: (row['avgTtfbMillis'] as num?)?.toDouble(),
          avgDurationMillis: (row['avgDurationMillis'] as num?)?.toDouble(),
          errors: (row['errors'] as num?)?.toInt() ?? 0,
          retryCount: (row['retryCount'] as num?)?.toInt() ?? 0,
        )).toList();
  }

  /// 按渠道+模型聚合的 token 总量(供逐组费用估算后再求和)。
  Future<List<ProviderModelCostStats>> providerModelCostStats({
    required int start,
    String? providerId,
    String? model,
  }) async {
    final rows = await _db.rawQuery('''
SELECT r.providerId AS providerId,
       r.model AS model,
       SUM(r.inputTokens) AS inputTokens,
       SUM(r.cachedInputTokens) AS cachedInputTokens,
       SUM(r.outputTokens) AS outputTokens,
       SUM(r.cacheCreationTokens) AS cacheCreationTokens
FROM $_table r
WHERE r.createdAt >= ?${_filter('r')}
GROUP BY r.providerId, r.model''',
        [start, ..._filterArgs(providerId, model)]);
    return rows
        .map((row) => ProviderModelCostStats(
              providerId: row['providerId'] as String?,
              model: row['model'] as String?,
              inputTokens: (row['inputTokens'] as num?)?.toInt() ?? 0,
              cachedInputTokens: (row['cachedInputTokens'] as num?)?.toInt() ?? 0,
              outputTokens: (row['outputTokens'] as num?)?.toInt() ?? 0,
              cacheCreationTokens: (row['cacheCreationTokens'] as num?)?.toInt() ?? 0,
            ))
        .toList();
  }

  /// 周期整体汇总(恒一行;无记录时返回零值)。
  Future<CallSummary> summary({
    required int start,
    String? providerId,
    String? model,
  }) async {
    final rows = await _db.rawQuery('''
SELECT COUNT(*) AS calls,
       SUM(inputTokens) AS inputTokens,
       SUM(outputTokens) AS outputTokens,
       SUM(cachedInputTokens) AS cachedInputTokens,
       SUM(cacheCreationTokens) AS cacheCreationTokens,
       SUM(CASE WHEN status = 'error' THEN 1 ELSE 0 END) AS errors,
       AVG(ttfbMillis) AS avgTtfbMillis,
       AVG(durationMillis) AS avgDurationMillis,
       SUM(retryCount) AS retryCount
FROM $_table
WHERE createdAt >= ?${_filter('')}''',
        [start, ..._filterArgs(providerId, model)]);
    if (rows.isEmpty) return CallSummary.empty;
    final row = rows.first;
    return CallSummary(
      calls: (row['calls'] as num?)?.toInt() ?? 0,
      inputTokens: (row['inputTokens'] as num?)?.toInt() ?? 0,
      outputTokens: (row['outputTokens'] as num?)?.toInt() ?? 0,
      cachedInputTokens: (row['cachedInputTokens'] as num?)?.toInt() ?? 0,
      cacheCreationTokens: (row['cacheCreationTokens'] as num?)?.toInt() ?? 0,
      errors: (row['errors'] as num?)?.toInt() ?? 0,
      avgTtfbMillis: (row['avgTtfbMillis'] as num?)?.toDouble(),
      avgDurationMillis: (row['avgDurationMillis'] as num?)?.toDouble(),
      retryCount: (row['retryCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// 周期内调用总数(供明细分页算总页数)。
  Future<int> callsCount({
    required int start,
    String? providerId,
    String? model,
  }) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS total FROM $_table WHERE createdAt >= ?${_filter('')}',
      [start, ..._filterArgs(providerId, model)],
    );
    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  /// 调用明细分页(倒序,offset 起取 limit 条),LEFT JOIN 渠道名。
  Future<List<LlmCallRecordRow>> recent({
    required int start,
    required int offset,
    required int limit,
    String? providerId,
    String? model,
  }) async {
    final rows = await _db.rawQuery('''
SELECT r.*, json_extract(p.json, '\$.name') AS providerName
FROM $_table r
LEFT JOIN providers p ON p.id = r.providerId
WHERE r.createdAt >= ?${_filter('r')}
ORDER BY r.createdAt DESC
LIMIT ? OFFSET ?''',
        [start, ..._filterArgs(providerId, model), limit, offset]);
    return rows.map((row) {
      final map = Map<String, Object?>.from(row);
      final providerName = map.remove('providerName') as String?;
      return LlmCallRecordRow(
        record: LlmCallRecord(
          id: (map['id'] as num?)?.toInt() ?? 0,
          sessionId: map['sessionId'] as String?,
          providerId: map['providerId'] as String?,
          model: map['model'] as String?,
          reasoningEffort: map['reasoningEffort'] as String?,
          kind: (map['kind'] as String?) ?? 'chat',
          inputTokens: (map['inputTokens'] as num?)?.toInt() ?? 0,
          outputTokens: (map['outputTokens'] as num?)?.toInt() ?? 0,
          cachedInputTokens: (map['cachedInputTokens'] as num?)?.toInt() ?? 0,
          cacheCreationTokens: (map['cacheCreationTokens'] as num?)?.toInt() ?? 0,
          ttfbMillis: (map['ttfbMillis'] as num?)?.toInt(),
          durationMillis: (map['durationMillis'] as num?)?.toInt(),
          status: (map['status'] as String?) ?? 'success',
          errorMessage: map['errorMessage'] as String?,
          stopReason: map['stopReason'] as String?,
          retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
          createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
        ),
        providerName: providerName,
      );
    }).toList();
  }
}