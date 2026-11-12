import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../db/daos.dart';
import 'provider_config.dart';

final providersProvider =
    AsyncNotifierProvider<ProvidersNotifier, List<ProviderConfig>>(ProvidersNotifier.new);

class ProvidersNotifier extends AsyncNotifier<List<ProviderConfig>> {
  @override
  Future<List<ProviderConfig>> build() => ref.watch(databaseProvider).providerDao.list();

  Future<void> save(ProviderConfig config) async {
    await ref.read(databaseProvider).providerDao.upsert(config.sanitized());
    ref.invalidateSelf();
    await future;
  }

  Future<void> remove(String id) async {
    await ref.read(databaseProvider).providerDao.delete(id);
    ref.invalidateSelf();
    await future;
  }

  /// 长按拖拽调整提供商顺序(持久化到 sortOrder)。
  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = state.valueOrNull ?? const <ProviderConfig>[];
    if (oldIndex < 0 || oldIndex >= list.length) return;
    final ids = [for (final provider in list) provider.id];
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex.clamp(0, ids.length), moved);
    await ref.read(databaseProvider).providerDao.reorder(ids);
    ref.invalidateSelf();
    await future;
  }
}