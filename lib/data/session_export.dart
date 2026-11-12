import 'dart:io';

import 'package:path/path.dart' as p;

import '../agent/models/agent_message.dart';
import '../agent/models/chat_session.dart';

/// 会话导出:把一次对话导成可读的 Markdown 文件。
///
/// 与上游的差异(有意):上游导出 tar.gz 备份包(含附件、便于迁移),
/// 这里导出 Markdown——手机上没有解包工具,tar.gz 导出来也看不了,Markdown 可直接阅读与分享。
/// 需要严格迁移语义时应另做备份功能,而不是把导出做成压缩包。
class SessionExporter {
  SessionExporter(this.exportsDir);

  final Directory exportsDir;

  /// 导出为 `<exports>/codecraft-session-<标题>-<时间戳>.md`,返回文件路径。
  ///
  /// 文件名里的标题做安全化处理(去掉路径分隔符与文件系统保留字符),避免写出目录外。
  Future<String> export(ChatSession session, List<AgentMessage> messages) async {
    await exportsDir.create(recursive: true);
    final safeTitle = _safeName(session.title.trim().isEmpty ? 'untitled' : session.title);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(p.join(exportsDir.path, 'codecraft-session-$safeTitle-$stamp.md'));
    await file.writeAsString(render(session, messages));
    return file.path;
  }

  /// 渲染 Markdown 正文(纯函数,便于测试)。
  static String render(ChatSession session, List<AgentMessage> messages) {
    final buffer = StringBuffer()
      ..writeln('# ${session.title.trim().isEmpty ? '未命名会话' : session.title}')
      ..writeln()
      ..writeln('- 会话 ID:${session.id}')
      ..writeln('- 创建时间:${_formatTime(session.createdAt)}')
      ..writeln('- 更新时间:${_formatTime(session.updatedAt)}')
      ..writeln('- 模式:${session.mode.name}');
    final totalTokens = session.totalInputTokens + session.totalOutputTokens;
    if (totalTokens > 0) {
      buffer.writeln(
        '- Tokens:${session.totalInputTokens} 输入 / ${session.totalOutputTokens} 输出',
      );
    }
    buffer
      ..writeln()
      ..writeln('---')
      ..writeln();

    for (final message in messages) {
      // 压缩 marker 只是内部分隔符,导出件里跳过(接手摘要正常导出)。
      if (message.isCompactionMarker) continue;
      buffer
        ..writeln('## ${_roleLabel(message)}')
        ..writeln();
      final content = message.content.trim();
      if (content.isNotEmpty) {
        buffer
          ..writeln(content)
          ..writeln();
      }
      // 工具调用/结果只留一行摘要:导出件是给人看的,完整 JSON 会把正文淹掉。
      if (message.toolName != null && message.toolName!.isNotEmpty) {
        buffer
          ..writeln('> 工具 ${message.toolName}${message.isError ? '(失败)' : ''}')
          ..writeln();
      }
      final reasoning = message.reasoning?.trim();
      if (reasoning != null && reasoning.isNotEmpty) {
        buffer
          ..writeln('<details><summary>思考过程</summary>')
          ..writeln()
          ..writeln(reasoning)
          ..writeln()
          ..writeln('</details>')
          ..writeln();
      }
      buffer.writeln('_${_formatTime(message.timestamp)}_');
      buffer.writeln();
    }
    return buffer.toString();
  }

  static String _roleLabel(AgentMessage message) => switch (message.role) {
        MessageRole.user => '用户',
        MessageRole.assistant => '助手',
        MessageRole.tool => '工具结果',
      };

  static String _formatTime(int millis) {
    final time = DateTime.fromMillisecondsSinceEpoch(millis);
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }

  /// 文件名安全化:去掉路径分隔符与常见非法字符,压缩空白。
  static String _safeName(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'[/\\:*?"<>|\n\r\t]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
    final trimmed = cleaned.replaceAll(RegExp(r'^_+|_+$'), '');
    if (trimmed.isEmpty) return 'untitled';
    // 超长标题会撞文件系统上限。
    return trimmed.length <= 60 ? trimmed : trimmed.substring(0, 60);
  }
}