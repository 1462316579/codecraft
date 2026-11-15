import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'container_launcher.dart';

/// 可下载的容器镜像（均为 aarch64 rootfs 压缩包）。
class ContainerImage {
  const ContainerImage({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.sizeLabel,
  });

  /// 镜像 id，同时作为容器 id 前缀。
  final String id;
  final String name;
  final String description;
  final String url;
  final String sizeLabel;
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
    description: 'glibc + apt，最新 LTS（Resolute Raccoon），推荐',
    url:
        'https://cdimage.ubuntu.com/ubuntu-base/releases/26.04/release/ubuntu-base-26.04.1-base-arm64.tar.gz',
    sizeLabel: '约 35 MB',
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
        () => _extractTarGz(archiveFile.path, staging.path),
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

// ---------------------------------------------------------------- rootfs 解压

/// 解压 tar.gz 到 [rootPath]，返回需要补执行位的文件路径。
///
/// 用 dart:io 的 gzip 解码器（原生 zlib）先把压缩包流式解成 tar，再自己单遍扫描：
/// archive 包的纯 Dart 解压慢一个数量级，而它的惰性 tar 解码又无法在扫描时
/// 安全取回文件内容，所以这里自己解析（保留 mode / 符号链接 / 硬链接语义）。
Future<List<String>> _extractTarGz(String archivePath, String rootPath) async {
  final tarPath = '$rootPath.part.tar';
  final tarFile = File(tarPath);
  try {
    await File(archivePath)
        .openRead()
        .transform(gzip.decoder)
        .pipe(tarFile.openWrite());
    return _extractTar(tarPath, rootPath);
  } finally {
    if (tarFile.existsSync()) {
      try {
        tarFile.deleteSync();
      } catch (_) {}
    }
  }
}

List<String> _extractTar(String tarPath, String rootPath) {
  final raf = File(tarPath).openSync(mode: FileMode.read);
  final total = raf.lengthSync();
  final execPaths = <String>[];
  final header = Uint8List(512);
  String? pendingName;
  String? pendingLink;
  var offset = 0;

  try {
    while (offset + 512 <= total) {
      raf.setPositionSync(offset);
      final read = raf.readIntoSync(header);
      if (read < 512) break;
      if (_isZeroBlock(header)) break;

      final name = _readString(header, 0, 100);
      final mode = _readOctal(header, 100, 8);
      final size = _readOctal(header, 124, 12);
      final typeByte = header[156];
      final type = typeByte == 0 ? '0' : String.fromCharCode(typeByte);
      var link = _readString(header, 157, 100);
      final prefix = _readString(header, 345, 155);

      final dataOffset = offset + 512;
      offset = dataOffset + ((size + 511) ~/ 512) * 512;

      if (type == 'L') {
        pendingName = _readText(raf, dataOffset, size);
        continue;
      }
      if (type == 'K') {
        pendingLink = _readText(raf, dataOffset, size);
        continue;
      }
      if (type == 'x' || type == 'g') {
        final record = _readText(raf, dataOffset, size);
        final parsed = _parsePax(record);
        if (parsed.name != null) pendingName = parsed.name;
        if (parsed.link != null) pendingLink = parsed.link;
        continue;
      }

      var entryName = pendingName ?? (prefix.isEmpty ? name : '$prefix/$name');
      pendingName = null;
      final nextLink = pendingLink;
      if (nextLink != null) {
        link = nextLink;
        pendingLink = null;
      }

      final clean = _sanitizePath(entryName);
      if (clean == null || clean.isEmpty) continue;
      final targetPath = p.join(rootPath, clean);

      switch (type) {
        case '5': // 目录
          Directory(targetPath).createSync(recursive: true);
          break;
        case '2': // 符号链接
          _ensureParent(targetPath);
          _recreateLink(targetPath, link);
          break;
        case '1': // 硬链接（Android 上同样用符号链接等价实现）
          _ensureParent(targetPath);
          final hardTarget = _sanitizePath(link);
          _recreateLink(
            targetPath,
            hardTarget == null ? link : p.join(rootPath, hardTarget),
          );
          break;
        case '3':
        case '4':
        case '6': // 设备节点 / FIFO，容器里用不到
          break;
        default: // '0' / '7'
          final file = File(targetPath);
          file.parent.createSync(recursive: true);
          final sink = file.openSync(mode: FileMode.write);
          try {
            var remaining = size;
            var position = dataOffset;
            final buffer = Uint8List(64 * 1024);
            while (remaining > 0) {
              raf.setPositionSync(position);
              final chunk = remaining > buffer.length ? buffer.length : remaining;
              final n = raf.readIntoSync(buffer, 0, chunk);
              if (n <= 0) break;
              sink.writeFromSync(buffer, 0, n);
              position += n;
              remaining -= n;
            }
          } finally {
            sink.closeSync();
          }
          if ((mode & 0x49) != 0) execPaths.add(targetPath);
          break;
      }
    }
  } finally {
    raf.closeSync();
  }
  return execPaths;
}

void _ensureParent(String path) =>
    Directory(p.dirname(path)).createSync(recursive: true);

void _recreateLink(String path, String target) {
  final link = Link(path);
  if (link.existsSync()) link.deleteSync();
  final file = File(path);
  if (file.existsSync()) file.deleteSync();
  final dir = Directory(path);
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  link.createSync(target);
}

/// 清理 tar 里的相对/绝对路径，拒绝越界（`..`）。
String? _sanitizePath(String raw) {
  var path = raw.replaceAll('\\', '/');
  while (path.startsWith('./')) {
    path = path.substring(2);
  }
  if (path.isEmpty) return null;
  if (path.startsWith('/')) path = path.substring(1);
  final segments = <String>[];
  for (final segment in path.split('/')) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..') {
      if (segments.isEmpty) return null;
      segments.removeLast();
      continue;
    }
    segments.add(segment);
  }
  return segments.join('/');
}

bool _isZeroBlock(Uint8List block) {
  for (final byte in block) {
    if (byte != 0) return false;
  }
  return true;
}

String _readString(Uint8List buffer, int offset, int length) {
  var end = offset;
  final limit = offset + length;
  while (end < limit && buffer[end] != 0) {
    end++;
  }
  return utf8.decode(buffer.sublist(offset, end), allowMalformed: true);
}

int _readOctal(Uint8List buffer, int offset, int length) {
  var value = 0;
  var seen = false;
  for (var i = offset; i < offset + length; i++) {
    final byte = buffer[i];
    if (byte == 0 || byte == 0x20) {
      if (seen) break;
      continue;
    }
    if (byte < 0x30 || byte > 0x37) break;
    value = value * 8 + (byte - 0x30);
    seen = true;
  }
  return value;
}

String _readText(RandomAccessFile raf, int offset, int size) {
  if (size <= 0) return '';
  raf.setPositionSync(offset);
  final bytes = raf.readSync(size);
  return utf8.decode(bytes, allowMalformed: true);
}

class _PaxRecord {
  const _PaxRecord({this.name, this.link});

  final String? name;
  final String? link;
}

_PaxRecord _parsePax(String text) {
  String? name;
  String? link;
  for (final line in const LineSplitter().convert(text)) {
    final space = line.indexOf(' ');
    if (space <= 0) continue;
    final rest = line.substring(space + 1);
    final eq = rest.indexOf('=');
    if (eq <= 0) continue;
    final key = rest.substring(0, eq);
    final value = rest.substring(eq + 1);
    if (key == 'path') name = value;
    if (key == 'linkpath') link = value;
  }
  return _PaxRecord(name: name, link: link);
}
