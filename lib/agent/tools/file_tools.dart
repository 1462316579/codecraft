import 'dart:convert';
import 'dart:typed_data';

import '../../data/workspace_files.dart';
import 'tool.dart';
import 'workspace.dart';

/// 文件后端取用方式:由 [workspaceFilesProvider] 给出当前工作区的实现。
typedef FilesSupplier = Future<WorkspaceFiles> Function();

/// 单次 readFile 的行数上限(对齐上游:end_line 跨度最多 2000 行)。
const int kReadFileMaxLines = 2000;

/// 单次 readFile 的字节上限:超出即截断并提示续读。
const int kReadFileMaxBytes = 64 * 1024;

/// `readFile`:读取文件内容,支持分段续读。
class ReadFileTool extends AgentTool {
  ReadFileTool(this.workspace, this.files);

  final Workspace workspace;
  final FilesSupplier files;

  @override
  String get name => 'readFile';

  @override
  String get description =>
      '读取文件内容(工作区文件)。单次读取有行数与字节上限,超出可用 start_line 分段续读。';

  @override
  Set<ToolCapability> get capabilities => const {ToolCapability.readWorkspace};

  @override
  Map<String, ToolParameter> get parameters => const {
        'path': ToolParameter(
          name: 'path',
          type: ParameterType.string,
          description: '文件路径:相对于工作区根目录的路径(如 src/main.dart),或 ~/workspace/... 形式;绝对路径(/...) 亦可。',
        ),
        'start_line': ToolParameter(
          name: 'start_line',
          type: ParameterType.integer,
          description: '开始行号(从 1 计)。',
          required: false,
        ),
        'end_line': ToolParameter(
          name: 'end_line',
          type: ParameterType.integer,
          description: '结束行号;与 start_line 的跨度最多 2000 行,超出按 2000 行截断。',
          required: false,
        ),
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args, {String? sessionId}) async {
    final rawPath = args['path'] as String?;
    if (rawPath == null || rawPath.trim().isEmpty) {
      return const ToolError('缺少必需参数:path', code: 'MISSING_PATH');
    }
    final String filePath;
    try {
      filePath = workspace.resolve(rawPath);
    } on ToolPathException catch (e) {
      return ToolError(e.message, code: 'INVALID_PATH');
    }
    final WorkspaceFiles backend;
    final bool exists;
    final List<String> allLines;
    // 二进制文件(APK 里的 .dex/.so)读不成文本:退化成可打印字符串,
    // 这样逆向项目里 readFile 仍能直接拿到线索,而不是一句「读取失败」。
    var binary = false;
    try {
      backend = await files();
      exists = await backend.exists(filePath);
      if (!exists) {
        return ToolError('文件不存在:$rawPath', code: 'FILE_NOT_FOUND');
      }
      String text;
      Uint8List? bytes;
      try {
        bytes = await backend.readBytes(filePath);
      } catch (_) {
        // 远端工作区不支持字节读取,退回纯文本。
        bytes = null;
      }
      if (bytes != null && looksBinary(bytes)) {
        text = extractPrintableStrings(bytes);
        binary = true;
      } else {
        text = bytes != null ? utf8.decode(bytes) : await backend.readText(filePath);
      }
      allLines = const LineSplitter().convert(text);
    } on WorkspaceFileException catch (e) {
      return ToolError(e.message, code: 'READ_FAILED');
    } catch (e) {
      return ToolError('读取失败:$e', code: 'READ_FAILED');
    }

    final startLine = ((args['start_line'] as int?) ?? 1).clamp(1, 1 << 31);
    final requestedEnd = args['end_line'] as int?;
    final lineCap = startLine + kReadFileMaxLines - 1;
    final endCap = requestedEnd != null ? (requestedEnd < lineCap ? requestedEnd : lineCap) : lineCap;

    final buffer = StringBuffer();
    var totalLines = 0;
    var emittedLines = 0;
    var byteCount = 0;
    var truncatedByBytes = false;
    for (final line in allLines) {
      totalLines++;
      if (totalLines < startLine) continue;
      if (totalLines > endCap) continue;
      if (truncatedByBytes) continue;
      final lineBytes = utf8.encode(line).length + 1;
      if (byteCount + lineBytes > kReadFileMaxBytes && emittedLines > 0) {
        truncatedByBytes = true;
        continue;
      }
      if (emittedLines > 0) buffer.write('\n');
      buffer.write(line);
      byteCount += lineBytes;
      emittedLines++;
    }

    final lastEmitted = startLine + emittedLines - 1;
    final wantedEnd = requestedEnd != null
        ? (requestedEnd < totalLines ? requestedEnd : totalLines)
        : totalLines;
    final truncated = emittedLines > 0 && lastEmitted < wantedEnd;
    final note = truncated
        ? '内容超过上限已截断,可从第 ${lastEmitted + 1} 行起用 start_line 继续读取。'
        : null;

    return ToolSuccess({
      'path': workspace.display(filePath),
      'content': buffer.toString(),
      if (binary) 'binary': true,
      if (binary)
        'note': '这是二进制文件,内容为提取出的可打印字符串(每行一段,未保留原始偏移)。'
            '需要更精确的定位请用 Bash 的 strings/objdump 配合 grep。',
      'start_line': startLine,
      'end_line': emittedLines == 0 ? startLine : lastEmitted,
      'total_lines': totalLines,
      'truncated': truncated,
      if (note != null) 'note': note,
    });
  }
}

/// `writeFile`:写入完整文件内容(自动创建父目录)。
class WriteFileTool extends AgentTool {
  WriteFileTool(this.workspace, this.files);

  final Workspace workspace;
  final FilesSupplier files;

  @override
  String get name => 'writeFile';

  @override
  String get description => '写入完整文件内容,文件不存在时自动创建(含父目录)。局部修改请用 editFile。';

  @override
  ToolPermissionPolicy get permissionPolicy => ToolPermissionPolicy.ask;

  @override
  Set<ToolCapability> get capabilities => const {ToolCapability.writeWorkspace};

  @override
  Map<String, ToolParameter> get parameters => const {
        'path': ToolParameter(
          name: 'path',
          type: ParameterType.string,
          description: '文件路径:相对于工作区根目录的路径(如 src/main.dart),或 ~/workspace/... 形式;绝对路径(/...) 亦可。',
        ),
        'content': ToolParameter(
          name: 'content',
          type: ParameterType.string,
          description: '要写入的完整内容。',
        ),
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args, {String? sessionId}) async {
    final rawPath = args['path'] as String?;
    final content = args['content'] as String?;
    if (rawPath == null || rawPath.trim().isEmpty) {
      return const ToolError('缺少必需参数:path', code: 'MISSING_PATH');
    }
    if (content == null) {
      return const ToolError('缺少必需参数:content', code: 'MISSING_CONTENT');
    }
    final String filePath;
    try {
      filePath = workspace.resolve(rawPath);
    } on ToolPathException catch (e) {
      return ToolError(e.message, code: 'INVALID_PATH');
    }
    final bool existed;
    try {
      final backend = await files();
      existed = await backend.exists(filePath);
      await backend.writeText(filePath, content);
    } on WorkspaceFileException catch (e) {
      return ToolError(e.message, code: 'WRITE_FAILED');
    } catch (e) {
      return ToolError('写入失败:$e', code: 'WRITE_FAILED');
    }
    return ToolSuccess({
      'path': workspace.display(filePath),
      'created': !existed,
      'bytes': utf8.encode(content).length,
      'lines': content.isEmpty ? 0 : content.split('\n').length,
    });
  }
}

/// `editFile`:按精确字符串匹配局部修改(整批原子生效)。修改文件的首选工具。
class EditFileTool extends AgentTool {
  EditFileTool(this.workspace, this.files);

  final Workspace workspace;
  final FilesSupplier files;

  @override
  String get name => 'editFile';

  @override
  String get description =>
      '按精确字符串匹配局部修改已有文件,是修改文件的首选。edits 可一次提交多处修改,整批原子生效(任一处失败则全部回滚)。整文件重写用 writeFile。';

  @override
  ToolPermissionPolicy get permissionPolicy => ToolPermissionPolicy.ask;

  @override
  Set<ToolCapability> get capabilities => const {ToolCapability.writeWorkspace};

  @override
  Map<String, ToolParameter> get parameters => {
        'path': const ToolParameter(
          name: 'path',
          type: ParameterType.string,
          description: '文件路径:相对于工作区根目录的路径(如 src/main.dart),或 ~/workspace/... 形式;绝对路径(/...) 亦可。',
        ),
        'edits': ToolParameter(
          name: 'edits',
          type: ParameterType.array,
          description: '要应用的编辑列表,按顺序依次生效,每个编辑在前一个的结果上匹配。'
              '单处修改也用只含一个元素的数组。每个元素:{old_string, new_string, replace_all?}。',
          itemsSchema: const {
            'type': 'object',
            'properties': {
              'old_string': {
                'type': 'string',
                'description': '要被替换的原文,需与文件当前内容精确匹配(含缩进和换行)。带足够上下文以保证唯一。',
              },
              'new_string': {
                'type': 'string',
                'description': '替换后的新内容。传空字符串表示删除匹配到的内容。',
              },
              'replace_all': {
                'type': 'boolean',
                'description': '是否替换该 old_string 的全部匹配项。默认 false(要求唯一匹配)。',
              },
            },
            'required': ['old_string', 'new_string'],
          },
        ),
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args, {String? sessionId}) async {
    final rawPath = args['path'] as String?;
    if (rawPath == null || rawPath.trim().isEmpty) {
      return const ToolError('缺少必需参数:path', code: 'MISSING_PATH');
    }
    final rawEdits = args['edits'];
    if (rawEdits is! List || rawEdits.isEmpty) {
      return const ToolError('缺少必需参数:edits(至少一个编辑)', code: 'MISSING_EDITS');
    }
    final String filePath;
    try {
      filePath = workspace.resolve(rawPath);
    } on ToolPathException catch (e) {
      return ToolError(e.message, code: 'INVALID_PATH');
    }
    final WorkspaceFiles backend;
    final String original;
    try {
      backend = await files();
      if (!await backend.exists(filePath)) {
        return ToolError('文件不存在:$rawPath', code: 'FILE_NOT_FOUND');
      }
      original = await backend.readText(filePath);
    } on WorkspaceFileException catch (e) {
      return ToolError(e.message, code: 'READ_FAILED');
    } catch (e) {
      return ToolError('读取失败:$e', code: 'READ_FAILED');
    }

    var content = original;
    var applied = 0;
    for (var i = 0; i < rawEdits.length; i++) {
      final edit = rawEdits[i];
      if (edit is! Map) {
        return ToolError('第 ${i + 1} 个编辑格式不正确', code: 'INVALID_EDIT');
      }
      final oldString = edit['old_string'] as String?;
      final newString = edit['new_string'] as String?;
      final replaceAll = (edit['replace_all'] as bool?) ?? false;
      if (oldString == null || oldString.isEmpty || newString == null) {
        return ToolError('第 ${i + 1} 个编辑缺少 old_string/new_string', code: 'INVALID_EDIT');
      }
      final occurrences = _countOccurrences(content, oldString);
      if (occurrences == 0) {
        return ToolError(
          '第 ${i + 1} 个编辑的 old_string 未在文件中找到(未做任何修改)',
          code: 'NO_MATCH',
        );
      }
      if (occurrences > 1 && !replaceAll) {
        return ToolError(
          '第 ${i + 1} 个编辑的 old_string 匹配到 $occurrences 处(未做任何修改);'
          '请补充更多上下文,或把 replace_all 设为 true。',
          code: 'MULTIPLE_MATCHES',
        );
      }
      content = replaceAll
          ? content.replaceAll(oldString, newString)
          : content.replaceFirst(oldString, newString);
      applied += replaceAll ? occurrences : 1;
    }

    try {
      await backend.writeText(filePath, content);
    } on WorkspaceFileException catch (e) {
      return ToolError(e.message, code: 'WRITE_FAILED');
    } catch (e) {
      return ToolError('写入失败:$e', code: 'WRITE_FAILED');
    }
    return ToolSuccess({
      'path': workspace.display(filePath),
      'applied_edits': rawEdits.length,
      'replacements': applied,
      'lines': content.isEmpty ? 0 : content.split('\n').length,
    });
  }

  static int _countOccurrences(String content, String pattern) {
    if (pattern.isEmpty) return 0;
    var count = 0;
    var index = content.indexOf(pattern);
    while (index != -1) {
      count++;
      index = content.indexOf(pattern, index + pattern.length);
    }
    return count;
  }
}
