import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 容器缺失/运行环境不可用。终端与命令引擎据此给出引导文案。
class ContainerMissingException implements Exception {
  const ContainerMissingException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// PRoot 运行环境状态（由 Kotlin 侧 ProotInstaller 提供）。
class ProotStatus {
  const ProotStatus({
    this.installed = false,
    this.installing = false,
    this.stage = '',
    this.error,
  });

  final bool installed;
  final bool installing;
  final String stage;
  final String? error;
}

/// PRoot 运行环境：APK 内置的 proot 二进制，首次使用时安装到应用私有目录。
///
/// 不再内置 Termux bootstrap：proot 只需自身 + loader + libtalloc + libandroid-shmem。
class ProotRuntime {
  ProotRuntime._();

  static const MethodChannel _channel =
      MethodChannel('ids.codecraft.app/native_paths');

  static String? _filesDir;

  static Future<String> filesDir() async {
    final cached = _filesDir;
    if (cached != null) return cached;
    final value = await _channel.invokeMethod<String>('filesDir');
    if (value == null || value.isEmpty) {
      throw const ContainerMissingException('无法获取应用私有目录');
    }
    _filesDir = value;
    return value;
  }

  static Future<String> dir() async => p.join(await filesDir(), 'proot');

  static Future<String> prootPath() async =>
      p.join(await dir(), 'bin', 'proot');

  static Future<ProotStatus> status() async {
    try {
      final raw =
          await _channel.invokeMethod<Map<Object?, Object?>>('prootStatus');
      if (raw == null) return const ProotStatus();
      return ProotStatus(
        installed: raw['installed'] == true,
        installing: raw['installing'] == true,
        stage: (raw['stage'] as String?) ?? '',
        error: raw['error'] as String?,
      );
    } on MissingPluginException {
      return const ProotStatus(installed: true);
    } catch (_) {
      return const ProotStatus();
    }
  }

  static Future<bool> isInstalled() async => (await status()).installed;

  /// 安装（或修复）PRoot 运行环境；已安装时直接返回 true。
  static Future<bool> ensure({
    void Function(String stage)? onStage,
    Duration timeout = const Duration(minutes: 3),
  }) async {
    if (await isInstalled()) return true;
    unawaited(
      _channel
          .invokeMethod<bool>('ensureProot')
          .catchError((Object _) => false),
    );

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      final current = await status();
      if (current.stage.isNotEmpty) onStage?.call(current.stage);
      if (current.installed) return true;
      if (current.error != null && current.error!.isNotEmpty) return false;
      if (!current.installing && current.stage == '安装失败') return false;
    }
    return false;
  }

  /// 给容器 rootfs 里的文件补执行位（解压后调用，分批发送避免通道消息过大）。
  static Future<void> chmodExecutable(List<String> paths) async {
    const batch = 400;
    for (var start = 0; start < paths.length; start += batch) {
      final end = start + batch > paths.length ? paths.length : start + batch;
      await _channel.invokeMethod<int>(
        'chmodExecutable',
        {'paths': paths.sublist(start, end)},
      );
    }
  }
}

/// 一个已安装的容器。
class ContainerInfo {
  const ContainerInfo({
    required this.id,
    required this.name,
    required this.imageId,
    required this.path,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String imageId;
  final String path;
  final int createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imageId': imageId,
        'path': path,
        'createdAt': createdAt,
      };

  factory ContainerInfo.fromJson(Map<String, dynamic> json) => ContainerInfo(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '容器',
        imageId: (json['imageId'] as String?) ?? '',
        path: (json['path'] as String?) ?? '',
        createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      );

  /// rootfs 占用体积（字节）。
  int get sizeBytes => _directorySize(Directory(path));
}

int _directorySize(Directory dir) {
  if (!dir.existsSync()) return 0;
  var total = 0;
  try {
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += entity.lengthSync();
        } catch (_) {}
      }
    }
  } catch (_) {}
  return total;
}

/// 容器元数据：安装列表与默认容器，落盘在 shared_preferences。
class ContainerStore {
  ContainerStore._();

  static const String _prefsKey = 'codecraft.containers.v1';

  static Future<String> containersDir() async =>
      p.join(await ProotRuntime.filesDir(), 'containers');

  static Future<ContainerStoreData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return const ContainerStoreData();

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const ContainerStoreData();
      final map = decoded.cast<String, dynamic>();
      final rawList = (map['containers'] as List?) ?? const [];
      final containers = <ContainerInfo>[];
      for (final item in rawList) {
        if (item is! Map) continue;
        final info = ContainerInfo.fromJson(item.cast<String, dynamic>());
        if (info.id.isEmpty || info.path.isEmpty) continue;
        // 目录被系统清掉或用户手动删除时，同时清掉元数据。
        if (!Directory(info.path).existsSync()) continue;
        containers.add(info);
      }
      final defaultId = map['default'] as String?;
      final validDefault = containers.any((c) => c.id == defaultId)
          ? defaultId
          : (containers.isEmpty ? null : containers.first.id);
      return ContainerStoreData(
        containers: containers,
        defaultId: validDefault,
      );
    } catch (_) {
      return const ContainerStoreData();
    }
  }

  static Future<void> save(ContainerStoreData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'default': data.defaultId,
        'containers': data.containers.map((c) => c.toJson()).toList(),
      }),
    );
  }
}

/// 容器元数据快照。
class ContainerStoreData {
  const ContainerStoreData({this.containers = const [], this.defaultId});

  final List<ContainerInfo> containers;
  final String? defaultId;

  ContainerInfo? get defaultContainer {
    for (final container in containers) {
      if (container.id == defaultId) return container;
    }
    return containers.isEmpty ? null : containers.first;
  }
}

/// 容器启动参数（终端与 AI 命令共用，保证两边环境完全一致）。
class ContainerLaunchSpec {
  const ContainerLaunchSpec({
    required this.executable,
    required this.prootArguments,
    required this.shell,
    required this.environment,
    required this.workingDirectory,
    required this.containerName,
    required this.rootfs,
  });

  /// proot 可执行文件路径。
  final String executable;

  /// proot 自己的参数（-r / -b / -w 等）。
  final List<String> prootArguments;

  /// 容器内的 shell。
  final String shell;

  /// 宿主侧环境变量（含 PROOT_LOADER 等关键项）。
  final Map<String, String> environment;

  /// 启动时的工作目录。
  final String workingDirectory;

  final String containerName;
  final String rootfs;

  /// 交互式登录 shell 的完整参数。
  List<String> get loginArguments => [...prootArguments, shell, '-l'];

  /// 执行单条命令的完整参数。
  List<String> commandArguments(String command) =>
      [...prootArguments, shell, '-c', command];

  /// 执行脚本文件（AI 工具写临时脚本时使用）。
  List<String> scriptArguments(String scriptPath) =>
      [...prootArguments, shell, scriptPath];
}

/// 唯一的容器启动入口。
///
/// 负责：确保 PRoot 运行环境 → 读取默认容器 → 拼装启动参数。
/// 未安装运行环境或容器时抛 [ContainerMissingException]。
class ContainerLauncher {
  ContainerLauncher._();

  static const String _guestPath =
      '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin';

  /// 容器是否可用（运行环境 + 默认容器都在）。
  static Future<bool> isReady() async {
    if (!await ProotRuntime.isInstalled()) return false;
    final store = await ContainerStore.load();
    return store.defaultContainer != null;
  }

  static Future<ContainerLaunchSpec> build({
    String? workdir,
    void Function(String stage)? onStage,
  }) async {
    final filesDir = await ProotRuntime.filesDir();
    final runtimeDir = p.join(filesDir, 'proot');

    if (!await ProotRuntime.isInstalled()) {
      onStage?.call('正在安装 PRoot 运行环境…');
      final ok = await ProotRuntime.ensure(onStage: onStage);
      if (!ok) {
        throw const ContainerMissingException(
          'PRoot 运行环境安装失败，请到 设置 → 容器与镜像 重试',
        );
      }
    }

    final store = await ContainerStore.load();
    final container = store.defaultContainer;
    if (container == null) {
      throw const ContainerMissingException(
        '尚未安装容器，请到 设置 → 容器与镜像 下载镜像',
      );
    }

    // 工作区（应用文档目录）以相同绝对路径映射进容器：
    // AI 工具给出的宿主绝对路径在容器里同样有效，无需再做路径换算。
    final docs = (await getApplicationDocumentsDirectory()).path;
    final cwd = (workdir != null && workdir.isNotEmpty) ? workdir : docs;

    final prootArguments = <String>[
      '--kill-on-exit',
      '--link2symlink',
      '-0',
      '-r', container.path,
      '-b', '/dev',
      '-b', '/proc',
      '-b', '/sys',
      '-b', '$docs:$docs',
      '-w', cwd,
    ];

    final environment = <String, String>{
      // proot 的 loader 路径是编译期写死的 Termux 绝对路径，只能靠环境变量覆盖。
      'PROOT_LOADER': p.join(runtimeDir, 'libexec', 'proot', 'loader'),
      'PROOT_LOADER_32': p.join(runtimeDir, 'libexec', 'proot', 'loader32'),
      'PROOT_TMP_DIR': p.join(runtimeDir, 'tmp'),
      // 部分 Android 内核上 seccomp 加速不可用，交给 proot 走 ptrace 的普通路径。
      'PROOT_NO_SECCOMP': '1',
      'HOME': '/root',
      'TERM': 'xterm-256color',
      'COLORTERM': 'truecolor',
      'LANG': 'C.UTF-8',
      'PATH': _guestPath,
    };

    try {
      for (final dir in [
        p.join(runtimeDir, 'tmp'),
        p.join(await ContainerStore.containersDir(), '.downloads'),
      ]) {
        await Directory(dir).create(recursive: true);
      }
      // proot 的 -b/-w 要求 guest 侧路径存在：先把工作区的同级路径
      // 在 rootfs 里建出来，绑定后 AI 的宿主绝对路径就能直接使用。
      final guestWorkdir = cwd.replaceFirst(RegExp(r'^/+'), '');
      if (guestWorkdir.isNotEmpty) {
        await Directory(p.join(container.path, guestWorkdir))
            .create(recursive: true);
      }
    } catch (_) {}

    return ContainerLaunchSpec(
      executable: p.join(runtimeDir, 'bin', 'proot'),
      prootArguments: prootArguments,
      shell: '/bin/sh',
      environment: environment,
      workingDirectory: cwd,
      containerName: container.name,
      rootfs: container.path,
    );
  }
}
