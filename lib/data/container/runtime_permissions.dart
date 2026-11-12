import 'package:flutter/services.dart';

/// 首次启动的运行时权限:直接触发系统的原生授权弹窗。
///
/// 具体申请哪些由原生侧按 Android 版本决定(13+ 媒体权限,12 及以下存储读写),
/// Dart 只负责「请求一次」和「查询是否还有待授予项」。
class RuntimePermissions {
  RuntimePermissions._();

  static const MethodChannel _channel = MethodChannel('ids.codecraft.app/permissions');

  /// 弹系统授权框;返回用户是否全部允许。
  static Future<bool> requestStartup() async {
    try {
      return await _channel.invokeMethod<bool>('requestStartup') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 是否还有未授予的启动权限(不弹框)。
  static Future<bool> hasPending() async {
    try {
      return await _channel.invokeMethod<bool>('hasPending') ?? false;
    } catch (_) {
      return false;
    }
  }
}
