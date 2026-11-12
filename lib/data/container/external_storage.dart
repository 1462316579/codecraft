import 'package:flutter/services.dart';

/// 外部共享存储(`/storage/emulated/0/...`)的平台通道。
///
/// 两条授权路径:
/// - **全文件访问权限**(Android 11+ 的 `MANAGE_EXTERNAL_STORAGE`):授予后可直接用普通路径读写,
///   代价是该权限较重、部分分发渠道不接受;
/// - **系统目录选择器**(SAF):不挑权限,但只能访问用户选中的那棵子树。
class ExternalStorage {
  ExternalStorage._();

  static const MethodChannel _channel =
      MethodChannel('ids.codecraft.app/external_storage');

  /// 主存储根(多用户/工作资料下不是固定 `/storage/emulated/0`)。
  static Future<String> primaryRoot() async {
    try {
      final value = await _channel.invokeMethod<String>('primaryRoot');
      return (value == null || value.isEmpty) ? '/storage/emulated/0' : value;
    } catch (_) {
      return '/storage/emulated/0';
    }
  }

  /// 是否已获得外部存储访问权限(11+ 查全文件访问,10 及以下查读写权限)。
  static Future<bool> hasAccess() async {
    try {
      return await _channel.invokeMethod<bool>('hasAllFilesAccess') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 跳系统设置页申请「所有文件访问权限」;返回是否成功跳转(不代表已授予)。
  static Future<bool> requestAllFilesAccess() async {
    try {
      return await _channel.invokeMethod<bool>('requestAllFilesAccess') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 系统目录选择器:返回选中目录的绝对路径;用户取消或无法还原路径时返回 null。
  static Future<String?> pickDirectory() async {
    try {
      return await _channel.invokeMethod<String>('pickDirectory');
    } catch (_) {
      return null;
    }
  }
}