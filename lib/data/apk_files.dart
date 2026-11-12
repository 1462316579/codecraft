import 'package:flutter/services.dart';

/// 读取 / 解压 APK(逆向项目的数据源)。
class ApkFiles {
  ApkFiles._();

  static const MethodChannel _channel = MethodChannel('ids.codecraft.app/apk_files');

  /// 把一个应用的安装包解压到 [destDir],返回写出的文件数。
  ///
  /// [apkPaths] 首个是 base.apk,其后是 ABI/语言等分卷——AAB 分发的应用,
  /// 原生库(如 `lib/arm64-v8a/libapp.so`)常只存在于分卷里,漏掉就看不到。
  /// 解压在原生侧的后台线程完成,APK 上百 MB 也不会卡住界面。
  static Future<int> extract(List<String> apkPaths, String destDir) async {
    final count = await _channel.invokeMethod<int>('extract', {
      'apkPaths': apkPaths,
      'destDir': destDir,
    });
    return count ?? 0;
  }
}
