import 'dart:convert';
import 'dart:typed_data';

import 'package:codecraft/reverse/binary/byte_reader.dart';
import 'package:codecraft/reverse/dex/dalvik_disassembler.dart';
import 'package:codecraft/reverse/dex/dex_file.dart';
import 'package:flutter_test/flutter_test.dart';

/// 真实 dex 夹具:R8 产出的 `RecordTag` 类(704 字节,dex 038)。
///
/// 用它而不是手工构造字节,是因为手工构造只能验证「按我理解写」的格式,
/// 而真实 dex 能验证解析器与规范是否一致。期望值由独立的 Python 解析器逐字段核对得出。
const String _recordTagDex =
    'ZGV4CjAzOABEjpy2XtJg+1IUwDeiftzzD0H0jtl2xUTAAgAAcAAAAHhWNBIAAAAAAAAAAEQCAAAHAAAAcAAAAAMA'
    'AACMAAAAAQAAAJgAAAAAAAAAAAAAAAIAAACkAAAAAQAAALQAAADsAQAA1AAAAOwAAAD0AAAACAEAACoBAAA+AQAA'
    'QQEAAAQCAAACAAAAAwAAAAQAAAAEAAAAAgAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAEUAAABAAAAAAAAAAEA'
    'AAAAAAAAOAIAAAAAAAABAAEAAQAAAAAAAAAEAAAAcBABAAAADgAGPGluaXQ+ABJEOCQkU3ludGhldGljQ2xhc3MA'
    'IExjb20vYW5kcm9pZC90b29scy9yOC9SZWNvcmRUYWc7ABJMamF2YS9sYW5nL09iamVjdDsAAVYAwAF+fkQ4eyJi'
    'YWNrZW5kIjoiZGV4IiwiY29tcGlsYXRpb24tbW9kZSI6ImRlYnVnIiwiZGVzdWdhcmVkLWxpYnJhcnktaWRlbnRp'
    'ZmllcnMiOlsiY29tLnRvb2xzLmFuZHJvaWQ6ZGVzdWdhcl9qZGtfbGlic19jb25maWd1cmF0aW9uOjIuMS41Il0s'
    'Imhhcy1jaGVja3N1bXMiOnRydWUsIm1pbi1hcGkiOjI2LCJ2ZXJzaW9uIjoiOC45LjM1In0AMn5+fnsiTGNvbS9h'
    'bmRyb2lkL3Rvb2xzL3I4L1JlY29yZFRhZzsiOiI0MjhmYzljYSJ9AAAAAQAAhKAE1AEAAAoAAAAAAAAAAQAAAAAA'
    'AAABAAAABwAAAHAAAAACAAAAAwAAAIwAAAADAAAAAQAAAJgAAAAFAAAAAgAAAKQAAAAGAAAAAQAAALQAAAABIAAA'
    'AQAAANQAAAACIAAABwAAAOwAAAAAIAAAAQAAADgCAAAAEAAAAQAAAEQCAAA=';

Uint8List _fixture() => base64Decode(_recordTagDex);

void main() {
  group('字节读取器', () {
    test('小端整数按声明位宽读出', () {
      final reader = ByteReader(Uint8List.fromList([0x78, 0x56, 0x34, 0x12]));
      expect(reader.u2(), 0x5678);
      expect(reader.u2(), 0x1234);
    });

    test('u4 超出 int32 范围时仍是正数', () {
      // Dex 里大量偏移字段是 0xFFFFFFFF(表示「无」),按有符号读会变成 -1。
      final reader = ByteReader(Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF]));
      expect(reader.u4(), 0xFFFFFFFF);
    });

    test('s4 与 s2 按补码取负', () {
      expect(ByteReader(Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF])).s4(), -1);
      expect(ByteReader(Uint8List.fromList([0xFE, 0xFF])).s2(), -2);
    });

    test('uleb128 单字节与多字节', () {
      expect(ByteReader(Uint8List.fromList([0x7F])).uleb128(), 127);
      // 0x80 0x01 → 128
      expect(ByteReader(Uint8List.fromList([0x80, 0x01])).uleb128(), 128);
      // 0xE5 0x8E 0x26 → 624485
      expect(ByteReader(Uint8List.fromList([0xE5, 0x8E, 0x26])).uleb128(), 624485);
    });

    test('sleb128 负数', () {
      // 0x7F → -1
      expect(ByteReader(Uint8List.fromList([0x7F])).sleb128(), -1);
      // 0x80 0x7F → -128
      expect(ByteReader(Uint8List.fromList([0x80, 0x7F])).sleb128(), -128);
    });

    test('越界读取抛明确的格式异常', () {
      final reader = ByteReader(Uint8List.fromList([1, 2]));
      expect(() => reader.u4(), throwsA(isA<BinaryFormatException>()));
    });

    test('seek 越界被拒绝', () {
      final reader = ByteReader(Uint8List.fromList([1, 2]));
      expect(() => reader.seek(3), throwsA(isA<BinaryFormatException>()));
      expect(() => reader.seek(-1), throwsA(isA<BinaryFormatException>()));
    });
  });

  group('MUTF-8 编解码', () {
    test('普通中文往返', () {
      const text = '天玄大陆';
      final encoded = encodeMutf8(text);
      expect(decodeMutf8(encoded), text);
    });

    test('NUL 编码成 C0 80 两字节', () {
      final encoded = encodeMutf8('a\u0000b');
      expect(encoded, [0x61, 0xC0, 0x80, 0x62]);
      expect(decodeMutf8(encoded), 'a\u0000b');
    });

    test('emoji 按 CESU-8 拆成两个代理项', () {
      // 增补平面字符:MUTF-8 用两个三字节代理项表示,不是标准 UTF-8 的四字节。
      const emoji = '\u{1F600}';
      final encoded = encodeMutf8(emoji);
      expect(encoded, hasLength(6));
      expect(decodeMutf8(encoded), emoji);
    });

    test('截断的多字节序列不抛异常', () {
      // 被改坏的 dex 里字符串可能被截断,解析器不能因此崩掉。
      expect(() => decodeMutf8(Uint8List.fromList([0xE4, 0xB8])), returnsNormally);
    });
  });

  group('Dex 文件头', () {
    late DexFile dex;

    setUpAll(() => dex = DexFile.parse(_fixture()));

    test('版本号与文件大小', () {
      expect(dex.header.version, 38);
      expect(dex.header.fileSize, 704);
      expect(dex.header.checksum, 0xb69c8e44);
    });

    test('各常量表长度与偏移', () {
      expect(dex.header.stringIdsSize, 7);
      expect(dex.header.stringIdsOff, 112);
      expect(dex.header.typeIdsSize, 3);
      expect(dex.header.typeIdsOff, 140);
      expect(dex.header.protoIdsSize, 1);
      expect(dex.header.fieldIdsSize, 0);
      expect(dex.header.methodIdsSize, 2);
      expect(dex.header.classDefsSize, 1);
      expect(dex.header.classDefsOff, 180);
      expect(dex.header.dataOff, 212);
    });

    test('非 dex 内容被拒绝', () {
      expect(
        () => DexFile.parse(Uint8List.fromList(List<int>.filled(200, 0))),
        throwsA(isA<BinaryFormatException>()),
      );
    });

    test('过短的文件不会读越界', () {
      expect(
        () => DexFile.parse(Uint8List.fromList(utf8.encode('dex\n035\u0000'))),
        throwsA(isA<BinaryFormatException>()),
      );
    });
  });

  group('Dex 常量池', () {
    late DexFile dex;

    setUpAll(() => dex = DexFile.parse(_fixture()));

    test('字符串按索引解码', () {
      expect(dex.stringAt(0), '<init>');
      expect(dex.stringAt(1), r'D8$$SyntheticClass');
      expect(dex.stringAt(2), 'Lcom/android/tools/r8/RecordTag;');
      expect(dex.stringAt(3), 'Ljava/lang/Object;');
      expect(dex.stringAt(4), 'V');
    });

    test('字符串索引越界时报明确错误', () {
      expect(() => dex.stringAt(99), throwsA(isA<BinaryFormatException>()));
      expect(() => dex.stringAt(-1), throwsA(isA<BinaryFormatException>()));
    });

    test('字符串数据的字节区间可用于等长替换', () {
      final range = dex.stringBytesRange(4);
      // 'V' 占一个字节,区间长度为 1。
      expect(range.end - range.start, 1);
      expect(dex.bytes.sublist(range.start, range.end), [0x56]);
    });

    test('类型描述符转 Java 风格名', () {
      expect(DexFile.prettyType('Ljava/lang/String;'), 'java.lang.String');
      expect(DexFile.prettyType('[I'), 'int[]');
      expect(DexFile.prettyType('[[Ljava/lang/String;'), 'java.lang.String[][]');
      expect(DexFile.prettyType('V'), 'void');
      expect(DexFile.prettyType('Z'), 'boolean');
      expect(DexFile.prettyType('J'), 'long');
    });

    test('方法原型与签名', () {
      final proto = dex.protoAt(0);
      expect(proto.shorty, 'V');
      expect(proto.returnType, 'V');
      expect(proto.parameters, isEmpty);
    });

    test('方法引用带类名与名称', () {
      final method = dex.methodAt(0);
      expect(method.className, 'Lcom/android/tools/r8/RecordTag;');
      expect(method.name, '<init>');
      expect(method.signature, 'void <init>()');
    });
  });

  group('Dex 类结构', () {
    late DexFile dex;

    setUpAll(() => dex = DexFile.parse(_fixture()));

    test('类名、父类、访问标志', () {
      final type = dex.classes.single;
      expect(type.name, 'com.android.tools.r8.RecordTag');
      expect(type.descriptor, 'Lcom/android/tools/r8/RecordTag;');
      expect(type.superclass, 'java.lang.Object');
      expect(type.accessFlags, 0x1401);
      expect(DexAccess.describe(type.accessFlags, forClass: true),
          containsAll(['public', 'abstract', 'synthetic']));
      expect(type.packageName, 'com.android.tools.r8');
    });

    test('源文件名取自 source_file_idx', () {
      expect(dex.classes.single.sourceFile, r'D8$$SyntheticClass');
    });

    test('方法归入 direct/virtual 两组', () {
      final type = dex.classes.single;
      expect(type.directMethods, hasLength(1));
      expect(type.virtualMethods, isEmpty);
      expect(type.methods.single.method.name, '<init>');
      expect(type.methods.single.hasCode, isTrue);
    });

    test('无字段', () {
      expect(dex.classes.single.fields, isEmpty);
    });
  });

  group('方法体解析', () {
    late DexFile dex;

    setUpAll(() => dex = DexFile.parse(_fixture()));

    test('寄存器数量与指令流', () {
      final method = dex.classes.single.methods.single;
      final code = dex.codeAt(method.codeOff);
      expect(code.registersSize, 1);
      expect(code.insSize, 1);
      expect(code.outsSize, 1);
      expect(code.triesSize, 0);
      expect(code.insns, [0x1070, 0x0001, 0x0000, 0x000e]);
    });
  });

  group('Dalvik 反汇编', () {
    late DexFile dex;
    late List<DisassembledInsn> insns;

    setUpAll(() {
      dex = DexFile.parse(_fixture());
      final code = dex.codeAt(dex.classes.single.methods.single.codeOff);
      insns = DalvikDisassembler(dex).disassemble(code);
    });

    test('两条指令按地址排列', () {
      expect(insns, hasLength(2));
      expect(insns[0].address, 0);
      // invoke-direct 是 35c 格式,占 3 个码元(6 字节),所以第二条在偏移 6。
      expect(insns[1].address, 6);
    });

    test('invoke-direct 带寄存器列表与完整方法引用', () {
      // 0x1070:opcode 0x70 = invoke-direct,AA=1 个参数
      expect(insns[0].mnemonic, 'invoke-direct');
      expect(
        insns[0].operands,
        '{v0}, Ljava/lang/Object;-><init>()V',
      );
    });

    test('return-void 无操作数', () {
      expect(insns[1].mnemonic, 'return-void');
      expect(insns[1].operands, isEmpty);
      expect(insns[1].text, 'return-void');
    });

    test('原始码元保留,便于与十六进制视图对照', () {
      expect(insns[0].raw, '1070 0001 0000');
      expect(insns[1].raw, '000e');
    });

    test('指令宽度覆盖全部格式', () {
      // 抽查几种关键格式的码元数,写错会让后续指令整体错位。
      expect(DalvikDisassembler.widthOf(InsnFormat.f10x), 1);
      expect(DalvikDisassembler.widthOf(InsnFormat.f12x), 1);
      expect(DalvikDisassembler.widthOf(InsnFormat.f22x), 2);
      expect(DalvikDisassembler.widthOf(InsnFormat.f35c), 3);
      expect(DalvikDisassembler.widthOf(InsnFormat.f3rc), 3);
      expect(DalvikDisassembler.widthOf(InsnFormat.f45cc), 4);
      expect(DalvikDisassembler.widthOf(InsnFormat.f51l), 5);
    });

    test('opcode 表完整覆盖 256 项', () {
      expect(dalvikOpcodes, hasLength(256));
    });

    test('未定义 opcode 原样输出而不跳过', () {
      // 0x73 是保留位:跳过会让后面的指令错位,必须输出占位并继续。
      final code = DexCode(
        registersSize: 1,
        insSize: 0,
        outsSize: 0,
        insns: const [0x0073, 0x000e],
        triesSize: 0,
      );
      final result = DalvikDisassembler(dex).disassemble(code);
      expect(result, hasLength(2));
      expect(result[0].mnemonic, 'unknown');
      expect(result[0].operands, '0x73');
      expect(result[1].mnemonic, 'return-void');
    });

    test('指令流被截断时不崩溃', () {
      final code = DexCode(
        registersSize: 1,
        insSize: 0,
        outsSize: 0,
        // const(31i)需要 3 个码元,这里只给 1 个。
        insns: const [0x0014],
        triesSize: 0,
      );
      final result = DalvikDisassembler(dex).disassemble(code);
      expect(result.single.mnemonic, 'truncated');
    });
  });

  group('分支目标与标签', () {
    test('goto 的目标地址插入标签', () {
      final dex = DexFile.parse(_fixture());
      // goto +2(跳到第 3 个码元处,即字节偏移 4),后面补 return-void。
      final code = DexCode(
        registersSize: 1,
        insSize: 0,
        outsSize: 0,
        insns: const [0x0228, 0x0000, 0x000e],
        triesSize: 0,
      );
      final result = DalvikDisassembler(dex).disassemble(code);
      expect(result[0].mnemonic, 'goto');
      expect(result[0].operands, ':label_4');
      expect(result[1].mnemonic, ':label_4\nreturn-void');
    });

    test('if-eqz 的 16 位相对偏移', () {
      final dex = DexFile.parse(_fixture());
      // if-eqz v0, +2 → 从偏移 0 跳到偏移 4(即后面的 return-void)
      final code = DexCode(
        registersSize: 1,
        insSize: 0,
        outsSize: 0,
        insns: const [0x0038, 0x0002, 0x000e, 0x000e],
        triesSize: 0,
      );
      final result = DalvikDisassembler(dex).disassemble(code);
      expect(result[0].mnemonic, 'if-eqz');
      expect(result[0].operands, 'v0, :label_4');
    });
  });
}