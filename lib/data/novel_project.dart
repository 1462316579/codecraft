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

/// 写作根下已有的一本小说(目录名即书名)。
class NovelInfo {
  const NovelInfo({
    required this.name,
    required this.path,
    required this.modified,
  });

  final String name;
  final String path;
  final DateTime modified;
}

/// 新建 / 选择已有小说的结果。
class NovelSelection {
  const NovelSelection.create(this.spec) : existingTitle = null;

  const NovelSelection.existing(this.existingTitle) : spec = null;

  /// 新建小说时收集的设定;选择已有小说时为 null。
  final NovelSpec? spec;

  /// 已有小说的目录名;新建小说时为 null。
  final String? existingTitle;

  bool get isExisting => existingTitle != null;

  String get title => existingTitle ?? spec!.title;
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

  /// 列出写作根下已有的小说目录(按最近修改倒序),用于「选择已有小说」。
  /// 目录不存在或不可读时返回空列表。
  static Future<List<NovelInfo>> list(String writingRoot) async {
    final root = Directory(writingRoot);
    if (!await root.exists()) return const [];
    final novels = <NovelInfo>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (name.isEmpty || name.startsWith('.')) continue;
      final stat = await entity.stat();
      novels.add(NovelInfo(name: name, path: entity.path, modified: stat.modified));
    }
    novels.sort((a, b) => b.modified.compareTo(a.modified));
    return novels;
  }

  /// 旧布局兼容:早期写作工作区根就是「AI小说」本身,章节/资料写在
  /// `AI小说/小说章节` 等根级目录;改成 `AI小说/<书名>` 后这些内容不在工作区里,
  /// 文件树会看起来是空的。把旧目录内容搬进小说目录:
  ///
  /// - 只处理三个固定目录,同名项已存在且非空时跳过(绝不覆盖用户内容);
  /// - 目标是 0 字节的脚手架占位文件时,用旧的非空文件替换;
  /// - 旧目录搬空后删除,仍有内容(其它书的残留)则保留;
  /// - 单条搬运失败只跳过该条,不抛出。
  ///
  /// 返回成功搬运的条目数。可重复执行。
  static Future<int> migrateLegacyLayout(String writingRoot, String title) async {
    final novelRoot = Directory(p.join(writingRoot, dirName(title)));
    if (!await novelRoot.exists()) return 0;
    var moved = 0;
    for (final name in const [charactersDirName, materialsDirName, chaptersDirName]) {
      final legacy = Directory(p.join(writingRoot, name));
      if (!await legacy.exists()) continue;
      final target = Directory(p.join(novelRoot.path, name));
      try {
        if (!await target.exists()) await target.create(recursive: true);
        await for (final entity in legacy.list(followLinks: false)) {
          final destPath = p.join(target.path, p.basename(entity.path));
          final destFile = File(destPath);
          final destDir = Directory(destPath);
          final destExists = await destFile.exists() || await destDir.exists();
          if (destExists && !await _replaceablePlaceholder(destFile, entity)) {
            continue;
          }
          if (destExists) await destFile.delete();
          try {
            await entity.rename(destPath);
            moved++;
          } on FileSystemException {
            // 跨设备或权限不足:跳过这一条,原文件保持不动。
          }
        }
        // 旧目录已搬空则删掉,避免下次重复迁移;还有别的内容就留着。
        if (!await legacy.list(followLinks: false).isEmpty) continue;
        try {
          await legacy.delete();
        } on FileSystemException {
          // 删除失败不影响迁移结果。
        }
      } on FileSystemException {
        // 旧目录不可读或无权限:跳过该目录。
      }
    }
    return moved;
  }

  /// 目标是否是可用旧文件替换的空脚手架占位(0 字节文件),且旧条目是非空文件。
  static Future<bool> _replaceablePlaceholder(File dest, FileSystemEntity source) async {
    if (source is! File) return false;
    if (!await dest.exists()) return false;
    try {
      if (await dest.length() != 0) return false;
      return await source.length() > 0;
    } on FileSystemException {
      return false;
    }
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