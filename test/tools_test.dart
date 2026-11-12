import 'dart:convert';
import 'dart:io';

import 'package:codecraft/agent/tools/browser_tool.dart';
import 'package:codecraft/agent/tools/explorer_tools.dart';
import 'package:codecraft/agent/tools/file_tools.dart';
import 'package:codecraft/data/workspace_files.dart';
import 'package:codecraft/agent/tools/tool.dart';
import 'package:codecraft/agent/tools/workspace.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 工具默认用宿主文件后端(local 目标的实现)。
  Future<WorkspaceFiles> localFiles() async => const LocalWorkspaceFiles();

  late Directory sandbox;
  late Workspace workspace;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('ws_test');
    workspace = Workspace(sandbox.path);
  });

  tearDown(() {
    sandbox.deleteSync(recursive: true);
  });

  group('Workspace 路径解析', () {
    test('~/workspace/... 与相对路径映射到沙盒根', () {
      expect(workspace.resolve('~/workspace'), sandbox.path);
      expect(workspace.resolve('~/workspace/src/a.dart'), '${sandbox.path}/src/a.dart');
      expect(workspace.resolve('src/a.dart'), '${sandbox.path}/src/a.dart');
    });

    test('越界路径被拒绝', () {
      expect(() => workspace.resolve('~/workspace/../secret'), throwsA(isA<ToolPathException>()));
    });

    test('绝对路径(容器/本地)直接返回', () {
      expect(workspace.resolve('/etc/passwd'), '/etc/passwd');
      expect(workspace.resolve('/storage/emulated/0/AI小说/我的世界'), '/storage/emulated/0/AI小说/我的世界');
    });

    test('display 还原为 ~/workspace 写法', () {
      expect(workspace.display('${sandbox.path}/a/b.txt'), '~/workspace/a/b.txt');
      expect(workspace.display(sandbox.path), '~/workspace');
    });
  });

  group('readFile', () {
    test('读取内容与行窗口', () async {
      final file = File('${sandbox.path}/a.txt');
      await file.writeAsString('l1\nl2\nl3\nl4');
      final tool = ReadFileTool(workspace, localFiles);

      final all = await tool.execute({'path': '~/workspace/a.txt'});
      expect(all, isA<ToolSuccess>());
      final data = (all as ToolSuccess).data as Map<String, dynamic>;
      expect(data['content'], 'l1\nl2\nl3\nl4');
      expect(data['total_lines'], 4);

      final windowed = await tool.execute({
        'path': 'a.txt',
        'start_line': 2,
        'end_line': 3,
      }) as ToolSuccess;
      expect((windowed.data as Map<String, dynamic>)['content'], 'l2\nl3');
      expect((windowed.data as Map<String, dynamic>)['start_line'], 2);
      expect((windowed.data as Map<String, dynamic>)['end_line'], 3);
    });

    test('文件不存在与路径越界返回错误', () async {
      final tool = ReadFileTool(workspace, localFiles);
      expect((await tool.execute({'path': 'nope.txt'}) as ToolError).code, 'FILE_NOT_FOUND');
      expect((await tool.execute({'path': '~/workspace/../secret'}) as ToolError).code, 'INVALID_PATH');
    });
  });

  group('writeFile', () {
    test('自动创建父目录并写入', () async {
      final tool = WriteFileTool(workspace, localFiles);
      final result = await tool.execute({
        'path': '~/workspace/src/deep/file.txt',
        'content': 'hello',
      }) as ToolSuccess;
      expect((result.data as Map<String, dynamic>)['created'], true);
      expect(File('${sandbox.path}/src/deep/file.txt').readAsStringSync(), 'hello');
    });
  });

  group('editFile', () {
    test('唯一匹配替换', () async {
      final file = File('${sandbox.path}/code.dart');
      await file.writeAsString('var a = 1;\nvar b = 2;');
      final tool = EditFileTool(workspace, localFiles);
      final result = await tool.execute({
        'path': 'code.dart',
        'edits': [
          {'old_string': 'var b = 2;', 'new_string': 'var b = 3;'},
        ],
      }) as ToolSuccess;
      expect((result.data as Map<String, dynamic>)['replacements'], 1);
      expect(file.readAsStringSync(), 'var a = 1;\nvar b = 3;');
    });

    test('多处匹配且未开 replace_all 时拒绝且不写入', () async {
      final file = File('${sandbox.path}/multi.txt');
      await file.writeAsString('x\nx\n');
      final tool = EditFileTool(workspace, localFiles);
      final error = await tool.execute({
        'path': 'multi.txt',
        'edits': [
          {'old_string': 'x', 'new_string': 'y'},
        ],
      }) as ToolError;
      expect(error.code, 'MULTIPLE_MATCHES');
      expect(file.readAsStringSync(), 'x\nx\n', reason: '失败时必须整批回滚');
    });

    test('整批原子:第二个编辑失败时第一个也不生效', () async {
      final file = File('${sandbox.path}/atomic.txt');
      await file.writeAsString('one two');
      final tool = EditFileTool(workspace, localFiles);
      final error = await tool.execute({
        'path': 'atomic.txt',
        'edits': [
          {'old_string': 'one', 'new_string': '1'},
          {'old_string': '不存在的内容', 'new_string': 'x'},
        ],
      }) as ToolError;
      expect(error.code, 'NO_MATCH');
      expect(file.readAsStringSync(), 'one two');
    });

    test('replace_all 全量替换', () async {
      final file = File('${sandbox.path}/all.txt');
      await file.writeAsString('x-x-x');
      final tool = EditFileTool(workspace, localFiles);
      final result = await tool.execute({
        'path': 'all.txt',
        'edits': [
          {'old_string': 'x', 'new_string': 'y', 'replace_all': true},
        ],
      }) as ToolSuccess;
      expect((result.data as Map<String, dynamic>)['replacements'], 3);
      expect(file.readAsStringSync(), 'y-y-y');
    });
  });

  group('list / search', () {
    test('list 支持 -la 与 head 截断', () async {
      File('${sandbox.path}/b.txt').writeAsStringSync('b');
      File('${sandbox.path}/a.txt').writeAsStringSync('a');
      final tool = ListTool(workspace, localFiles);

      final plain = await tool.execute({'args': '~/workspace'}) as ToolSuccess;
      expect(((plain.data as Map<String, dynamic>)['output'] as String).split('\n'), ['a.txt', 'b.txt']);

      final long = await tool.execute({'args': '-la ~/workspace | head -n 1'}) as ToolSuccess;
      final lines = ((long.data as Map<String, dynamic>)['output'] as String).split('\n');
      expect(lines.length, 1);
      expect(lines.first, contains('a.txt'));
      expect((long.data as Map<String, dynamic>)['truncated'], true);
    });

    test('search 支持 -n 与引号模式', () async {
      File('${sandbox.path}/x.dart').writeAsStringSync('void main() {}\n// 其他\nvoid main2() {}');
      final tool = SearchTool(workspace, localFiles);
      final result = await tool.execute({'args': '-n "void main" ~/workspace'}) as ToolSuccess;
      final output = (result.data as Map<String, dynamic>)['output'] as String;
      expect(output, contains('~/workspace/x.dart:1: void main() {}'));
      expect(output, isNot(contains('其他')));
    });

    test('search 非法正则返回错误', () async {
      final tool = SearchTool(workspace, localFiles);
      final error = await tool.execute({'args': '-n "(" ~/workspace'}) as ToolError;
      expect(error.code, 'INVALID_PATTERN');
    });
  });

  group('工具 schema', () {
    test('readFile 的 JSON Schema 形状', () {
      final schema = ReadFileTool(workspace, localFiles).toJsonSchema();
      expect(schema['type'], 'object');
      expect((schema['properties'] as Map)['path']['type'], 'string');
      expect(schema['required'], ['path']);
    });

    test('browser 仅 action 为必需参数', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final schema = container.read(browserToolProvider).toJsonSchema();
      expect(schema['required'], ['action']);
      expect((schema['properties'] as Map).containsKey('selector'), isTrue);
    });

    test('editFile 的 edits 携带 items 结构', () {
      final schema = EditFileTool(workspace, localFiles).toJsonSchema();
      final edits = (schema['properties'] as Map)['edits'] as Map;
      expect(edits['type'], 'array');
      expect((edits['items'] as Map)['required'], ['old_string', 'new_string']);
    });

    test('数组参数缺 itemsSchema 时兜底为字符串数组(上游 38ddde77)', () {
      final schema = _ArrayParamTool(false).toJsonSchema();
      final tags = (schema['properties'] as Map)['tags'] as Map;
      expect(tags['type'], 'array');
      expect(tags['items'], {'type': 'string'});
    });

    test('数组参数带 itemsSchema 时原样并入', () {
      final schema = _ArrayParamTool(true).toJsonSchema();
      final tags = (schema['properties'] as Map)['tags'] as Map;
      expect(tags['items'], {'type': 'integer'});
    });

    test('工具结果传输串(status 判别)', () {
      expect(
        const ToolSuccess({'a': 1}).toTransportString(),
        '{"status":"success","data":{"a":1}}',
      );
      expect(
        const ToolError('boom', code: 'X').toTransportString(),
        '{"status":"error","message":"boom","code":"X"}',
      );
      expect(
        jsonDecode(const ToolPartial({'a': 1}, '部分').toTransportString()),
        {'status': 'partial', 'data': {'a': 1}, 'message': '部分'},
      );
    });
  });
}

/// 仅用于 schema 测试的最小工具(对齐上游 AgentToolTest 的 TestTool)。
class _ArrayParamTool extends AgentTool {
  _ArrayParamTool(this.withItems);

  final bool withItems;

  @override
  String get name => 'test_tool';

  @override
  String get description => 'test tool';

  @override
  Map<String, ToolParameter> get parameters => {
        'tags': ToolParameter(
          name: 'tags',
          type: ParameterType.array,
          description: 'tags',
          required: false,
          itemsSchema: withItems ? {'type': 'integer'} : null,
        ),
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args, {String? sessionId}) async =>
      const ToolSuccess('');
}