import 'package:codecraft/data/git/container_git.dart';
import 'package:flutter_test/flutter_test.dart';

/// git 输出里带引号路径的还原(`unquoteGitPath`)。
///
/// 重点是八进制转义的多字节还原:git 逐字节输出 `\344\270\255`,若逐段转字符就会得到
/// 三个 Latin-1 字符(Git 页中文目录名乱码的成因),必须攒成字节序列后整体按 UTF-8 解码。
void main() {
  test('普通路径原样返回', () {
    expect(unquoteGitPath('src/Main.kt'), 'src/Main.kt');
    expect(unquoteGitPath('中文目录/文件.txt'), '中文目录/文件.txt');
  });

  test('带引号且含空格的路径', () {
    expect(unquoteGitPath('"c d.txt"'), 'c d.txt');
  });

  test('引号与反斜杠的转义', () {
    expect(unquoteGitPath(r'"a\"b.txt"'), 'a"b.txt');
    expect(unquoteGitPath(r'"a\\b.txt"'), r'a\b.txt');
  });

  test('控制字符转义', () {
    expect(unquoteGitPath(r'"a\tb.txt"'), 'a\tb.txt');
    expect(unquoteGitPath(r'"a\nb.txt"'), 'a\nb.txt');
    expect(unquoteGitPath(r'"a\001b.txt"'), 'a\u0001b.txt');
  });

  test('八进制 UTF-8 按整体字节序列解码', () {
    expect(unquoteGitPath(r'"\344\270\255\346\226\207"'), '中文');
    expect(
      unquoteGitPath(
        r'"\344\270\255\346\226\207\347\233\256\345\275\225/\346\226\207\344\273\266.txt"',
      ),
      '中文目录/文件.txt',
    );
  });

  test('八进制与 ASCII 混排', () {
    expect(unquoteGitPath(r'"\344\270\255 \346\226\207.txt"'), '中 文.txt');
    expect(unquoteGitPath(r'"中文\001名.txt"'), '中文\u0001名.txt');
  });

  test('转义表覆盖 a/b/f/v', () {
    expect(unquoteGitPath(r'"a\ab"'), 'a\u0007b');
    expect(unquoteGitPath(r'"a\bb"'), 'a\bb');
    expect(unquoteGitPath(r'"a\fb"'), 'a\u000Cb');
    expect(unquoteGitPath(r'"a\vb"'), 'a\u000Bb');
  });

  test('未知转义保留反斜杠(对齐上游:只前进一个字符)', () {
    expect(unquoteGitPath(r'"a\qb"'), r'a\qb');
  });
}