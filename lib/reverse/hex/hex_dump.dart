import 'dart:typed_data';

/// 十六进制视图的一行。
class HexRow {
  const HexRow({
    required this.offset,
    required this.bytes,
    required this.ascii,
    required this.bytesPerRow,
  });

  /// 该行在文件里的起始偏移。
  final int offset;

  /// 本行实际字节(末行可能不足)。
  final List<int> bytes;

  /// 对应的可打印 ASCII,不可打印字符用 `.` 占位。
  final String ascii;

  /// 每行显示的字节数。
  final int bytesPerRow;

  /// 偏移列:固定 8 位十六进制,便于纵向对齐。
  String get offsetText => offset.toRadixString(16).padLeft(8, '0');

  /// 十六进制列:每字节两位,不足的位置补空格保持等宽。
  String get hexText => [
        for (var i = 0; i < bytesPerRow; i++)
          i < bytes.length ? bytes[i].toRadixString(16).padLeft(2, '0') : '  ',
      ].join(' ');
}

/// 十六进制视图的纯逻辑部分(不做渲染,便于测试)。
class HexDump {
  /// 默认每行字节数:手机宽度下 16 字节放不下(偏移 + 十六进制 + ASCII 会超宽)。
  static const int defaultBytesPerRow = 16;

  /// 把 [bytes] 切成每行 [bytesPerRow] 字节。
  ///
  /// [maxRows] 用来限制一次渲染的行数:几百 MB 的文件全量切行会直接吃光内存,
  /// 界面按需分段取。
  static List<HexRow> rows(
    Uint8List bytes, {
    int start = 0,
    int? maxRows,
    int bytesPerRow = defaultBytesPerRow,
  }) {
    final rows = <HexRow>[];
    final begin = start.clamp(0, bytes.length);
    final limit = maxRows == null ? null : begin + maxRows * bytesPerRow;
    final end = limit == null ? bytes.length : limit.clamp(0, bytes.length);
    for (var offset = begin; offset < end; offset += bytesPerRow) {
      final slice = Uint8List.sublistView(
        bytes,
        offset,
        (offset + bytesPerRow).clamp(0, end),
      );
      rows.add(HexRow(
        offset: offset,
        bytes: slice.toList(),
        ascii: _asciiOf(slice),
        bytesPerRow: bytesPerRow,
      ));
    }
    return rows;
  }

  /// 文件总行数(用于滚动条与跳转)。
  static int rowCount(int byteLength, {int bytesPerRow = defaultBytesPerRow}) =>
      (byteLength + bytesPerRow - 1) ~/ bytesPerRow;

  /// 偏移 [offset] 落在第几行。
  static int rowOf(int offset, {int bytesPerRow = defaultBytesPerRow}) =>
      offset ~/ bytesPerRow;

  static String _asciiOf(List<int> bytes) => String.fromCharCodes(
        bytes.map((b) => b >= 0x20 && b <= 0x7E ? b : 0x2E),
      );
}

/// 解析用户输入的十六进制字节。
///
/// 接受 `ff`、`0xFF`、`F` 三种写法;只允许单字节,
/// 多字节替换走字符串编辑,避免一次误改整段代码。
int? parseHexByte(String input) {
  var text = input.trim();
  if (text.toLowerCase().startsWith('0x')) text = text.substring(2);
  text = text.replaceAll(' ', '');
  if (text.isEmpty || text.length > 2) return null;
  final value = int.tryParse(text, radix: 16);
  if (value == null || value < 0 || value > 0xFF) return null;
  return value;
}