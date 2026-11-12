import 'dart:math' as math;
import 'dart:typed_data';

import 'package:codecraft/core/util/image_downscaler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// 生成测试用 PNG:纯色或确定性噪声;alpha 控制是否带透明通道。
Uint8List testPng(int width, int height, {bool alpha = false, bool noise = false}) {
  final image = img.Image(width: width, height: height, numChannels: alpha ? 4 : 3);
  if (noise) {
    final rnd = math.Random(42);
    for (final pixel in image) {
      pixel
        ..r = rnd.nextInt(256)
        ..g = rnd.nextInt(256)
        ..b = rnd.nextInt(256)
        ..a = 255;
    }
  } else {
    img.fill(
      image,
      color: alpha ? img.ColorRgba8(200, 100, 50, 128) : img.ColorRgb8(200, 100, 50),
    );
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('fitWithin', () {
    test('范围内返回原尺寸', () {
      expect(ImageDownscaler.fitWithin(1200, 800), (1200, 800));
    });

    test('长边等比缩小', () {
      expect(ImageDownscaler.fitWithin(4000, 3000), (1568, 1176));
      expect(ImageDownscaler.fitWithin(3000, 4000), (1176, 1568));
    });

    test('极端宽高比不会缩到 0', () {
      expect(ImageDownscaler.fitWithin(100000, 10), (1568, 1));
    });
  });

  group('downscale', () {
    test('够小且边长达标的图原样返回', () {
      final bytes = testPng(800, 600);
      final result = ImageDownscaler.downscale(bytes, 'image/png');
      expect(result.bytes, same(bytes));
      expect(result.mimeType, 'image/png');
    });

    test('大图等比缩小到长边 1568,不透明图输出 JPEG', () {
      final result = ImageDownscaler.downscale(testPng(4000, 3000, noise: true), 'image/png');
      expect(result.mimeType, 'image/jpeg');
      final decoded = img.decodeImage(result.bytes);
      expect(decoded!.width, 1568);
      expect(decoded.height, 1176);
    });

    test('透明图缩小后保持 PNG', () {
      final result = ImageDownscaler.downscale(
        testPng(2000, 2000, alpha: true, noise: true),
        'image/png',
      );
      expect(result.mimeType, 'image/png');
      final decoded = img.decodeImage(result.bytes);
      expect(decoded!.width, 1568);
      expect(decoded.height, 1568);
    });

    test('GIF 原样返回', () {
      final bytes = Uint8List.fromList([0x47, 0x49, 0x46, 0x38]);
      final result = ImageDownscaler.downscale(bytes, 'image/gif');
      expect(result.bytes, same(bytes));
      expect(result.mimeType, 'image/gif');
    });

    test('解码失败原样返回', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final result = ImageDownscaler.downscale(bytes, 'image/png');
      expect(result.bytes, same(bytes));
      expect(result.mimeType, 'image/png');
    });

    test('重编码后更大时保留原图', () {
      // 纯色大图 PNG 压缩后极小,重编码成 JPEG 反而更大,应原样返回。
      final bytes = testPng(1600, 1600);
      final result = ImageDownscaler.downscale(bytes, 'image/png');
      expect(result.bytes, same(bytes));
      expect(result.mimeType, 'image/png');
    });
  });

  test('downscaleToBase64 返回 mime 与 base64', () {
    final result = ImageDownscaler.downscaleToBase64(
      testPng(4000, 3000, noise: true),
      'image/png',
    );
    expect(result.mimeType, 'image/jpeg');
    expect(result.base64, isNotEmpty);
  });
}
