
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 一个已安装应用:公开元数据 + 按需加载的图标。
class InstalledApp {
  const InstalledApp({
    required this.packageName,
    required this.label,
    required this.versionName,
    required this.versionCode,
    this.isSystem = false,
    this.apkPath,
    this.apkPaths = const [],
  });

  final String packageName;
  final String label;
  final String versionName;
  final int versionCode;
  final bool isSystem;

  /// 安装包路径(`ApplicationInfo.sourceDir`);逆向项目按它解包。
  final String? apkPath;

  /// 全部分卷:base.apk 在前,其后是 ABI/语言等分卷。
  final List<String> apkPaths;

  /// 列表行的第三行文案:`1.2.3 (45)`;缺版本号时只显示 code。
  String get versionLabel => versionName.isEmpty ? '$versionCode' : '$versionName ($versionCode)';

  static InstalledApp fromMap(Map<Object?, Object?> map) => InstalledApp(
        packageName: map['packageName'] as String? ?? '',
        label: map['label'] as String? ?? '',
        versionName: map['versionName'] as String? ?? '',
        versionCode: (map['versionCode'] as int?) ?? 0,
        isSystem: (map['isSystem'] as bool?) ?? false,
        apkPath: map['apkPath'] as String?,
        apkPaths: switch (map['apkPaths']) {
          final List<Object?> list => [
              for (final item in list)
                if (item is String) item,
            ],
          _ => const [],
        },
      );
}

final installedAppsProvider =
    FutureProvider<List<InstalledApp>>((ref) => InstalledAppsService.listApps());

/// 每个包名的图标;FutureProvider.family 自带缓存,列表滚动时不重复取。
final appIconProvider = FutureProvider.family<Uint8List?, String>(
  (ref, packageName) => InstalledAppsService.appIcon(packageName),
);

/// 与宿主 Android 通信:读已安装应用的公开信息。
class InstalledAppsService {
  static const _channel = MethodChannel('ids.codecraft.app/installed_apps');

  static Future<List<InstalledApp>> listApps() async {
    final rows = await _channel.invokeListMethod<Object?>('listApps') ?? const [];
    return [
      for (final row in rows)
        if (row is Map) InstalledApp.fromMap(row),
    ];
  }

  static Future<Uint8List?> appIcon(String packageName) =>
      _channel.invokeMethod<Uint8List>('appIcon', {'packageName': packageName});

  /// 预热并返回可枚举到的第三方应用数。
  ///
  /// 部分 ROM 在应用首次查询已安装应用时弹自己的授权框(「是否允许获取已安装的应用信息」),
  /// 该框随查询结束而消失、几乎抓不住。放在首次启动的授权流程里调用一次,
  /// 让这一步发生在用户还没有开始操作的时候。
  /// 进程级缓存:首次启动授权流程已枚举过,后续 entering 页面时直接复用,避免重复 enumerate 卡顿。
  static int? _cachedThirdPartyCount;

  /// 预热并返回可枚举到的第三方应用数。
  ///
  /// 部分 ROM 在应用首次查询已安装应用时弹自己的授权框(「是否允许获取已安装的应用信息」),
  /// 该框随查询结束而消失、几乎抓不住。放在首次启动的授权流程里调用一次,
  /// 让这一步发生在用户还没有开始操作的时候。
  static Future<int> warmUp({bool force = false}) async {
    if (!force && _cachedThirdPartyCount != null) return _cachedThirdPartyCount!;
    try {
      final apps = await listApps();
      _cachedThirdPartyCount = apps.where((app) => !app.isSystem).length;
      return _cachedThirdPartyCount!;
    } catch (_) {
      _cachedThirdPartyCount = 0;
      return 0;
    }
  }

  /// 测试用:清空缓存。
  static void resetCache() => _cachedThirdPartyCount = null;
}
