import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Adler-32 模数(Dex 的 checksum 用它)。
const int _adlerMod = 65521;

/// Adler-32:Dex 文件头第 8-11 字节是这个值。
int adler32(Uint8List data, {int start = 0}) {
  var a = 1;
  var b = 0;
  for (var i = start; i < data.length; i++) {
    a = (a + data[i]) % _adlerMod;
    b = (b + a) % _adlerMod;
  }
  return (b << 16) | a;
}

/// SHA-1 摘要:Dex 文件头第 12-31 字节是 `bytes[32..]` 的 SHA-1。
Uint8List sha1Digest(Uint8List data, {int start = 0}) =>
    Uint8List.fromList(sha1.convert(Uint8List.sublistView(data, start)).bytes);

/// 按 Dex 规范重算文件头的 checksum 与 signature。
///
/// 手工改过 dex 的任何字节后都必须调用:Android 运行时校验这两个字段,
/// 不重算会直接拒绝加载(表现为「解析包时出现问题」)。
///
/// 规范顺序是「先算 signature 写回 12-31,再算覆盖签名的 checksum 写回 8-11」。
/// checksum 的计算范围从偏移 12 开始,所以必须先写 signature。
void refreshDexChecksum(Uint8List bytes) {
  if (bytes.length < 32) return;
  final signature = sha1Digest(bytes, start: 32);
  bytes.setRange(12, 32, signature);
  final checksum = adler32(bytes, start: 12);
  bytes[8] = checksum & 0xFF;
  bytes[9] = (checksum >> 8) & 0xFF;
  bytes[10] = (checksum >> 16) & 0xFF;
  bytes[11] = (checksum >> 24) & 0xFF;
}