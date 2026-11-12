import 'package:flutter/services.dart';

/// 「软件权限」页里没有运行时弹窗的几项状态。
class SoftwarePermissionStatus {
  const SoftwarePermissionStatus({this.battery = false, this.shizuku = false});

  /// 是否已加入电池优化白名单。
  final bool battery;

  /// Shizuku 是否已安装。
  final bool shizuku;
}

/// 电池优化 / 自启动 / Shizuku。
///
/// 这几项系统都不提供应用内权限弹窗:电池优化是系统确认框,自启动是厂商页面,
/// Shizuku 是独立应用。存储与通知的运行时权限走 [RuntimePermissions]。
class SoftwarePermissions {
  SoftwarePermissions._();

  static const MethodChannel _channel =
      MethodChannel('ids.codecraft.app/software_permissions');

  static Future<SoftwarePermissionStatus> status() async {
    try {
      final map = await _channel.invokeMapMethod<String, Object?>('status');
      return SoftwarePermissionStatus(
        battery: (map?['battery'] as bool?) ?? false,
        shizuku: (map?['shizuku'] as bool?) ?? false,
      );
    } catch (_) {
      return const SoftwarePermissionStatus();
    }
  }

  /// 申请加入电池优化白名单(系统确认框);结果需回到前台后重新查询。
  static Future<bool> requestIgnoreBattery() async {
    try {
      return await _channel.invokeMethod<bool>('requestIgnoreBattery') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 跳厂商自启动管理页(无对应页面时退到应用详情)。
  static Future<bool> openAutoStart() async {
    try {
      return await _channel.invokeMethod<bool>('openAutoStart') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 打开 Shizuku;未安装时去应用市场。
  static Future<bool> openShizuku() async {
    try {
      return await _channel.invokeMethod<bool>('openShizuku') ?? false;
    } catch (_) {
      return false;
    }
  }
}