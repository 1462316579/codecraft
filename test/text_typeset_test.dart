import 'package:codecraft/core/util/text_typeset.dart';
import 'package:flutter_test/flutter_test.dart';

/// 写作项目「自动排版」与字数统计(纯函数)。
void main() {
  group('段落整理', () {
    test('普通段落首行缩进两个全角空格', () {
      expect(typesetText('天玄大陆。'), '\u3000\u3000天玄大陆。');
    });

    test('去掉每行首尾空白', () {
      expect(typesetText('   天玄大陆。   \n'), '\u3000\u3000天玄大陆。\n');
    });

    test('连续空行合并成一个', () {
      expect(
        typesetText('第一段\n\n\n\n第二段\n'),
        '\u3000\u3000第一段\n\n\u3000\u3000第二段\n',
      );
    });

    test('文末多余空行去掉,但保留结尾换行', () {
      expect(typesetText('一段\n\n\n'), '\u3000\u3000一段\n');
    });

    test('原文没有结尾换行就不补', () {
      expect(typesetText('一段'), '\u3000\u3000一段');
    });

    test('CRLF 统一成 LF', () {
      expect(typesetText('第一段\r\n第二段\r\n'), '\u3000\u3000第一段\n\u3000\u3000第二段\n');
    });

    test('空文件原样返回', () {
      expect(typesetText(''), '');
    });
  });

  group('标点全角化', () {
    test('中文旁的半角标点转全角', () {
      expect(typesetText('你好,世界.'), '\u3000\u3000你好,世界。');
    });

    test('问号叹号冒号分号括号都转', () {
      expect(
        typesetText('什么?真的!他说:"好"(笑)'),
        '\u3000\u3000什么?真的!他说:“好”(笑)',
      );
    });

    test('全角标点后的多余空格去掉', () {
      expect(typesetText('打熬筋骨, 引气入体'), '\u3000\u3000打熬筋骨,引气入体');
    });

    test('小数不被当成句号', () {
      expect(typesetText('圆周率是3.14'), '\u3000\u3000圆周率是3.14');
    });

    test('网址里的冒号与点保持原样', () {
      expect(
        typesetText('见 http://a.b/c 说明'),
        '\u3000\u3000见 http://a.b/c 说明',
      );
    });

    test('英文句子不动', () {
      expect(typesetText('Hello, world. Fine!'), '\u3000\u3000Hello, world. Fine!');
    });

    test('中文引号按顺序成对转换', () {
      expect(typesetText('他说:"你好"'), '\u3000\u3000他说:“你好”');
    });
  });

  group('Markdown 结构不被破坏', () {
    test('标题不缩进', () {
      expect(typesetText('# 世界观设定\n'), '# 世界观设定\n');
    });

    test('列表项不缩进', () {
      expect(
        typesetText('- 打熬筋骨, 引气入体\n'),
        '- 打熬筋骨,引气入体\n',
      );
    });

    test('有序列表的编号点号不转全角', () {
      expect(typesetText('1. 炼体\n'), '1. 炼体\n');
    });

    test('引用与表格行不缩进', () {
      expect(typesetText('> 一句引用\n'), '> 一句引用\n');
      expect(typesetText('| 名称 | 说明 |\n'), '| 名称 | 说明 |\n');
    });

    test('分隔线保持原样', () {
      expect(typesetText('---\n'), '---\n');
    });

    test('代码块内部完全不动', () {
      const source = '正文\n\n```dart\nvoid main() {\n  print("hi, there.");\n}\n```\n';
      expect(
        typesetText(source),
        '\u3000\u3000正文\n\n```dart\nvoid main() {\n  print("hi, there.");\n}\n```\n',
      );
    });
  });

  group('字数统计', () {
    test('去掉空白后计数', () {
      expect(countWords('\u3000\u3000天玄大陆\n\n灵气充沛'), 8);
    });

    test('空文本为 0', () {
      expect(countWords(''), 0);
      expect(countWords('   \n\t'), 0);
    });
  });
}