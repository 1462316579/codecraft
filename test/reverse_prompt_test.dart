import 'dart:io';
import 'dart:typed_data';

import 'package:codecraft/agent/models/chat_session.dart';
import 'package:codecraft/agent/models/project.dart';
import 'package:codecraft/agent/prompt/system_prompt.dart';
import 'package:codecraft/agent/tools/file_tools.dart';
import 'package:codecraft/agent/tools/tool.dart';
import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/data/workspace_files.dart';
import 'package:flutter_test/flutter_test.dart';

/// 造一段带二进制噪声的内容:模拟 `.dex`/`.so` 里的字节布局。
Uint8List binaryWith(List<String> strings) {
  final bytes = <int>[];
  for (final text in strings) {
    // 前后各插一段不可打印字节,把字符串隔开。
    bytes.addAll([0x00, 0x01, 0x02, 0xFF]);
    bytes.addAll(text.codeUnits);
  }
  bytes.addAll([0x00, 0x00]);
  return Uint8List.fromList(bytes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('系统提示词', () {
    test('逆向项目注入 APK 解包说明', () async {
      final prompt = await composeSystemPromptFromAssets(projectKind: ProjectKind.reverse);

      expect(prompt, contains('应用逆向项目'));
      expect(prompt, contains('AndroidManifest.xml'));
      expect(prompt, contains('classes.dex'));
      expect(prompt, contains('libapp.so'));
    });

    test('逆向说明要求直接动手,不要先做免责声明', () async {
      final prompt = await composeSystemPromptFromAssets(projectKind: ProjectKind.reverse);

      expect(prompt, contains('直接动手做'), reason: '缺这段就会停在泛泛而谈');
      expect(prompt, contains('不需要先做免责声明'));
    });

    test('普通项目不带逆向说明', () async {
      final coding = await composeSystemPromptFromAssets(projectKind: ProjectKind.coding);
      final writing = await composeSystemPromptFromAssets(projectKind: ProjectKind.writing);
      final none = await composeSystemPromptFromAssets();

      expect(coding, isNot(contains('应用逆向项目')));
      expect(writing, isNot(contains('应用逆向项目')));
      expect(none, isNot(contains('应用逆向项目')));
    });

    test('三款场景提示词按项目类型注入', () async {
      final coding = await composeSystemPromptFromAssets(projectKind: ProjectKind.coding);
      final writing = await composeSystemPromptFromAssets(projectKind: ProjectKind.writing);

      expect(coding, contains('编程项目'));
      expect(writing, contains('写作项目'));
      expect(coding, isNot(contains('写作项目')));
      expect(writing, isNot(contains('编程项目')));
    });

    test('无项目类型时不注入场景提示词', () async {
      final prompt = await composeSystemPromptFromAssets();

      expect(prompt, isNot(contains('编程项目')));
      expect(prompt, isNot(contains('写作项目')));
      expect(prompt, isNot(contains('应用逆向项目')));
    });

    test('写作模式段落仍然生效(与项目类型互不干扰)', () async {
      final prompt = await composeSystemPromptFromAssets(mode: AgentMode.write, projectKind: ProjectKind.reverse);

      expect(prompt, contains('写作模式'));
      expect(prompt, contains('应用逆向项目'));
    });

    test('说明工作区内置的逆向工具与写回边界', () async {
      final prompt = await composeSystemPromptFromAssets(projectKind: ProjectKind.reverse);

      expect(prompt, contains('Dex 编辑器'));
      expect(prompt, contains('ARSC 编辑器'));
      expect(prompt, contains('十六进制'));
      // 写回能力很窄,提示词必须说清楚,否则模型会承诺做不到的事。
      expect(prompt, contains('等长替换'));
      expect(prompt, contains('做不到'));
    });
  });

  group('二进制内容提取', () {
    test('提取可打印字符串,跳过噪声与过短的片段', () {
      final bytes = binaryWith([
        'com.example.app',
        'rewardedVideoDidRewardSuccess',
        'ab', // 短于 4 字符,丢弃
        'https://api.example.com/reward',
      ]);

      final text = extractPrintableStrings(bytes);

      expect(text, contains('com.example.app'));
      expect(text, contains('rewardedVideoDidRewardSuccess'));
      expect(text, contains('https://api.example.com/reward'));
      expect(text, isNot(contains('ab')), reason: '短片段是噪声');
    });

    test('每段一行,便于按行续读', () {
      final text = extractPrintableStrings(binaryWith(['alpha', 'beta']));
      expect(text.split('\n'), ['alpha', 'beta']);
    });

    test('全零字节不产出内容', () {
      expect(extractPrintableStrings(Uint8List(64)), isEmpty);
    });
  });

  group('readFile 读二进制', () {
    late Directory dir;
    late Workspace workspace;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('ws_binary');
      workspace = Workspace(dir.path);
    });

    tearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    test('读取 .so 时返回可打印字符串而不是报错', () async {
      final file = File('${dir.path}/libapp.so');
      file.writeAsBytesSync(binaryWith([
        'libapp.so',
        'flutter/assets/kernel_blob.bin',
      ]));

      final tool = ReadFileTool(
        workspace,
        () async => const LocalWorkspaceFiles(),
      );
      final result = await tool.execute({'path': '~/workspace/libapp.so'});

      expect(result, isA<ToolSuccess>());
      final data = (result as ToolSuccess).data as Map<String, Object?>;
      expect(data['binary'], isTrue, reason: '要标明这是二进制,避免误当成源码');
      expect(data['content'], contains('kernel_blob.bin'));
      expect(data['note'], contains('可打印字符串'));
    });

    test('普通文本文件仍按文本返回', () async {
      File('${dir.path}/a.txt').writeAsStringSync('第一行\n第二行\n');

      final tool = ReadFileTool(
        workspace,
        () async => const LocalWorkspaceFiles(),
      );
      final result = await tool.execute({'path': '~/workspace/a.txt'});

      final data = (result as ToolSuccess).data as Map<String, Object?>;
      expect(data['binary'], isNull);
      expect(data['content'], contains('第二行'));
    });
  });

  group('search 搜二进制', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('ws_search_bin'));
    tearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    test('能在 .dex 里搜到字符串', () async {
      File('${dir.path}/classes.dex').writeAsBytesSync(binaryWith([
        'com/example/reward/RewardManager',
        'app/api/ad/reward/query',
      ]));
      File('${dir.path}/README.md').writeAsStringSync('nothing here\n');

      final hits = await LocalWorkspaceFiles(root: dir.path).searchLines(
        dir.path,
        'reward/query',
        limit: 10,
      );

      expect(hits, hasLength(1));
      expect(hits.single.path, endsWith('classes.dex'));
      expect(hits.single.text, contains('app/api/ad/reward/query'));
    });

    test('普通文本仍正常匹配', () async {
      File('${dir.path}/a.txt').writeAsStringSync('hello world\n');

      final hits = await LocalWorkspaceFiles(root: dir.path).searchLines(
        dir.path,
        'hello',
        limit: 10,
      );

      expect(hits.single.text, 'hello world');
      expect(hits.single.line, 1);
    });
  });
}