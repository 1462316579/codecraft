import 'dart:convert';
import 'dart:typed_data';

import 'package:codecraft/reverse/arsc/arsc_editor.dart';
import 'package:codecraft/reverse/arsc/arsc_file.dart';
import 'package:codecraft/reverse/binary/byte_reader.dart';
import 'package:flutter_test/flutter_test.dart';

/// 小端字节写入器:测试里手工拼一个合法的 resources.arsc。
class _Writer {
  final BytesBuilder _bytes = BytesBuilder();

  int get length => _bytes.length;

  void u1(int value) => _bytes.addByte(value & 0xFF);

  void u2(int value) {
    _bytes
      ..addByte(value & 0xFF)
      ..addByte((value >> 8) & 0xFF);
  }

  void u4(int value) {
    _bytes
      ..addByte(value & 0xFF)
      ..addByte((value >> 8) & 0xFF)
      ..addByte((value >> 16) & 0xFF)
      ..addByte((value >> 24) & 0xFF);
  }

  void raw(List<int> values) => _bytes.add(values);

  void zeros(int count) {
    for (var i = 0; i < count; i++) {
      _bytes.addByte(0);
    }
  }

  void uleb(int value) {
    var remaining = value;
    do {
      var byte = remaining & 0x7F;
      remaining >>= 7;
      if (remaining != 0) byte |= 0x80;
      _bytes.addByte(byte);
    } while (remaining != 0);
  }

  Uint8List take() => _bytes.takeBytes();
}

/// 构造一个 UTF-8 字符串池 chunk。
Uint8List _stringPool(List<String> strings) {
  final data = _Writer();
  final offsets = <int>[];
  for (final value in strings) {
    offsets.add(data.length);
    final encoded = utf8.encode(value);
    data
      ..uleb(value.length)
      ..uleb(encoded.length)
      ..raw(encoded)
      ..u1(0);
  }
  final body = data.take();
  final writer = _Writer();
  writer
    ..u2(ResChunkType.stringPool)
    ..u2(28)
    ..u4(28 + strings.length * 4 + body.length) // size
    ..u4(strings.length)
    ..u4(0) // styleCount
    ..u4(0x100) // flags:UTF-8
    ..u4(28 + strings.length * 4) // stringsStart
    ..u4(0); // stylesStart
  offsets.forEach(writer.u4);
  writer.raw(body);
  return writer.take();
}

/// 构造一个包:两个类型(string / color),每个类型有一个默认配置的 type chunk。
Uint8List _package({
  required int globalStringsOffset,
  required List<String> typeNames,
  required List<String> keyNames,
  required List<List<({String key, int dataType, int data})>> entriesByType,
}) {
  final typePool = _stringPool(typeNames);
  final keyPool = _stringPool(keyNames);

  final typeChunks = <Uint8List>[];
  for (var typeIndex = 0; typeIndex < entriesByType.length; typeIndex++) {
    final entries = entriesByType[typeIndex];
    final writer = _Writer();
    const headerSize = 84; // ResChunk_header(8) + 12 + config(64)
    final entriesStart = headerSize + entries.length * 4;

    final entryBytes = _Writer();
    final offsets = <int>[];
    for (final entry in entries) {
      offsets.add(entryBytes.length);
      final keyIndex = keyNames.indexOf(entry.key);
      entryBytes
        ..u2(8) // ResTable_entry.size
        ..u2(0) // flags
        ..u4(keyIndex)
        ..u2(8) // Res_value.size
        ..u1(0) // res0
        ..u1(entry.dataType)
        ..u4(entry.data);
    }
    final body = entryBytes.take();

    writer
      ..u2(ResChunkType.tableType)
      ..u2(headerSize)
      ..u4(entriesStart + body.length) // chunk size
      ..u1(typeIndex + 1) // type id(从 1 开始)
      ..u1(0) // flags
      ..u2(0) // reserved
      ..u4(entries.length)
      ..u4(entriesStart)
      ..u4(64) // config.size
      ..zeros(60); // 其余配置字段全 0 = 默认配置
    offsets.forEach(writer.u4);
    writer.raw(body);
    typeChunks.add(writer.take());
  }

  const headerSize = 288;
  final typeStringsOffset = headerSize;
  final keyStringsOffset = headerSize + typePool.length;
  final childrenSize =
      typePool.length + keyPool.length + typeChunks.fold<int>(0, (sum, c) => sum + c.length);

  final writer = _Writer();
  writer
    ..u2(ResChunkType.tablePackage)
    ..u2(headerSize)
    ..u4(headerSize + childrenSize)
    ..u4(0x7f) // package id
    ..u2(0x63)
    ..u2(0x6F)
    ..u2(0x6D)
    ..u2(0x2E)
    ..u2(0x61)
    ..u2(0x70)
    ..u2(0x70)
    ..u2(0) // name "com.app" + NUL
    ..zeros((128 - 8) * 2) // 名字字段固定 128 个 u2
    ..u4(typeStringsOffset)
    ..u4(0) // lastPublicType
    ..u4(keyStringsOffset)
    ..u4(0) // lastPublicKey
    ..u4(0); // typeIdOffset
  writer.raw(typePool);
  writer.raw(keyPool);
  for (final chunk in typeChunks) {
    writer.raw(chunk);
  }
  return writer.take();
}

/// 拼一个最小的 resources.arsc。
Uint8List _arsc({
  required List<String> globalStrings,
  required List<String> typeNames,
  required List<String> keyNames,
  required List<List<({String key, int dataType, int data})>> entriesByType,
}) {
  final pool = _stringPool(globalStrings);
  final pkg = _package(
    globalStringsOffset: 12 + pool.length,
    typeNames: typeNames,
    keyNames: keyNames,
    entriesByType: entriesByType,
  );
  final writer = _Writer();
  writer
    ..u2(ResChunkType.table)
    ..u2(12)
    ..u4(12 + pool.length + pkg.length)
    ..u4(1) // packageCount
    ..raw(pool)
    ..raw(pkg);
  return writer.take();
}

void main() {
  group('语言/国家码解码', () {
    ResConfig configWith({required int lang0, required int lang1, int size = 64}) {
      final writer = _Writer()
        ..u4(size)
        ..zeros(4) // mcc / mnc
        ..u1(lang0)
        ..u1(lang1)
        ..u1(0)
        ..u1(0);
      while (writer.length < size) {
        writer.zeros(4);
      }
      return ResConfig.parse(writer.take(), 0);
    }

    test('原样 ASCII 写法(aapt2 对新版配置的写法)', () {
      // "ca":两个字节就是 'c' 'a'
      expect(configWith(lang0: 0x63, lang1: 0x61).language, 'ca');
    });

    test('紧凑编码写法(AOSP 规范)', () {
      // "ca" 紧凑编码:0x08 0x00
      expect(configWith(lang0: 0x08, lang1: 0x00).language, 'ca');
      // "de":'d'=3 → 3<<2 = 12 = 0x0C,'e'=4 → 4<<5 = 0x80
      expect(configWith(lang0: 0x0C, lang1: 0x80).language, 'de');
    });

    test('未指定语言时为空', () {
      expect(configWith(lang0: 0, lang1: 0).language, '');
    });

    test('限定符串默认值为 default', () {
      expect(configWith(lang0: 0, lang1: 0).qualifier, 'default');
      expect(configWith(lang0: 0x63, lang1: 0x61).qualifier, 'ca');
    });

    test('config 较短时不做越界读取', () {
      final writer = _Writer()..u4(4);
      final config = ResConfig.parse(writer.take(), 0);
      expect(config.qualifier, 'default');
      expect(config.language, '');
    });
  });

  group('资源值渲染', () {
    final pool = ResStringPool(
      strings: const ['你好', '世界'],
      isUtf8: true,
      offset: 0,
      size: 0,
      headerSize: 0,
      stringsStart: 0,
    );

    String render(int dataType, int data) =>
        ResValue(dataType: dataType, data: data).render(pool);

    test('字符串去全局池取文本', () {
      expect(render(ResValueType.string, 1), '"世界"');
    });

    test('字符串索引越界时不崩', () {
      expect(render(ResValueType.string, 99), '""');
    });

    test('引用按 0x 补足 8 位', () {
      expect(render(ResValueType.reference, 0x7f0d0001), '@0x7f0d0001');
    });

    test('整数按有符号解析', () {
      expect(render(ResValueType.intDec, 42), '42');
      expect(render(ResValueType.intDec, 0xFFFFFFFF), '-1');
    });

    test('布尔与十六进制', () {
      expect(render(ResValueType.intBoolean, 0), 'false');
      expect(render(ResValueType.intBoolean, 1), 'true');
      expect(render(ResValueType.intHex, 0x1F), '0x0000001f');
    });

    test('颜色带 alpha', () {
      expect(render(ResValueType.intColorArgb8, 0xFF112233), '#ff112233');
    });

    test('维度带单位', () {
      // 单位(dp=1)在位 28-31,尾数 16 在低位
      final data = (1 << 28) | 16;
      expect(render(ResValueType.dimension, data), '16dp');
    });

    test('维度基数按 4 位左移缩放', () {
      // radix=1 时分母为 16:尾数 16 → 1
      final data = (1 << 28) | (1 << 24) | 16;
      expect(render(ResValueType.dimension, data), '1dp');
    });
  });

  group('字符串池', () {
    test('UTF-8 池按偏移取串', () {
      final bytes = _stringPool(['alpha', '中文']);
      final pool = ResStringPool.parse(bytes, 0);
      expect(pool.count, 2);
      expect(pool.isUtf8, isTrue);
      expect(pool.at(0), 'alpha');
      expect(pool.at(1), '中文');
      expect(pool.at(5), '');
    });

    test('不是字符串池时报错', () {
      final writer = _Writer()
        ..u2(ResChunkType.table)
        ..u2(12)
        ..u4(12)
        ..u4(1);
      expect(
        () => ResStringPool.parse(writer.take(), 0),
        throwsA(isA<BinaryFormatException>()),
      );
    });
  });

  group('完整 ARSC', () {
    late ArscFile arsc;

    setUpAll(() {
      arsc = ArscFile.parse(_arsc(
        globalStrings: const ['你好', '世界', 'res/drawable/icon.png'],
        typeNames: const ['string', 'color'],
        keyNames: const ['app_name', 'greeting', 'icon', 'bg'],
        entriesByType: [
          [
            (key: 'app_name', dataType: ResValueType.string, data: 0),
            (key: 'greeting', dataType: ResValueType.string, data: 1),
            (key: 'icon', dataType: ResValueType.string, data: 2),
          ],
          [
            (key: 'bg', dataType: ResValueType.intColorArgb8, data: 0xFF000000),
          ],
        ],
      ));
    });

    test('包名与包 id', () {
      expect(arsc.packages, hasLength(1));
      expect(arsc.packages.single.name, 'com.app');
      expect(arsc.packages.single.id, 0x7f);
    });

    test('资源 id 按 包:类型:序号 拼出', () {
      final ids = arsc.resources.map((r) => r.id).toList();
      expect(ids, contains(0x7f010000));
      expect(ids, contains(0x7f010001));
      expect(ids, contains(0x7f020000));
    });

    test('类型名与 key 取自各自的池', () {
      final appName = arsc.resources.firstWhere((r) => r.key == 'app_name');
      expect(appName.type, 'string');
      expect(appName.primary!.render(arsc.globalStrings), '"你好"');
      final bg = arsc.resources.firstWhere((r) => r.key == 'bg');
      expect(bg.type, 'color');
      expect(bg.primary!.render(arsc.globalStrings), '#ff000000');
    });

    test('文件引用型 drawable 值原样展示', () {
      final icon = arsc.resources.firstWhere((r) => r.key == 'icon');
      expect(icon.primary!.render(arsc.globalStrings), '"res/drawable/icon.png"');
    });

    test('默认配置被识别为 default', () {
      expect(arsc.resources.first.primary!.config.qualifier, 'default');
    });

    test('全局字符串池就是字符常量池的数据源', () {
      expect(arsc.globalStrings.count, 3);
      expect(arsc.globalStrings.at(0), '你好');
      expect(arsc.globalStrings.at(2), 'res/drawable/icon.png');
    });

    test('不是 arsc 时报错', () {
      expect(
        () => ArscFile.parse(Uint8List.fromList(List<int>.filled(64, 0))),
        throwsA(isA<BinaryFormatException>()),
      );
    });

    test('过短的数据不会读越界', () {
      expect(
        () => ArscFile.parse(Uint8List.fromList([0x02, 0x00])),
        throwsA(isA<BinaryFormatException>()),
      );
    });
  });

  group('ARSC 等长替换', () {
    Uint8List build() => _arsc(
          globalStrings: const ['你好', '世界', 'res/drawable/icon.png'],
          typeNames: const ['string'],
          keyNames: const ['greeting'],
          entriesByType: [
            [(key: 'greeting', dataType: ResValueType.string, data: 1)],
          ],
        );

    test('等长替换后重新解析能读到新值', () {
      final bytes = build();
      final arsc = ArscFile.parse(bytes);
      final editor = ArscEditor(arsc);
      // '世界' 与 '翻译' 都是 6 字节
      expect(editor.validateReplace(1, '翻译'), isNull);
      final outcome = editor.replaceGlobalString(1, '翻译');
      expect(outcome.isOk, isTrue);

      final updated = ArscFile.parse(outcome.bytes!);
      expect(updated.globalStrings.at(1), '翻译');
      // 引用它的资源值跟着变
      final greeting = updated.resources.firstWhere((r) => r.key == 'greeting');
      expect(greeting.primary!.render(updated.globalStrings), '"翻译"');
    });

    test('长度不同被拒绝并说明原因', () {
      final editor = ArscEditor(ArscFile.parse(build()));
      final problem = editor.validateReplace(1, '世界啊');
      expect(problem, isNotNull);
      expect(problem, contains('长度必须一致'));
      expect(editor.replaceGlobalString(1, '世界啊').isOk, isFalse);
    });

    test('只有长度的替换也不破坏其他字符串', () {
      final editor = ArscEditor(ArscFile.parse(build()));
      final outcome = editor.replaceGlobalString(1, '翻译');
      final updated = ArscFile.parse(outcome.bytes!);
      expect(updated.globalStrings.at(0), '你好');
      expect(updated.globalStrings.at(2), 'res/drawable/icon.png');
      expect(updated.resources, hasLength(1));
    });

    test('索引越界被拒绝', () {
      final editor = ArscEditor(ArscFile.parse(build()));
      expect(editor.validateReplace(99, 'x'), '字符串索引越界');
    });
  });
}