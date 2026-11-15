import 'dart:io';
import 'dart:isolate';

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
    this.fallbackUrls = const [],
    this.autoInstall = false,
  });

  /// 镜像 id，同时作为容器 id 前缀。
  final String id;
  final String name;
  final String description;
  final String url;
  final String sizeLabel;

  /// 主地址失败时依次尝试的备用地址（国内镜像加速）。
  final List<String> fallbackUrls;

  /// 是否在首次启动时自动下载安装。
  final bool autoInstall;
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
    description: 'glibc + apt，最新 LTS（Resolute Raccoon），首次启动自动下载',
    url:
        'https://mirrors.ustc.edu.cn/ubuntu-cdimage/ubuntu-base/releases/26.04/release/ubuntu-base-26.04.1-base-arm64.tar.gz',
    fallbackUrls: [
      'https://mirrors.aliyun.com/ubuntu-cdimage/ubuntu-base/releases/26.04/release/ubuntu-base-26.04.1-base-arm64.tar.gz',
      'https://cdimage.ubuntu.com/ubuntu-base/releases/26.04/release/ubuntu-base-26.04.1-base-arm64.tar.gz',
    ],
    sizeLabel: '约 35 MB',
    autoInstall: true,
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
    // 首次启动自动下载 Ubuntu 26.04（国内镜像源），无需用户手动点击。
    if (!await ContainerStore.autoInstallSeeded()) {
      final image =
          kContainerImages.where((item) => item.autoInstall).firstOrNull;
      if (image != null && !state.busy) {
        if (state.containers.any((c) => c.imageId == image.id)) {
          await ContainerStore.markAutoInstallSeeded();
        } else {
          final info = await install(image);
          if (info != null) await ContainerStore.markAutoInstallSeeded();
        }
      }
    }
  }

  /// 下载并安装一个镜像，成功后若没有默认容器则设为默认。
  Future<ContainerInfo?> install(ContainerImage image) async {
    if (state.busy) return null;
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
        await _downloadImage(image, archiveFile, (received, total) {
          if (total > 0) {
            final ratio = (received / total).clamp(0.0, 1.0);
            state = state.copyWith(
              busyProgress: ratio,
              busyStage: () =>
                  '正在下载 ${image.name} · ${(ratio * 100).toStringAsFixed(0)}%',
            );
          } else {
            state = state.copyWith(
              busyStage: () => '正在下载 ${image.name} · '
                  '${(received / 1024 / 1024).toStringAsFixed(1)} MB',
            );
          }
        });
      }

      // 部分镜像站出错时会返回 200 的 HTML 页面，解压前先校验 gzip 头。
      final head = await archiveFile.openRead(0, 2).first;
      if (head.length < 2 || head[0] != 0x1f || head[1] != 0x8b) {
        throw StateError('下载内容不是有效的镜像压缩包，请重试');
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
      final execPaths = await _extractRootfs(archiveFile.path, staging.path);

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
      // 安装失败时清掉压缩包，避免下次复用不完整/损坏的文件。
      try {
        final dir = await ContainerStore.containersDir();
        final archive = File(p.join(dir, '.downloads', '${image.id}.tar.gz'));
        if (archive.existsSync()) archive.deleteSync();
      } catch (_) {}
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

  /// 下载镜像压缩包：直连下载，失败时依次换备用源并重试。
  Future<void> _downloadImage(
    ContainerImage image,
    File target,
    void Function(int received, int total) onProgress,
  ) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..autoUncompress = false
      ..userAgent = 'CodeCraft-Android'
      // 系统里残留的代理（如抓包代理）会让下载卡死，这里强制直连。
      ..findProxy = ((_) => 'DIRECT');
    final urls = <String>[
      image.url,
      ...image.fallbackUrls,
    ].where((url) => url.isNotEmpty).toList();

    Object? lastError;
    try {
      for (final url in urls) {
        // 单个源失败两次再换下一个，避免一次抖动就整体失败。
        for (var attempt = 0; attempt < 2; attempt++) {
          final part = File('${target.path}.part');
          IOSink? sink;
          try {
            final request = await client.getUrl(Uri.parse(url));
            final response = await request.close();
            if (response.statusCode != HttpStatus.ok) {
              await response.drain<void>();
              throw HttpException(
                'HTTP ${response.statusCode}',
                uri: Uri.parse(url),
              );
            }
            final total = response.contentLength;
            var received = 0;
            onProgress(0, total);
            sink = part.openWrite();
            await for (final chunk in response) {
              sink.add(chunk);
              received += chunk.length;
              onProgress(received, total);
            }
            await sink.flush();
            await sink.close();
            sink = null;
            if ((await part.length()) == 0) {
              throw const HttpException('下载内容为空');
            }
            if (await target.exists()) await target.delete();
            await part.rename(target.path);
            return;
          } catch (e) {
            lastError = e;
            // 半截文件不能复用，删掉后重新下载。
            try {
              await sink?.close();
            } catch (_) {}
            try {
              if (await part.exists()) await part.delete();
            } catch (_) {}
          }
        }
      }
    } finally {
      client.close(force: true);
    }
    throw lastError ?? StateError('镜像下载失败');
  }

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
    if (e is SocketException) {
      final detail = e.osError?.message ?? e.message;
      return '下载失败：网络连接中断（$detail）';
    }
    if (e is HandshakeException) return '下载失败：HTTPS 握手失败（${e.message}）';
    if (e is HttpException) return '下载失败：${e.message}';
    if (e is FileSystemException) {
      return '安装失败：写入文件出错（${e.osError?.message ?? e.message}）';
    }
    if (e is StateError) return '安装失败：${e.message}';
    return '操作失败：$e';
  }
}

/// 解压 rootfs。必须是顶层函数：在 `install` 里直接写闭包会共享 capture context，
/// 把 ContainerNotifier（含 Riverpod 容器）一起发进 isolate，直接报 unsendable。
Future<List<String>> _extractRootfs(String archive, String target) =>
    Isolate.run(() => extractTarGz(archive, target));
