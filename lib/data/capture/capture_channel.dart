import 'dart:io';

import 'package:flutter/services.dart';

/// Android 抓包辅助通道（CA 安装引导 + VPN 控制）。
class CaptureChannel {
  CaptureChannel._();

  static const _channel = MethodChannel('ids.codecraft.app/capture');

  static Future<bool> installCaCert(String path) async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('installCaCert', {'path': path});
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openSecuritySettings() async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('openSecuritySettings');
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  /// 请求 VPN 权限。返回:
  /// - "granted": 已授权
  /// - "need_permission": 需要用户授权(会弹系统对话框，需监听 onActivityResult 回调)
  /// - "denied": 被拒绝或出错
  static Future<String> requestVpnPermission() async {
    if (!Platform.isAndroid) return "denied";
    try {
      final result = await _channel.invokeMethod<String>('requestVpnPermission');
      return result ?? "denied";
    } catch (_) {
      return "denied";
    }
  }

  /// 启动 VPN 服务(需已授权)
  static Future<bool> startVpn(int proxyPort) async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('startVpn', {'proxyPort': proxyPort});
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  /// 停止 VPN 服务
  static Future<bool> stopVpn() async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('stopVpn');
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  /// 检查 VPN 是否正在运行
  static Future<bool> isVpnRunning() async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('isVpnRunning');
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  /// 最近一次 VPN 启动失败的原因（供界面直接展示）。
  static Future<String?> vpnLastError() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('vpnLastError');
    } catch (_) {
      return null;
    }
  }
}
