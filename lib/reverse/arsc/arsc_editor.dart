import 'dart:convert';
import 'dart:typed_data';

import '../dex/dex_editor.dart' show EditOutcome;
import 'arsc_file.dart';

/// ARSC 的等长字符串替换。
///
/// 与 dex 同理:池里所有引用都是索引,字符串一变长,池内后续单串的相对偏移、
/// 以及 `ResStringPool_header.stringsStart` 之后的布局都会挪位。等长替换
/// 只覆盖字符串数据本身,不碰任何偏移;ARSC 没有校验和,写完即可用。
class ArscEditor {
  ArscEditor(this.file);

  final ArscFile file;

  /// 校验把全局池第 [index] 个字符串改成 [value] 是否可行。
  String? validateReplace(int index, String value) {
    return validateInPool(file.globalStrings, index, value);
  }

  /// 校验在任意池里的替换(包内的类型名池、键名池也可以用同一套规则)。
  String? validateInPool(ResStringPool pool, int index, String value) {
    if (index < 0 || index >= pool.strings.length) return '字符串索引越界';
    final range = pool.rangeOf(file.bytes, index);
    if (range == null) return '拿不到这个字符串在文件里的位置';
    final encoded = pool.isUtf8 ? utf8.encode(value) : null;
    final newLength = encoded != null ? encoded.length : value.length * 2;
    if (newLength != range.byteLength) {
      return '新内容编码后为 $newLength 字节,原字符串为 ${range.byteLength} 字节。'
          '长度必须一致,否则池内偏移会全部错位。';
    }
    // UTF-8 池还有一段 uleb128 的 utf16 长度前缀,它的字节数也不能变。
    if (pool.isUtf8) {
      final oldPrefix = _ulebSize(pool.strings[index].length);
      final newPrefix = _ulebSize(value.length);
      if (oldPrefix != newPrefix) {
        return '长度前缀会从 $oldPrefix 字节变成 $newPrefix 字节,超出等长替换范围。';
      }
    } else if (value.length != pool.strings[index].length) {
      return 'UTF-16 池要求字符数完全一致';
    }
    return null;
  }

  /// 替换全局池里的字符串。
  EditOutcome replaceGlobalString(int index, String value) {
    return replaceInPool(file.globalStrings, index, value);
  }

  EditOutcome replaceInPool(ResStringPool pool, int index, String value) {
    final problem = validateInPool(pool, index, value);
    if (problem != null) return EditOutcome.failed(problem);
    final range = pool.rangeOf(file.bytes, index);
    if (range == null) return const EditOutcome.failed('拿不到这个字符串在文件里的位置');
    final bytes = Uint8List.fromList(file.bytes);
    if (pool.isUtf8) {
      // UTF-16 长度前缀不影响布局,但写回真实值更严谨;这里长度前缀已校验过等长。
      final encoded = utf8.encode(value);
      bytes.setRange(range.dataStart, range.dataStart + encoded.length, encoded);
    } else {
      final units = value.codeUnits;
      for (var i = 0; i < units.length; i++) {
        final position = range.dataStart + i * 2;
        bytes[position] = units[i] & 0xFF;
        bytes[position + 1] = (units[i] >> 8) & 0xFF;
      }
    }
    return EditOutcome.ok(bytes);
  }

  /// 直接改字节(十六进制编辑用)。ARSC 没有校验和,不需要额外修头。
  EditOutcome applyByteEdits(Map<int, int> edits) {
    final bytes = Uint8List.fromList(file.bytes);
    for (final entry in edits.entries) {
      if (entry.key < 0 || entry.key >= bytes.length) {
        return EditOutcome.failed('偏移 ${entry.key} 超出文件范围');
      }
      bytes[entry.key] = entry.value & 0xFF;
    }
    return EditOutcome.ok(bytes);
  }

  static int _ulebSize(int value) {
    var remaining = value;
    var size = 1;
    while (remaining >= 0x80) {
      remaining >>= 7;
      size++;
    }
    return size;
  }
}