import 'dart:ffi';

import 'package:codecraft/data/db/app_database.dart';
import 'package:codecraft/data/db/daos.dart';
import 'package:codecraft/data/db/llm_call_records.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';

/// 覆盖 Token 统计页用到的全部聚合查询(上游 LlmCallRecordDao 的口径)。
void main() {
  late AppDatabase db;

  setUpAll(() {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  setUp(() async {
    db = await AppDatabase.open(inMemory: true);
  });

  tearDown(() => db.close());

  Future<void> seed() async {
    final dao = db.llmCallDao;
    await dao.insert(LlmCallRecord(
      sessionId: 's1',
      providerId: 'p1',
      model: 'm1',
      reasoningEffort: 'medium',
      inputTokens: 1000,
      outputTokens: 200,
      cachedInputTokens: 400,
      cacheCreationTokens: 100,
      ttfbMillis: 300,
      durationMillis: 1500,
      status: 'success',
      stopReason: 'end_turn',
      retryCount: 1,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    await dao.insert(LlmCallRecord(
      providerId: 'p2',
      model: 'm2',
      inputTokens: 500,
      outputTokens: 50,
      status: 'error',
      errorMessage: 'boom',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  test('汇总/按天/按小时/渠道/模型/渠道+模型聚合都能跑通', () async {
    await seed();
    final dao = db.llmCallDao;
    final start = 0;
    final tz = DateTime.now().timeZoneOffset.inMilliseconds;

    final summary = await dao.summary(start: start);
    expect(summary.calls, 2);
    expect(summary.inputTokens, 1500);
    expect(summary.outputTokens, 250);
    expect(summary.cachedInputTokens, 400);
    expect(summary.cacheCreationTokens, 100);
    expect(summary.errors, 1);
    expect(summary.retryCount, 1);

    final days = await dao.dayStats(start: start, tzOffsetMillis: tz);
    expect(days.length, 1);
    expect(days.first.calls, 2);

    final hours = await dao.hourStats(start: start, tzOffsetMillis: tz);
    expect(hours.length, 1);

    final providers = await dao.providerStats(start: start);
    expect(providers.length, 2);
    expect(providers.first.providerId, 'p1');

    final models = await dao.modelStats(start: start);
    expect(models.length, 2);

    final costGroups = await dao.providerModelCostStats(start: start);
    expect(costGroups.length, 2);
    expect(costGroups.first.inputTokens + costGroups.last.inputTokens, 1500);

    expect(await dao.callsCount(start: start), 2);
  });

  test('筛选参数为空与有值都能跑通,命中率计算正确', () async {
    await seed();
    final dao = db.llmCallDao;

    final filtered = await dao.summary(start: 0, providerId: 'p1', model: 'm1');
    expect(filtered.calls, 1);
    expect(filtered.inputTokens, 1000);

    final onlyProvider = await dao.providerStats(start: 0, providerId: 'p1');
    expect(onlyProvider.length, 1);

    final rows = await dao.recent(start: 0, offset: 0, limit: 10, providerId: 'p1');
    expect(rows.length, 1);
    expect(rows.first.record.cachedInputTokens, 400);
    expect(rows.first.providerName, isNull);
  });

  test('明细分页:limit/offset 生效且按时间倒序', () async {
    await seed();
    final dao = db.llmCallDao;
    final page1 = await dao.recent(start: 0, offset: 0, limit: 1);
    final page2 = await dao.recent(start: 0, offset: 1, limit: 1);
    expect(page1.length, 1);
    expect(page2.length, 1);
    expect(page1.first.record.id, isNot(page2.first.record.id));
    expect(
      page1.first.record.createdAt >= page2.first.record.createdAt,
      isTrue,
    );
  });

  test('清空记录后汇总归零(重置功能)', () async {
    await seed();
    final dao = db.llmCallDao;
    await dao.deleteAll();
    final summary = await dao.summary(start: 0);
    expect(summary.calls, 0);
    expect(summary.totalTokens, 0);
    expect(await dao.callsCount(start: 0), 0);
  });

  test('渠道名从 providers.json 取(表里没有 name 列)', () async {
    await db.db.insert('providers', {
      'id': 'p1',
      'json': '{"id":"p1","name":"My Channel"}',
      'sortOrder': 0,
    });
    await seed();
    final dao = db.llmCallDao;

    final providers = await dao.providerStats(start: 0);
    final p1 = providers.firstWhere((item) => item.providerId == 'p1');
    expect(p1.providerName, 'My Channel');

    final rows = await dao.recent(start: 0, offset: 0, limit: 10);
    expect(
      rows.firstWhere((row) => row.record.providerId == 'p1').providerName,
      'My Channel',
    );
  });
}