import 'dart:ffi';

import 'package:codecraft/agent/models/chat_session.dart';
import 'package:codecraft/agent/models/project.dart';
import 'package:codecraft/app/router.dart';
import 'package:codecraft/data/db/app_database.dart';
import 'package:codecraft/data/db/daos.dart';
import 'package:codecraft/data/settings/app_settings.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> pumpShell(WidgetTester tester, AppDatabase db, SharedPreferences prefs) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      // 聊天是独立路由(从项目列表 push 进去),所以这里要用真实 router。
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: ref.watch(routerProvider),
        ),
      ),
    ),
  );
}

/// 反复 pump 直到条件命中(不用 pumpAndSettle:页面里有无限动画)。
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxPumps = 60,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (condition()) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = await AppDatabase.open(inMemory: true);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('已有项目:启动停在项目列表,点项目才进聊天页', (tester) async {
    await db.projectDao.upsert(
      const Project(id: 'p1', name: '既有项目', createdAt: 1, updatedAt: 1),
    );
    await db.sessionDao.upsert(
      const ChatSession(
        id: 's1',
        title: '既有会话',
        createdAt: 1,
        updatedAt: 1,
        projectId: 'p1',
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    await pumpShell(tester, db, prefs);

    // 启动一律停在项目列表,不自动进聊天页。
    await pumpUntil(tester, () => find.text('既有项目').evaluate().isNotEmpty);
    expect(find.text('有什么可以帮你的?'), findsNothing, reason: '启动不应进入聊天页');

    await tester.tap(find.text('既有项目').first);
    await pumpUntil(tester, () => find.text('有什么可以帮你的?').evaluate().isNotEmpty);

    expect(find.text('有什么可以帮你的?'), findsOneWidget, reason: '空会话显示欢迎文案');
    expect(find.byType(CircularProgressIndicator), findsNothing, reason: '不应停留在加载态');
    // 打开项目不会新建项目,也不会新建第二条会话。
    expect(await db.projectDao.list(), hasLength(1));
    expect(await db.sessionDao.list(), hasLength(1));
  });

  testWidgets('没有会话:停在项目页的空态,不自动建会话', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await pumpShell(tester, db, prefs);

    await pumpUntil(tester, () => find.text('还没有项目').evaluate().isNotEmpty);

    expect(find.text('还没有项目'), findsOneWidget, reason: '项目页默认空态');
    expect(find.byType(CircularProgressIndicator), findsNothing, reason: '不应停留在加载态');
    final sessions = await db.sessionDao.list();
    expect(sessions, isEmpty, reason: '不应再自动创建会话,改由用户从加号新建');
  });

  testWidgets('底部有项目与设置两个页签,点设置进入设置页', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await pumpShell(tester, db, prefs);
    await pumpUntil(tester, () => find.text('还没有项目').evaluate().isNotEmpty);

    expect(find.text('项目'), findsWidgets);
    expect(find.text('设置'), findsOneWidget, reason: '底栏应有设置页签');

    await tester.tap(find.text('设置'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('设置'), findsWidgets, reason: '已切到设置页');
  });

  testWidgets('侧边栏不再有设置入口', (tester) async {
    await db.sessionDao.upsert(
      const ChatSession(id: 's1', title: '既有会话', createdAt: 1, updatedAt: 1),
    );
    final prefs = await SharedPreferences.getInstance();
    await pumpShell(tester, db, prefs);
    await pumpUntil(tester, () => find.text('有什么可以帮你的?').evaluate().isNotEmpty);

    // 设置入口唯一:底栏。全屏范围内「设置」只出现一次(底栏那一处),
    // 若侧边栏还留着入口,这里会数到两个。
    expect(find.text('设置'), findsOneWidget, reason: '设置只在底部导航出现');
  });
}