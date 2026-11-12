import 'dart:typed_data';

/// 解析二进制格式时遇到的非法数据:偏移越界、magic 不符、长度字段自相矛盾。
///
/// 逆向项目面对的 APK 千奇百怪(加固、混淆、被改过的包),解析器必须能明确报错
/// 而不是抛出难懂的 RangeError。
class BinaryFormatException implements Exception {
  const BinaryFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 小端字节读取器。Dex 与 ARSC 都是小端布局,共用这一层。
class ByteReader {
  ByteReader(this.bytes, {int offset = 0}) : _offset = offset {
    if (offset < 0 || offset > bytes.length) {
      throw BinaryFormatException('起始偏移越界:$offset / ${bytes.length}');
    }
  }

  final Uint8List bytes;
  int _offset;

  int get offset => _offset;

  int get length => bytes.length;

  int get remaining => bytes.length - _offset;

  bool get atEnd => _offset >= bytes.length;

  void seek(int value) {
    if (value < 0 || value > bytes.length) {
      throw BinaryFormatException('偏移越界:$value / ${bytes.length}');
    }
    _offset = value;
  }

  void skip(int count) => seek(_offset + count);

  void _require(int count) {
    if (_offset + count > bytes.length) {
      throw BinaryFormatException(
        '读取 $count 字节越界:偏移 $_offset,文件长度 ${bytes.length}',
      );
    }
  }

  int u1() {
    _require(1);
    return bytes[_offset++];
  }

  int u2() {
    _require(2);
    final value = bytes[_offset] | (bytes[_offset + 1] << 8);
    _offset += 2;
    return value;
  }

  int s2() {
    final value = u2();
    return (value & 0x8000) != 0 ? value - 0x10000 : value;
  }

  int u4() {
    _require(4);
    final value = bytes[_offset] |
        (bytes[_offset + 1] << 8) |
        (bytes[_offset + 2] << 16) |
        (bytes[_offset + 3] << 24);
    _offset += 4;
    return value;
  }

  int s4() {
    final value = u4();
    return (value & 0x80000000) != 0 ? value - 0x100000000 : value;
  }

  int u8() {
    final low = u4();
    final high = u4();
    return low | (high << 32);
  }

  Uint8List read(int count) {
    _require(count);
    final slice = Uint8List.sublistView(bytes, _offset, _offset + count);
    _offset += count;
    return slice;
  }

  /// 无符号 LEB128(Dex 的字符串长度、ARSC 的 UTF-8 串长度都用它)。
  int uleb128() {
    var result = 0;
    var shift = 0;
    while (true) {
      final byte = u1();
      result |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) return result;
      shift += 7;
      // Dex 允许的最大位宽是 32 位,超过说明数据已经坏了,继续读只会越读越偏。
      if (shift > 35) throw const BinaryFormatException('uleb128 编码过长');
    }
  }

  /// 有符号 LEB128(Dex 的调试信息、switch 表)。
  int sleb128() {
    var result = 0;
    var shift = 0;
    int byte;
    do {
      byte = u1();
      result |= (byte & 0x7F) << shift;
      shift += 7;
    } while ((byte & 0x80) != 0);
    if (shift < 64 && (byte & 0x40) != 0) {
      result |= -(1 << shift);
    }
    return result;
  }
}

/// 解码 Dex 的 MUTF-8(修改版 UTF-8)。
///
/// 与标准 UTF-8 的两处差别:NUL 写成 `C0 80` 两字节;增补平面字符按 CESU-8
/// 拆成两个三字节代理项。因此不能直接用 `utf8.decode`,否则含 emoji 的字符串会抛异常。
String decodeMutf8(Uint8List bytes, {int start = 0, int? end}) {
  final limit = end ?? bytes.length;
  final units = <int>[];
  var i = start;
  while (i < limit) {
    final a = bytes[i++];
    if (a < 0x80) {
      units.add(a);
      continue;
    }
    if ((a & 0xE0) == 0xC0) {
      if (i >= limit) break;
      units.add(((a & 0x1F) << 6) | (bytes[i++] & 0x3F));
      continue;
    }
    if ((a & 0xF0) == 0xE0) {
      if (i + 1 >= limit) break;
      units.add(((a & 0x0F) << 12) | ((bytes[i] & 0x3F) << 6) | (bytes[i + 1] & 0x3F));
      i += 2;
      continue;
    }
    if ((a & 0xF8) == 0xF0) {
      if (i + 2 >= limit) break;
      final code = ((a & 0x07) << 18) |
          ((bytes[i] & 0x3F) << 12) |
          ((bytes[i + 1] & 0x3F) << 6) |
          (bytes[i + 2] & 0x3F);
      i += 3;
      if (code > 0x10FFFF) continue;
      final v = code - 0x10000;
      units
        ..add(0xD800 + (v >> 10))
        ..add(0xDC00 + (v & 0x3FF));
      continue;
    }
    // 非法首字节:跳过,避免整串解析失败。
  }
  return String.fromCharCodes(units);
}

/// 把字符串编码成 MUTF-8 字节(用于校验长度、写回字符串常量池)。
Uint8List encodeMutf8(String value) {
  final out = BytesBuilder(copy: false);
  for (final unit in value.codeUnits) {
    if (unit == 0) {
      out
        ..addByte(0xC0)
        ..addByte(0x80);
    } else if (unit < 0x80) {
      out.addByte(unit);
    } else if (unit < 0x800) {
      out
        ..addByte(0xC0 | (unit >> 6))
        ..addByte(0x80 | (unit & 0x3F));
    } else {
      out
        ..addByte(0xE0 | (unit >> 12))
        ..addByte(0x80 | ((unit >> 6) & 0x3F))
        ..addByte(0x80 | (unit & 0x3F));
    }
  }
  return out.takeBytes();
}