import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:codecraft/agent/chat_controller.dart';
import 'package:codecraft/agent/models/agent_attachment.dart';
import 'package:codecraft/agent/models/agent_message.dart';
import 'package:codecraft/agent/models/agent_ui_state.dart';
import 'package:codecraft/agent/models/chat_session.dart';
import 'package:codecraft/agent/protocols/http_transport.dart';
import 'package:codecraft/agent/sessions_controller.dart';
import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/data/db/app_database.dart';
import 'package:codecraft/data/db/daos.dart';
import 'package:codecraft/data/permissions.dart';
import 'package:codecraft/data/providers/provider_config.dart';
import 'package:codecraft/data/providers/provider_store.dart';
import 'package:codecraft/data/settings/app_settings.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 标题请求(首条消息后后台发起)对脚本序列是额外消耗:识别后返回空流,
/// 保持脚本按主请求次序消耗(标题生成失败 = 保留临时标题,符合各测试断言)。
bool _isTitleRequest(Map<String, dynamic> body) {
  final messages = body['messages'];
  if (messages is! List || messages.isEmpty) return false;
  final first = messages.first;
  if (first is! Map) return false;
  final content = first['content'];
  return content is String && content.contains('会话标题生成器');
}

class ScriptedTransport implements SseTransport {
  ScriptedTransport(this.lines);

  final List<String> lines;
  int calls = 0;
  Map<String, dynamic>? lastBody;

  @override
  Stream<String> postSseLines({
    required String url,
    required Map<String, dynamic> body,
    required Map<String, String> headers,
    Duration? idleTimeout,
    CancelToken? cancelToken,
  }) async* {
    if (_isTitleRequest(body)) return;
    calls++;
    lastBody = body;
    for (final line in lines) {
      yield line;
    }
  }
}

Future<ChatViewState> waitIdle(ProviderContainer container, String sessionId) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(deadline)) {
    final state = container.read(chatControllerProvider(sessionId));
    if (state.loaded && !state.streaming && state.messages.length >= 2) return state;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('等待流式结束超时');
}

/// `send()` 现在只负责「提交并启动」,不等整轮结束;要断言执行结果就得等轮次收尾。
Future<void> waitTurnEnd(ProviderContainer container, String sessionId) => waitFor(
      () {
        final state = container.read(chatControllerProvider(sessionId));
        return !state.streaming && state.pendingPermission == null;
      },
      reason: '本轮对话应已结束',
    );

Future<void> waitFor(bool Function() condition, {String? reason}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('等待条件超时:${reason ?? ''}');
}

/// 按调用次序依次返回不同脚本的传输(用于工具循环:第一次返回工具调用,第二次返回最终回答)。
class QueueTransport implements SseTransport {
  QueueTransport(this.scripts);

  final List<List<String>> scripts;
  final List<Map<String, dynamic>> bodies = [];
  int _index = 0;

  @override
  Stream<String> postSseLines({
    required String url,
    required Map<String, dynamic> body,
    required Map<String, String> headers,
    Duration? idleTimeout,
    CancelToken? cancelToken,
  }) async* {
    if (_isTitleRequest(body)) return;
    bodies.add(body);
    final script = _index < scripts.length ? scripts[_index] : const <String>[];
    _index++;
    for (final line in script) {
      yield line;
    }
  }
}

/// 只吐一个增量、随后持续心跳保持连接打开(模拟真实长连接未结束,且可被取消)。
class HangingTransport implements SseTransport {
  @override
  Stream<String> postSseLines({
    required String url,
    required Map<String, dynamic> body,
    required Map<String, String> headers,
    Duration? idleTimeout,
    CancelToken? cancelToken,
  }) async* {
    if (_isTitleRequest(body)) return;
    yield 'data: {"choices":[{"delta":{"content":"半句话"}}]}';
    yield '';
    while (true) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      yield ': ping';
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
  late ScriptedTransport transport;
  late Directory workspaceDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    db = await AppDatabase.open(inMemory: true);
    workspaceDir = Directory.systemTemp.createTempSync('ws_flow');
    transport = ScriptedTransport([
      'data: {"choices":[{"delta":{"content":"你好"}}]}',
      '',
      'data: {"choices":[{"delta":{"content":"呀"},"finish_reason":"stop"}]}',
      '',
      'data: {"choices":[],"usage":{"prompt_tokens":4,"completion_tokens":2}}',
      '',
      'data: [DONE]',
      '',
    ]);
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(preferences),
        sseTransportProvider.overrideWithValue(transport),
        workspaceProvider.overrideWithValue(Workspace(workspaceDir.path)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    workspaceDir.deleteSync(recursive: true);
  });

  test('端到端:发送 → 流式 → 落库 → 会话命名与用量', () async {
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

    // 新建默认是 Auto;这里显式指定模型,测「指定模型」这条路径。
    final created = await container.read(sessionsProvider.notifier).create();
    expect(created.model, 'auto', reason: '新建会话默认 Auto Model');
    await container.read(sessionsProvider.notifier).upsert(
          created.copyWith(providerId: () => 'p1', model: () => 'mock-model'),
        );
    final session = (await container.read(sessionsProvider.future))
        .firstWhere((s) => s.id == created.id);
    expect(session.providerId, 'p1');
    expect(session.model, 'mock-model');

    final controller = container.read(chatControllerProvider(session.id).notifier);
    await controller.send('你好');
    final state = await waitIdle(container, session.id);

    expect(state.streaming, false);
    expect(state.errorCode, isNull);
    expect(state.messages.length, 2);
    expect(state.messages.first.role, MessageRole.user);
    expect(state.messages.last.role, MessageRole.assistant);
    expect(state.messages.last.content, '你好呀');
    expect(state.messages.last.inputTokens, 4);
    expect(state.messages.last.outputTokens, 2);

    // 落库校验
    final stored = await db.messageDao.listBySession(session.id);
    expect(stored.length, 2);
    final storedSession = await db.sessionDao.get(session.id);
    expect(storedSession!.title, '你好');
    expect(storedSession.totalInputTokens, 4);
    expect(storedSession.totalOutputTokens, 2);

    // 请求体校验:system prompt 在前,历史消息在后
    final messages = (transport.lastBody!['messages'] as List).cast<Map>();
    expect(messages.length, 2);
    expect(messages.first['role'], 'system');
    expect(messages.last['content'], '你好');
  });

  test('停止:保留已接收的部分内容并落库', () async {
    final hanging = HangingTransport();
    container.dispose();
    final preferences = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(preferences),
        sseTransportProvider.overrideWithValue(hanging),
        workspaceProvider.overrideWithValue(Workspace(workspaceDir.path)),
      ],
    );
    await container.read(providersProvider.future);
    await container.read(providersProvider.notifier).save(
          const ProviderConfig(
            id: 'p2',
            name: 'Mock',
            type: ProviderType.openai,
            apiKey: 'sk-test',
            baseUrl: 'https://mock.local',
            defaultModel: 'mock-model',
          ),
        );
    // 显式指定模型(新建默认是 Auto)。
    final created = await container.read(sessionsProvider.notifier).create();
    await container.read(sessionsProvider.notifier).upsert(
          created.copyWith(providerId: () => 'p2', model: () => 'mock-model'),
        );
    final session = (await container.read(sessionsProvider.future))
        .firstWhere((s) => s.id == created.id);

    final controller = container.read(chatControllerProvider(session.id).notifier);
    unawaited(controller.send('继续'));
    await waitFor(
      () => container.read(chatControllerProvider(session.id)).streamingText.isNotEmpty,
      reason: '首个增量未到达',
    );
    await controller.stop().timeout(const Duration(seconds: 10));

    final stored = await db.messageDao.listBySession(session.id);
    expect(stored.length, 2);
    expect(stored.last.role, MessageRole.assistant);
    expect(stored.last.content, '半句话');

    // 取消的调用也要进统计(对齐上游 finally 无条件落库,status = cancelled)。
    final records = await db.llmCallDao.recent(start: 0, offset: 0, limit: 10);
    expect(records, hasLength(1), reason: '停止后仍应记一条调用记录');
    expect(records.first.record.status, 'cancelled');
    expect(records.first.record.model, 'mock-model');
    expect(records.first.record.providerId, 'p2');
    expect(records.first.record.durationMillis, greaterThan(0));
  });

  test('切换模式后会话刷新(页面链路:upsert → sessionByIdProvider)', () async {
    await container.read(providersProvider.future);
    final session = await container.read(sessionsProvider.notifier).create();

    final current = await container.read(sessionByIdProvider(session.id).future);
    expect(current!.mode, AgentMode.build);

    await container
        .read(sessionsProvider.notifier)
        .upsert(current.copyWith(mode: AgentMode.write));

    final refreshed = await container.read(sessionByIdProvider(session.id).future);
    expect(refreshed!.mode, AgentMode.write, reason: '模式应已持久化并刷新到页面');

    final persisted = await db.sessionDao.get(session.id);
    expect(persisted!.mode, AgentMode.write);
  });

  test('发送带附件的消息:附件落库、待发送列表清空', () async {
    await container.read(providersProvider.future);
    await container.read(providersProvider.notifier).save(
          const ProviderConfig(
            id: 'p3',
            name: 'Mock',
            type: ProviderType.openai,
            apiKey: 'sk-test',
            baseUrl: 'https://mock.local',
            defaultModel: 'mock-model',
          ),
        );
    final session = await container.read(sessionsProvider.notifier).create();

    final dir = Directory.systemTemp.createTempSync('att_test');
    final file = File('${dir.path}/pic.png')..writeAsBytesSync([1, 2, 3]);
    final controller = container.read(chatControllerProvider(session.id).notifier);
    controller.addAttachment(
      AgentAttachment(
        fileName: 'pic.png',
        localPath: file.path,
        mimeType: 'image/png',
        sizeBytes: 3,
      ),
    );
    expect(
      container.read(chatControllerProvider(session.id)).pendingAttachments.length,
      1,
      reason: '附加后应出现在待发送列表',
    );

    await controller.send('看看这张图');
    final state = await waitIdle(container, session.id);

    expect(state.pendingAttachments, isEmpty, reason: '发送后待发送列表应清空');
    final stored = await db.messageDao.listBySession(session.id);
    expect(stored.first.attachments.length, 1, reason: '附件元数据应随消息落库');
    expect(stored.first.attachments.first.fileName, 'pic.png');

    dir.deleteSync(recursive: true);
  });

  test('工具循环:writeFile 需授权 → 执行落库 → 回放给模型 → 最终回答', () async {
    await container.read(providersProvider.future);
    await container.read(providersProvider.notifier).save(
          const ProviderConfig(
            id: 'p4',
            name: 'Mock',
            type: ProviderType.openai,
            apiKey: 'sk-test',
            baseUrl: 'https://mock.local',
            defaultModel: 'mock-model',
          ),
        );
    final session = await container.read(sessionsProvider.notifier).create();

    final queue = QueueTransport([
      [
        'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"id":"call_1","function":{"name":"writeFile","arguments":"{\\"path\\":\\"~/workspace/a.txt\\",\\"content\\":\\"hello\\"}"}}]},"finish_reason":"tool_calls"}]}',
        '',
        'data: [DONE]',
        '',
      ],
      [
        'data: {"choices":[{"delta":{"content":"已写入 a.txt"},"finish_reason":"stop"}]}',
        '',
        'data: [DONE]',
        '',
      ],
    ]);

    container.dispose();
    final preferences = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(preferences),
        sseTransportProvider.overrideWithValue(queue),
        workspaceProvider.overrideWithValue(Workspace(workspaceDir.path)),
      ],
    );

    final controller = container.read(chatControllerProvider(session.id).notifier);
    unawaited(controller.send('把 hello 写进 a.txt'));
    await waitFor(
      () => container.read(chatControllerProvider(session.id)).pendingPermission != null,
      reason: '写入工具应先请求授权',
    );
    controller.resolvePermission(PermissionChoice.once);
    await waitTurnEnd(container, session.id);

    final stored = await db.messageDao.listBySession(session.id);
    expect(
      stored.map((m) => m.role).toList(),
      [MessageRole.user, MessageRole.assistant, MessageRole.tool, MessageRole.assistant],
      reason: '消息序列:用户 → 带工具调用的助手 → 工具结果 → 最终助手',
    );
    expect(stored[2].toolName, 'writeFile');
    expect(stored[2].isError, false);
    expect(File('${workspaceDir.path}/a.txt').readAsStringSync(), 'hello');
    expect(stored.last.content, '已写入 a.txt');

    final secondMessages = (queue.bodies[1]['messages'] as List).cast<Map>();
    expect(secondMessages.any((m) => m['role'] == 'tool'), true,
        reason: '第二次请求应回放 tool 消息');
  });

  test('send 在流式结束前就返回(输入框才能立刻清空)', () async {
    // 用会一直挂着的传输:若 send 仍在等整轮结束,这个 await 会超时。
    final hanging = HangingTransport();
    container.dispose();
    final preferences = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(preferences),
        sseTransportProvider.overrideWithValue(hanging),
        workspaceProvider.overrideWithValue(Workspace(workspaceDir.path)),
      ],
    );
    await container.read(providersProvider.future);
    await container.read(providersProvider.notifier).save(
          const ProviderConfig(
            id: 'p3',
            name: 'Mock',
            type: ProviderType.openai,
            apiKey: 'sk-test',
            baseUrl: 'https://mock.local',
            defaultModel: 'mock-model',
          ),
        );
    final created = await container.read(sessionsProvider.notifier).create();
    await container.read(sessionsProvider.notifier).upsert(
          created.copyWith(providerId: () => 'p3', model: () => 'mock-model'),
        );
    final session = (await container.read(sessionsProvider.future))
        .firstWhere((s) => s.id == created.id);
    final controller = container.read(chatControllerProvider(session.id).notifier);

    final accepted = await controller.send('你好').timeout(const Duration(seconds: 5));
    expect(accepted, isTrue, reason: 'send 应只表示「已接受」,不等整轮结束');
    // 此时仍在流式中:证明 send 没有等对话跑完。
    expect(container.read(chatControllerProvider(session.id)).streaming, isTrue);
    controller.stop();
  });
}
