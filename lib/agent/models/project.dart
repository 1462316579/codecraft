import 'dart:convert';
import 'dart:typed_data';

import 'chat_session.dart';

/// 项目的类型:决定工作区与可用工具集。
enum ProjectKind {
  /// 编程:内部沙盒工作区。
  coding,

  /// 写作:外部「AI小说」目录。
  writing,

  /// 应用逆向:目标是某个已安装的应用。
  reverse;

  static ProjectKind parse(String? value) => values.firstWhere(
        (k) => k.name == value,
        orElse: () => ProjectKind.coding,
      );
}

/// 一个项目:可命名的容器,下挂多条会话。
///
/// 与会话分开的意义:聊天页的「新建会话」只在本项目内加一条,不会再凭空多出项目。
/// 「应用逆向」项目额外持有目标应用的元数据(包名/名称/版本/图标文件),列表行按截图样式展示。
class Project {
  const Project({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.mode = AgentMode.build,
    this.kind = ProjectKind.coding,
    this.appPackage,
    this.appName,
    this.appVersionName,
    this.appVersionCode,
    this.appIcon,
    this.appApkPath,
    this.appApkPaths = const [],
  });

  final String id;
  final String name;
  final int createdAt;
  final int updatedAt;
  final AgentMode mode;
  final ProjectKind kind;

  /// 应用逆向项目的目标应用;其余类型为 null。
  final String? appPackage;
  final String? appName;
  final String? appVersionName;
  final int? appVersionCode;
  final Uint8List? appIcon;

  /// 目标应用安装包在设备上的路径(`ApplicationInfo.sourceDir`)。
  ///
  /// 逆向项目的文件面板按它读 APK 内的文件;拿不到路径时文件面板退回工作区。
  final String? appApkPath;

  /// 全部分卷(base 在前):逆向项目解包时逐个展开,原生库常只在分卷里。
  final List<String> appApkPaths;

  /// 实际要解包的安装包列表:没有分卷信息时退回单个 [appApkPath]。
  List<String> get apkPathsToExtract {
    if (appApkPaths.isNotEmpty) return appApkPaths;
    final single = appApkPath;
    return (single == null || single.isEmpty) ? const [] : [single];
  }

  /// 列表第三行文案:`1.2.3 (45)`。
  String get appVersionLabel {
    final code = appVersionCode ?? 0;
    final name = appVersionName ?? '';
    return name.isEmpty ? '$code' : '$name ($code)';
  }

  Project copyWith({
    String? name,
    int? updatedAt,
    AgentMode? mode,
    String? appPackage,
    String? appName,
    String? appVersionName,
    int? appVersionCode,
    Uint8List? appIcon,
    String? appApkPath,
  }) =>
      Project(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        mode: mode ?? this.mode,
        kind: kind,
        appPackage: appPackage ?? this.appPackage,
        appName: appName ?? this.appName,
        appVersionName: appVersionName ?? this.appVersionName,
        appVersionCode: appVersionCode ?? this.appVersionCode,
        appIcon: appIcon ?? this.appIcon,
        appApkPath: appApkPath ?? this.appApkPath,
        appApkPaths: appApkPaths,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'mode': mode.name,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'kind': kind.name,
        'appPackage': appPackage,
        'appName': appName,
        'appVersionName': appVersionName,
        'appVersionCode': appVersionCode,
        'appIcon': appIcon,
        'appApkPath': appApkPath,
        'appApkPaths': appApkPaths.isEmpty ? null : jsonEncode(appApkPaths),
      };

  static Project fromMap(Map<String, Object?> map) => Project(
        id: map['id'] as String,
        name: (map['name'] as String?) ?? '',
        createdAt: (map['createdAt'] as int?) ?? 0,
        updatedAt: (map['updatedAt'] as int?) ?? 0,
        mode: AgentMode.parse(map['mode'] as String?),
        kind: ProjectKind.parse(map['kind'] as String?),
        appPackage: map['appPackage'] as String?,
        appName: map['appName'] as String?,
        appVersionName: map['appVersionName'] as String?,
        appVersionCode: map['appVersionCode'] as int?,
        appIcon: map['appIcon'] as Uint8List?,
        appApkPath: map['appApkPath'] as String?,
        appApkPaths: _decodePaths(map['appApkPaths']),
      );

  static List<String> _decodePaths(Object? raw) {
    if (raw is! String || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is String && item.isNotEmpty) item,
      ];
    } catch (_) {
      return const [];
    }
  }
}