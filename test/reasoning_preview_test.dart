import 'package:codecraft/features/chat/widgets/message_bubble.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('思考折叠行预览(对齐上游 reasoningPreviewLine)', () {
    test('进行中取最后一行,跟着模型正在写的内容滚动', () {
      const text = '先分析项目结构\n再确认依赖\n正在读 chat_page';
      expect(reasoningPreviewLine(text, live: true), '正在读 chat_page');
    });

    test('结束后固定取第一行', () {
      const text = '先分析项目结构\n再确认依赖\n正在读 chat_page';
      expect(reasoningPreviewLine(text, live: false), '先分析项目结构');
    });

    test('末尾是空行时进行中取上一条有内容的行', () {
      const text = '第一行\n第二行\n\n  \n';
      expect(reasoningPreviewLine(text, live: true), '第二行');
    });

    test('全是空白时返回空串,交给调用方回落文案', () {
      expect(reasoningPreviewLine('   \n\n  ', live: true), '');
      expect(reasoningPreviewLine('', live: false), '');
    });

    test('结束后跳过开头空行取首个非空行', () {
      const text = '\n\n  正文开始\n后续';
      expect(reasoningPreviewLine(text, live: false), '正文开始');
    });
  });
}
