import 'dart:typed_data';

import '../binary/byte_reader.dart';

/// 访问标志位(Dex 规范 `access_flags`)。
class DexAccess {
  const DexAccess._();

  static const int public = 0x1;
  static const int private = 0x2;
  static const int protected = 0x4;
  static const int staticFlag = 0x8;
  static const int finalFlag = 0x10;
  static const int synchronized = 0x20;
  static const int superFlag = 0x20;
  static const int volatileFlag = 0x40;
  static const int bridge = 0x40;
  static const int transientFlag = 0x80;
  static const int varargs = 0x80;
  static const int native = 0x100;
  static const int interfaceFlag = 0x200;
  static const int abstract = 0x400;
  static const int strict = 0x800;
  static const int synthetic = 0x1000;
  static const int annotation = 0x2000;
  static const int enumFlag = 0x4000;
  static const int constructor = 0x10000;
  static const int declaredSynchronized = 0x20000;

  /// 修饰符的展示顺序按 Java 习惯,避免每次渲染都现排。
  static List<String> describe(int flags, {required bool forClass}) {
    final out = <String>[];
    if (flags & public != 0) out.add('public');
    if (flags & private != 0) out.add('private');
    if (flags & protected != 0) out.add('protected');
    if (flags & staticFlag != 0) out.add('static');
    if (flags & finalFlag != 0) out.add('final');
    if (flags & synchronized != 0 && !forClass) out.add('synchronized');
    if (flags & volatileFlag != 0 && !forClass) out.add('volatile');
    if (flags & transientFlag != 0 && !forClass) out.add('transient');
    if (flags & bridge != 0 && !forClass) out.add('bridge');
    if (flags & varargs != 0 && !forClass) out.add('varargs');
    if (flags & native != 0) out.add('native');
    if (flags & interfaceFlag != 0) out.add('interface');
    if (flags & abstract != 0) out.add('abstract');
    if (flags & strict != 0) out.add('strictfp');
    if (flags & synthetic != 0) out.add('synthetic');
    if (flags & annotation != 0) out.add('annotation');
    if (flags & enumFlag != 0) out.add('enum');
    if (flags & constructor != 0) out.add('constructor');
    return out;
  }
}

/// Dex 文件头(`header_item`,固定 112 字节)。
class DexHeader {
  const DexHeader({
    required this.version,
    required this.checksum,
    required this.signature,
    required this.fileSize,
    required this.stringIdsSize,
    required this.stringIdsOff,
    required this.typeIdsSize,
    required this.typeIdsOff,
    required this.protoIdsSize,
    required this.protoIdsOff,
    required this.fieldIdsSize,
    required this.fieldIdsOff,
    required this.methodIdsSize,
    required this.methodIdsOff,
    required this.classDefsSize,
    required this.classDefsOff,
    required this.dataSize,
    required this.dataOff,
  });

  /// magic 里的三位版本号,如 035 / 039。
  final int version;
  final int checksum;
  final Uint8List signature;
  final int fileSize;
  final int stringIdsSize;
  final int stringIdsOff;
  final int typeIdsSize;
  final int typeIdsOff;
  final int protoIdsSize;
  final int protoIdsOff;
  final int fieldIdsSize;
  final int fieldIdsOff;
  final int methodIdsSize;
  final int methodIdsOff;
  final int classDefsSize;
  final int classDefsOff;
  final int dataSize;
  final int dataOff;
}

/// `proto_id_item`:方法原型(返回类型 + 参数类型)。
class DexProto {
  const DexProto({
    required this.shorty,
    required this.returnType,
    required this.parameters,
  });

  final String shorty;
  final String returnType;
  final List<String> parameters;
}

/// `field_id_item`。
class DexFieldRef {
  const DexFieldRef({
    required this.className,
    required this.type,
    required this.name,
  });

  final String className;
  final String type;
  final String name;

  @override
  String toString() => '$className.$name: $type';
}

/// `method_id_item`。
class DexMethodRef {
  const DexMethodRef({
    required this.className,
    required this.name,
    required this.proto,
  });

  final String className;
  final String name;
  final DexProto proto;

  /// 带参数的类型签名,如 `void onCreate(android.os.Bundle)`。
  String get signature {
    final params = proto.parameters.map(DexFile.prettyType).join(', ');
    return '${DexFile.prettyType(proto.returnType)} $name($params)';
  }
}

/// `code_item`:一个方法的方法体。
class DexCode {
  const DexCode({
    required this.registersSize,
    required this.insSize,
    required this.outsSize,
    required this.insns,
    required this.triesSize,
  });

  final int registersSize;
  final int insSize;
  final int outsSize;

  /// 指令流,每条指令占 1 个或以上 16 位码元。
  final List<int> insns;
  final int triesSize;
}

/// 编码后的字段(`encoded_field`):字段引用 + 访问标志。
class DexEncodedField {
  const DexEncodedField({required this.field, required this.accessFlags});

  final DexFieldRef field;
  final int accessFlags;
}

/// 编码后的方法(`encoded_method`):方法引用 + 访问标志 + 方法体偏移。
class DexEncodedMethod {
  const DexEncodedMethod({
    required this.method,
    required this.accessFlags,
    required this.codeOff,
  });

  final DexMethodRef method;
  final int accessFlags;

  /// 0 表示抽象方法或 native 方法,没有方法体。
  final int codeOff;

  bool get hasCode => codeOff != 0;
}

/// `class_def_item` 解析结果。
class DexClass {
  const DexClass({
    required this.name,
    required this.descriptor,
    required this.accessFlags,
    required this.superclass,
    required this.interfaces,
    required this.sourceFile,
    required this.staticFields,
    required this.instanceFields,
    required this.directMethods,
    required this.virtualMethods,
  });

  /// Java 风格类名,如 `com.example.Foo`。
  final String name;
  final String descriptor;
  final int accessFlags;
  final String? superclass;
  final List<String> interfaces;
  final String? sourceFile;
  final List<DexEncodedField> staticFields;
  final List<DexEncodedField> instanceFields;
  final List<DexEncodedMethod> directMethods;
  final List<DexEncodedMethod> virtualMethods;

  List<DexEncodedMethod> get methods => [...directMethods, ...virtualMethods];

  List<DexEncodedField> get fields => [...staticFields, ...instanceFields];

  /// 类所属包名(取最后一个 `/` 之前的部分,转成点分)。
  String get packageName {
    final slash = descriptor.lastIndexOf('/');
    if (slash < 0) return '';
    return descriptor.substring(1, slash).replaceAll('/', '.');
  }
}

/// 解析后的 Dex 文件。
///
/// 字符串、类型、字段、方法都按需解码并缓存:一个 11MB 的 dex 有十万级字符串,
/// 打开文件时全量解码会让界面卡住好几秒,而这些内容多数用户根本不会看到。
class DexFile {
  DexFile._(this.bytes, this.header);

  final Uint8List bytes;
  final DexHeader header;

  final Map<int, String> _stringCache = {};
  final Map<int, String> _typeCache = {};
  final Map<int, DexProto> _protoCache = {};
  final Map<int, DexFieldRef> _fieldCache = {};
  final Map<int, DexMethodRef> _methodCache = {};
  final Map<int, DexCode> _codeCache = {};

  List<DexClass>? _classes;

  /// 解析失败时抛 [BinaryFormatException]。
  static DexFile parse(Uint8List bytes) {
    final reader = ByteReader(bytes);
    final magic = reader.read(8);
    if (magic[0] != 0x64 || magic[1] != 0x65 || magic[2] != 0x78 || magic[3] != 0x0A) {
      throw const BinaryFormatException('不是 Dex 文件(magic 不符)');
    }
    if (magic[7] != 0) {
      throw const BinaryFormatException('不是 Dex 文件(magic 结尾应为 0)');
    }
    final version = (magic[4] - 0x30) * 100 + (magic[5] - 0x30) * 10 + (magic[6] - 0x30);

    final checksum = reader.u4();
    final signature = reader.read(20);
    final fileSize = reader.u4();
    reader.u4(); // header_size,固定 112
    reader.u4(); // endian_tag
    reader.u4(); // link_size
    reader.u4(); // link_off
    reader.u4(); // map_off
    final header = DexHeader(
      version: version,
      checksum: checksum,
      signature: signature,
      fileSize: fileSize,
      stringIdsSize: reader.u4(),
      stringIdsOff: reader.u4(),
      typeIdsSize: reader.u4(),
      typeIdsOff: reader.u4(),
      protoIdsSize: reader.u4(),
      protoIdsOff: reader.u4(),
      fieldIdsSize: reader.u4(),
      fieldIdsOff: reader.u4(),
      methodIdsSize: reader.u4(),
      methodIdsOff: reader.u4(),
      classDefsSize: reader.u4(),
      classDefsOff: reader.u4(),
      dataSize: reader.u4(),
      dataOff: reader.u4(),
    );
    return DexFile._(bytes, header);
  }

  /// 字符串总数(`string_ids` 表长度)。
  int get stringCount => header.stringIdsSize;

  /// 第 [index] 个字符串(MUTF-8 解码,按需缓存)。
  String stringAt(int index) {
    final cached = _stringCache[index];
    if (cached != null) return cached;
    if (index < 0 || index >= header.stringIdsSize) {
      throw BinaryFormatException('字符串索引越界:$index / ${header.stringIdsSize}');
    }
    final reader = ByteReader(bytes, offset: header.stringIdsOff + index * 4);
    final dataOff = reader.u4();
    final value = _readStringData(dataOff);
    _stringCache[index] = value;
    return value;
  }

  String _readStringData(int dataOff) {
    final reader = ByteReader(bytes, offset: dataOff);
    reader.uleb128(); // utf16 长度:解码时用不上,靠 0x00 终止符判断结尾
    final start = reader.offset;
    var end = start;
    while (end < bytes.length && bytes[end] != 0) {
      end++;
    }
    return decodeMutf8(bytes, start: start, end: end);
  }

  /// 字符串在文件里的数据区偏移(写回时定位用)。
  int stringDataOffset(int index) {
    if (index < 0 || index >= header.stringIdsSize) {
      throw BinaryFormatException('字符串索引越界:$index / ${header.stringIdsSize}');
    }
    final reader = ByteReader(bytes, offset: header.stringIdsOff + index * 4);
    return reader.u4();
  }

  /// 字符串数据的编码字节区间(不含 uleb128 前缀与结尾的 0)。
  ({int start, int end}) stringBytesRange(int index) {
    final reader = ByteReader(bytes, offset: stringDataOffset(index));
    reader.uleb128();
    final start = reader.offset;
    var end = start;
    while (end < bytes.length && bytes[end] != 0) {
      end++;
    }
    return (start: start, end: end);
  }

  /// 类型描述符(如 `Ljava/lang/String;`)。
  String typeDescriptor(int index) {
    final cached = _typeCache[index];
    if (cached != null) return cached;
    if (index < 0 || index >= header.typeIdsSize) {
      throw BinaryFormatException('类型索引越界:$index / ${header.typeIdsSize}');
    }
    final reader = ByteReader(bytes, offset: header.typeIdsOff + index * 4);
    final value = stringAt(reader.u4());
    _typeCache[index] = value;
    return value;
  }

  /// 类型总数。
  int get typeCount => header.typeIdsSize;

  DexProto protoAt(int index) {
    final cached = _protoCache[index];
    if (cached != null) return cached;
    final reader = ByteReader(bytes, offset: header.protoIdsOff + index * 12);
    final shorty = stringAt(reader.u4());
    final returnType = typeDescriptor(reader.u4());
    final parametersOff = reader.u4();
    final parameters = <String>[];
    if (parametersOff != 0) {
      final listReader = ByteReader(bytes, offset: parametersOff);
      final size = listReader.u4();
      for (var i = 0; i < size; i++) {
        parameters.add(typeDescriptor(listReader.u2()));
      }
    }
    final proto = DexProto(shorty: shorty, returnType: returnType, parameters: parameters);
    _protoCache[index] = proto;
    return proto;
  }

  DexFieldRef fieldAt(int index) {
    final cached = _fieldCache[index];
    if (cached != null) return cached;
    final reader = ByteReader(bytes, offset: header.fieldIdsOff + index * 8);
    final ref = DexFieldRef(
      className: typeDescriptor(reader.u2()),
      type: typeDescriptor(reader.u2()),
      name: stringAt(reader.u4()),
    );
    _fieldCache[index] = ref;
    return ref;
  }

  DexMethodRef methodAt(int index) {
    final cached = _methodCache[index];
    if (cached != null) return cached;
    final reader = ByteReader(bytes, offset: header.methodIdsOff + index * 8);
    final className = typeDescriptor(reader.u2());
    final proto = protoAt(reader.u2());
    final ref = DexMethodRef(
      className: className,
      name: stringAt(reader.u4()),
      proto: proto,
    );
    _methodCache[index] = ref;
    return ref;
  }

  /// 读取方法体(`code_item`)。
  DexCode codeAt(int codeOff) {
    final cached = _codeCache[codeOff];
    if (cached != null) return cached;
    final reader = ByteReader(bytes, offset: codeOff);
    final registersSize = reader.u2();
    final insSize = reader.u2();
    final outsSize = reader.u2();
    final triesSize = reader.u2();
    reader.u4(); // debug_info_off
    final insnsSize = reader.u4();
    final insns = List<int>.filled(insnsSize, 0);
    for (var i = 0; i < insnsSize; i++) {
      insns[i] = reader.u2();
    }
    final code = DexCode(
      registersSize: registersSize,
      insSize: insSize,
      outsSize: outsSize,
      insns: insns,
      triesSize: triesSize,
    );
    _codeCache[codeOff] = code;
    return code;
  }

  /// 全部类定义(首次访问时解析并缓存)。
  List<DexClass> get classes {
    final cached = _classes;
    if (cached != null) return cached;
    final list = <DexClass>[];
    for (var i = 0; i < header.classDefsSize; i++) {
      list.add(_readClassDef(i));
    }
    _classes = list;
    return list;
  }

  DexClass _readClassDef(int index) {
    final reader = ByteReader(bytes, offset: header.classDefsOff + index * 32);
    final classIdx = reader.u4();
    final accessFlags = reader.u4();
    final superclassIdx = reader.u4();
    final interfacesOff = reader.u4();
    final sourceFileIdx = reader.u4();
    reader.u4(); // annotations_off
    final classDataOff = reader.u4();
    reader.u4(); // static_values_off

    final descriptor = typeDescriptor(classIdx);
    final interfaces = <String>[];
    if (interfacesOff != 0) {
      final listReader = ByteReader(bytes, offset: interfacesOff);
      final size = listReader.u4();
      for (var i = 0; i < size; i++) {
        interfaces.add(typeDescriptor(listReader.u2()));
      }
    }

    final staticFields = <DexEncodedField>[];
    final instanceFields = <DexEncodedField>[];
    final directMethods = <DexEncodedMethod>[];
    final virtualMethods = <DexEncodedMethod>[];
    if (classDataOff != 0) {
      final data = ByteReader(bytes, offset: classDataOff);
      final staticCount = data.uleb128();
      final instanceCount = data.uleb128();
      final directCount = data.uleb128();
      final virtualCount = data.uleb128();

      var fieldIdx = 0;
      for (var i = 0; i < staticCount; i++) {
        fieldIdx += data.uleb128();
        staticFields.add(DexEncodedField(field: fieldAt(fieldIdx), accessFlags: data.uleb128()));
      }
      fieldIdx = 0;
      for (var i = 0; i < instanceCount; i++) {
        fieldIdx += data.uleb128();
        instanceFields.add(DexEncodedField(field: fieldAt(fieldIdx), accessFlags: data.uleb128()));
      }
      var methodIdx = 0;
      for (var i = 0; i < directCount; i++) {
        methodIdx += data.uleb128();
        final flags = data.uleb128();
        directMethods.add(DexEncodedMethod(
          method: methodAt(methodIdx),
          accessFlags: flags,
          codeOff: data.uleb128(),
        ));
      }
      methodIdx = 0;
      for (var i = 0; i < virtualCount; i++) {
        methodIdx += data.uleb128();
        final flags = data.uleb128();
        virtualMethods.add(DexEncodedMethod(
          method: methodAt(methodIdx),
          accessFlags: flags,
          codeOff: data.uleb128(),
        ));
      }
    }

    return DexClass(
      name: prettyType(descriptor),
      descriptor: descriptor,
      accessFlags: accessFlags,
      superclass: superclassIdx == 0xFFFFFFFF ? null : prettyType(typeDescriptor(superclassIdx)),
      interfaces: interfaces.map(prettyType).toList(),
      sourceFile: sourceFileIdx == 0xFFFFFFFF ? null : stringAt(sourceFileIdx),
      staticFields: staticFields,
      instanceFields: instanceFields,
      directMethods: directMethods,
      virtualMethods: virtualMethods,
    );
  }

  /// 描述符转 Java 风格类型名:`Ljava/lang/String;` → `java.lang.String`,
  /// `[I` → `int[]`。
  static String prettyType(String descriptor) {
    var dims = 0;
    var i = 0;
    while (i < descriptor.length && descriptor[i] == '[') {
      dims++;
      i++;
    }
    if (i >= descriptor.length) return descriptor;
    String base;
    final marker = descriptor[i];
    switch (marker) {
      case 'V':
        base = 'void';
      case 'Z':
        base = 'boolean';
      case 'B':
        base = 'byte';
      case 'S':
        base = 'short';
      case 'C':
        base = 'char';
      case 'I':
        base = 'int';
      case 'J':
        base = 'long';
      case 'F':
        base = 'float';
      case 'D':
        base = 'double';
      case 'L':
        final end = descriptor.lastIndexOf(';');
        base = (end > i ? descriptor.substring(i + 1, end) : descriptor.substring(i + 1))
            .replaceAll('/', '.');
      default:
        base = descriptor.substring(i);
    }
    return '$base${'[]' * dims}';
  }
}