import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:codecraft/agent/chat_controller.dart';
import 'package:codecraft/agent/models/agent_message.dart';
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
import 'package:codecraft/data/workspaces.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 固定工作区:真实 workspacesProvider 是异步的,就绪后会把 currentWorkspaceProvider
/// 切到 projects/<名> 目录,导致规则写入与读取落在不同目录(部件/流程测试里必须固定)。
class _StableWorkspaces extends WorkspacesNotifier {
  _StableWorkspaces(this.fixed);

  final WorkspacesState fixed;

  @override
  Future<WorkspacesState> build() async => fixed;
}

/// 标题请求(首条消息后后台发起)识别:系统提示词是指令模板。
bool _isTitleRequest(Map<String, dynamic> body) {
  final messages = body['messages'];
  if (messages is! List || messages.isEmpty) return false;
  final first = messages.first;
  if (first is! Map) return false;
  final content = first['content'];
  return content is String && content.contains('会话标题生成器');
}

/// 按调用次序返回脚本的传输:第一次给工具调用,之后给最终回答。
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
    // 标题请求不消耗脚本序列、不计入 bodies(返回空流 = 标题生成失败,保留临时标题)。
    if (_isTitleRequest(body)) return;
    bodies.add(body);
    final script = _index < scripts.length ? scripts[_index] : const <String>[];
    _index++;
    for (final line in script) {
      yield line;
    }
  }
}

List<String> writeFileScript(String path, String content) => [
      'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"id":"call_1","function":'
          '{"name":"writeFile","arguments":"{\\"path\\":\\"$path\\",\\"content\\":\\"$content\\"}"}}]},'
          '"finish_reason":"tool_calls"}]}',
      '',
      'data: [DONE]',
      '',
    ];

const List<String> finalAnswerScript = [
  'data: {"choices":[{"delta":{"content":"完成"},"finish_reason":"stop"}]}',
  '',
  'data: [DONE]',
  '',
];

/// `send()` 现在只负责「提交并启动」,不等整轮结束;要断言执行结果就得等轮次收尾。
///
/// 条件必须同时满足:已开始过流式、当前不在流式、没有待授权。
/// 只判 `!streaming` 会在 send 刚返回、流式还没起来的瞬间误判为「已结束」。
Future<void> waitTurnEnd(
  ProviderContainer container,
  String sessionId, {
  int minMessages = 2,
}) async {
  await waitFor(() {
    final state = container.read(chatControllerProvider(sessionId));
    // 判据用「已落够消息 + 不在流式 + 无待授权」:拒绝路径不进入 streaming,
    // 只看 streaming 会在刚 send 完的瞬间误判为已结束。
    return !state.streaming &&
        state.pendingPermission == null &&
        state.messages.length >= minMessages;
  }, reason: '本轮对话应已结束');
}

Future<void> waitFor(bool Function() condition, {String? reason}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('等待条件超时:${reason ?? ''}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late AppDatabase db;
  late ProviderContainer container;
  late Directory workspaceDir;
  late Directory configDir;

  Future<void> boot(QueueTransport transport) async {
    container.dispose();
    final preferences = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(preferences),
        sseTransportProvider.overrideWithValue(transport),
        workspaceProvider.overrideWithValue(Workspace(workspaceDir.path)),
        workspacesProvider.overrideWith(
          () => _StableWorkspaces(
            WorkspacesState(
              workspaces: [WorkspaceInfo(name: 'test', path: workspaceDir.path)],
            ),
          ),
        ),
        configDirProvider.overrideWithValue(configDir.path),
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
  }

  Future<ChatSession> newSession({AgentMode mode = AgentMode.build}) async {
    final session = await container.read(sessionsProvider.notifier).create();
    if (mode != AgentMode.build) {
      await container
          .read(sessionsProvider.notifier)
          .upsert(session.copyWith(mode: mode));
    }
    return session;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = await AppDatabase.open(inMemory: true);
    workspaceDir = Directory.systemTemp.createTempSync('perm_ws');
    configDir = Directory.systemTemp.createTempSync('perm_config');
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        workspaceProvider.overrideWithValue(Workspace(workspaceDir.path)),
        configDirProvider.overrideWithValue(configDir.path),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    workspaceDir.deleteSync(recursive: true);
    configDir.deleteSync(recursive: true);
  });

  test('选「仅本次」:执行一次但不落规则', () async {
    await boot(QueueTransport([writeFileScript('~/workspace/a.txt', 'one'), finalAnswerScript]));
    final session = await newSession();
    final controller = container.read(chatControllerProvider(session.id).notifier);
    unawaited(controller.send('写 a.txt'));

    await waitFor(
      () => container.read(chatControllerProvider(session.id)).pendingPermission != null,
      reason: '写文件应先请求授权',
    );
    final pending = container.read(chatControllerProvider(session.id)).pendingPermission!;
    expect(pending.toolName, 'writeFile');
    expect(pending.title, '确认执行工具');
    expect(pending.rememberablePatterns, [PermissionRule.wholeTool]);
    expect(pending.details, contains('a.txt'));

    controller.resolvePermission(PermissionChoice.once);
    await waitTurnEnd(container, session.id);

    expect(File('${workspaceDir.path}/a.txt').readAsStringSync(), 'one');
    expect(
      File('${workspaceDir.path}/.codecraft/permissions.json').existsSync(),
      isFalse,
      reason: '仅本次不应写入规则文件',
    );
  });

  test('选「始终允许」:执行并写入项目规则,下一次同类调用不再弹窗', () async {
    await boot(QueueTransport([
      writeFileScript('~/workspace/a.txt', 'first'),
      finalAnswerScript,
      writeFileScript('~/workspace/b.txt', 'second'),
      finalAnswerScript,
    ]));
    final session = await newSession();
    final controller = container.read(chatControllerProvider(session.id).notifier);
    unawaited(controller.send('写 a.txt'));
    await waitFor(
      () => container.read(chatControllerProvider(session.id)).pendingPermission != null,
    );
    controller.resolvePermission(PermissionChoice.always);
    await waitTurnEnd(container, session.id);

    final rulesFile = File('${workspaceDir.path}/.codecraft/permissions.json');
    expect(rulesFile.existsSync(), isTrue);
    expect(rulesFile.readAsStringSync(), contains('"writeFile"'));

    // 第二次同工具调用:规则命中 → 不再弹窗,直接执行。
    // 记录当前消息数:只判「不在流式」会在第二轮还没起来时立刻满足而误判。
    final beforeSecond = container.read(chatControllerProvider(session.id)).messages.length;
    unawaited(controller.send('再写 b.txt'));
    await waitTurnEnd(container, session.id, minMessages: beforeSecond + 2);
    expect(
      container.read(chatControllerProvider(session.id)).pendingPermission,
      isNull,
      reason: '已记忆的规则应免去弹窗',
    );
    expect(File('${workspaceDir.path}/b.txt').readAsStringSync(), 'second');
  });

  test('选「拒绝」:工具结果落库为 USER_REJECTED', () async {
    await boot(QueueTransport([writeFileScript('~/workspace/c.txt', 'no'), finalAnswerScript]));
    final session = await newSession();
    final controller = container.read(chatControllerProvider(session.id).notifier);
    unawaited(controller.send('写 c.txt'));
    await waitFor(
      () => container.read(chatControllerProvider(session.id)).pendingPermission != null,
    );
    controller.resolvePermission(PermissionChoice.reject);
    await waitTurnEnd(container, session.id);
    final stored = await db.messageDao.listBySession(session.id);
    final toolMessage = stored.firstWhere((m) => m.role == MessageRole.tool);
    expect(toolMessage.isError, isTrue);
    expect(toolMessage.content, contains('USER_REJECTED'));
    expect(toolMessage.content, contains('用户拒绝执行该工具'));
    expect(File('${workspaceDir.path}/c.txt').existsSync(), isFalse);
  });

  test('全局 deny 规则:跨作用域优先,直接拒绝', () async {
    File('${configDir.path}/permissions.json').writeAsStringSync(
      '{"permissions":{"deny":["writeFile"]}}',
    );
    await boot(QueueTransport([writeFileScript('~/workspace/f.txt', 'x'), finalAnswerScript]));
    final session = await newSession();
    unawaited(container.read(chatControllerProvider(session.id).notifier).send('写 f.txt'));
    await waitTurnEnd(container, session.id);
    final stored = await db.messageDao.listBySession(session.id);
    final toolMessage = stored.firstWhere((m) => m.role == MessageRole.tool);
    expect(toolMessage.isError, isTrue);
    expect(toolMessage.content, contains('SYSTEM_DENIED'));
    expect(toolMessage.content, contains('禁止执行'));
  });
}