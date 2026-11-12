import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/util/ids.dart';
import '../data/providers/provider_config.dart';
import '../data/providers/provider_store.dart';
import '../data/settings/general_settings.dart';
import 'chat_controller.dart' show sseTransportProvider;
import 'models/agent_message.dart';
import 'protocols/llm_client.dart';
import 'protocols/llm_client_factory.dart';
import 'protocols/url_utils.dart';

/// 提交信息生成提示词(移植自上游 `assets/prompts/agent/commit-generator.md`,
/// 去掉首行说明注释;上游这段提示词可由用户在提示词页覆盖,本移植暂以内置常量提供)。
const String commitGeneratorPrompt = '''
你是一个 Git 提交信息生成器。根据传入的 git diff,输出一行符合 Conventional Commits 规范的提交信息,不输出任何其他解释、前缀或多余文字。

<rules>
- 格式为:<type>(<scope>): <subject>,scope 可选
- 允许的 type:feat, fix, refactor, docs, style, chore, ci, build, perf, test
- subject 用清晰简练的中文,句末不加句号
- 提炼变更的核心目的,不简单罗列被修改的文件名
- 输出必须且仅有单行,字数控制在 50 字以内
- 不输出 Markdown 引用标记(如 ```),只输出纯文本单行
</rules>''';

/// diff 送入模型前的截断长度(对齐上游 12000 字符)。
const int commitDiffLimit = 12000;

/// 包给模型的输入格式(对齐上游 `git diff:\n```diff\n…\n````)。
String buildCommitDiffPrompt(String diff) => 'git diff:\n```diff\n$diff\n```';

/// 取首个非空行,去掉包裹的反引号/双引号,截到 100 字;无有效内容返回 null。
String? cleanCommitMessage(String raw) {
  String? line;
  for (final candidate in raw.split('\n')) {
    if (candidate.trim().isNotEmpty) {
      line = candidate.trim();
      break;
    }
  }
  if (line == null) return null;
  var text = line;
  if (text.length >= 2 && text.startsWith('`') && text.endsWith('`')) {
    text = text.substring(1, text.length - 1);
  }
  if (text.startsWith('"')) text = text.substring(1);
  if (text.endsWith('"')) text = text.substring(0, text.length - 1);
  text = text.trim();
  final limited = text.length > 100 ? text.substring(0, 100) : text;
  return limited.trim().isEmpty ? null : limited;
}

final commitMessageGeneratorProvider =
    Provider<CommitMessageGenerator>((ref) => CommitMessageGenerator(ref));

/// 依据暂存差异让模型生成一行提交信息(对齐上游 `AgentWorkflow.generateCommitMessage`)。
///
/// 上游按「会话绑定的供应商 → 全局默认模型」解析;本移植尚无全局默认模型设置,
/// 取第一个启用且配好 Key 的供应商及其生效模型。
class CommitMessageGenerator {
  CommitMessageGenerator(this._ref);

  final Ref _ref;

  /// 返回清理后的提交信息;无可用供应商/模型、或调用失败时返回 null。
  Future<String?> generate(String diff) async {
    final trimmed = diff.trim();
    if (trimmed.isEmpty) return null;
    final provider = await _pickProvider();
    if (provider == null) return null;
    final model = provider.effectiveModel.trim();
    if (model.isEmpty) return null;

    final general = _ref.read(generalSettingsProvider);
    final client = createLlmClient(
      type: provider.type,
      transport: _ref.read(sseTransportProvider),
      config: LlmClientConfig(
        apiKey: provider.firstUsableApiKey,
        baseUrl: provider.baseUrl,
        model: model,
        useFullUrl: provider.useFullUrl,
        temperature: fixedTemperature(model),
        firstByteTimeout: general.firstByteTimeoutSec <= 0
            ? null
            : Duration(seconds: general.firstByteTimeoutSec),
        idleTimeout: general.streamIdleTimeoutSec <= 0
            ? null
            : Duration(seconds: general.streamIdleTimeoutSec),
        maxRetries: general.maxNetworkRetries,
        customHeaders: provider.resolvedHeaders(),
      ),
    );

    final truncated =
        trimmed.length > commitDiffLimit ? trimmed.substring(0, commitDiffLimit) : trimmed;
    final buffer = StringBuffer();
    final done = Completer<void>();
    client
        .completeStream(
      systemPrompt: commitGeneratorPrompt,
      messages: [
        AgentMessage(
          id: newId(),
          sessionId: '',
          role: MessageRole.user,
          content: buildCommitDiffPrompt(truncated),
          timestamp: nowMs(),
        ),
      ],
    )
        .listen(
      (chunk) {
        if (chunk is TextDelta) buffer.write(chunk.text);
      },
      onError: (_) {
        if (!done.isCompleted) done.complete();
      },
      onDone: () {
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future;
    return cleanCommitMessage(buffer.toString());
  }

  Future<ProviderConfig?> _pickProvider() async {
    List<ProviderConfig> providers;
    try {
      providers = await _ref.read(providersProvider.future);
    } catch (_) {
      return null;
    }
    for (final provider in providers) {
      if (provider.isEnabled && provider.hasUsableApiKey) return provider;
    }
    return null;
  }
}