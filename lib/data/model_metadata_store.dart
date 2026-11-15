import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../agent/models/model_metadata.dart';
import '../agent/tools/workspace.dart';

/// 自定义模型元数据存储(对齐上游 CustomModelMetadataStore):
/// key 为「提供商ID:模型名」复合键,优先级高于自动解析结果。
class CustomModelMetadataStore {
  CustomModelMetadataStore(this._file);

  final File _file;

  Future<Map<String, ModelMetadata>> all() async {
    try {
      if (!await _file.exists()) return const {};
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is! Map) return const {};
      return {
        for (final entry in decoded.entries)
          if (entry.value is Map)
            '${entry.key}': ModelMetadata.fromJson(
              '${entry.key}',
              (entry.value as Map).cast<String, Object?>(),
            ),
      };
    } catch (_) {
      return const {};
    }
  }

  Future<void> put(String providerId, String model, ModelMetadata metadata) async {
    final map = Map<String, ModelMetadata>.of(await all());
    map[modelMetadataKey(providerId, model)] = metadata;
    await _write(map);
  }

  /// 批量补写窗口信息(拉取模型后调用):只填空缺字段,用户已填的内容原样保留。
  ///
  /// 一次写盘,避免几百个模型逐个 `put` 时反复读写同一个文件。
  Future<void> putAll(String providerId, Map<String, ModelMetadata> models) async {
    if (models.isEmpty) return;
    final map = Map<String, ModelMetadata>.of(await all());
    for (final entry in models.entries) {
      final key = modelMetadataKey(providerId, entry.key);
      final fetched = entry.value;
      final existing = map[key];
      if (existing == null) {
        map[key] = fetched;
        continue;
      }
      map[key] = ModelMetadata(
        id: existing.id,
        providerId: existing.providerId,
        displayName: existing.displayName,
        contextTokens: existing.contextTokens > 0
            ? existing.contextTokens
            : fetched.contextTokens,
        inputTokens: existing.inputTokens ?? fetched.inputTokens,
        outputTokens: existing.outputTokens ?? fetched.outputTokens,
        supportsTools: existing.supportsTools,
        supportsVision: existing.supportsVision,
        supportsReasoning: existing.supportsReasoning,
        supportsImageOutput: existing.supportsImageOutput,
        reasoningCanDisable: existing.reasoningCanDisable,
        reasoningEffortOptions: existing.reasoningEffortOptions,
        inputCostUsdPerM: existing.inputCostUsdPerM,
        outputCostUsdPerM: existing.outputCostUsdPerM,
        cacheReadCostUsdPerM: existing.cacheReadCostUsdPerM,
        cacheWriteCostUsdPerM: existing.cacheWriteCostUsdPerM,
      );
    }
    await _write(map);
  }

  Future<void> remove(String providerId, String model) async {
    final map = Map<String, ModelMetadata>.of(await all());
    if (map.remove(modelMetadataKey(providerId, model)) != null) {
      await _write(map);
    }
  }

  Future<void> _write(Map<String, ModelMetadata> map) async {
    await _file.parent.create(recursive: true);
    final json = jsonEncode({
      for (final entry in map.entries) entry.key: entry.value.toJson(),
    });
    await _file.writeAsString(json);
  }
}

final modelMetadataStoreProvider = Provider<CustomModelMetadataStore>(
  (ref) => CustomModelMetadataStore(
    File(p.join(ref.watch(configDirProvider), 'model_metadata.json')),
  ),
);

/// 自定义元数据全量(模型页与元数据标签用);写入后由调用方 invalidate。
final customModelMetadataProvider = FutureProvider<Map<String, ModelMetadata>>(
  (ref) => ref.watch(modelMetadataStoreProvider).all(),
);