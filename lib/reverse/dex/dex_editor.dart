import 'dart:typed_data';

import '../binary/byte_reader.dart';
import '../binary/checksum.dart';
import 'dex_file.dart';

/// 一次编辑的结果:成功时给出新的完整字节,失败时给出可直接展示给用户的原因。
class EditOutcome {
  const EditOutcome.ok(this.bytes) : error = null;

  const EditOutcome.failed(this.error) : bytes = null;

  final Uint8List? bytes;
  final String? error;

  bool get isOk => bytes != null;
}

/// Dex 的等长字符串替换。
///
/// 只允许「编码后字节数不变」的修改:dex 里所有字符串都靠 `string_ids` 里的偏移定位,
/// 长度一变就要重排整个数据区、重算所有指向它的偏移,那等于重写整个 dex,
/// 一旦算错产出的包直接无法加载。等长替换不动任何偏移,只需重算 checksum 与 sha1。
class DexEditor {
  DexEditor(this.file);

  final DexFile file;

  /// 校验把第 [index] 个字符串改成 [value] 是否可行;不可行时给出原因。
  String? validateReplace(int index, String value) {
    if (index < 0 || index >= file.header.stringIdsSize) {
      return '字符串索引越界';
    }
    final range = file.stringBytesRange(index);
    final encoded = encodeMutf8(value);
    final original = range.end - range.start;
    if (encoded.length != original) {
      return '新内容编码后为 ${encoded.length} 字节,原字符串为 $original 字节。'
          '长度必须一致,否则会移动整个 dex 的偏移。';
    }
    // 长度前缀(uleb128 的 utf16 长度)本身也必须占同样字节数。
    final oldPrefix = _ulebSize(file.stringAt(index).length);
    final newPrefix = _ulebSize(value.length);
    if (oldPrefix != newPrefix) {
      return '长度前缀会从 $oldPrefix 字节变成 $newPrefix 字节,超出等长替换范围。';
    }
    return null;
  }

  /// 替换第 [index] 个字符串并重算文件头。
  EditOutcome replaceString(int index, String value) {
    final problem = validateReplace(index, value);
    if (problem != null) return EditOutcome.failed(problem);
    final range = file.stringBytesRange(index);
    final bytes = Uint8List.fromList(file.bytes);
    bytes.setRange(range.start, range.end, encodeMutf8(value));
    refreshDexChecksum(bytes);
    return EditOutcome.ok(bytes);
  }

  /// 直接改字节后重算文件头(十六进制编辑用)。
  EditOutcome applyByteEdits(Map<int, int> edits) {
    final bytes = Uint8List.fromList(file.bytes);
    for (final entry in edits.entries) {
      if (entry.key < 0 || entry.key >= bytes.length) {
        return EditOutcome.failed('偏移 ${entry.key} 超出文件范围');
      }
      bytes[entry.key] = entry.value & 0xFF;
    }
    refreshDexChecksum(bytes);
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