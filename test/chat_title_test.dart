import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:codecraft/agent/chat_controller.dart';
import 'package:codecraft/agent/models/agent_ui_state.dart';
import 'package:codecraft/agent/models/chat_session.dart';
import 'package:codecraft/agent/protocols/http_transport.dart';
import 'package:codecraft/agent/sessions_controller.dart';
import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/data/db/app_database.dart';
import 'package:codecraft/data/db/daos.dart';
import 'package:codecraft/data/providers/provider_config.dart';
import 'package:codecraft/data/providers/provider_store.dart';
import 'package:codecraft/data/settings/app_settings.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 主请求脚本:流式产出「你好呀」后结束。
const List<String> _mainScript = [
  'data: {"choices":[{"delta":{"content":"你好"}}]}',
  '',
  'data: {"choices":[{"delta":{"content":"呀"},"finish_reason":"stop"}]}',
  '',
  'data: {"choices":[],"usage":{"prompt_tokens":4,"completion_tokens":2}}',
  '',
  'data: [DONE]',
  '',
];

/// 标题请求脚本:直接给出标题。
const List<String> _titleScript = [
  'data: {"choices":[{"delta":{"content":"聊天开场白"}}]}',
  '',
  'data: {"choices":[],"usage":{"prompt_tokens":2,"completion_tokens":1}}',
  '',
  'data: [DONE]',
  '',
];

/// 空响应脚本(无任何内容增量,直接结束)。
const List<String> _emptyScript = [
  'data: {"choices":[{"delta":{}}],"finish_reason":"stop"}',
  '',
  'data: {"choices":[],"usage":{"prompt_tokens":4,"completion_tokens":0}}',
  '',
  'data: [DONE]',
  '',
];

/// 按调用次序返回不同脚本,并记录「标题请求是否在主请求首个内容之前发起」。
class TitleTimingTransport implements SseTransport {
  TitleTimingTransport(this.scripts);

  final List<List<String>> scripts;
  final List<Map<String, dynamic>> bodies = [];
  int calls = 0;
  var firstChunkEmitted = false;
  var titleStartedBeforeFirstContent = false;

  @override
  Stream<String> postSseLines({
    required String url,
    required Map<String, dynamic> body,
    required Map<String, String> headers,
    Duration? idleTimeout,
    CancelToken? cancelToken,
  }) async* {
    calls++;
    bodies.add(body);
    final script = calls <= scripts.length ? scripts[calls - 1] : const <String>[];
    for (final line in script) {
      if (calls == 1 && line.startsWith('data: {"choices":[{"delta":{"content"')) {
        firstChunkEmitted = true;
      }
      if (calls == 2 && !firstChunkEmitted) {
        titleStartedBeforeFirstContent = true;
      }
      yield line;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  sqfliteFfiInit();
  // 用无隔离工厂:override 是 isolate 级全局,隔离工厂里会失效
  databaseFactory = databaseFactoryFfiNoIsolate;

  late AppDatabase db;
  late ProviderContainer container;
  late Directory workspaceDir;
  late TitleTimingTransport transport;

  Future<void> initContainer() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    db = await AppDatabase.open(inMemory: true);
    workspaceDir = Directory.systemTemp.createTempSync('ws_title');
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(preferences),
        sseTransportProvider.overrideWithValue(transport),
        workspaceProvider.overrideWithValue(Workspace(workspaceDir.path)),
      ],
    );
  }

  setUp(() async {
    transport = TitleTimingTransport([_mainScript, _titleScript]);
    await initContainer();
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    workspaceDir.deleteSync(recursive: true);
  });

  Future<ChatSession> setUpSession() async {
    await container.read(providersProvider.future);
    await container.read(providersProvider.notifier).save(
          const ProviderConfig(
            id: 'p1',
            name: 'Mock',
            type: ProviderType.openai,
            apiKey: 'sk-test',
            baseUrl: 'https://mock.local',
            defaultModel: 'mock-model',
          ),
        );
    final created = await container.read(sessionsProvider.notifier).create();
    await container.read(sessionsProvider.notifier).upsert(
          created.copyWith(providerId: () => 'p1', model: () => 'mock-model'),
        );
    return (await container.read(sessionsProvider.future)).firstWhere((s) => s.id == created.id);
  }

  Future<ChatViewState> waitIdle(String sessionId) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      final state = container.read(chatControllerProvider(sessionId));
      // 空响应场景不落库 assistant 消息,这里只等本轮流式结束(标题完成由 waitTitleDone 负责)。
      if (state.loaded && !state.streaming) return state;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    fail('等待流式结束超时');
  }

  Future<void> waitTitleDone() async {
    // 标题请求是第二个 HTTP 调用;等它发出并留出聚合落库时间。
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      if (transport.calls >= 2) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    fail('标题请求未发出');
  }

  test('标题请求延后到主请求首个内容后发起,生成成功替换临时标题', () async {
    final session = await setUpSession();
    final controller = container.read(chatControllerProvider(session.id).notifier);
    await controller.send('你好,今天天气怎么样');
    await waitIdle(session.id);
    await waitTitleDone();

    // 主请求与标题请求都发出去了
    expect(transport.calls, 2);
    expect(transport.bodies.length, 2);
    // 延后语义:标题请求发起时主请求已产出首个内容
    expect(transport.titleStartedBeforeFirstContent, isFalse);

    // 标题请求正文:system 是指令、只带首条用户消息、无工具定义
    final titleBody = transport.bodies[1];
    final titleMessages = (titleBody['messages'] as List).cast<Map<String, dynamic>>();
    expect(titleMessages.length, 2);
    expect(titleMessages.first['role'], 'system');
    expect(titleMessages.first['content'], contains('标题'));
    expect(titleMessages[1]['role'], 'user');
    expect(titleMessages[1]['content'], '你好,今天天气怎么样');
    expect(titleBody.containsKey('tools'), isFalse);

    // 主请求不受影响,且标题已替换临时标题落库
    final state = container.read(chatControllerProvider(session.id));
    expect(state.messages.length, 2);
    final stored = await db.sessionDao.get(session.id);
    expect(stored!.title, '聊天开场白');
  });

  test('主请求空响应时标题请求随本轮收尾兜底发起', () async {
    transport = TitleTimingTransport([_emptyScript, _titleScript]);
    container.dispose();
    await db.close();
    workspaceDir.deleteSync(recursive: true);
    await initContainer();

    final session = await setUpSession();
    final controller = container.read(chatControllerProvider(session.id).notifier);
    await controller.send('你好');
    await waitIdle(session.id);
    await waitTitleDone();

    expect(transport.calls, 2);
    final stored = await db.sessionDao.get(session.id);
    expect(stored!.title, '聊天开场白');
  });

  test('标题请求取不到内容时保留临时标题', () async {
    transport = TitleTimingTransport([_mainScript, _emptyScript]);
    container.dispose();
    await db.close();
    workspaceDir.deleteSync(recursive: true);
    await initContainer();

    final session = await setUpSession();
    final controller = container.read(chatControllerProvider(session.id).notifier);
    await controller.send('你好,今天天气怎么样');
    await waitIdle(session.id);
    await waitTitleDone();

    final stored = await db.sessionDao.get(session.id);
    expect(stored!.title, '你好,今天天气怎么样');
  });
}
