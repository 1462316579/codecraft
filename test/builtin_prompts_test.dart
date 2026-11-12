import 'dart:io';

import 'package:codecraft/agent/models/project.dart';
import 'package:codecraft/agent/prompt/system_prompt.dart';
import 'package:codecraft/agent/prompts.dart';
import 'package:codecraft/data/prompts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('内置编号片段索引:10 个编号齐全、正文非空、进程级缓存命中', () async {
    final index = await loadBuiltinPromptIndex();
    expect(index.keys, containsAll(<int>[0, 10, 15, 20, 30, 40, 50, 60, 70, 99]));
    for (final content in index.values) {
      expect(content.trim(), isNotEmpty);
    }
    final again = await loadBuiltinPromptIndex();
    expect(again, same(index), reason: '第二次调用应命中进程级缓存');
  });

  test('renderStatic 把内置片段正文拼进静态基线(生产路径)', () async {
    final tmp = Directory.systemTemp.createTempSync('prompts_verify');
    final catalog = PromptFragmentCatalog(configDir: tmp.path, workspaceRoot: tmp.path);
    final index = await loadBuiltinPromptIndex();
    final baseline = catalog.renderStatic(index);
    expect(baseline, contains('你是 Codecraft'), reason: '00-identity 正文');
    expect(baseline, contains('## 可用技能'), reason: '99-runtime-context 正文');
    expect(baseline, contains('{{CODECRAFT_WORKSPACE}}'), reason: '基线保留变量占位,由 compose 阶段展开');
  });

  test('完整系统提示词:内置基线 + 变量展开 + 场景提示词', () async {
    final prompt = await composeSystemPromptFromAssets();
    expect(prompt, contains('你是 Codecraft'));
    expect(prompt, contains('## 可用技能'));
    expect(prompt, isNot(contains('{{CODECRAFT_')));
  });

  test('三款场景提示词正文按项目类型注入且互不串', () async {
    final coding = await composeSystemPromptFromAssets(projectKind: ProjectKind.coding);
    final writing = await composeSystemPromptFromAssets(projectKind: ProjectKind.writing);
    final reverse = await composeSystemPromptFromAssets(projectKind: ProjectKind.reverse);

    expect(coding, contains('编程项目'));
    expect(writing, contains('写作项目'));
    expect(reverse, contains('应用逆向项目'));
    expect(coding, isNot(contains('写作项目')));
    expect(coding, isNot(contains('应用逆向项目')));
    expect(writing, isNot(contains('编程项目')));
    expect(writing, isNot(contains('应用逆向项目')));
    expect(reverse, isNot(contains('编程项目')));
    expect(reverse, isNot(contains('写作项目')));
  });
}
