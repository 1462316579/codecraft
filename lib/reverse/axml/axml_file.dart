import 'dart:convert';
import 'dart:typed_data';

import '../binary/byte_reader.dart';

/// AXML chunk 类型(`ResChunk_header.type`)。
class AXmlChunkType {
  const AXmlChunkType._();

  /// XML 文件头 / 字符串池等公共 chunk。
  static const int nullType = 0x0000;
  static const int stringPool = 0x0001;
  static const int table = 0x0002;
  static const int xml = 0x0003;

  /// XML 树 chunk。
  static const int startNamespace = 0x0100;
  static const int endNamespace = 0x0101;
  static const int startElement = 0x0102;
  static const int endElement = 0x0103;
  static const int cdata = 0x0104;
  static const int extension = 0x0105;

  static String nameOf(int type) => switch (type) {
        nullType => 'null',
        stringPool => 'string-pool',
        table => 'table',
        xml => 'xml',
        startNamespace => 'start-namespace',
        endNamespace => 'end-namespace',
        startElement => 'start-element',
        endElement => 'end-element',
        cdata => 'cdata',
        extension => 'extension',
        _ => '0x${type.toRadixString(16).padLeft(4, '0')}',
      };
}

/// AXML 资源值类型(`Res_value.dataType`)。
class AXmlValueType {
  const AXmlValueType._();

  static const int nul = 0x00;
  static const int reference = 0x01;
  static const int attribute = 0x02;
  static const int string = 0x03;
  static const int floatType = 0x04;
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

  static String nameOf(int type) => switch (type) {
        nul => 'null',
        reference => 'reference',
        attribute => 'attribute',
        string => 'string',
        floatType => 'float',
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

/// 二进制 AXML 的字符串池(`ResStringPool`)。
class AXmlStringPool {
  const AXmlStringPool({
    required this.strings,
    required this.isUtf8,
    required this.offset,
    required this.size,
  });

  final List<String> strings;
  final bool isUtf8;
  final int offset;
  final int size;

  /// 文本内容的编码格式:utf-8 或 utf-16le。
  String get encoding => isUtf8 ? 'utf-8' : 'utf-16le';
}

/// 二进制 XML 文档的解析结果。
///
/// 逐节点呈现,方便 UI 层渲染成可读的 XML 文本。
class AXmlNode {
  const AXmlNode({
    required this.name,
    required this.attributes,
    required this.text,
    required this.children,
  });

  /// 元素名,如 `manifest`、`application`、`activity`。文本节点时为空。
  final String name;

  /// 属性列表:`(name, rawValue, resolvedString)`。
  final List<(String, String, String?)> attributes;

  /// 元素内的文本/CDATA(叶子节点)。
  final String text;

  /// 子元素(嵌套结构)。
  final List<AXmlNode> children;

  /// 是否文本节点。
  bool get isText => name.isEmpty;

  /// 以常见缩进风格渲染为 XML 文本。
  String render({int indent = 0}) {
    final spaces = ' ' * (indent * 2);
    final attrs = attributes.isEmpty
        ? ''
        : ' ' +
            attributes
                .map((a) {
                  final value = a.$3 ?? a.$2;
                  return '${a.$1}="${_escapeXml(value)}"';
                })
                .join(' ');
    if (isText) {
      return '${spaces}${_escapeXml(text)}';
    }
    if (children.isEmpty && text.isEmpty) {
      return '${spaces}<${name}${attrs} />';
    }
    final open = '${spaces}<${name}${attrs}>';
    if (children.isEmpty && text.isNotEmpty) {
      return '$open${_escapeXml(text)}</${name}>';
    }
    final childXml = children.map((c) => c.render(indent: indent + 1)).join('\n');
    return '$open\n$childXml\n${spaces}</${name}>';
  }

  static String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

/// 解析后的 AXML 文档。
class AXmlFile {
  AXmlFile._(this.nodes);

  /// 文档根节点列表(通常只有一个根元素)。
  final List<AXmlNode> nodes;

  /// 二进制 AXML 解析失败时抛 [BinaryFormatException]。
  static AXmlFile parse(Uint8List bytes) {
    final reader = ByteReader(bytes);

    // AXML 文件以 0x00080003 开头(小端:03 00 08 00)。
    final magic = reader.u4();
    if (magic != 0x00080003) {
      throw BinaryFormatException('不是 AXML 文件(magic 不符:0x${magic.toRadixString(8)})');
    }
    final headerSize = reader.u2();
    final size = reader.u4();
    if (size != bytes.length) {
      // 严格模式可抛;这里只记录差异,继续解析。
    }
    reader.skip(headerSize - 12); // 已读 12 字节(magic 4 + headerSize 2 + size 4 + padding 2)

    AXmlStringPool? stringPool;
    final nodes = <AXmlNode>[];
    final stack = <AXmlNode>[];

    while (reader.remaining > 0) {
      final chunkStart = reader.offset;
      final chunkType = reader.u2();
      final chunkHeaderSize = reader.u2();
      final chunkSize = reader.u4();

      switch (chunkType) {
        case AXmlChunkType.stringPool:
          stringPool = _readStringPool(reader, chunkHeaderSize, chunkSize);
        case AXmlChunkType.startNamespace:
          _readNamespace(reader, chunkHeaderSize, chunkSize); // 命名空间暂不渲染
        case AXmlChunkType.endNamespace:
          _readNamespace(reader, chunkHeaderSize, chunkSize);
        case AXmlChunkType.startElement:
          final node = _readStartElement(reader, chunkHeaderSize, chunkSize, stringPool);
          nodes.add(node);
          stack.add(node);
        case AXmlChunkType.endElement:
          stack.removeLast();
        case AXmlChunkType.cdata:
        case AXmlChunkType.extension:
          reader.skip(chunkSize - 8);
        default:
          reader.skip(chunkSize - 8);
      }

      // 跳到下一个 chunk:每个 chunk 从 chunkStart 开始,总长 chunkSize。
      reader.seek(chunkStart + chunkSize);
    }

    return AXmlFile._(nodes);
  }

  /// 读取字符串池。
  static AXmlStringPool _readStringPool(
    ByteReader reader,
    int headerSize,
    int size,
  ) {
    final stringCount = reader.u4();
    final styleCount = reader.u4();
    final flags = reader.u4();
    final stringsStart = reader.u4();
    final stylesStart = reader.u4();

    final isUtf8 = (flags & 0x100) != 0;

    final offsets = <int>[];
    for (var i = 0; i < stringCount; i++) {
      offsets.add(reader.u4());
    }
    // 样式表偏移暂不解析。
    reader.skip(styleCount * 4);

    final strings = <String>[];
    for (var i = 0; i < stringCount; i++) {
      final strStart = reader.offset;
      // 相对于字符串池起始的偏移:stringsStart + offsets[i]
      final absOffset = reader.offset - (stringsStart - stringsStart); // 占位,下面重新定位
      // 使用绝对文件偏移:reader 当前在 string pool chunk 内,需要算出实际文件偏移。
      // 这里简化:直接按字符串池基地址 + offsets[i] 读取。
      final baseOffset = reader.offset - offsets.length * 4 - 20; // chunkStart + headerSize - 已读部分
      // 更可靠:重新计算字符串池数据起始。
      reader.seek(stringsStart + offsets[i]);
      if (isUtf8) {
        final len = reader.uleb128();
        final bytes = reader.read(len);
        strings.add(utf8.decode(bytes));
      } else {
        final ulen = reader.u4();
        final units = <int>[];
        for (var j = 0; j < ulen; j++) {
          units.add(reader.u2());
        }
        strings.add(String.fromCharCodes(units));
      }
      // 恢复到正确位置以便读取下一个偏移(但 reader 已在 seek 之后,这里不再依赖顺序读取,跳过即可)。
      if (i < stringCount - 1) {
        reader.seek(stringsStart + offsets[i + 1]);
      }
    }

    return AXmlStringPool(
      strings: strings,
      isUtf8: isUtf8,
      offset: reader.offset,
      size: size,
    );
  }

  /// 读取命名空间 chunk(暂不渲染,只跳过数据)。
  static void _readNamespace(ByteReader reader, int headerSize, int size) {
    reader.skip(size - 8);
  }

  /// 读取开始元素 chunk。
  static AXmlNode _readStartElement(
    ByteReader reader,
    int headerSize,
    int chunkSize,
    AXmlStringPool? pool,
  ) {
    // ResXMLTree_node:
    // lineNumber: u4
    // comment: u4 (string pool index or -1)
    final lineNumber = reader.u4();
    final commentIdx = reader.s4(); // 有符号,-1 表示无

    final attributesStart = reader.u4(); // 属性区在 chunk 内的偏移(相对 chunk 开头?实际是绝对偏移)
    final attributesSize = reader.u4(); // 属性数量 * 5 * 4 ? 不,这是属性列表的字节大小
    final attributeCount = reader.u4();
    reader.u4(); // id_attribute_index
    reader.u4(); // class_attribute_index
    reader.u4(); // style_attribute_index

    final nameIdx = reader.u2();
    reader.u2(); // class_name_idx
    reader.u2(); // style_idx
    reader.u2(); // unknown

    final elementName = pool != null && nameIdx < pool.strings.length
        ? pool.strings[nameIdx]
        : '0x${nameIdx.toRadixString(16).padLeft(4, '0')}';

    final attributes = <(String, String, String?)>[];
    // 属性块:每个属性占 20 字节:
    // namespace u2, name u2, rawValue u4, typedValue type u1, typedValue data u1, padding u2 (共 16? 实际上 5*4=20)
    // 正确结构:16 字节头 + attributeCount * 5 * 4 = 16 + attrCount * 20
    var attrReaderOffset = reader.offset;
    // 属性区从 attributesStart 开始(绝对文件偏移)
    reader.seek(attributesStart);
    for (var i = 0; i < attributeCount; i++) {
      reader.u2(); // namespace_idx
      final attrNameIdx = reader.u2();
      final attrRawValueIdx = reader.u4();
      final attrType = reader.u1();
      final attrData = reader.u1();
      reader.u2(); // padding

      final attrName = pool != null && attrNameIdx < pool.strings.length
          ? pool.strings[attrNameIdx]
          : '0x${attrNameIdx.toRadixString(16).padLeft(4, '0')}';

      String rawValue;
      String? resolved;

      if (attrRawValueIdx == 0xFFFFFFFF) {
        rawValue = '';
      } else if (pool != null && attrRawValueIdx < pool.strings.length) {
        rawValue = pool.strings[attrRawValueIdx];
      } else {
        rawValue = '0x${attrRawValueIdx.toRadixString(8)}';
      }

      resolved = _resolveTypedValue(attrType, attrData, pool);

      attributes.add((attrName, rawValue, resolved));
    }

    // 恢复 reader 到 chunk 末尾,由调用方统一跳到下一个 chunk。
    reader.seek(attrReaderOffset + (attributesSize > 0 ? attributesSize : 0));

    return AXmlNode(
      name: elementName,
      attributes: attributes,
      text: '',
      children: const [],
    );
  }

  /// 把 Res_value 的类型 + 数据解析为可读字符串(资源引用、整数、布尔、颜色等)。
  static String? _resolveTypedValue(int type, int data, AXmlStringPool? pool) {
    switch (type) {
      case AXmlValueType.nul:
        return null;
      case AXmlValueType.reference:
      case AXmlValueType.attribute:
        return '@0x${data.toRadixString(8).padLeft(8, '0')}';
      case AXmlValueType.string:
        return pool != null && data < pool.strings.length
            ? pool.strings[data]
            : '0x${data.toRadixString(8).padLeft(8, '0')}';
      case AXmlValueType.floatType:
        return data.toStringAsFixed(2);
      case AXmlValueType.intDec:
        return data.toString();
      case AXmlValueType.intHex:
        return '0x${data.toRadixString(16).padLeft(8, '0')}';
      case AXmlValueType.intBoolean:
        return data != 0 ? 'true' : 'false';
      case AXmlValueType.intColorArgb8:
      case AXmlValueType.intColorRgb8:
      case AXmlValueType.intColorArgb4:
      case AXmlValueType.intColorRgb4:
        return '#${data.toRadixString(16).padLeft(8, '0')}';
      default:
        return '0x${data.toRadixString(16).padLeft(8, '0')}';
    }
  }
}
