import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:codecraft/agent/chat_controller.dart';
import 'package:codecraft/agent/models/agent_ui_state.dart';
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

/// 吐一个增量后就**彻底静默**(等待一个永不完成的 Future)。
///
/// 这正是设备上的真实状态:服务端迟迟不再发数据,`async*` 生成器停在 await 上。
/// 生成器只在「产出」时检查订阅取消,所以仅取消订阅并不能打断它——
/// 必须用 CancelToken 打断底层请求。
/// 标题请求识别:系统提示词是指令模板。
bool _isTitleRequest(Map<String, dynamic> body) {
  final messages = body['messages'];
  if (messages is! List || messages.isEmpty) return false;
  final first = messages.first;
  if (first is! Map) return false;
  final content = first['content'];
  return content is String && content.contains('会话标题生成器');
}

class SilentTransport implements SseTransport {
  SilentTransport(this.onCancel);

  final void Function()? onCancel;
  CancelToken? lastToken;

  @override
  Stream<String> postSseLines({
    required String url,
    required Map<String, dynamic> body,
    required Map<String, String> headers,
    Duration? idleTimeout,
    CancelToken? cancelToken,
  }) async* {
    // 标题请求不记录 token(否则覆盖主请求的 token,干扰取消断言),直接空流结束。
    if (_isTitleRequest(body)) return;
    lastToken = cancelToken;
    cancelToken?.whenCancel.then((_) => onCancel?.call());
    yield 'data: {"choices":[{"delta":{"content":"半句话"}}]}';
    yield '';
    // 永不完成:模拟服务端不再发数据。
    await Completer<void>().future;
  }
}

/// 吐一个增量后**正常结束**,但不给收尾块(没有 [DONE]、没有 finish_reason)。
///
/// 连接中途被断、服务端提前收尾时就是这样:既不报错、也不取消,
/// 早先这条路径不会清 streaming,界面会永远停在「正在思考」。
class TruncatedTransport implements SseTransport {
  @override
  Stream<String> postSseLines({
    required String url,
    required Map<String, dynamic> body,
    required Map<String, String> headers,
    Duration? idleTimeout,
    CancelToken? cancelToken,
  }) async* {
    yield 'data: {"choices":[{"delta":{"content":"半句话"}}]}';
    yield '';
    // 到此结束:没有 [DONE],也没有 finish_reason。
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late AppDatabase db;
  late ProviderContainer container;
  late Directory workspaceDir;

  Future<String> boot(SseTransport transport) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    db = await AppDatabase.open(inMemory: true);
    workspaceDir = Directory.systemTemp.createTempSync('ws_stop');
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(preferences),
        sseTransportProvider.overrideWithValue(transport),
        workspaceProvider.overrideWithValue(Workspace(workspaceDir.path)),
      ],
    );
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
    return created.id;
  }

  tearDown(() async {
    container.dispose();
    await db.close();
    if (workspaceDir.existsSync()) workspaceDir.deleteSync(recursive: true);
  });

  Future<ChatViewState> waitStreaming(String sessionId) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      final state = container.read(chatControllerProvider(sessionId));
      if (state.streamingText.isNotEmpty) return state;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    fail('等待首个增量超时');
  }

  test('服务端静默时 stop() 立即返回并把状态收尾,不被网络取消卡住', () async {
    final transport = SilentTransport(null);
    final sessionId = await boot(transport);

    final controller = container.read(chatControllerProvider(sessionId).notifier);
    unawaited(controller.send('继续'));
    await waitStreaming(sessionId);

    // 关键:stop() 必须在很短时间内返回。若先 await 取消订阅,
    // 生成器卡在 await 上会让它永远不返回(设备上表现为「点了没反应」)。
    await controller.stop().timeout(
          const Duration(seconds: 2),
          onTimeout: () => fail('stop() 被网络取消卡住了'),
        );

    final state = container.read(chatControllerProvider(sessionId));
    expect(state.streaming, isFalse, reason: '停止后应立刻退出流式状态');
    expect(state.retry, isNull);
  });

  test('停止会取消底层请求的 CancelToken', () async {
    final transport = SilentTransport(null);
    final sessionId = await boot(transport);

    final controller = container.read(chatControllerProvider(sessionId).notifier);
    unawaited(controller.send('继续'));
    await waitStreaming(sessionId);

    expect(transport.lastToken?.isCancelled, isFalse);
    await controller.stop().timeout(const Duration(seconds: 2));
    expect(transport.lastToken?.isCancelled, isTrue,
        reason: '必须打断底层 HTTP 请求,否则连接一直挂着');
  });

  test('已收到的部分内容落库保留', () async {
    final transport = SilentTransport(null);
    final sessionId = await boot(transport);

    final controller = container.read(chatControllerProvider(sessionId).notifier);
    unawaited(controller.send('继续'));
    await waitStreaming(sessionId);
    await controller.stop().timeout(const Duration(seconds: 2));

    final stored = await db.messageDao.listBySession(sessionId);
    expect(stored.last.content, '半句话', reason: '停掉也要留下已经看到的内容');
  });

  test('流正常结束但没给收尾块:不再卡在「正在思考」', () async {
    final sessionId = await boot(TruncatedTransport());
    final controller = container.read(chatControllerProvider(sessionId).notifier);

    await controller.send('继续');

    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline) &&
        container.read(chatControllerProvider(sessionId)).streaming) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    final state = container.read(chatControllerProvider(sessionId));
    expect(state.streaming, isFalse, reason: '这条路径早先不会清 streaming,界面会一直显示正在思考');
    expect(state.errorCode, isNotNull, reason: '要告诉用户响应被中断了');
    expect(state.errorDetail, contains('中断'));
  });

  test('中断时已经流下来的内容保留,不丢', () async {
    final sessionId = await boot(TruncatedTransport());
    final controller = container.read(chatControllerProvider(sessionId).notifier);

    await controller.send('继续');
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline) &&
        container.read(chatControllerProvider(sessionId)).streaming) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    final stored = await db.messageDao.listBySession(sessionId);
    expect(stored.last.content, '半句话', reason: '中断不该让已经看到的内容消失');
  });
}
