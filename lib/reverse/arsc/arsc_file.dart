import 'dart:convert';
import 'dart:typed_data';

import '../binary/byte_reader.dart';

/// ARSC 里的 chunk 类型(`ResChunk_header.type`)。
class ResChunkType {
  const ResChunkType._();

  static const int nullType = 0x0000;
  static const int stringPool = 0x0001;
  static const int table = 0x0002;
  static const int xml = 0x0003;
  static const int tablePackage = 0x0200;
  static const int tableType = 0x0201;
  static const int tableTypeSpec = 0x0202;
}

/// `Res_value.dataType`:资源值的实际类型。
class ResValueType {
  const ResValueType._();

  static const int nul = 0x00;
  static const int reference = 0x01;
  static const int attribute = 0x02;
  static const int string = 0x03;
  static const int float = 0x04;
  static const int dimension = 0x05;
  static const int fraction = 0x06;
  static const int dynamicReference = 0x07;
  static const int dynamicAttribute = 0x08;
  static const int intDec = 0x10;
  static const int intHex = 0x11;
  static const int intBoolean = 0x12;
  static const int intColorArgb8 = 0x1c;
  static const int intColorRgb8 = 0x1d;
  static const int intColorArgb4 = 0x1e;
  static const int intColorRgb4 = 0x1f;

  /// 类型名(十六进制视图之外的界面展示用)。
  static String nameOf(int type) => switch (type) {
        nul => 'null',
        reference => 'reference',
        attribute => 'attribute',
        string => 'string',
        float => 'float',
        dimension => 'dimension',
        fraction => 'fraction',
        dynamicReference => 'dynamic-reference',
        dynamicAttribute => 'dynamic-attribute',
        intDec => 'int',
        intHex => 'hex',
        intBoolean => 'bool',
        intColorArgb8 || intColorRgb8 || intColorArgb4 || intColorRgb4 => 'color',
        _ => '0x${type.toRadixString(16).padLeft(2, '0')}',
      };
}

/// 二进制 XML / ARSC 共用的字符串池(`ResStringPool`)。
class ResStringPool {
  ResStringPool({
    required this.strings,
    required this.isUtf8,
    required this.offset,
    required this.size,
    required this.headerSize,
    required this.stringsStart,
  });

  /// 池内全部字符串(`const-string`、资源值都从这里取)。
  final List<String> strings;

  /// true 表示池用 UTF-8 编码(带 uleb128 双长度前缀),否则是 UTF-16。
  final bool isUtf8;

  /// 池在文件里的起始偏移与总长度(等长替换时要回写)。
  final int offset;
  final int size;
  final int headerSize;

  /// 字符串数据区相对池起点的偏移(`ResStringPool_header.stringsStart`)。
  final int stringsStart;

  int get count => strings.length;

  /// 第 [index] 个字符串;越界返回空串而不是抛异常(被改坏的包很常见)。
  String at(int index) => index >= 0 && index < strings.length ? strings[index] : '';

  /// 第 [index] 个字符串在文件里的字节区间。
  ///
  /// 返回 `dataStart/dataEnd` 与两段长度前缀所占的字节数——等长替换必须保证
  /// 数据区长度与长度前缀的编码长度都不变,否则后续所有偏移都会错位。
  ({int dataStart, int dataEnd, int prefixBytes, int byteLength})? rangeOf(
    Uint8List bytes,
    int index,
  ) {
    if (index < 0 || index >= strings.length) return null;
    final entryOffset = offset + headerSize + index * 4;
    if (entryOffset + 4 > bytes.length) return null;
    final relative = ByteReader(bytes, offset: entryOffset).u4();
    var position = offset + stringsStart + relative;
    if (position < 0 || position >= bytes.length) return null;
    final reader = ByteReader(bytes, offset: position);
    if (isUtf8) {
      reader.uleb128(); // utf16 长度
      final byteLength = reader.uleb128();
      final dataStart = reader.offset;
      return (
        dataStart: dataStart,
        dataEnd: (dataStart + byteLength).clamp(0, bytes.length),
        prefixBytes: dataStart - position,
        byteLength: byteLength,
      );
    }
    var length = reader.u2();
    if ((length & 0x8000) != 0) {
      final low = reader.u2();
      length = ((length & 0x7FFF) << 16) | low;
    }
    final dataStart = reader.offset;
    return (
      dataStart: dataStart,
      dataEnd: (dataStart + length * 2).clamp(0, bytes.length),
      prefixBytes: dataStart - position,
      byteLength: length * 2,
    );
  }

  /// 解析一个 `ResStringPool` chunk。[chunkOffset] 指向 `ResChunk_header`。
  static ResStringPool parse(Uint8List bytes, int chunkOffset) {
    final reader = ByteReader(bytes, offset: chunkOffset);
    final type = reader.u2();
    if (type != ResChunkType.stringPool) {
      throw BinaryFormatException('不是字符串池 chunk:type=0x${type.toRadixString(16)}');
    }
    final headerSize = reader.u2();
    final size = reader.u4();
    final stringCount = reader.u4();
    reader.u4(); // styleCount:样式信息,界面用不到
    final flags = reader.u4();
    final stringsStart = reader.u4();
    reader.u4(); // stylesStart

    final isUtf8 = (flags & 0x100) != 0;
    final dataStart = chunkOffset + stringsStart;
    final strings = <String>[];
    // 偏移数组紧跟在 header 之后;越界或被改坏时按能读多少读多少。
    final offsetsReader = ByteReader(bytes, offset: chunkOffset + headerSize);
    for (var i = 0; i < stringCount; i++) {
      if (offsetsReader.remaining < 4) break;
      final stringOffset = offsetsReader.u4();
      final start = dataStart + stringOffset;
      if (start < 0 || start >= bytes.length) {
        strings.add('');
        continue;
      }
      try {
        final decoded = isUtf8
            ? _readUtf8String(bytes, start)
            : _readUtf16String(bytes, start);
        strings.add(decoded);
      } on BinaryFormatException {
        strings.add('');
      }
    }
    return ResStringPool(
      strings: strings,
      isUtf8: isUtf8,
      offset: chunkOffset,
      size: size,
      headerSize: headerSize,
      stringsStart: stringsStart,
    );
  }

  /// UTF-8 池:`uleb128 utf16长度` + `uleb128 字节长度` + 字节 + 0x00。
  static String _readUtf8String(Uint8List bytes, int start) {
    final reader = ByteReader(bytes, offset: start);
    reader.uleb128();
    final byteLength = reader.uleb128();
    final begin = reader.offset;
    final end = (begin + byteLength).clamp(0, bytes.length);
    return utf8.decode(bytes.sublist(begin, end), allowMalformed: true);
  }

  /// UTF-16 池:`u2 长度`(最高位表示长串,此时再读 u2 拼成 31 位)+ 字符。
  static String _readUtf16String(Uint8List bytes, int start) {
    final reader = ByteReader(bytes, offset: start);
    var length = reader.u2();
    if ((length & 0x8000) != 0) {
      final low = reader.u2();
      length = ((length & 0x7FFF) << 16) | low;
    }
    final units = <int>[];
    for (var i = 0; i < length; i++) {
      if (reader.remaining < 2) break;
      units.add(reader.u2());
    }
    return String.fromCharCodes(units);
  }
}

/// 一个 `Res_value`:资源值本体。
class ResValue {
  const ResValue({required this.dataType, required this.data});

  final int dataType;
  final int data;

  String get typeName => ResValueType.nameOf(dataType);

  /// 渲染成人类可读的值。[strings] 用来把 `TYPE_STRING` 的索引翻成文本。
  String render(ResStringPool? strings) {
    switch (dataType) {
      case ResValueType.nul:
        return 'null';
      case ResValueType.reference:
        return '@0x${data.toRadixString(16).padLeft(8, '0')}';
      case ResValueType.attribute:
        return '?0x${data.toRadixString(16).padLeft(8, '0')}';
      case ResValueType.dynamicReference:
        return '@dynamic/0x${data.toRadixString(16).padLeft(8, '0')}';
      case ResValueType.dynamicAttribute:
        return '?dynamic/0x${data.toRadixString(16).padLeft(8, '0')}';
      case ResValueType.string:
        final text = strings?.at(data) ?? '';
        return '"$text"';
      case ResValueType.float:
        return '${Float32List.fromList([data.toDouble()]).single}';
      case ResValueType.dimension:
        return _formatComplex(data, const ['px', 'dp', 'sp', 'pt', 'in', 'mm']);
      case ResValueType.fraction:
        return _formatComplex(data, const ['%', '%p']);
      case ResValueType.intDec:
        return _asSigned32(data).toString();
      case ResValueType.intHex:
        return '0x${data.toRadixString(16).padLeft(8, '0')}';
      case ResValueType.intBoolean:
        return data == 0 ? 'false' : 'true';
      case ResValueType.intColorArgb8:
        return '#${data.toRadixString(16).padLeft(8, '0')}';
      case ResValueType.intColorRgb8:
        return '#${(data & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
      case ResValueType.intColorArgb4:
      case ResValueType.intColorRgb4:
        return '#${data.toRadixString(16).padLeft(4, '0')}';
      default:
        return '0x${data.toRadixString(16).padLeft(8, '0')}';
    }
  }

  /// dimension/fraction 的编码:低 24 位尾数,位 24-25 是基数指数,位 28-31 是单位。
  static String _formatComplex(int data, List<String> units) {
    final unitIndex = (data >> 28) & 0xF;
    final radix = (data >> 24) & 0x3;
    final mantissa = data & 0xFFFFFF;
    final unit = unitIndex < units.length ? units[unitIndex] : 'unit$unitIndex';
    final value = mantissa / (1 << (radix * 4));
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return '$text$unit';
  }

  static int _asSigned32(int value) =>
      (value & 0x80000000) != 0 ? value - 0x100000000 : value;
}

/// 配置限定符(`ResTable_config`):语言、密度、SDK 版本等。
///
/// 只解析界面需要区分的字段;其余字段跳过,避免因为不同 Android 版本的
/// config 长度差异导致解析失败。
class ResConfig {
  const ResConfig({
    required this.qualifier,
    required this.language,
    required this.country,
    required this.density,
    required this.sdkVersion,
  });

  /// 展示用的限定符串,如 `default` / `zh` / `v26` / `480dpi`。
  final String qualifier;
  final String language;
  final String country;
  final int density;
  final int sdkVersion;

  static const ResConfig defaultConfig = ResConfig(
    qualifier: 'default',
    language: '',
    country: '',
    density: 0,
    sdkVersion: 0,
  );

  /// 解析 config:[configOffset] 指向 `ResTable_config.size`。
  ///
  /// 各字段按固定偏移直接读,不顺着读:不同 Android 版本的 config 长度不一样,
  /// 顺序读一旦错位就会把密度当成键盘类型。
  static ResConfig parse(Uint8List bytes, int configOffset) {
    final size = ByteReader(bytes, offset: configOffset).u4();
    if (size < 4) return defaultConfig;

    int readU2(int offset) => size >= offset - configOffset + 2
        ? ByteReader(bytes, offset: offset).u2()
        : 0;
    int readU1(int offset) => size >= offset - configOffset + 1
        ? ByteReader(bytes, offset: offset).u1()
        : 0;

    final mcc = readU2(configOffset + 4);
    final mnc = readU2(configOffset + 6);
    final language = _unpackLocale(
      readU1(configOffset + 8),
      readU1(configOffset + 9),
      base: 0x61,
    );
    final country = _unpackLocale(
      readU1(configOffset + 10),
      readU1(configOffset + 11),
      base: 0x30,
    );
    final orientation = readU1(configOffset + 12);
    final density = readU2(configOffset + 14);
    final sdkVersion = readU2(configOffset + 24);
    final uiMode = readU1(configOffset + 29);

    final parts = <String>[];
    if (mcc != 0) parts.add('mcc$mcc');
    if (mnc != 0) parts.add('mnc$mnc');
    if (language.isNotEmpty) parts.add(country.isEmpty ? language : '$language-r$country');
    if (orientation == 1) parts.add('port');
    if (orientation == 2) parts.add('land');
    if ((uiMode & 0x0F) == 2) parts.add('desk');
    if ((uiMode & 0x0F) == 3) parts.add('car');
    if ((uiMode & 0x0F) == 4) parts.add('television');
    if (density != 0) parts.add('${density}dpi');
    if (sdkVersion != 0) parts.add('v$sdkVersion');

    return ResConfig(
      qualifier: parts.isEmpty ? 'default' : parts.join('-'),
      language: language,
      country: country,
      density: density,
      sdkVersion: sdkVersion,
    );
  }

  /// 解出语言/国家码。
  ///
  /// 同一个字段有两种写法:
  /// - 紧凑编码(AOSP 规范):两字母各占 5 位,第二字节的低 5 位恒为 0;
  ///   三字母码把高位置 1 后分拆。
  /// - 原样 ASCII(aapt2 对新版配置的写法):两个字节就是 `c` `a`。
  ///
  /// 紧凑编码的第二个字节必是 0x20 的倍数,据此可以无歧义地分辨两种写法。
  static String _unpackLocale(int first, int second, {required int base}) {
    if (first == 0 && second == 0) return '';
    if ((second & 0x1F) != 0) {
      return String.fromCharCodes([first, second]).trim();
    }
    if ((first & 0x80) != 0) {
      // 三字母码:首字母在低 5 位,后两字母拼在剩余位里。
      return String.fromCharCodes([
        base + (first & 0x1F),
        base + (((second & 0x03) << 3) | ((first & 0x60) >> 5)),
        base + ((second & 0x7C) >> 2),
      ]);
    }
    final a = (first & 0x7C) >> 2;
    final b = ((first & 0x03) << 3) | ((second & 0xE0) >> 5);
    if (a == 0) return '';
    return String.fromCharCodes([base + a, base + b]);
  }
}

/// 某条目在某个配置下的取值。
class ResConfigValue {
  const ResConfigValue({
    required this.config,
    required this.value,
    required this.complex,
  });

  final ResConfig config;

  /// 复杂条目(style/array/plurals)没有单一值,这里给 null。
  final ResValue? value;

  /// true 表示是 `ResTable_map_entry`(bag 资源)。
  final bool complex;

  String render(ResStringPool? strings) =>
      complex ? '<bag>' : (value?.render(strings) ?? 'null');
}

/// 一个资源条目:`type/key` 加上它在各配置下的取值。
class ResResource {
  ResResource({
    required this.id,
    required this.type,
    required this.key,
    required this.values,
  });

  /// 完整资源 id,如 `0x7f0a0001`。
  final int id;
  final String type;
  final String key;
  final List<ResConfigValue> values;

  /// 默认配置下的取值(界面上作为主值展示)。
  ResConfigValue? get primary {
    for (final value in values) {
      if (value.config.qualifier == 'default') return value;
    }
    return values.isEmpty ? null : values.first;
  }
}

/// 一个 package(`ResTable_package`)。
class ResPackage {
  ResPackage({
    required this.id,
    required this.name,
    required this.typeStrings,
    required this.keyStrings,
    required this.resources,
  });

  final int id;
  final String name;
  final ResStringPool typeStrings;
  final ResStringPool keyStrings;
  final List<ResResource> resources;
}

/// 解析后的 `resources.arsc`。
class ArscFile {
  ArscFile({
    required this.bytes,
    required this.globalStrings,
    required this.packages,
  });

  final Uint8List bytes;

  /// 全局值字符串池:`TYPE_STRING` 的值都指向这里,也是「字符常量池」视图的数据源。
  final ResStringPool globalStrings;

  final List<ResPackage> packages;

  /// 全部资源(跨 package 展开),界面按 type/key 分组展示用。
  List<ResResource> get resources => [for (final package in packages) ...package.resources];

  static ArscFile parse(Uint8List bytes) {
    final reader = ByteReader(bytes);
    final type = reader.u2();
    if (type != ResChunkType.table) {
      throw BinaryFormatException('不是 resources.arsc(chunk type=0x${type.toRadixString(16)})');
    }
    final headerSize = reader.u2();
    final size = reader.u4();
    reader.u4(); // packageCount:实际按 chunk 遍历,不依赖这个计数

    ResStringPool? globalStrings;
    final packages = <ResPackage>[];
    var offset = headerSize;
    final end = size == 0 ? bytes.length : size.clamp(0, bytes.length);
    while (offset + 8 <= end) {
      final chunkReader = ByteReader(bytes, offset: offset);
      final chunkType = chunkReader.u2();
      chunkReader.u2(); // headerSize
      final chunkSize = chunkReader.u4();
      if (chunkSize < 8) break;
      if (chunkType == ResChunkType.stringPool && globalStrings == null) {
        globalStrings = ResStringPool.parse(bytes, offset);
      } else if (chunkType == ResChunkType.tablePackage) {
        packages.add(_parsePackage(bytes, offset, globalStrings));
      }
      offset += chunkSize;
    }

    return ArscFile(
      bytes: bytes,
      globalStrings: globalStrings ??
          ResStringPool(
            strings: const [],
            isUtf8: false,
            offset: 0,
            size: 0,
            headerSize: 0,
            stringsStart: 0,
          ),
      packages: packages,
    );
  }

  static ResPackage _parsePackage(Uint8List bytes, int offset, ResStringPool? globalStrings) {
    final reader = ByteReader(bytes, offset: offset);
    reader.u2(); // type
    final headerSize = reader.u2();
    final chunkSize = reader.u4();
    final id = reader.u4();
    final nameUnits = <int>[];
    for (var i = 0; i < 128; i++) {
      final unit = reader.u2();
      if (unit == 0) {
        // 名字以 NUL 结尾,后面可能还有残留字符:整体跳过。
        reader.skip((127 - i) * 2);
        break;
      }
      nameUnits.add(unit);
    }
    final typeStringsOffset = reader.u4();
    reader.u4(); // lastPublicType
    final keyStringsOffset = reader.u4();
    reader.u4(); // lastPublicKey
    reader.u4(); // typeIdOffset(API 21+)

    final name = String.fromCharCodes(nameUnits);
    final packageSize = chunkSize == 0 ? bytes.length - offset : chunkSize;
    final packageEnd = (offset + packageSize).clamp(0, bytes.length);

    final typeStrings = typeStringsOffset != 0
        ? ResStringPool.parse(bytes, offset + typeStringsOffset)
        : ResStringPool(
            strings: const [],
            isUtf8: false,
            offset: 0,
            size: 0,
            headerSize: 0,
            stringsStart: 0,
          );
    final keyStrings = keyStringsOffset != 0
        ? ResStringPool.parse(bytes, offset + keyStringsOffset)
        : ResStringPool(
            strings: const [],
            isUtf8: false,
            offset: 0,
            size: 0,
            headerSize: 0,
            stringsStart: 0,
          );

    final resources = <int, ResResource>{};
    var childOffset = offset + headerSize;
    while (childOffset + 8 <= packageEnd) {
      final childReader = ByteReader(bytes, offset: childOffset);
      final childType = childReader.u2();
      childReader.u2(); // headerSize
      final childSize = childReader.u4();
      if (childSize < 8) break;
      if (childType == ResChunkType.tableType) {
        // 同一资源在不同配置(语言/密度)下各占一个 type chunk,按资源 id 合并。
        for (final entry in _parseType(
          bytes,
          childOffset,
          id,
          typeStrings,
          keyStrings,
        )) {
          final existing = resources[entry.id];
          if (existing == null) {
            resources[entry.id] = ResResource(
              id: entry.id,
              type: entry.type,
              key: entry.key,
              values: [entry.value],
            );
          } else {
            existing.values.add(entry.value);
          }
        }
      }
      childOffset += childSize;
    }

    return ResPackage(
      id: id,
      name: name,
      typeStrings: typeStrings,
      keyStrings: keyStrings,
      resources: resources.values.toList()
        ..sort((a, b) => a.id.compareTo(b.id)),
    );
  }

  /// 解析一个 `ResTable_type`(某类型在某配置下的全部条目)。
  static List<_RawEntry> _parseType(
    Uint8List bytes,
    int offset,
    int packageId,
    ResStringPool typeStrings,
    ResStringPool keyStrings,
  ) {
    final reader = ByteReader(bytes, offset: offset);
    reader.u2(); // type
    final headerSize = reader.u2();
    final chunkSize = reader.u4();
    final typeId = reader.u1();
    final flags = reader.u1();
    reader.u2(); // reserved
    final entryCount = reader.u4();
    final entriesStart = reader.u4();
    final config = ResConfig.parse(bytes, reader.offset);

    final typeName = typeStrings.at(typeId - 1);
    final sparse = (flags & 0x01) != 0;
    final offset16 = (flags & 0x02) != 0;

    final resources = <_RawEntry>[];
    final offsetsReader = ByteReader(bytes, offset: offset + headerSize);
    final entriesBase = offset + entriesStart;
    final chunkEnd = (offset + (chunkSize == 0 ? bytes.length : chunkSize))
        .clamp(0, bytes.length);

    for (var i = 0; i < entryCount; i++) {
      int entryIndex;
      int entryOffset;
      if (sparse) {
        // 稀疏模式:每项是 (u2 条目号, u2 偏移)。
        if (offsetsReader.remaining < 4) break;
        entryIndex = offsetsReader.u2();
        entryOffset = offsetsReader.u2() * 4;
      } else if (offset16) {
        if (offsetsReader.remaining < 2) break;
        entryIndex = i;
        final value = offsetsReader.u2();
        if (value == 0xFFFF) continue;
        entryOffset = value * 4;
      } else {
        if (offsetsReader.remaining < 4) break;
        entryIndex = i;
        final value = offsetsReader.u4();
        if (value == 0xFFFFFFFF) continue;
        entryOffset = value;
      }

      final entryPosition = entriesBase + entryOffset;
      if (entryPosition + 8 > chunkEnd) continue;
      try {
        final entryReader = ByteReader(bytes, offset: entryPosition);
        final entrySize = entryReader.u2();
        final entryFlags = entryReader.u2();
        final keyIndex = entryReader.u4();
        final key = keyStrings.at(keyIndex);
        final complex = (entryFlags & 0x0001) != 0;

        ResValue? value;
        if (!complex) {
          // ResTable_entry 之后紧跟 Res_value;compact 条目把值内联在 size 字段里。
          final valueOffset = (entryFlags & 0x0008) != 0 ? entryPosition + 4 : entryPosition + entrySize;
          if (valueOffset + 8 <= chunkEnd) {
            final valueReader = ByteReader(bytes, offset: valueOffset);
            valueReader.u2(); // size
            valueReader.u1(); // res0
            final dataType = valueReader.u1();
            value = ResValue(dataType: dataType, data: valueReader.u4());
          }
        } else {
          // bag 资源(style/array):值在 ResTable_map 里,界面统一显示为 <bag>。
          value = null;
        }

        final resourceId = (packageId << 24) | ((typeId & 0xFF) << 16) | (entryIndex & 0xFFFF);
        resources.add(_RawEntry(
          id: resourceId,
          type: typeName.isEmpty ? 'type$typeId' : typeName,
          key: key,
          value: ResConfigValue(config: config, value: value, complex: complex),
        ));
      } on BinaryFormatException {
        // 单个条目坏掉不影响其余条目。
        continue;
      }
    }
    return resources;
  }
}

/// 解析过程中的中间条目:同一资源在多个配置下会有多条,之后按 id 合并。
class _RawEntry {
  const _RawEntry({
    required this.id,
    required this.type,
    required this.key,
    required this.value,
  });

  final int id;
  final String type;
  final String key;
  final ResConfigValue value;
}