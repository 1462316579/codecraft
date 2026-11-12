import '../../data/workspace_files.dart';
import 'file_tools.dart';
import 'tool.dart';
import 'workspace.dart';

/// `list`:按 ls 风格列出工作区文件(原生实现,不依赖容器 shell)。
class ListTool extends AgentTool {
  ListTool(this.workspace, this.files);

  final Workspace workspace;
  final FilesSupplier files;

  /// 输出行数上限(等同上游的 `| head` 截断)。
  static const int maxOutputLines = 200;

  @override
  String get name => 'list';

  @override
  String get description =>
      '按 ls 风格列出文件和目录。例:args="-la 工作区路径"。支持追加 `| head [-n N]` 截断输出。';

  @override
  Set<ToolCapability> get capabilities => const {ToolCapability.readWorkspace};

  @override
  Map<String, ToolParameter> get parameters => const {
        'args': ToolParameter(
          name: 'args',
          type: ParameterType.string,
          description: 'ls 风格参数与路径,如 "-la ."、"src/main.dart"。相对路径相对工作区根目录。',
        ),
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args, {String? sessionId}) async {
    final raw = (args['args'] as String?)?.trim() ?? '';
    final (flags, pathArg, headLimit) = _parseArgs(raw);
    final String directory;
    try {
      directory = workspace.resolve(pathArg.isEmpty ? '~/workspace' : pathArg);
    } on ToolPathException catch (e) {
      return ToolError(e.message, code: 'INVALID_PATH');
    }
    final WorkspaceFiles backend;
    final List<DirEntry> entries;
    try {
      backend = await files();
      if (!await backend.isDirectory(directory)) {
        return ToolError('目录不存在:$pathArg', code: 'NOT_FOUND');
      }
      entries = await backend.listDir(directory);
    } on WorkspaceFileException catch (e) {
      return ToolError(e.message, code: 'LIST_FAILED');
    } catch (e) {
      return ToolError('列目录失败:$e', code: 'LIST_FAILED');
    }

    var records = <_Entry>[];
    for (final entry in entries) {
      if (!flags.contains('a') && entry.name.startsWith('.')) continue;
      records.add(_Entry(
        name: entry.name,
        isDirectory: entry.isDirectory,
        size: entry.size,
        modified: entry.modified,
      ));
    }
    if (flags.contains('t')) {
      records.sort((a, b) => b.modified.compareTo(a.modified));
    } else if (flags.contains('S')) {
      records.sort((a, b) => b.size.compareTo(a.size));
    } else {
      records.sort((a, b) => a.name.compareTo(b.name));
    }
    if (flags.contains('r')) {
      records = records.reversed.toList();
    }

    final lines = <String>[];
    for (final record in records) {
      if (flags.contains('l')) {
        final kind = record.isDirectory ? 'd' : '-';
        final size = flags.contains('h') ? _humanSize(record.size) : '${record.size}';
        final time = _formatTime(record.modified);
        lines.add('$kind ${size.padLeft(8)} $time ${record.name}');
      } else {
        lines.add(record.name);
      }
    }

    final limit = headLimit ?? maxOutputLines;
    var truncated = false;
    if (lines.length > limit) {
      lines.removeRange(limit, lines.length);
      truncated = true;
    }
    return ToolSuccess({
      'output': lines.join('\n'),
      'count': records.length,
      'truncated': truncated,
    });
  }

  (String flags, String path, int? head) _parseArgs(String raw) {
    var text = raw;
    int? head;
    final headMatch = RegExp(r'\|\s*head(?:\s+-n\s*(\d+))?\s*$').firstMatch(text);
    if (headMatch != null) {
      head = int.tryParse(headMatch.group(1) ?? '') ?? 10;
      text = text.substring(0, headMatch.start).trim();
    }
    final parts = text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    var flags = '';
    String? path;
    for (final part in parts) {
      if (part.startsWith('-') && !part.startsWith('--')) {
        flags += part.substring(1);
      } else {
        path = part;
      }
    }
    return (flags, path ?? '', head);
  }

  /// ls -h 风格的字节数。
  static String _humanSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    const units = ['K', 'M', 'G', 'T'];
    var value = bytes / 1024;
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    return '${value.toStringAsFixed(value < 10 ? 1 : 0)}${units[unit]}';
  }

  /// ls 风格时间:当年只显示月日时分,跨年显示日期。
  static String _formatTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    final now = DateTime.now();
    if (time.year == now.year) {
      return '${two(time.month)}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}';
    }
    return '${time.year}-${two(time.month)}-${two(time.day)}';
  }
}

class _Entry {
  _Entry({
    required this.name,
    required this.isDirectory,
    required this.size,
    required this.modified,
  });

  final String name;
  final bool isDirectory;
  final int size;
  final DateTime modified;
}

/// `search`:在工作区内搜索文本内容(原生实现;本地逐行匹配,Codespace 走远端 grep)。
class SearchTool extends AgentTool {
  SearchTool(this.workspace, this.files);

  final Workspace workspace;
  final FilesSupplier files;

  static const int maxMatches = 200;

  @override
  String get name => 'search';

  @override
  String get description =>
      '在工作区内搜索文本内容。例:args="-n "pattern" 工作区路径"。支持追加 `| head [-n N]` 截断输出。';

  @override
  Set<ToolCapability> get capabilities => const {ToolCapability.readWorkspace};

  @override
  Map<String, ToolParameter> get parameters => const {
        'args': ToolParameter(
          name: 'args',
          type: ParameterType.string,
          description: 'rg 风格参数:如 -n "pattern" .、-i "pattern" src/。相对路径相对工作区根目录。'
              '二进制文件(`.dex`/`.so` 等)按可打印字符串匹配,可直接搜 APK 里的类名与文案。',
        ),
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args, {String? sessionId}) async {
    final raw = (args['args'] as String?)?.trim() ?? '';
    final parsed = _parseArgs(raw);
    if (parsed == null) {
      return const ToolError(
        '参数格式不正确,示例:-n "pattern" ~/workspace',
        code: 'INVALID_ARGS',
      );
    }
    final (pattern, flags, pathArg, headLimit) = parsed;
    final WorkspaceFiles backend;
    try {
      backend = await files();
    } catch (e) {
      return ToolError('搜索后端不可用:$e', code: 'SEARCH_FAILED');
    }
    final String root;
    try {
      root = workspace.resolve(pathArg.isEmpty ? '~/workspace' : pathArg);
    } on ToolPathException catch (e) {
      return ToolError(e.message, code: 'INVALID_PATH');
    }
    // 本地实现用 Dart 正则、远端用 grep -E,方言不完全一致;但「模式本身不合法」
    // 应当在这里就判出来(远端 grep 的写法无法提前校验),保持两侧一致的错误码。
    if (!flags.contains('F')) {
      try {
        RegExp(pattern);
      } catch (e) {
        return ToolError('正则表达式不合法:$e', code: 'INVALID_PATTERN');
      }
    }

    final limit = headLimit ?? maxMatches;
    final List<SearchHit> hits;
    try {
      hits = await backend.searchLines(
        root,
        pattern,
        ignoreCase: flags.contains('i'),
        fixed: flags.contains('F'),
        limit: limit,
      );
    } on WorkspaceFileException catch (e) {
      return ToolError(e.message, code: 'SEARCH_FAILED');
    } catch (e) {
      return ToolError('搜索失败:$e', code: 'SEARCH_FAILED');
    }
    if (hits.isEmpty &&
        !await backend.exists(root) &&
        !await backend.isDirectory(root)) {
      return ToolError('路径不存在:$pathArg', code: 'NOT_FOUND');
    }

    final lines = [
      for (final hit in hits)
        flags.contains('n')
            ? '${workspace.display(hit.path)}:${hit.line}: ${hit.text}'
            : '${workspace.display(hit.path)}: ${hit.text}',
    ];

    return ToolSuccess({
      'output': lines.join('\n'),
      'matches': lines.length,
      // 命中数达到上限即视为被截断(与原来的提前停止语义一致)。
      'truncated': lines.length >= limit,
    });
  }

  /// 解析 `-n "pattern" ~/workspace/app` 形式的参数。
  (String, String, String, int?)? _parseArgs(String raw) {
    var text = raw;
    int? head;
    final headMatch = RegExp(r'\|\s*head(?:\s+-n\s*(\d+))?\s*$').firstMatch(text);
    if (headMatch != null) {
      head = int.tryParse(headMatch.group(1) ?? '') ?? 10;
      text = text.substring(0, headMatch.start).trim();
    }

    var flags = '';
    String? pattern;
    String? path;

    final tokenPattern = RegExp(r'(-[a-zA-Z]+)|"((?:[^"\\]|\\.)*)"|(\S+)');
    final tokens = <String>[];
    for (final match in tokenPattern.allMatches(text)) {
      if (match.group(1) != null) {
        flags += match.group(1)!.substring(1);
      } else if (match.group(2) != null) {
        tokens.add(match.group(2)!.replaceAll(r'\"', '"').replaceAll(r'\\', r'\'));
      } else {
        tokens.add(match.group(3)!);
      }
    }
    if (tokens.isEmpty) return null;
    pattern = tokens.removeAt(0);
    if (tokens.isNotEmpty) path = tokens.removeLast();
    return (pattern, flags, path ?? '', head);
  }
}