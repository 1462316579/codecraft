import 'package:codecraft/core/util/line_diff.dart';
import 'package:flutter_test/flutter_test.dart';

/// 移植自上游 `app/src/test/java/com/codecraft/core/util/LineDiffTest.kt`。
DiffLine ctx(String text) => DiffLine(DiffLineType.context, text);
DiffLine add(String text) => DiffLine(DiffLineType.add, text);
DiffLine del(String text) => DiffLine(DiffLineType.remove, text);

void main() {
  group('diff', () {
    test('完全相同只产出上下文行', () {
      expect(LineDiff.diff('a\nb\nc', 'a\nb\nc'), [ctx('a'), ctx('b'), ctx('c')]);
    });

    test('单行相同是上下文', () {
      expect(LineDiff.diff('hello', 'hello'), [ctx('hello')]);
    });

    test('纯插入产出新增行', () {
      expect(LineDiff.diff('', 'a\nb'), [del(''), add('a'), add('b')]);
    });

    test('中间插入产出新增', () {
      expect(LineDiff.diff('a\nc', 'a\nb\nc'), [ctx('a'), add('b'), ctx('c')]);
    });

    test('纯删除产出删除行', () {
      expect(LineDiff.diff('a\nb', ''), [del('a'), del('b'), add('')]);
    });

    test('中间删除产出删除', () {
      expect(LineDiff.diff('a\nb\nc', 'a\nc'), [ctx('a'), del('b'), ctx('c')]);
    });

    test('中间行修改产出先删后增', () {
      expect(LineDiff.diff('a\nb\nc', 'a\nx\nc'), [ctx('a'), del('b'), add('x'), ctx('c')]);
    });

    test('相邻重复行优先按删除处理', () {
      expect(LineDiff.diff('a\nb', 'b'), [del('a'), ctx('b')]);
    });

    test('两侧都为空产出一行空上下文', () {
      expect(LineDiff.diff('', ''), [ctx('')]);
    });

    test('中间空行是上下文', () {
      expect(LineDiff.diff('a\n\nb', 'a\n\nb'), [ctx('a'), ctx(''), ctx('b')]);
    });

    test('多行混合改动', () {
      expect(
        LineDiff.diff('l1\nl2\nl3\nl4', 'l1\nl2x\nl4\nl5'),
        [ctx('l1'), del('l2'), del('l3'), add('l2x'), ctx('l4'), add('l5')],
      );
    });

    test('末尾换行新增表现为空新增行', () {
      expect(LineDiff.diff('a', 'a\n'), [ctx('a'), add('')]);
    });

    test('末尾换行删除表现为空删除行', () {
      expect(LineDiff.diff('a\n', 'a'), [ctx('a'), del('')]);
    });
  });

  group('toUnified', () {
    test('每行按类型加前缀', () {
      expect(LineDiff.toUnified('a\nb\nc', 'a\nx\nc'), ' a\n-b\n+x\n c');
    });

    test('完全相同用空格前缀', () {
      expect(LineDiff.toUnified('hello', 'hello'), ' hello');
    });
  });
}