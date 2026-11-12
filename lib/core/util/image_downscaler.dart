import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// 发给模型的图片先缩小再编码(对齐上游 ImageDownscaler)。
///
/// 模型侧会把超过长边上限(Anthropic 约 1568px)的图缩小后再看,原图多传的字节
/// 不带来任何信息,却会在每一轮历史回放里重复占用请求体。只处理发给模型的副本,
/// 工作区里的原文件不动。
class ImageDownscaler {
  const ImageDownscaler._();

  /// 长边上限(像素):超过此边长的图等比缩小(上游 MAX_EDGE)。
  static const int maxEdge = 1568;

  /// 长边达标且字节数小于此值时视为「已经够小」,原样返回(上游 SMALL_BYTES)。
  static const int smallBytes = 300 * 1024;

  /// 重编码 JPEG 质量(上游 JPEG_QUALITY)。
  static const int jpegQuality = 85;

  /// 长边不超过 [edge] 的等比目标尺寸;已在范围内返回原尺寸。
  static (int, int) fitWithin(int width, int height, [int edge = maxEdge]) {
    final longest = math.max(width, height);
    if (longest <= edge) return (width, height);
    final scale = edge / longest;
    return (
      math.max(1, (width * scale).toInt()),
      math.max(1, (height * scale).toInt()),
    );
  }

  /// 解码不了、动图、已经够小或重编码后更大时,原样返回。
  static ({String mimeType, Uint8List bytes}) downscale(
    Uint8List bytes,
    String mimeType,
  ) {
    final original = (mimeType: mimeType, bytes: bytes);
    if (mimeType.toLowerCase() == 'image/gif') return original;
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return original;
      if (math.max(decoded.width, decoded.height) <= maxEdge &&
          bytes.length <= smallBytes) {
        return original;
      }

      // 重编码会丢掉 EXIF,朝向必须先落到像素上,否则竖拍的照片会横着发给模型。
      final oriented = img.bakeOrientation(decoded);
      final target = fitWithin(oriented.width, oriented.height);
      final scaled = math.max(oriented.width, oriented.height) > maxEdge
          ? img.copyResize(oriented, width: target.$1, height: target.$2)
          : oriented;
      final keepAlpha =
          scaled.hasAlpha && mimeType.toLowerCase() != 'image/jpeg';
      final encoded = keepAlpha
          ? img.encodePng(scaled)
          : img.encodeJpg(scaled, quality: jpegQuality);
      if (encoded.length >= bytes.length) return original;
      return (
        mimeType: keepAlpha ? 'image/png' : 'image/jpeg',
        bytes: Uint8List.fromList(encoded),
      );
    } catch (_) {
      return original;
    }
  }

  /// 缩小后的 base64 与实际 mime。
  static ({String mimeType, String base64}) downscaleToBase64(
    Uint8List bytes,
    String mimeType,
  ) {
    final result = downscale(bytes, mimeType);
    return (mimeType: result.mimeType, base64: base64Encode(result.bytes));
  }
}
