import 'dart:io';

import 'package:codecraft/agent/models/agent_message.dart';
import 'package:codecraft/agent/models/chat_session.dart';
import 'package:codecraft/data/session_export.dart';
import 'package:flutter_test/flutter_test.dart';

/// 会话导出(Markdown):内容完整、文件名安全、落在 exports 目录。
void main() {
  ChatSession session({String title = '测试会话'}) => ChatSession(
        id: 's1',
        title: title,
        createdAt: DateTime(2026, 10, 26, 10).millisecondsSinceEpoch,
        updatedAt: DateTime(2026, 10, 26, 11).millisecondsSinceEpoch,
        totalInputTokens: 120,
        totalOutputTokens: 80,
      );

  AgentMessage message(MessageRole role, String content, {int minute = 0}) => AgentMessage(
        id: 'm$minute',
        sessionId: 's1',
        role: role,
        content: content,
        timestamp: DateTime(2026, 10, 26, 10, minute).millisecondsSinceEpoch,
      );

  group('渲染 Markdown', () {
    test('含标题、元信息与全部消息', () {
      final markdown = SessionExporter.render(session(), [
        message(MessageRole.user, '你好', minute: 1),
        message(MessageRole.assistant, '你好,有什么可以帮你?', minute: 2),
      ]);
      expect(markdown, contains('# 测试会话'));
      expect(markdown, contains('会话 ID:s1'));
      expect(markdown, contains('120 输入 / 80 输出'));
      expect(markdown, contains('## 用户'));
      expect(markdown, contains('你好'));
      expect(markdown, contains('## 助手'));
      expect(markdown, contains('有什么可以帮你'));
    });

    test('未命名会话用占位标题', () {
      final markdown = SessionExporter.render(session(title: '  '), const []);
      expect(markdown, contains('未命名会话'));
    });

    test('工具消息标注工具名与失败状态', () {
      final toolMessage = AgentMessage(
        id: 'm3',
        sessionId: 's1',
        role: MessageRole.tool,
        content: '输出',
        timestamp: 0,
        toolName: 'Bash',
        isError: true,
      );
      final markdown = SessionExporter.render(session(), [toolMessage]);
      expect(markdown, contains('工具 Bash(失败)'));
    });

    test('思考过程放进折叠块', () {
      final withReasoning = AgentMessage(
        id: 'm4',
        sessionId: 's1',
        role: MessageRole.assistant,
        content: '答案',
        timestamp: 0,
        reasoning: '先想一下',
      );
      final markdown = SessionExporter.render(session(), [withReasoning]);
      expect(markdown, contains('<details><summary>思考过程</summary>'));
      expect(markdown, contains('先想一下'));
    });

    test('空消息内容不产生多余小节', () {
      final markdown = SessionExporter.render(session(), [
        message(MessageRole.user, '   '),
      ]);
      expect(markdown, contains('## 用户'));
      expect(markdown.trimRight().endsWith('_2026-10-26 10:00:00_'), isTrue);
    });
  });

  group('写文件', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('export-test'));
    tearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    test('写到 exports 目录,文件名含安全化标题', () async {
      final path = await SessionExporter(dir)
          .export(session(title: 'a/b:c*d'), [message(MessageRole.user, 'hi')]);
      expect(path, contains(dir.path));
      expect(File(path).existsSync(), isTrue);
      final name = path.split(Platform.pathSeparator).last;
      expect(name, startsWith('codecraft-session-a_b_c_d-'));
      expect(name, endsWith('.md'));
      expect(File(path).readAsStringSync(), contains('# a/b:c*d'));
    });

    test('目录不存在时自动创建', () async {
      final nested = Directory('${dir.path}/deep/exports');
      final path = await SessionExporter(nested).export(session(), const []);
      expect(File(path).existsSync(), isTrue);
    });

    test('超长标题被截断,避免超出文件名上限', () async {
      final path = await SessionExporter(dir).export(session(title: 'x' * 200), const []);
      final name = path.split(Platform.pathSeparator).last;
      expect(name.length, lessThan(120));
    });
  });
}