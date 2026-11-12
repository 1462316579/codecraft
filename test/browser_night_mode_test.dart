import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 浏览器夜间模式注入脚本必须是**合法 JS**。
///
/// 真实 bug 历史:Dart 三引号里把正则写成 4 个反斜杠,Dart 求值后 JS 收到 2 个,
/// 正则抛 `SyntaxError: Unterminated group`,整段脚本不执行 → 点夜间模式毫无反应。
/// 这类错误 dart analyze 查不出来,只能校验源码里的反斜杠数量。
void main() {
  late String source;

  setUpAll(() {
    source = File('lib/data/browser/browser_manager.dart').readAsStringSync();
  });

  /// 抽出 `static const String <name> = '''...''';` 的正文。
  String scriptBody(String name) {
    final marker = "static const String $name = '''";
    final start = source.indexOf(marker);
    expect(start, greaterThan(-1), reason: '应能找到 $name');
    final bodyStart = start + marker.length;
    final bodyEnd = source.indexOf("''';", bodyStart);
    expect(bodyEnd, greaterThan(bodyStart), reason: '$name 应有结束引号');
    return source.substring(bodyStart, bodyEnd);
  }

  /// 源码里某行的反斜杠连续长度(Dart 源码字符层面)。
  int backslashRun(String line, int fromIndex) {
    var count = 0;
    for (var i = fromIndex; i < line.length && line[i] == r'\'; i++) {
      count++;
    }
    return count;
  }

  group('夜间模式注入脚本', () {
    test('正则的转义层数正确(JS 必须收到单反斜杠)', () {
      final body = scriptBody('_nightOnScript');
      final line = body.split('\n').firstWhere((l) => l.contains('c.match('));

      // 抓 `c.match(` 之后第一处反斜杠,检查连续个数。
      final after = line.substring(line.indexOf('c.match('));
      final firstBackslash = after.indexOf(r'\');
      expect(firstBackslash, greaterThan(-1), reason: '正则里应有转义');

      // Dart 源码必须写 **两个** 反斜杠:求值后 JS 得到 1 个(合法)。
      // 写 1 个 → JS 得到 0 个(`(` 变分组);写 4 个 → JS 得到 2 个(非法正则)。
      final run = backslashRun(after, firstBackslash);
      expect(run, 2,
          reason: 'Dart 源码应为 2 个反斜杠(JS 收到 1 个),实际 $run 个:$line');
    });

    test('整个正则行不含 4 连反斜杠', () {
      final body = scriptBody('_nightOnScript');
      final line = body.split('\n').firstWhere((l) => l.contains('c.match('));
      expect(line.contains(r'\\\\'), isFalse,
          reason: '出现 4 连反斜杠会让 JS 收到 2 个,正则报 Unterminated group:$line');
    });

    test('开启脚本会插入压暗蒙版并设置 color-scheme', () {
      final body = scriptBody('_nightOnScript');
      expect(body, contains('colorScheme'));
      expect(body, contains(r'$_nightStyleId'));
      expect(body, contains(r'$_nightCss'));
      expect(body, contains('isDark'));
    });

    test('关闭脚本会移除蒙版并恢复 color-scheme', () {
      final body = scriptBody('_nightOffScript');
      expect(body, contains('removeChild'));
      expect(body, contains(r'$_nightStyleId'));
      expect(body, contains("meta.content = 'light'"));
    });

    test('两个脚本的花括号配平', () {
      for (final name in ['_nightOnScript', '_nightOffScript']) {
        final body = scriptBody(name);
        var depth = 0;
        for (var i = 0; i < body.length; i++) {
          if (body[i] == r'\') {
            i++; // 跳过被转义的字符
            continue;
          }
          if (body[i] == '{') depth++;
          if (body[i] == '}') depth--;
          expect(depth, greaterThanOrEqualTo(0), reason: '$name 花括号不配平');
        }
        expect(depth, 0, reason: '$name 花括号应配平');
      }
    });
  });
}
