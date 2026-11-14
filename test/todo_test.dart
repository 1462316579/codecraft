import 'dart:ffi';

import 'package:codecraft/agent/models/agent_message.dart';
import 'package:codecraft/agent/models/todo_item.dart';
import 'package:codecraft/agent/tools/todo_tool.dart';
import 'package:codecraft/agent/tools/tool.dart';
import 'package:codecraft/data/db/app_database.dart';
import 'package:codecraft/data/db/daos.dart';
import 'package:codecraft/data/todos.dart';
import 'package:codecraft/features/chat/widgets/message_bubble.dart';
import 'package:codecraft/features/chat/widgets/todo_views.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../lib/core/icons/iconfont.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';

TodoItem todo(
  String subject, {
  TodoStatus status = TodoStatus.pending,
  String description = '',
}) =>
    TodoItem(
      id: subject,
      sessionId: 's1',
      subject: subject,
      description: description,
      status: status,
      createdAt: 0,
      updatedAt: 0,
    );

void main() {
  group('todo 工具', () {
    late AppDatabase db;
    late TodoTool tool;

    setUpAll(() {
      open.overrideFor(
          OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfiNoIsolate;
    });

    setUp(() async {
      db = await AppDatabase.open(inMemory: true);
      tool = TodoTool(db.todoDao);
    });

    tearDown(() => db.close());

    Future<ToolResult> run(Object? items, {String? sessionId = 's1'}) =>
        tool.execute({'items': items}, sessionId: sessionId);

    test('快照替换:写入清单并返回完成度与逐项字段', () async {
      final result = await run([
        {'subject': '分析项目结构', 'status': 'completed', 'priority': 2},
        {'subject': '实现工具', 'description': '对齐上游', 'status': 'in_progress'},
        '写测试',
      ]);

      final data = (result as ToolSuccess).data as Map<String, dynamic>;
      expect(data['total'], 3);
      expect(data['completed'], 1);
      final items = (data['items'] as List).cast<Map<String, dynamic>>();
      expect(items.map((item) => item['subject']), ['分析项目结构', '实现工具', '写测试']);
      expect(items[0]['status'], 'completed');
      expect(items[0]['priority'], 2);
      expect(items[0]['order'], 0);
      expect(items[1]['status'], 'in_progress');
      expect(items[1]['description'], '对齐上游');
      expect(items[2]['status'], 'pending', reason: '未给 status 时落下为 pending');
      expect(items[2]['description'], '');
    });

    test('同标题(忽略大小写与首尾空格)复用旧条目的 id 与创建时间', () async {
      await run(['Step One']);
      final first = (await db.todoDao.listBySession('s1')).single;
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await run([
        {'subject': ' step one ', 'status': 'completed'},
      ]);
      final second = (await db.todoDao.listBySession('s1')).single;
      expect(second.id, first.id);
      expect(second.createdAt, first.createdAt);
      expect(second.updatedAt, greaterThan(first.updatedAt));
      expect(second.status, TodoStatus.completed);
      expect(second.subject, 'step one');
    });

    test('重复标题按出现顺序一对一复用', () async {
      await run(['A', 'A']);
      final before = await db.todoDao.listBySession('s1');
      await run(['A', 'A']);
      final after = await db.todoDao.listBySession('s1');
      expect(after.length, 2);
      expect(after[0].id, before[0].id);
      expect(after[1].id, before[1].id);
      expect(after[0].id, isNot(after[1].id));
    });

    test('空数组清空清单', () async {
      await run(['A']);
      final cleared = await run([]);
      expect(
          ((cleared as ToolSuccess).data as Map<String, dynamic>)['total'], 0);
      expect(await db.todoDao.listBySession('s1'), isEmpty);
    });

    test('缺 items / 缺标题 / 非法 status 各自报错,且失败不破坏原清单', () async {
      await run(['保留我']);

      final missing = await tool.execute(const {}, sessionId: 's1');
      expect((missing as ToolError).code, 'MISSING_ITEMS');

      final noSubject = await run([
        {'description': '没有标题'},
      ]);
      expect((noSubject as ToolError).code, 'INVALID_ITEM');
      expect(noSubject.message, '第 1 项缺少字符串标题或 subject 字段');

      final badStatus = await run([
        {'subject': 'A', 'status': 'later'},
      ]);
      expect((badStatus as ToolError).message, '待办操作失败:第 1 项 status 无效');

      final kept = await db.todoDao.listBySession('s1');
      expect(kept.map((item) => item.subject), ['保留我']);
    });

    test('未关联会话返回 NO_SESSION', () async {
      final result = await tool.execute({'items': <Object>[]});
      expect((result as ToolError).code, 'NO_SESSION');
    });

    test('工具结果可解析成 UI 快照;错误与非 JSON 返回 null', () async {
      final result = await run([
        {'subject': 'A', 'status': 'completed'},
        'B',
      ]);
      final snapshot = TodoSnapshot.parseToolResult(result.toTransportString());
      expect(snapshot, isNotNull);
      expect(snapshot!.total, 2);
      expect(snapshot.completed, 1);
      expect(snapshot.items.map((item) => item.subject), ['A', 'B']);
      expect(snapshot.items.first.status, TodoStatus.completed);

      expect(TodoSnapshot.parseToolResult('{"status":"error","message":"x"}'),
          isNull);
      expect(TodoSnapshot.parseToolResult('不是 JSON'), isNull);
    });
  });

  group('待办 UI', () {
    Future<void> pumpDashboard(
        WidgetTester tester, List<TodoItem> items) async {
      final container = ProviderContainer(
        overrides: [
          sessionTodosProvider.overrideWith((ref, sessionId) => items)
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: TodoDashboardBar(sessionId: 's1'),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('面板显示标题与进度,折叠态摘要进行中的任务,点开看全部', (tester) async {
      await pumpDashboard(tester, [
        todo('分析项目', status: TodoStatus.completed),
        todo('实现工具', status: TodoStatus.inProgress, description: '对齐上游'),
        todo('写测试'),
      ]);

      expect(find.text('任务待办'), findsOneWidget);
      expect(find.text('1/3 完成'), findsOneWidget);
      expect(find.text('实现工具'), findsOneWidget, reason: '折叠态显示进行中的任务');
      expect(find.text('分析项目'), findsNothing, reason: '折叠态不展开列表');

      await tester.tap(find.text('任务待办'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('分析项目'), findsOneWidget);
      expect(find.text('写测试'), findsOneWidget);
      expect(find.text('对齐上游'), findsOneWidget);
      expect(find.text('进行中'), findsOneWidget);
    });

    testWidgets('全部完成时进度胶囊改为「全部完成」', (tester) async {
      await pumpDashboard(tester, [
        todo('A', status: TodoStatus.completed),
        todo('B', status: TodoStatus.completed),
      ]);

      expect(find.text('全部完成'), findsOneWidget);
      expect(find.text('任务待办'), findsOneWidget);
    });

    testWidgets('无待办时不渲染面板', (tester) async {
      await pumpDashboard(tester, const []);
      expect(find.text('任务待办'), findsNothing);
    });

    testWidgets('工具行图标:todo 用对勾(对齐上游 toolIcon)', (tester) async {
      expect(toolIconFor('todo'), Iconfont.check);
      expect(toolIconFor('Todo'), Iconfont.check, reason: '工具名忽略大小写');
      expect(toolIconFor('bash'), Iconfont.terminal);
      expect(toolIconFor('unknownTool'), Iconfont.wrench,
          reason: '未归类工具回落通用图标');

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: ToolRow(
                name: 'todo',
                args: '{"items":[]}',
                result:
                    '{"status":"success","data":{"total":0,"completed":0,"items":[]}}'),
          ),
        ),
      );

      expect(find.byIcon(Iconfont.check), findsOneWidget);
    });

    testWidgets('执行中场景文案:todo 说「正在整理待办」,空闲说「正在思考」', (tester) async {
      final l10n = lookupAppLocalizations(const Locale('zh'));
      expect(toolRunningLabel(l10n, 'todo'), '正在整理待办');
      expect(toolRunningLabel(l10n, 'bash'), '正在执行命令');
      expect(toolRunningLabel(l10n, 'mcp__github__search'), '正在调用工具',
          reason: 'MCP 动态工具回落通用文案');

      Future<void> pumpBubble(String? runningTool) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: MessageBubble(
                role: MessageRole.assistant,
                content: '',
                streaming: true,
                runningTool: runningTool,
              ),
            ),
          ),
        );
      }

      await pumpBubble('todo');
      expect(find.text('正在整理待办'), findsOneWidget);

      await pumpBubble(null);
      expect(find.text('正在思考'), findsOneWidget);
    });

    testWidgets('工具行:todo 结果显示计数与结构化卡片', (tester) async {
      const result =
          '{"status":"success","data":{"total":2,"completed":1,"items":['
          '{"id":"1","subject":"分析项目","description":"","status":"completed","priority":0,"order":0},'
          '{"id":"2","subject":"实现工具","description":"","status":"pending","priority":0,"order":1}]}}';
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: ToolRow(name: 'todo', args: '{"items":[]}', result: result),
          ),
        ),
      );

      expect(find.text('todo'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget, reason: '标题行行尾显示完成度');

      await tester.tap(find.text('todo'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('分析项目'), findsOneWidget);
      expect(find.text('实现工具'), findsOneWidget);
      expect(find.text('"items"'), findsNothing, reason: '待办结果不展示原始 JSON');
    });
  });
}
