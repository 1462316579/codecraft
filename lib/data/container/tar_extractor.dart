import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

// ---------------------------------------------------------------- rootfs 解压

/// 解压 tar.gz 到 [rootPath]，返回需要补执行位的文件路径。
///
/// 用 dart:io 的 gzip 解码器（原生 zlib）先把压缩包流式解成 tar，再自己单遍扫描：
/// archive 包的纯 Dart 解压慢一个数量级，而它的惰性 tar 解码又无法在扫描时
/// 安全取回文件内容，所以这里自己解析（保留 mode / 符号链接 / 硬链接语义）。
Future<List<String>> extractTarGz(String archivePath, String rootPath) async {
  final tarPath = '$rootPath.part.tar';
  final tarFile = File(tarPath);
  try {
    await File(archivePath)
        .openRead()
        .transform(gzip.decoder)
        .pipe(tarFile.openWrite());
    return _extractTar(tarPath, rootPath);
  } finally {
    if (tarFile.existsSync()) {
      try {
        tarFile.deleteSync();
      } catch (_) {}
    }
  }
}

List<String> _extractTar(String tarPath, String rootPath) {
  final raf = File(tarPath).openSync(mode: FileMode.read);
  final total = raf.lengthSync();
  final execPaths = <String>[];
  final header = Uint8List(512);
  String? pendingName;
  String? pendingLink;
  var offset = 0;

  try {
    while (offset + 512 <= total) {
      raf.setPositionSync(offset);
      final read = raf.readIntoSync(header);
      if (read < 512) break;
      if (_isZeroBlock(header)) break;

      final name = _readString(header, 0, 100);
      final mode = _readOctal(header, 100, 8);
      final size = _readOctal(header, 124, 12);
      final typeByte = header[156];
      final type = typeByte == 0 ? '0' : String.fromCharCode(typeByte);
      var link = _readString(header, 157, 100);
      final prefix = _readString(header, 345, 155);

      final dataOffset = offset + 512;
      offset = dataOffset + ((size + 511) ~/ 512) * 512;

      if (type == 'L') {
        pendingName = _readText(raf, dataOffset, size);
        continue;
      }
      if (type == 'K') {
        pendingLink = _readText(raf, dataOffset, size);
        continue;
      }
      if (type == 'x' || type == 'g') {
        final record = _readText(raf, dataOffset, size);
        final parsed = _parsePax(record);
        if (parsed.name != null) pendingName = parsed.name;
        if (parsed.link != null) pendingLink = parsed.link;
        continue;
      }

      var entryName = pendingName ?? (prefix.isEmpty ? name : '$prefix/$name');
      pendingName = null;
      final nextLink = pendingLink;
      if (nextLink != null) {
        link = nextLink;
        pendingLink = null;
      }

      final clean = _sanitizePath(entryName);
      if (clean == null || clean.isEmpty) continue;
      final targetPath = p.join(rootPath, clean);

      switch (type) {
        case '5': // 目录
          Directory(targetPath).createSync(recursive: true);
          break;
        case '2': // 符号链接
          _ensureParent(targetPath);
          _recreateLink(targetPath, link);
          break;
        case '1': // 硬链接：Android 上无法创建硬链接，用相对符号链接等价实现。
          // 链接目标必须相对本文件所在目录，这样容器内（PRoot）和宿主侧
          // 都能解析到同一份 rootfs 里的文件；用宿主绝对路径会让容器内断链。
          _ensureParent(targetPath);
          final hardTarget = _sanitizePath(link);
          if (hardTarget == null) break;
          _recreateLink(
            targetPath,
            p.relative(
              p.join(rootPath, hardTarget),
              from: p.dirname(targetPath),
            ),
          );
          break;
        case '3':
        case '4':
        case '6': // 设备节点 / FIFO，容器里用不到
          break;
        default: // '0' / '7'
          final file = File(targetPath);
          file.parent.createSync(recursive: true);
          final sink = file.openSync(mode: FileMode.write);
          try {
            var remaining = size;
            var position = dataOffset;
            final buffer = Uint8List(64 * 1024);
            while (remaining > 0) {
              raf.setPositionSync(position);
              final chunk =
                  remaining > buffer.length ? buffer.length : remaining;
              final n = raf.readIntoSync(buffer, 0, chunk);
              if (n <= 0) break;
              sink.writeFromSync(buffer, 0, n);
              position += n;
              remaining -= n;
            }
          } finally {
            sink.closeSync();
          }
          if ((mode & 0x49) != 0) execPaths.add(targetPath);
          break;
      }
    }
  } finally {
    raf.closeSync();
  }
  return execPaths;
}

void _ensureParent(String path) =>
    Directory(p.dirname(path)).createSync(recursive: true);

void _recreateLink(String path, String target) {
  final link = Link(path);
  if (link.existsSync()) link.deleteSync();
  final file = File(path);
  if (file.existsSync()) file.deleteSync();
  final dir = Directory(path);
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  link.createSync(target);
}

/// 清理 tar 里的相对/绝对路径，拒绝越界（`..`）。
String? _sanitizePath(String raw) {
  var path = raw.replaceAll('\\', '/');
  while (path.startsWith('./')) {
    path = path.substring(2);
  }
  if (path.isEmpty) return null;
  if (path.startsWith('/')) path = path.substring(1);
  final segments = <String>[];
  for (final segment in path.split('/')) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..') {
      if (segments.isEmpty) return null;
      segments.removeLast();
      continue;
    }
    segments.add(segment);
  }
  return segments.join('/');
}

bool _isZeroBlock(Uint8List block) {
  for (final byte in block) {
    if (byte != 0) return false;
  }
  return true;
}

String _readString(Uint8List buffer, int offset, int length) {
  var end = offset;
  final limit = offset + length;
  while (end < limit && buffer[end] != 0) {
    end++;
  }
  return utf8.decode(buffer.sublist(offset, end), allowMalformed: true);
}

int _readOctal(Uint8List buffer, int offset, int length) {
  var value = 0;
  var seen = false;
  for (var i = offset; i < offset + length; i++) {
    final byte = buffer[i];
    if (byte == 0 || byte == 0x20) {
      if (seen) break;
      continue;
    }
    if (byte < 0x30 || byte > 0x37) break;
    value = value * 8 + (byte - 0x30);
    seen = true;
  }
  return value;
}

String _readText(RandomAccessFile raf, int offset, int size) {
  if (size <= 0) return '';
  raf.setPositionSync(offset);
  final bytes = raf.readSync(size);
  return utf8.decode(bytes, allowMalformed: true);
}

class _PaxRecord {
  const _PaxRecord({this.name, this.link});

  final String? name;
  final String? link;
}

_PaxRecord _parsePax(String text) {
  String? name;
  String? link;
  for (final line in const LineSplitter().convert(text)) {
    final space = line.indexOf(' ');
    if (space <= 0) continue;
    final rest = line.substring(space + 1);
    final eq = rest.indexOf('=');
    if (eq <= 0) continue;
    final key = rest.substring(0, eq);
    final value = rest.substring(eq + 1);
    if (key == 'path') name = value;
    if (key == 'linkpath') link = value;
  }
  return _PaxRecord(name: name, link: link);
}
