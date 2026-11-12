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