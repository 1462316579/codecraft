import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/app_database.dart';
import 'storage.dart';

class StorageUiState {
  const StorageUiState({
    this.entries = const {},
    this.scanning = false,
    this.deviceSpace = const DeviceSpace(totalBytes: 0, availableBytes: 0),
    this.expanded = const {},
    this.cleaning = false,
    this.selectedCleanup = const {CleanupKind.caches, CleanupKind.logs},
    this.freedBytes,
  });

  /// 已算出的分类;扫描中时逐项填充,缺项界面显示「—」。
  final Map<StorageCategory, StorageEntry> entries;
  final bool scanning;
  final DeviceSpace deviceSpace;
  final Set<StorageCategory> expanded;
  final bool cleaning;
  final Set<CleanupKind> selectedCleanup;

  /// 上一次清理释放的字节数,非空时界面给出提示。
  final int? freedBytes;

  int get totalBytes => entries.values.fold(0, (sum, entry) => sum + entry.bytes);

  /// 各可清理项当前大小;未统计完的项按 0 计,界面据此禁用按钮。
  Map<CleanupKind, int> get cleanableSizes => {
        CleanupKind.caches: entries[StorageCategory.caches]?.bytes ?? 0,
        CleanupKind.logs: entries[StorageCategory.logs]?.bytes ?? 0,
        CleanupKind.toolOutput: _aiConfigDetail(StorageDetailKey.toolOutput),
        CleanupKind.visionSessions: _aiConfigDetail(StorageDetailKey.visionSessions),
      };

  int get selectedBytes => cleanableSizes.entries
      .where((item) => selectedCleanup.contains(item.key))
      .fold(0, (sum, item) => sum + item.value);

  int _aiConfigDetail(String key) {
    final details = entries[StorageCategory.aiConfig]?.details ?? const <StorageDetail>[];
    for (final detail in details) {
      if (detail.key == key) return detail.bytes;
    }
    return 0;
  }

  StorageUiState copyWith({
    Map<StorageCategory, StorageEntry>? entries,
    bool? scanning,
    DeviceSpace? deviceSpace,
    Set<StorageCategory>? expanded,
    bool? cleaning,
    Set<CleanupKind>? selectedCleanup,
    int? freedBytes,
    bool clearFreedBytes = false,
  }) {
    return StorageUiState(
      entries: entries ?? this.entries,
      scanning: scanning ?? this.scanning,
      deviceSpace: deviceSpace ?? this.deviceSpace,
      expanded: expanded ?? this.expanded,
      cleaning: cleaning ?? this.cleaning,
      selectedCleanup: selectedCleanup ?? this.selectedCleanup,
      freedBytes: clearFreedBytes ? null : (freedBytes ?? this.freedBytes),
    );
  }
}

final storageScannerProvider = Provider<StorageScanner>((ref) {
  return StorageScanner(
    database: ref.watch(databaseProvider),
  );
});

final storageProvider =
    NotifierProvider<StorageController, StorageUiState>(StorageController.new);

/// 存储空间统计与清理:扫描逐项到达时增量刷新界面(对齐上游 StorageViewModel)。
class StorageController extends Notifier<StorageUiState> {
  StreamSubscription<StorageEntry>? _scanSubscription;
  bool _disposed = false;

  @override
  StorageUiState build() {
    ref.onDispose(() {
      _disposed = true;
      _scanSubscription?.cancel();
    });
    // 首帧后再启动扫描,避免在 build 阶段触发状态更新。
    Future.microtask(refresh);
    return const StorageUiState();
  }

  /// 重新统计。[clearMessage] 为 false 时保留上一次的「已释放」提示(清理后重扫用)。
  Future<void> refresh({bool clearMessage = true}) async {
    if (_disposed) return;
    // 在 await 之前取好依赖:容器可能在挂了之后(如页面已销毁)才恢复执行。
    final scanner = ref.read(storageScannerProvider);
    // 不 await 取消:扫描是 async* 生成器,跑到一半时取消要等它自己停下来,
    // 期间刷新会一直卡住。旧订阅随 _scanSubscription 被替换后再自行收尾。
    final previous = _scanSubscription;
    _scanSubscription = null;
    if (previous != null) unawaited(previous.cancel());
    final space = await scanner.deviceSpace();
    if (_disposed) return;
    state = state.copyWith(
      entries: const {},
      scanning: true,
      deviceSpace: space,
      clearFreedBytes: clearMessage,
    );

    late final StreamSubscription<StorageEntry> subscription;
    // 旧订阅被取消后仍可能补发一两条结果,按身份丢弃,避免覆盖新一轮的统计。
    bool isCurrent() => !_disposed && identical(_scanSubscription, subscription);
    subscription = scanner.scan().listen(
      (entry) {
        if (!isCurrent()) return;
        state = state.copyWith(entries: {...state.entries, entry.category: entry});
      },
      onDone: () {
        if (isCurrent()) state = state.copyWith(scanning: false);
      },
      onError: (_) {
        if (isCurrent()) state = state.copyWith(scanning: false);
      },
    );
    _scanSubscription = subscription;
  }

  void toggleExpanded(StorageCategory category) {
    final expanded = Set<StorageCategory>.from(state.expanded);
    if (!expanded.remove(category)) expanded.add(category);
    state = state.copyWith(expanded: expanded);
  }

  void toggleCleanup(CleanupKind kind) {
    if (state.cleaning) return;
    final selected = Set<CleanupKind>.from(state.selectedCleanup);
    if (!selected.remove(kind)) selected.add(kind);
    state = state.copyWith(selectedCleanup: selected);
  }

  Future<void> clean(List<CleanupKind> kinds) async {
    if (_disposed || state.cleaning || kinds.isEmpty) return;
    final scanner = ref.read(storageScannerProvider);
    state = state.copyWith(cleaning: true);
    var freed = 0;
    for (final kind in kinds.toSet()) {
      freed += await scanner.clean(kind);
    }
    if (_disposed) return;
    state = state.copyWith(cleaning: false, freedBytes: freed);
    await refresh(clearMessage: false);
  }
}
