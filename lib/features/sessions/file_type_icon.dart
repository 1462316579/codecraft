import 'package:flutter/material.dart';
import '../../core/icons/iconfont.dart';

/// 按文件语义与扩展名挑选侧边栏文件树的单色线性图标(逐值移植上游 `FileTypeIcon.kt`)。
///
/// 风格与全局一致:极简线性,渲染时跟随主题色着色。
IconData fileTypeIconFor(String name) {
  final lower = name.toLowerCase();
  if (_specialTerminalFiles.contains(lower)) return Iconfont.terminal;
  if (_specialTextFiles.contains(lower) || lower.startsWith('.env')) {
    return Iconfont.fileText;
  }

  final dot = name.lastIndexOf('.');
  final ext = dot <= 0 ? '' : name.substring(dot + 1).toLowerCase();
  if (_codeExts.contains(ext)) return Iconfont.code;
  if (_terminalExts.contains(ext)) return Iconfont.terminal;
  if (_textAndConfigExts.contains(ext)) return Iconfont.fileText;
  if (_imageExts.contains(ext)) return Iconfont.image;
  if (_videoExts.contains(ext)) return Iconfont.video;
  if (_audioExts.contains(ext)) return Iconfont.music;
  if (_archiveExts.contains(ext)) return Iconfont.package;
  if (_databaseExts.contains(ext)) return Iconfont.database;
  return Iconfont.file;
}

/// 源代码文件扩展名。
const Set<String> _codeExts = {
  'kt', 'kts', 'java', 'py', 'pyw', 'pyi',
  'js', 'mjs', 'cjs', 'jsx', 'ts', 'mts', 'cts', 'tsx',
  'c', 'h', 'cpp', 'cc', 'cxx', 'hpp', 'hh', 'hxx',
  'cs', 'go', 'rs', 'php', 'rb', 'swift', 'dart', 'lua',
  'scala', 'groovy', 'vue', 'svelte', 'astro',
  'html', 'htm', 'xhtml', 'css', 'scss', 'sass', 'less', 'styl',
  'r', 'pl', 'pm', 'tcl', 'hs', 'fs', 'fsx', 'clj', 'cljs',
  'ex', 'exs', 'erl', 'v', 'zig', 'nim', 'd', 'jl',
};

/// 脚本与命令行文件扩展名。
const Set<String> _terminalExts = {
  'sh', 'bash', 'zsh', 'ksh', 'csh', 'fish', 'bat', 'cmd', 'ps1', 'awk', 'sed',
};

/// 常见无后缀脚本或构建文件。
const Set<String> _specialTerminalFiles = {
  'dockerfile', 'containerfile', 'makefile', 'rakefile', 'vagrantfile', 'justfile',
};

/// 文档、纯文本与各类配置文件(json、yaml、xml、properties、env 等统一作为文本呈现)。
const Set<String> _textAndConfigExts = {
  'md', 'markdown', 'mdown', 'txt', 'rst', 'asciidoc', 'adoc',
  'doc', 'docx', 'rtf', 'log', 'csv', 'tsv', 'pdf',
  'json', 'jsonc', 'json5', 'yaml', 'yml', 'toml', 'xml',
  'ini', 'cfg', 'conf', 'properties', 'gradle', 'pro', 'plist',
  'lock', 'editorconfig',
};

/// 常见独立文本或配置规则文件名。
const Set<String> _specialTextFiles = {
  '.gitignore', '.gitattributes', '.gitmodules', '.dockerignore',
  '.npmrc', '.prettierrc', '.eslintrc', '.clang-format',
  'license', 'notice', 'authors', 'contributors', 'changelog',
};

/// 图片格式。
const Set<String> _imageExts = {
  'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'svg', 'ico',
  'heic', 'heif', 'avif', 'tif', 'tiff',
};

/// 视频媒体格式。
const Set<String> _videoExts = {'mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm'};

/// 音频格式。
const Set<String> _audioExts = {'mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a', 'wma'};

/// 压缩包与安装包。
const Set<String> _archiveExts = {
  'zip', 'tar', 'gz', 'tgz', 'bz2', 'tbz2', 'xz', 'txz', '7z', 'rar',
  'apk', 'apks', 'xapk', 'aab', 'jar', 'war', 'ear', 'deb', 'rpm', 'ipa', 'dmg', 'iso',
};

/// 数据库文件。
const Set<String> _databaseExts = {'sql', 'db', 'sqlite', 'sqlite3', 'mdb'};