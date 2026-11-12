import 'package:codecraft/core/util/git_ignore_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

/// `.gitignore` 匹配器:逐条对齐上游 GitIgnoreMatcher 的语义。
void main() {
  group('parse', () {
    test('去空行、注释与否定行,去掉目录尾斜杠', () {
      expect(
        GitIgnoreMatcher.parse(
          '\n# 注释\nnode_modules/\n!keep.txt\n*.log\n  build/  \n',
        ),
        ['node_modules', '*.log', 'build'],
      );
    });

    test('空内容得到空列表', () {
      expect(GitIgnoreMatcher.parse(''), isEmpty);
    });
  });

  group('matches', () {
    test('*.ext 匹配任意层级的文件名后缀', () {
      expect(GitIgnoreMatcher.matches('*.log', ['app.log']), isTrue);
      expect(GitIgnoreMatcher.matches('*.log', ['logs', 'app.log']), isTrue);
      expect(GitIgnoreMatcher.matches('*.log', ['logs', 'app.txt']), isFalse);
    });

    test('目录名匹配其自身与任意层级的同名目录(含其子路径)', () {
      expect(GitIgnoreMatcher.matches('build', ['build']), isTrue);
      expect(GitIgnoreMatcher.matches('build', ['src', 'build']), isTrue);
      // 规则段数少于路径段数时,从任意起点开窗比较:只要有一段相等就算命中
      // (与上游一致——它的作用是「弱化显示」,宁可多标不可漏标)。
      expect(GitIgnoreMatcher.matches('build', ['src', 'build', 'out.o']), isTrue);
    });

    test('带斜杠的规则按路径段匹配', () {
      expect(GitIgnoreMatcher.matches('src/gen', ['src', 'gen']), isTrue);
      expect(GitIgnoreMatcher.matches('src/gen', ['other', 'src', 'gen']), isTrue,
          reason: '非锚定时可从任意层开始');
    });

    test('anchored 只从根开始匹配', () {
      expect(GitIgnoreMatcher.matches('src/gen', ['src', 'gen'], anchored: true), isTrue);
      expect(GitIgnoreMatcher.matches('src/gen', ['other', 'src', 'gen'], anchored: true),
          isFalse);
    });

    test('**/ 前缀强制任意层级(anchored 也生效)', () {
      expect(
        GitIgnoreMatcher.matches('**/tmp', ['a', 'b', 'tmp'], anchored: true),
        isTrue,
      );
    });

    test('段内 * 通配', () {
      expect(GitIgnoreMatcher.matches('*.dart', ['main.dart']), isTrue);
      expect(GitIgnoreMatcher.matches('gen-*', ['gen-a']), isTrue);
      expect(GitIgnoreMatcher.matches('gen-*', ['other']), isFalse);
    });

    test('** 段匹配任意一段', () {
      expect(GitIgnoreMatcher.matches('a/**/z', ['a', 'b', 'z']), isTrue);
      expect(GitIgnoreMatcher.matches('a/**/z', ['a', 'z']), isFalse,
          reason: '** 占一段,路径段数不足');
    });

    test('空模式与纯斜杠不匹配任何东西', () {
      expect(GitIgnoreMatcher.matches('', ['a']), isFalse);
      expect(GitIgnoreMatcher.matches('/', ['a']), isFalse);
      // `**/` 先被去尾斜杠变成 `**`,于是按单段 `**` 规则命中任意单段路径
      // (上游 trimEnd('/') 在前,行为相同;只影响「整条规则就是 **/」这种写法)。
      expect(GitIgnoreMatcher.matches('**/', ['a']), isTrue);
    });

    test('isIgnored 任一命中即为真', () {
      const patterns = ['node_modules', '*.log'];
      expect(GitIgnoreMatcher.isIgnored(patterns, ['node_modules']), isTrue);
      expect(GitIgnoreMatcher.isIgnored(patterns, ['app.log']), isTrue);
      expect(GitIgnoreMatcher.isIgnored(patterns, ['src', 'main.dart']), isFalse);
    });
  });
}