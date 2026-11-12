import 'dart:ffi';
import 'dart:io';

import 'package:codecraft/agent/chat_controller.dart';
import 'package:codecraft/agent/models/agent_message.dart';
import 'package:codecraft/agent/models/agent_ui_state.dart';
import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/data/db/app_database.dart';
import 'package:codecraft/data/db/daos.dart';
import 'package:codecraft/data/settings/app_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  sqfliteFfiInit();
  // 用无隔离工厂:override 是 isolate 级全局,隔离工厂里会失效
  databaseFactory = databaseFactoryFfiNoIsolate;

  late AppDatabase db;
  late ProviderContainer container;
  late Directory workspaceDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    db = await AppDatabase.open(inMemory: true);
    workspaceDir = Directory.systemTemp.createTempSync('ws_page');
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(preferences),
        workspaceProvider.overrideWithValue(Workspace(workspaceDir.path)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    workspaceDir.deleteSync(recursive: true);
  });

  const sid = 's1';

  Future<void> insertMessages(int n) async {
    for (var i = 0; i < n; i++) {
      await db.messageDao.insert(AgentMessage(
        id: 'm$i',
        sessionId: sid,
        role: MessageRole.user,
        content: 'msg $i',
        timestamp: 1000 + i,
      ));
    }
  }

  Future<ChatViewState> waitLoaded() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      final state = container.read(chatControllerProvider(sid));
      if (state.loaded) return state;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    fail('等待初始加载超时');
  }

  test('初始只加载最新 50 条,hasMore 为真', () async {
    await insertMessages(120);
    container.read(chatControllerProvider(sid).notifier);
    final state = await waitLoaded();
    expect(state.messages.length, 50);
    expect(state.hasMore, isTrue);
    expect(state.messageLimit, 50);
    // 加载的是最新的 50 条(m70..m119),升序返回
    expect(state.messages.first.content, 'msg 70');
    expect(state.messages.last.content, 'msg 119');
  });

  test('loadMoreMessages 步长递增直至全量', () async {
    await insertMessages(120);
    container.read(chatControllerProvider(sid).notifier);
    await waitLoaded();
    final notifier = container.read(chatControllerProvider(sid).notifier);

    await notifier.loadMoreMessages();
    var state = container.read(chatControllerProvider(sid));
    expect(state.messages.length, 80); // 50 + clamp(25, 30, 90) = 80
    expect(state.messageLimit, 80);
    expect(state.messages.first.content, 'msg 40');
    expect(state.messages.last.content, 'msg 119');

    await notifier.loadMoreMessages();
    state = container.read(chatControllerProvider(sid));
    expect(state.messages.length, 120); // 80 + 40 = 120 >= 总数 → 全量
    expect(state.messageLimit, 0);
    expect(state.hasMore, isFalse);
    expect(state.messages.first.content, 'msg 0');
  });

  test('不足一页时全量加载且 hasMore 为假', () async {
    await insertMessages(30);
    container.read(chatControllerProvider(sid).notifier);
    final state = await waitLoaded();
    expect(state.messages.length, 30);
    expect(state.hasMore, isFalse);
    expect(state.messageLimit, 0);
  });

  test('删除消息后按当前上限刷新,范围不放大', () async {
    await insertMessages(120);
    container.read(chatControllerProvider(sid).notifier);
    await waitLoaded();
    final notifier = container.read(chatControllerProvider(sid).notifier);

    await notifier.deleteMessage('m119');
    final state = container.read(chatControllerProvider(sid));
    expect(state.messages.length, 50); // 仍按上限 50 重查(m69..m118)
    expect(state.hasMore, isTrue);
    expect(state.messageLimit, 50);
    expect(state.messages.last.content, 'msg 118');
  });

  test('DAO:limit 取最新 N 条且升序返回,count 准确', () async {
    await insertMessages(120);
    final latest50 = await db.messageDao.listBySession(sid, limit: 50);
    expect(latest50.length, 50);
    expect(latest50.first.content, 'msg 70');
    expect(latest50.last.content, 'msg 119');
    // 全量兼容
    final all = await db.messageDao.listBySession(sid);
    expect(all.length, 120);
    expect(await db.messageDao.countBySession(sid), 120);
    expect(await db.messageDao.countBySession('other'), 0);
  });
}
