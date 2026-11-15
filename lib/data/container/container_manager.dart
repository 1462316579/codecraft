import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'container_launcher.dart';
import 'tar_extractor.dart';

/// 可下载的容器镜像（均为 aarch64 rootfs 压缩包）。
class ContainerImage {
  const ContainerImage({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.sizeLabel,
    this.bundled = false,
  });

  /// 镜像 id，同时作为容器 id 前缀。
  final String id;
  final String name;
  final String description;
  final String url;
  final String sizeLabel;

  /// 是否随 APK 内置（无需联网下载）。
  final bool bundled;
}

/// 内置镜像源。全部已验证可下载（HTTP 200）。
const List<ContainerImage> kContainerImages = [
  ContainerImage(
    id: 'alpine-3.21',
    name: 'Alpine 3.21',
    description: 'musl + apk，体积最小，推荐日常使用',
    url:
        'https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/aarch64/alpine-minirootfs-3.21.3-aarch64.tar.gz',
    sizeLabel: '3.8 MB',
  ),
  ContainerImage(
    id: 'alpine-3.20',
    name: 'Alpine 3.20',
    description: 'musl + apk，上一稳定分支',
    url:
        'https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/aarch64/alpine-minirootfs-3.20.3-aarch64.tar.gz',
    sizeLabel: '3.9 MB',
  ),
  ContainerImage(
    id: 'ubuntu-26.04',
    name: 'Ubuntu 26.04 Base',
    description: 'glibc + apt，最新 LTS（Resolute Raccoon），已内置',
    url: '',
    sizeLabel: '内置',
    bundled: true,
  ),
  ContainerImage(
    id: 'ubuntu-24.04',
    name: 'Ubuntu 24.04 Base',
    description: 'glibc + apt，兼容性最好，安装较慢',
    url:
        'https://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/ubuntu-base-24.04.5-base-arm64.tar.gz',
    sizeLabel: '约 30 MB',
  ),
];

/// 容器页状态。
class ContainerState {
  const ContainerState({
    this.containers = const [],
    this.defaultId,
    this.runtimeInstalled = false,
    this.runtimeStage = '',
    this.loading = true,
    this.busyImageId,
    this.busyProgress = 0,
    this.busyStage,
    this.error,
  });

  final List<ContainerInfo> containers;
  final String? defaultId;

  /// PRoot 运行环境是否已安装。
  final bool runtimeInstalled;
  final String runtimeStage;

  final bool loading;

  /// 正在安装的镜像 id（为空表示空闲）。
  final String? busyImageId;
  final double busyProgress;
  final String? busyStage;
  final String? error;

  bool get busy => busyImageId != null;

  ContainerInfo? get defaultContainer {
    for (final container in containers) {
      if (container.id == defaultId) return container;
    }
    return containers.isEmpty ? null : containers.first;
  }

  ContainerState copyWith({
    List<ContainerInfo>? containers,
    String? Function()? defaultId,
    bool? runtimeInstalled,
    String? runtimeStage,
    bool? loading,
    String? Function()? busyImageId,
    double? busyProgress,
    String? Function()? busyStage,
    String? Function()? error,
  }) =>
      ContainerState(
        containers: containers ?? this.containers,
        defaultId: defaultId == null ? this.defaultId : defaultId(),
        runtimeInstalled: runtimeInstalled ?? this.runtimeInstalled,
        runtimeStage: runtimeStage ?? this.runtimeStage,
        loading: loading ?? this.loading,
        busyImageId: busyImageId == null ? this.busyImageId : busyImageId(),
        busyProgress: busyProgress ?? this.busyProgress,
        busyStage: busyStage == null ? this.busyStage : busyStage(),
        error: error == null ? this.error : error(),
      );
}

final containerProvider =
    NotifierProvider<ContainerNotifier, ContainerState>(ContainerNotifier.new);

/// 容器管理：下载镜像、解压安装、删除、设默认。
class ContainerNotifier extends Notifier<ContainerState> {
  @override
  ContainerState build() {
    Future<void>.microtask(refresh);
    return const ContainerState();
  }

  /// 刷新运行环境状态与已安装容器列表。
  Future<void> refresh() async {
    final store = await ContainerStore.load();
    final status = await ProotRuntime.status();
    state = state.copyWith(
      containers: store.containers,
      defaultId: () => store.defaultId,
      runtimeInstalled: status.installed,
      runtimeStage: status.stage,
      loading: false,
    );
    // 首次启动（或升级到内置 Ubuntu 26.04 的版本）自动装好内置镜像，
    // 用户打开设置就能看到已安装的容器，不需要再下载。
    if (!await ContainerStore.bundledSeeded()) {
      final image =
          kContainerImages.where((item) => item.bundled).firstOrNull;
      if (image != null && !state.busy) {
        final info = await _installBundled(image);
        if (info != null) await ContainerStore.markBundledSeeded();
      }
    }
  }

  /// 安装（修复）PRoot 运行环境。
  Future<void> ensureRuntime() async {
    if (state.runtimeInstalled) return;
    state = state.copyWith(error: () => null);
    final ok = await ProotRuntime.ensure(
      onStage: (stage) => state = state.copyWith(runtimeStage: stage),
    );
    final status = await ProotRuntime.status();
    state = state.copyWith(
      runtimeInstalled: ok || status.installed,
      runtimeStage: status.stage,
      error: () => ok ? null : 'PRoot 运行环境安装失败${status.error == null ? '' : '：${status.error}'}',
    );
  }

  /// 下载并安装一个镜像，成功后若没有默认容器则设为默认。
  Future<ContainerInfo?> install(ContainerImage image) async {
    if (state.busy) return null;
    if (image.bundled) return _installBundled(image);
    state = state.copyWith(
      busyImageId: () => image.id,
      busyProgress: 0,
      busyStage: () => '准备下载 ${image.name}…',
      error: () => null,
    );

    String? stagingPath;
    try {
      final containersDir = await ContainerStore.containersDir();
      final downloadDir = Directory(p.join(containersDir, '.downloads'));
      await downloadDir.create(recursive: true);
      final archiveFile = File(p.join(downloadDir.path, '${image.id}.tar.gz'));

      if (!await archiveFile.exists() || await archiveFile.length() == 0) {
        final dio = Dio(
          BaseOptions(
            receiveTimeout: const Duration(minutes: 15),
            headers: {'User-Agent': 'CodeCraft-Android'},
          ),
        );
        await dio.download(
          image.url,
          archiveFile.path,
          onReceiveProgress: (received, total) {
            if (total > 0) {
              final ratio = (received / total).clamp(0.0, 1.0);
              state = state.copyWith(
                busyProgress: ratio,
                busyStage: () =>
                    '正在下载 ${image.name} · ${(ratio * 100).toStringAsFixed(0)}%',
              );
            } else {
              state = state.copyWith(
                busyStage: () => '正在下载 ${image.name}…',
              );
            }
          },
        );
      }

      state = state.copyWith(
        busyProgress: 1,
        busyStage: () => '正在解压 rootfs（${image.name}）…',
      );

      final id = _uniqueId(image.id);
      final staging = Directory(p.join(containersDir, '.staging-$id'));
      if (staging.existsSync()) staging.deleteSync(recursive: true);
      staging.createSync(recursive: true);
      stagingPath = staging.path;

      // 解压耗时且是纯 CPU/磁盘操作，放到后台 isolate，避免卡住界面。
      final execPaths = await Isolate.run(
        () => extractTarGz(archiveFile.path, staging.path),
      );

      // 容器内没有 Android 的 DNS 配置，写一份公共 DNS，装包后才能联网。
      final etc = Directory(p.join(staging.path, 'etc'));
      etc.createSync(recursive: true);
      File(p.join(etc.path, 'resolv.conf')).writeAsStringSync(
        'nameserver 8.8.8.8\nnameserver 1.1.1.1\n',
      );

      // 注意：Alpine 的 /bin/sh 是指向 /bin/busybox 的符号链接，
      // 而该绝对路径只有在容器内才有效，宿主侧不能用 existsSync（会跟随链接）。
      if (FileSystemEntity.typeSync(
            p.join(staging.path, 'bin', 'sh'),
            followLinks: false,
          ) ==
          FileSystemEntityType.notFound) {
        throw StateError('镜像缺少 /bin/sh，无法作为容器使用');
      }

      if (execPaths.isNotEmpty) {
        await ProotRuntime.chmodExecutable(execPaths);
      }

      final finalDir = Directory(p.join(containersDir, id));
      if (finalDir.existsSync()) finalDir.deleteSync(recursive: true);
      staging.renameSync(finalDir.path);
      stagingPath = null;

      final info = ContainerInfo(
        id: id,
        name: image.name,
        imageId: image.id,
        path: finalDir.path,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final containers = [...state.containers, info];
      final defaultId = state.defaultId ?? id;
      await ContainerStore.save(
        ContainerStoreData(containers: containers, defaultId: defaultId),
      );

      // 安装成功后不再需要压缩包（重新安装会再次下载）。
      try {
        await archiveFile.delete();
      } catch (_) {}

      state = state.copyWith(
        containers: containers,
        defaultId: () => defaultId,
        busyImageId: () => null,
        busyProgress: 0,
        busyStage: () => null,
      );
      return info;
    } catch (e) {
      state = state.copyWith(
        busyImageId: () => null,
        busyProgress: 0,
        busyStage: () => null,
        error: () => _describe(e),
      );
      return null;
    } finally {
      final staging = stagingPath;
      if (staging != null) {
        try {
          final dir = Directory(staging);
          if (dir.existsSync()) dir.deleteSync(recursive: true);
        } catch (_) {}
      }
    }
  }

  /// 安装 APK 内置镜像（无需联网）。
  Future<ContainerInfo?> _installBundled(ContainerImage image) async {
    state = state.copyWith(
      busyImageId: () => image.id,
      busyProgress: 0,
      busyStage: () => '正在安装内置 ${image.name}…',
      error: () => null,
    );
    try {
      final info = await ContainerLauncher.installBundled(
        onStage: (stage) => state = state.copyWith(
          busyProgress: 1,
          busyStage: () => stage,
        ),
      );
      final store = await ContainerStore.load();
      state = state.copyWith(
        containers: store.containers,
        defaultId: () => store.defaultId,
        busyImageId: () => null,
        busyProgress: 0,
        busyStage: () => null,
      );
      return info;
    } catch (e) {
      state = state.copyWith(
        busyImageId: () => null,
        busyProgress: 0,
        busyStage: () => null,
        error: () => _describe(e),
      );
      return null;
    }
  }

  /// 删除容器；若删除的是默认容器，自动回退到剩余的第一个。
  Future<void> remove(String id) async {
    final target = state.containers.where((c) => c.id == id).firstOrNull;
    if (target == null) return;
    try {
      final dir = Directory(target.path);
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    } catch (e) {
      state = state.copyWith(error: () => '删除失败：$e');
      return;
    }

    final containers = state.containers.where((c) => c.id != id).toList();
    final defaultId = state.defaultId == id
        ? (containers.isEmpty ? null : containers.first.id)
        : state.defaultId;
    await ContainerStore.save(
      ContainerStoreData(containers: containers, defaultId: defaultId),
    );
    state = state.copyWith(
      containers: containers,
      defaultId: () => defaultId,
      error: () => null,
    );
  }

  Future<void> setDefault(String id) async {
    if (state.defaultId == id) return;
    await ContainerStore.save(
      ContainerStoreData(containers: state.containers, defaultId: id),
    );
    state = state.copyWith(defaultId: () => id);
  }

  void clearError() => state = state.copyWith(error: () => null);

  String _uniqueId(String base) {
    final existing = state.containers.map((c) => c.id).toSet();
    if (!existing.contains(base)) return base;
    for (var i = 2; i < 1000; i++) {
      final candidate = '$base-$i';
      if (!existing.contains(candidate)) return candidate;
    }
    return '$base-${DateTime.now().millisecondsSinceEpoch}';
  }

  String _describe(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status != null) return '下载失败（HTTP $status）';
      return '下载失败：${e.message ?? e.type.name}';
    }
    return e.toString();
  }
}
