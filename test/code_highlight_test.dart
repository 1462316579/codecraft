import 'package:codecraft/core/util/code_highlight.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('扩展名 → 语言', () {
    test('对齐上游 inferSyntaxLanguage 的映射', () {
      expect(syntaxLanguageFor('a/b/Main.kt'), 'kotlin');
      expect(syntaxLanguageFor('Main.kts'), 'kotlin');
      expect(syntaxLanguageFor('A.java'), 'java');
      expect(syntaxLanguageFor('m.py'), 'python');
      expect(syntaxLanguageFor('a.mjs'), 'javascript');
      expect(syntaxLanguageFor('a.ts'), 'typescript');
      expect(syntaxLanguageFor('a.go'), 'go');
      expect(syntaxLanguageFor('a.rb'), 'ruby');
      expect(syntaxLanguageFor('a.php'), 'php');
      expect(syntaxLanguageFor('a.swift'), 'swift');
      expect(syntaxLanguageFor('a.rs'), 'rust');
      expect(syntaxLanguageFor('a.c'), 'cpp');
      expect(syntaxLanguageFor('a.hpp'), 'cpp');
      expect(syntaxLanguageFor('a.cs'), 'cs');
      expect(syntaxLanguageFor('a.sh'), 'shell');
      expect(syntaxLanguageFor('a.dart'), 'dart');
      expect(syntaxLanguageFor('a.pl'), 'perl');
      expect(syntaxLanguageFor('a.coffee'), 'coffeescript');
    });

    test('未识别扩展名与无扩展名返回 null', () {
      expect(syntaxLanguageFor('README'), isNull);
      expect(syntaxLanguageFor('a.txt'), isNull);
      expect(syntaxLanguageFor('a.KT'), 'kotlin', reason: '大写扩展名同样识别');
    });
  });

  group('高亮区间', () {
    const code = "void main() {\n  // 注释\n  print('hi');\n}\n";

    test('返回按偏移升序的区间,且覆盖关键字与字符串', () {
      final spans = highlightSpans(code, 'dart', dark: false);
      expect(spans, isNotEmpty);
      for (var i = 1; i < spans.length; i++) {
        expect(spans[i].start, greaterThanOrEqualTo(spans[i - 1].end));
      }
      // 字符串 token 用 GitHub light 的 #032f62。
      expect(
        spans.any((s) => s.style.color == const Color(0xFF032F62)),
        isTrue,
        reason: "'hi' 应着色为字符串色",
      );
    });

    test('颜色随深浅色主题变化', () {
      final light = highlightSpans(code, 'dart', dark: false);
      final dark = highlightSpans(code, 'dart', dark: true);
      expect(light.first.style.color, isNot(dark.first.style.color));
    });

    test('语言未知或代码为空白时返回空', () {
      expect(highlightSpans(code, null, dark: false), isEmpty);
      expect(highlightSpans('   \n  ', 'dart', dark: false), isEmpty);
    });

    test('区间不越界', () {
      for (final span in highlightSpans(code, 'dart', dark: false)) {
        expect(span.start, greaterThanOrEqualTo(0));
        expect(span.end, lessThanOrEqualTo(code.length));
        expect(span.end, greaterThan(span.start));
      }
    });
  });

  group('按行切片', () {
    const code = 'final a = 1;\nfinal b = 2;\n';

    test('行起始偏移含末行哨兵', () {
      // 末尾换行会产生一个空尾行,故哨兵比行数多一项(对齐上游 lineOffsets)。
      expect(lineStartOffsets(code), [0, 13, 26, 27]);
      expect(lineStartOffsets(''), [0, 1]);
    });

    test('切片把偏移换算为行内偏移', () {
      final spans = highlightSpans(code, 'dart', dark: false);
      final offsets = lineStartOffsets(code);
      final second = sliceSpansForLine(spans, offsets[1], offsets[2]);
      expect(second, isNotEmpty);
      for (final span in second) {
        expect(span.start, greaterThanOrEqualTo(0));
        expect(span.start, lessThan('final b = 2;'.length));
      }
      // 第二行的关键字色应与整段里出现的同色一致。
      expect(second.first.style.color, spans.firstWhere((s) => s.start == 0).style.color);
    });

    test('空区间或空行返回空', () {
      expect(sliceSpansForLine(const [], 0, 10), isEmpty);
      expect(sliceSpansForLine(highlightSpans(code, 'dart', dark: false), 5, 5), isEmpty);
    });
  });
}