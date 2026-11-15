import 'dart:io';

import 'package:codecraft/data/novel_project.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// 旧写作布局迁移:内容原本在 `AI小说/小说章节` 等根级目录,工作区改成
/// `AI小说/<书名>` 后要搬进小说目录。
void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('novel-migration-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  const title = '穿越女频只为救女';

  test('把旧根级目录内容搬进小说目录,并删除空的旧目录', () async {
    await NovelScaffold.create(root.path, title);
    await File(p.join(root.path, '小说章节', '第1章.md')).create(recursive: true);
    await File(p.join(root.path, '角色关联', '主角.md')).create(recursive: true);
    await File(p.join(root.path, '小说资料', '小说大纲.md'))
        .create(recursive: true)
        .then((file) => file.writeAsString('旧大纲'));

    final moved = await NovelScaffold.migrateLegacyLayout(root.path, title);

    expect(moved, 3);
    final novel = p.join(root.path, NovelScaffold.dirName(title));
    expect(await File(p.join(novel, '小说章节', '第1章.md')).exists(), isTrue);
    expect(await File(p.join(novel, '角色关联', '主角.md')).exists(), isTrue);
    // 目标里原本是 0 字节脚手架占位,应被旧的正文替换。
    expect(
      await File(p.join(novel, '小说资料', '小说大纲.md')).readAsString(),
      '旧大纲',
    );
    // 搬空的旧目录被删除。
    expect(await Directory(p.join(root.path, '小说章节')).exists(), isFalse);
  });

  test('目标已有非空同名文件时跳过,不覆盖用户内容', () async {
    await NovelScaffold.create(root.path, title);
    final novel = p.join(root.path, NovelScaffold.dirName(title));
    final existing = File(p.join(novel, '小说章节', '第1章.md'));
    await existing.create(recursive: true);
    await existing.writeAsString('新内容');
    await File(p.join(root.path, '小说章节', '第1章.md'))
        .create(recursive: true)
        .then((file) => file.writeAsString('旧内容'));

    final moved = await NovelScaffold.migrateLegacyLayout(root.path, title);

    expect(moved, 0);
    expect(await existing.readAsString(), '新内容');
    // 未搬运的旧文件保留在原处,不丢数据。
    expect(await File(p.join(root.path, '小说章节', '第1章.md')).exists(), isTrue);
  });

  test('重复调用不再搬运(幂等)', () async {
    await NovelScaffold.create(root.path, title);
    await File(p.join(root.path, '小说章节', '第1章.md')).create(recursive: true);

    expect(await NovelScaffold.migrateLegacyLayout(root.path, title), 1);
    expect(await NovelScaffold.migrateLegacyLayout(root.path, title), 0);

    final novel = p.join(root.path, NovelScaffold.dirName(title));
    final files = await Directory(p.join(novel, '小说章节')).list().toList();
    expect(files.length, 1);
  });

  test('没有旧目录时不动任何文件', () async {
    await NovelScaffold.create(root.path, title);

    expect(await NovelScaffold.migrateLegacyLayout(root.path, title), 0);

    final novel = p.join(root.path, NovelScaffold.dirName(title));
    expect(
      await File(p.join(novel, '小说资料', '小说大纲.md')).exists(),
      isTrue,
    );
  });
}
