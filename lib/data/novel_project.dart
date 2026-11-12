import 'dart:io';

import 'package:path/path.dart' as p;

/// 新建小说时收集的设定(向导提问的答案)。
class NovelSpec {
  const NovelSpec({
    required this.title,
    this.tags = const [],
    this.wordsPerChapter,
    this.gender,
  });

  final String title;
  final List<String> tags;
  final int? wordsPerChapter;
  /// 小说类型:男频 / 女频;为空表示未选择。
  final String? gender;
}

/// 写作项目的小说目录脚手架:创建小说后在写作工作区根目录下建立固定结构。
///
/// <写作根>/<书名>/
/// ├── 角色关联/        存放角色
/// ├── 小说资料/        小说大纲.md、卷纲.md、人物库.md、世界观.md、章节摘要.md
/// └── 小说章节/        存放章节内容
class NovelScaffold {
  NovelScaffold._();

  static const String charactersDirName = '角色关联';
  static const String materialsDirName = '小说资料';
  static const String chaptersDirName = '小说章节';

  /// 小说资料目录下的五个空文件(与 AI 对话时按需填充)。
  static const List<String> materialFiles = [
    '小说大纲.md',
    '卷纲.md',
    '人物库.md',
    '世界观.md',
    '章节摘要.md',
  ];

  /// 书名转目录名:去掉文件系统非法字符与首尾空白/句点;过长截断。
  static String dirName(String title) {
    var name = title.trim().replaceAll(RegExp(r'[/\\:*?"<>|\r\n\t]'), '').trim();
    // 去掉首尾句点(Windows/SAF 对尾句点目录名不友好)
    while (name.startsWith('.')) {
      name = name.substring(1);
    }
    while (name.endsWith('.')) {
      name = name.substring(0, name.length - 1);
    }
    if (name.length > 80) name = name.substring(0, 80);
    return name.isEmpty ? '未命名小说' : name;
  }

  /// 在 [writingRoot] 下为 [title] 建小说目录与固定结构;已存在时幂等补全。
  /// 返回小说目录;任何 IO 失败抛 [FileSystemException] 由调用方提示。
  static Future<Directory> create(String writingRoot, String title) async {
    final novelDir = Directory(p.join(writingRoot, dirName(title)));
    if (!await novelDir.exists()) {
      await novelDir.create(recursive: true);
    }
    final charactersPath = p.join(novelDir.path, charactersDirName);
    final characters = Directory(charactersPath);
    if (!await characters.exists()) {
      await characters.create(recursive: true);
    }
    final materialsPath = p.join(novelDir.path, materialsDirName);
    final materials = Directory(materialsPath);
    if (!await materials.exists()) {
      await materials.create(recursive: true);
    }
    for (final file in materialFiles) {
      final target = File(p.join(materialsPath, file));
      if (!await target.exists()) {
        await target.writeAsString('');
      }
    }
    final chapters = Directory(p.join(novelDir.path, chaptersDirName));
    if (!await chapters.exists()) {
      await chapters.create(recursive: true);
    }
    return novelDir;
  }
}