import 'dart:io';

import 'package:flutter/services.dart';

/// 小窗（画中画）通道。
///
/// Android 侧把 Activity 切到画中画，并在窗口上挂两个 RemoteAction：
/// 开始 / 暂停代理、清空记录。窗口里的内容由 Dart 侧的紧凑列表绘制，
/// 动作回调通过 [onAction] 送回 Dart。
class CapturePictureInPicture {
  CapturePictureInPicture._();

  static const _channel = MethodChannel('ids.codecraft.app/capturePip');

  /// 小窗内的动作：'toggle' 启停代理，'clear' 清空记录。
  static void Function(String action)? onAction;
  static void Function(bool inPip)? onModeChanged;

  static bool _handlerSet = false;

  static bool get supported => Platform.isAndroid;

  static void _ensureHandler() {
    if (_handlerSet) return;
    _handlerSet = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'action':
          final action = call.arguments as String?;
          if (action != null) onAction?.call(action);
        case 'modeChanged':
          onModeChanged?.call(call.arguments == true);
      }
      return null;
    });
  }

  /// 进入小窗，[running] 决定窗口内动作按钮显示播放还是暂停。
  static Future<bool> enter({required bool running}) async {
    if (!supported) return false;
    _ensureHandler();
    try {
      final ok = await _channel.invokeMethod<bool>('enter', {'running': running});
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  /// 代理状态变化时更新小窗动作按钮。
  static Future<void> updateActions({required bool running}) async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<void>('updateActions', {'running': running});
    } catch (_) {}
  }
}