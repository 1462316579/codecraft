import 'dart:io';

import 'package:codecraft/data/novel_project.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('novel_scaffold_test');
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test('创建小说后建立固定目录结构', () async {
    final novelDir = await NovelScaffold.create(root.path, '星辰变');

    expect(novelDir.path, p.join(root.path, '星辰变'));
    expect(Directory(p.join(novelDir.path, '角色关联')).existsSync(), isTrue);
    expect(Directory(p.join(novelDir.path, '小说资料')).existsSync(), isTrue);
    expect(Directory(p.join(novelDir.path, '小说章节')).existsSync(), isTrue);

    for (final file in NovelScaffold.materialFiles) {
      final target = File(p.join(novelDir.path, '小说资料', file));
      expect(target.existsSync(), isTrue, reason: '$file 应为空文件');
      expect(target.readAsStringSync(), isEmpty);
    }
  });

  test('重复创建幂等:已存在的目录与文件不报错、不覆盖', () async {
    final novelDir = await NovelScaffold.create(root.path, '星辰变');
    // 预置一份内容,验证幂等创建不会清空
    final outline = File(p.join(novelDir.path, '小说资料', '小说大纲.md'));
    await outline.writeAsString('已有大纲');

    final again = await NovelScaffold.create(root.path, '星辰变');
    expect(again.path, novelDir.path);
    expect(outline.readAsStringSync(), '已有大纲');
  });

  test('书名去非法字符;空书名回退未命名小说', () {
    expect(NovelScaffold.dirName('我/的:小说?'), '我的小说');
    expect(NovelScaffold.dirName('  《测试》  '), '《测试》');
    expect(NovelScaffold.dirName('   '), '未命名小说');
    expect(NovelScaffold.dirName('a' * 100).length, 80);
  });

  test('书名首尾句点被去掉', () {
    expect(NovelScaffold.dirName('.隐身.'), '隐身');
  });
}