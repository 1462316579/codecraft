import '../../data/providers/provider_config.dart';
import 'deepseek_client.dart';
import 'gemini_client.dart';
import 'http_transport.dart';
import 'llm_client.dart';
import 'openai_client.dart';

/// 按供应商协议类型创建对应客户端。
LlmClient createLlmClient({
  required ProviderType type,
  required LlmClientConfig config,
  SseTransport? transport,
}) {
  final resolvedTransport = transport ?? HttpTransport();
  return switch (type) {
    ProviderType.openai => OpenAiClient(config, resolvedTransport),
    ProviderType.anthropic => DeepSeekClient(config, resolvedTransport),
    ProviderType.gemini => GeminiClient(config, resolvedTransport),
  };
}