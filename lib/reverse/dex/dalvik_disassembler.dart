import 'dex_file.dart';

/// 指令格式(Dalvik 字节码规范里的 layout 名称)。
enum InsnFormat {
  f10x,
  f12x,
  f11n,
  f11x,
  f10t,
  f20t,
  f22x,
  f21t,
  f21s,
  f21h,
  f21c,
  f23x,
  f22b,
  f22t,
  f22s,
  f22c,
  f32x,
  f30t,
  f31t,
  f31i,
  f31c,
  f35c,
  f3rc,
  f45cc,
  f4rcc,
  f51l,
}

/// 一条 opcode 的元信息。
class OpInfo {
  const OpInfo(this.name, this.format);

  final String name;
  final InsnFormat format;

  /// 该指令引用的常量池类型(决定操作数怎么渲染)。
  ReferenceKind get reference => switch (name) {
        final n when n.contains('string') || n == 'const-string' => ReferenceKind.string,
        final n when n.startsWith('const-class') ||
            n.startsWith('new-instance') ||
            n.startsWith('new-array') ||
            n.startsWith('check-cast') ||
            n.startsWith('instance-of') ||
            n.startsWith('filled-new-array') =>
          ReferenceKind.type,
        final n when n.startsWith('const-method') => ReferenceKind.methodHandle,
        final n when n.contains('field') => ReferenceKind.field,
        final n when n.startsWith('invoke') && !n.contains('polymorphic') && !n.contains('custom') =>
          ReferenceKind.method,
        _ => ReferenceKind.none,
      };
}

/// 指令操作数指向的常量池类别。
enum ReferenceKind { none, string, type, field, method, methodHandle, proto, callSite }

/// 完整的 256 项 opcode 表。
///
/// `null` 表示该 opcode 未定义(ODEX 专用或被保留),反汇编时按「未知指令」原样输出
/// 十六进制,不能直接跳过——跳过会让后续指令错位。
const List<OpInfo?> dalvikOpcodes = [
  // 00
  OpInfo('nop', InsnFormat.f10x),
  OpInfo('move', InsnFormat.f12x),
  OpInfo('move/from16', InsnFormat.f22x),
  OpInfo('move/16', InsnFormat.f32x),
  OpInfo('move-wide', InsnFormat.f12x),
  OpInfo('move-wide/from16', InsnFormat.f22x),
  OpInfo('move-wide/16', InsnFormat.f32x),
  OpInfo('move-object', InsnFormat.f12x),
  OpInfo('move-object/from16', InsnFormat.f22x),
  OpInfo('move-object/16', InsnFormat.f32x),
  OpInfo('move-result', InsnFormat.f11x),
  OpInfo('move-result-wide', InsnFormat.f11x),
  OpInfo('move-result-object', InsnFormat.f11x),
  OpInfo('move-exception', InsnFormat.f11x),
  OpInfo('return-void', InsnFormat.f10x),
  OpInfo('return', InsnFormat.f11x),
  // 10
  OpInfo('return-wide', InsnFormat.f11x),
  OpInfo('return-object', InsnFormat.f11x),
  OpInfo('const/4', InsnFormat.f11n),
  OpInfo('const/16', InsnFormat.f21s),
  OpInfo('const', InsnFormat.f31i),
  OpInfo('const/high16', InsnFormat.f21h),
  OpInfo('const-wide/16', InsnFormat.f21s),
  OpInfo('const-wide/32', InsnFormat.f31i),
  OpInfo('const-wide', InsnFormat.f51l),
  OpInfo('const-wide/high16', InsnFormat.f21h),
  OpInfo('const-string', InsnFormat.f21c),
  OpInfo('const-string/jumbo', InsnFormat.f31c),
  OpInfo('const-class', InsnFormat.f21c),
  OpInfo('monitor-enter', InsnFormat.f11x),
  OpInfo('monitor-exit', InsnFormat.f11x),
  OpInfo('check-cast', InsnFormat.f21c),
  // 20
  OpInfo('instance-of', InsnFormat.f22c),
  OpInfo('array-length', InsnFormat.f12x),
  OpInfo('new-instance', InsnFormat.f21c),
  OpInfo('new-array', InsnFormat.f22c),
  OpInfo('filled-new-array', InsnFormat.f35c),
  OpInfo('filled-new-array/range', InsnFormat.f3rc),
  OpInfo('fill-array-data', InsnFormat.f31t),
  OpInfo('throw', InsnFormat.f11x),
  OpInfo('goto', InsnFormat.f10t),
  OpInfo('goto/16', InsnFormat.f20t),
  OpInfo('goto/32', InsnFormat.f30t),
  OpInfo('packed-switch', InsnFormat.f31t),
  OpInfo('sparse-switch', InsnFormat.f31t),
  OpInfo('cmpl-float', InsnFormat.f23x),
  OpInfo('cmpg-float', InsnFormat.f23x),
  OpInfo('cmpl-double', InsnFormat.f23x),
  // 30
  OpInfo('cmpg-double', InsnFormat.f23x),
  OpInfo('cmp-long', InsnFormat.f23x),
  OpInfo('if-eq', InsnFormat.f22t),
  OpInfo('if-ne', InsnFormat.f22t),
  OpInfo('if-lt', InsnFormat.f22t),
  OpInfo('if-ge', InsnFormat.f22t),
  OpInfo('if-gt', InsnFormat.f22t),
  OpInfo('if-le', InsnFormat.f22t),
  OpInfo('if-eqz', InsnFormat.f21t),
  OpInfo('if-nez', InsnFormat.f21t),
  OpInfo('if-ltz', InsnFormat.f21t),
  OpInfo('if-gez', InsnFormat.f21t),
  OpInfo('if-gtz', InsnFormat.f21t),
  OpInfo('if-lez', InsnFormat.f21t),
  null,
  null,
  // 40
  null,
  null,
  null,
  null,
  OpInfo('aget', InsnFormat.f23x),
  OpInfo('aget-wide', InsnFormat.f23x),
  OpInfo('aget-object', InsnFormat.f23x),
  OpInfo('aget-boolean', InsnFormat.f23x),
  OpInfo('aget-byte', InsnFormat.f23x),
  OpInfo('aget-char', InsnFormat.f23x),
  OpInfo('aget-short', InsnFormat.f23x),
  OpInfo('aput', InsnFormat.f23x),
  OpInfo('aput-wide', InsnFormat.f23x),
  OpInfo('aput-object', InsnFormat.f23x),
  OpInfo('aput-boolean', InsnFormat.f23x),
  OpInfo('aput-byte', InsnFormat.f23x),
  // 50
  OpInfo('aput-char', InsnFormat.f23x),
  OpInfo('aput-short', InsnFormat.f23x),
  OpInfo('iget', InsnFormat.f22c),
  OpInfo('iget-wide', InsnFormat.f22c),
  OpInfo('iget-object', InsnFormat.f22c),
  OpInfo('iget-boolean', InsnFormat.f22c),
  OpInfo('iget-byte', InsnFormat.f22c),
  OpInfo('iget-char', InsnFormat.f22c),
  OpInfo('iget-short', InsnFormat.f22c),
  OpInfo('iput', InsnFormat.f22c),
  OpInfo('iput-wide', InsnFormat.f22c),
  OpInfo('iput-object', InsnFormat.f22c),
  OpInfo('iput-boolean', InsnFormat.f22c),
  OpInfo('iput-byte', InsnFormat.f22c),
  OpInfo('iput-char', InsnFormat.f22c),
  OpInfo('iput-short', InsnFormat.f22c),
  // 60
  OpInfo('sget', InsnFormat.f21c),
  OpInfo('sget-wide', InsnFormat.f21c),
  OpInfo('sget-object', InsnFormat.f21c),
  OpInfo('sget-boolean', InsnFormat.f21c),
  OpInfo('sget-byte', InsnFormat.f21c),
  OpInfo('sget-char', InsnFormat.f21c),
  OpInfo('sget-short', InsnFormat.f21c),
  OpInfo('sput', InsnFormat.f21c),
  OpInfo('sput-wide', InsnFormat.f21c),
  OpInfo('sput-object', InsnFormat.f21c),
  OpInfo('sput-boolean', InsnFormat.f21c),
  OpInfo('sput-byte', InsnFormat.f21c),
  OpInfo('sput-char', InsnFormat.f21c),
  OpInfo('sput-short', InsnFormat.f21c),
  OpInfo('invoke-virtual', InsnFormat.f35c),
  OpInfo('invoke-super', InsnFormat.f35c),
  // 70
  OpInfo('invoke-direct', InsnFormat.f35c),
  OpInfo('invoke-static', InsnFormat.f35c),
  OpInfo('invoke-interface', InsnFormat.f35c),
  null,
  OpInfo('invoke-virtual/range', InsnFormat.f3rc),
  OpInfo('invoke-super/range', InsnFormat.f3rc),
  OpInfo('invoke-direct/range', InsnFormat.f3rc),
  OpInfo('invoke-static/range', InsnFormat.f3rc),
  OpInfo('invoke-interface/range', InsnFormat.f3rc),
  null,
  null,
  OpInfo('neg-int', InsnFormat.f12x),
  OpInfo('not-int', InsnFormat.f12x),
  OpInfo('neg-long', InsnFormat.f12x),
  OpInfo('not-long', InsnFormat.f12x),
  OpInfo('neg-float', InsnFormat.f12x),
  // 80
  OpInfo('neg-double', InsnFormat.f12x),
  OpInfo('int-to-long', InsnFormat.f12x),
  OpInfo('int-to-float', InsnFormat.f12x),
  OpInfo('int-to-double', InsnFormat.f12x),
  OpInfo('long-to-int', InsnFormat.f12x),
  OpInfo('long-to-float', InsnFormat.f12x),
  OpInfo('long-to-double', InsnFormat.f12x),
  OpInfo('float-to-int', InsnFormat.f12x),
  OpInfo('float-to-long', InsnFormat.f12x),
  OpInfo('float-to-double', InsnFormat.f12x),
  OpInfo('double-to-int', InsnFormat.f12x),
  OpInfo('double-to-long', InsnFormat.f12x),
  OpInfo('double-to-float', InsnFormat.f12x),
  OpInfo('int-to-byte', InsnFormat.f12x),
  OpInfo('int-to-char', InsnFormat.f12x),
  OpInfo('int-to-short', InsnFormat.f12x),
  // 90
  OpInfo('add-int', InsnFormat.f23x),
  OpInfo('sub-int', InsnFormat.f23x),
  OpInfo('mul-int', InsnFormat.f23x),
  OpInfo('div-int', InsnFormat.f23x),
  OpInfo('rem-int', InsnFormat.f23x),
  OpInfo('and-int', InsnFormat.f23x),
  OpInfo('or-int', InsnFormat.f23x),
  OpInfo('xor-int', InsnFormat.f23x),
  OpInfo('shl-int', InsnFormat.f23x),
  OpInfo('shr-int', InsnFormat.f23x),
  OpInfo('ushr-int', InsnFormat.f23x),
  OpInfo('add-long', InsnFormat.f23x),
  OpInfo('sub-long', InsnFormat.f23x),
  OpInfo('mul-long', InsnFormat.f23x),
  OpInfo('div-long', InsnFormat.f23x),
  OpInfo('rem-long', InsnFormat.f23x),
  // a0
  OpInfo('and-long', InsnFormat.f23x),
  OpInfo('or-long', InsnFormat.f23x),
  OpInfo('xor-long', InsnFormat.f23x),
  OpInfo('shl-long', InsnFormat.f23x),
  OpInfo('shr-long', InsnFormat.f23x),
  OpInfo('ushr-long', InsnFormat.f23x),
  OpInfo('add-float', InsnFormat.f23x),
  OpInfo('sub-float', InsnFormat.f23x),
  OpInfo('mul-float', InsnFormat.f23x),
  OpInfo('div-float', InsnFormat.f23x),
  OpInfo('rem-float', InsnFormat.f23x),
  OpInfo('add-double', InsnFormat.f23x),
  OpInfo('sub-double', InsnFormat.f23x),
  OpInfo('mul-double', InsnFormat.f23x),
  OpInfo('div-double', InsnFormat.f23x),
  OpInfo('rem-double', InsnFormat.f23x),
  // b0
  OpInfo('add-int/2addr', InsnFormat.f12x),
  OpInfo('sub-int/2addr', InsnFormat.f12x),
  OpInfo('mul-int/2addr', InsnFormat.f12x),
  OpInfo('div-int/2addr', InsnFormat.f12x),
  OpInfo('rem-int/2addr', InsnFormat.f12x),
  OpInfo('and-int/2addr', InsnFormat.f12x),
  OpInfo('or-int/2addr', InsnFormat.f12x),
  OpInfo('xor-int/2addr', InsnFormat.f12x),
  OpInfo('shl-int/2addr', InsnFormat.f12x),
  OpInfo('shr-int/2addr', InsnFormat.f12x),
  OpInfo('ushr-int/2addr', InsnFormat.f12x),
  OpInfo('add-long/2addr', InsnFormat.f12x),
  OpInfo('sub-long/2addr', InsnFormat.f12x),
  OpInfo('mul-long/2addr', InsnFormat.f12x),
  OpInfo('div-long/2addr', InsnFormat.f12x),
  OpInfo('rem-long/2addr', InsnFormat.f12x),
  // c0
  OpInfo('and-long/2addr', InsnFormat.f12x),
  OpInfo('or-long/2addr', InsnFormat.f12x),
  OpInfo('xor-long/2addr', InsnFormat.f12x),
  OpInfo('shl-long/2addr', InsnFormat.f12x),
  OpInfo('shr-long/2addr', InsnFormat.f12x),
  OpInfo('ushr-long/2addr', InsnFormat.f12x),
  OpInfo('add-float/2addr', InsnFormat.f12x),
  OpInfo('sub-float/2addr', InsnFormat.f12x),
  OpInfo('mul-float/2addr', InsnFormat.f12x),
  OpInfo('div-float/2addr', InsnFormat.f12x),
  OpInfo('rem-float/2addr', InsnFormat.f12x),
  OpInfo('add-double/2addr', InsnFormat.f12x),
  OpInfo('sub-double/2addr', InsnFormat.f12x),
  OpInfo('mul-double/2addr', InsnFormat.f12x),
  OpInfo('div-double/2addr', InsnFormat.f12x),
  OpInfo('rem-double/2addr', InsnFormat.f12x),
  // d0
  OpInfo('add-int/lit16', InsnFormat.f22s),
  OpInfo('rsub-int', InsnFormat.f22s),
  OpInfo('mul-int/lit16', InsnFormat.f22s),
  OpInfo('div-int/lit16', InsnFormat.f22s),
  OpInfo('rem-int/lit16', InsnFormat.f22s),
  OpInfo('and-int/lit16', InsnFormat.f22s),
  OpInfo('or-int/lit16', InsnFormat.f22s),
  OpInfo('xor-int/lit16', InsnFormat.f22s),
  OpInfo('add-int/lit8', InsnFormat.f22b),
  OpInfo('rsub-int/lit8', InsnFormat.f22b),
  OpInfo('mul-int/lit8', InsnFormat.f22b),
  OpInfo('div-int/lit8', InsnFormat.f22b),
  OpInfo('rem-int/lit8', InsnFormat.f22b),
  OpInfo('and-int/lit8', InsnFormat.f22b),
  OpInfo('or-int/lit8', InsnFormat.f22b),
  OpInfo('xor-int/lit8', InsnFormat.f22b),
  // e0
  OpInfo('shl-int/lit8', InsnFormat.f22b),
  OpInfo('shr-int/lit8', InsnFormat.f22b),
  OpInfo('ushr-int/lit8', InsnFormat.f22b),
  null,
  null,
  null,
  null,
  null,
  null,
  null,
  null,
  null,
  null,
  null,
  null,
  null,
  // f0
  null,
  null,
  null,
  null,
  null,
  null,
  null,
  null,
  null,
  null,
  OpInfo('invoke-polymorphic', InsnFormat.f45cc),
  OpInfo('invoke-polymorphic/range', InsnFormat.f4rcc),
  OpInfo('invoke-custom', InsnFormat.f35c),
  OpInfo('invoke-custom/range', InsnFormat.f3rc),
  OpInfo('const-method-handle', InsnFormat.f21c),
  OpInfo('const-method-type', InsnFormat.f21c),
];

/// 一条反汇编后的指令。
class DisassembledInsn {
  const DisassembledInsn({
    required this.address,
    required this.opcode,
    required this.mnemonic,
    required this.operands,
    required this.raw,
  });

  /// 相对于指令流起点的字节偏移(Dex 里以码元为单位,这里换算成字节)。
  final int address;
  final int opcode;

  /// 未定义 opcode 时为 `unknown`。
  final String mnemonic;
  final String operands;

  /// 原始码元的十六进制,便于与十六进制视图对照。
  final String raw;

  String get text => operands.isEmpty ? mnemonic : '$mnemonic $operands';
}

/// Dalvik 反汇编器。
///
/// 输出与 smali 语法一致的文本,可直接对照 baksmali 的结果阅读。
class DalvikDisassembler {
  DalvikDisassembler(this.dex);

  final DexFile dex;

  /// 反汇编一个方法体。
  ///
  /// 分支目标按「指令地址」标注(`:cond_0` 这类标签),跳转指令的操作数写成标签名,
  /// 这样即使后续指令长度变化也不会让目标失效。
  List<DisassembledInsn> disassemble(DexCode code) {
    final insns = code.insns;
    final labels = _collectBranchTargets(insns);
    final out = <DisassembledInsn>[];
    var index = 0;
    while (index < insns.length) {
      final start = index;
      final unit = insns[index];
      final opcode = unit & 0xFF;
      final info = opcode < dalvikOpcodes.length ? dalvikOpcodes[opcode] : null;
      final address = start * 2;
      final label = labels.contains(address) ? ':label_${address.toRadixString(16)}\n' : '';
      if (info == null) {
        out.add(DisassembledInsn(
          address: address,
          opcode: opcode,
          mnemonic: '${label}unknown',
          operands: '0x${opcode.toRadixString(16).padLeft(2, '0')}',
          raw: _rawUnits(insns, start, 1),
        ));
        index += 1;
        continue;
      }
      final width = widthOf(info.format);
      if (index + width > insns.length) {
        out.add(DisassembledInsn(
          address: address,
          opcode: opcode,
          mnemonic: '${label}truncated',
          operands: _rawUnits(insns, start, insns.length - start),
          raw: _rawUnits(insns, start, insns.length - start),
        ));
        break;
      }
      out.add(DisassembledInsn(
        address: address,
        opcode: opcode,
        mnemonic: '$label${info.name}',
        operands: _renderOperands(info, insns, start, address),
        raw: _rawUnits(insns, start, width),
      ));
      index += width;
    }
    return out;
  }

  String _rawUnits(List<int> insns, int start, int count) => insns
      .sublist(start, (start + count).clamp(0, insns.length))
      .map((u) => u.toRadixString(16).padLeft(4, '0'))
      .join(' ');

  /// 每条格式占用的码元数。
  static int widthOf(InsnFormat format) => switch (format) {
        InsnFormat.f10x || InsnFormat.f12x || InsnFormat.f11n || InsnFormat.f11x => 1,
        InsnFormat.f10t || InsnFormat.f20t || InsnFormat.f22x || InsnFormat.f21t =>
          2,
        InsnFormat.f21s || InsnFormat.f21h || InsnFormat.f21c => 2,
        InsnFormat.f23x || InsnFormat.f22b || InsnFormat.f22t || InsnFormat.f22s => 2,
        InsnFormat.f22c || InsnFormat.f32x || InsnFormat.f30t || InsnFormat.f31t => 3,
        InsnFormat.f31i || InsnFormat.f31c => 3,
        InsnFormat.f35c || InsnFormat.f3rc => 3,
        InsnFormat.f45cc || InsnFormat.f4rcc => 4,
        InsnFormat.f51l => 5,
      };

  /// 找出所有分支目标地址,用于插标签。
  Set<int> _collectBranchTargets(List<int> insns) {
    final targets = <int>{};
    var index = 0;
    while (index < insns.length) {
      final unit = insns[index];
      final opcode = unit & 0xFF;
      final info = opcode < dalvikOpcodes.length ? dalvikOpcodes[opcode] : null;
      if (info == null) {
        index += 1;
        continue;
      }
      final width = widthOf(info.format);
      if (index + width > insns.length) break;
      final address = index * 2;
      switch (info.format) {
        case InsnFormat.f10t:
          // +AA:8 位有符号,单位是指令。
          final delta = _s8((unit >> 8) & 0xFF);
          targets.add(address + delta * 2);
        case InsnFormat.f20t:
          // +AAAA:16 位有符号。
          final delta = _s16(insns[index + 1]);
          targets.add(address + delta * 2);
        case InsnFormat.f30t:
          // +AAAAAAAA:32 位有符号,跨两个码元。
          final delta = _s32(insns[index + 1] | (insns[index + 2] << 16));
          targets.add(address + delta * 2);
        case InsnFormat.f21t:
        case InsnFormat.f22t:
          final delta = _s16(insns[index + 1]);
          targets.add(address + delta * 2);
        case InsnFormat.f31t:
          // 31t 是 switch/array 的负载偏移(相对当前指令),不是代码内分支。
          break;
        default:
          break;
      }
      index += width;
    }
    return targets;
  }

  static int _s8(int value) => (value & 0x80) != 0 ? value - 0x100 : value;

  static int _s16(int value) => (value & 0x8000) != 0 ? value - 0x10000 : value;

  static int _s32(int value) => (value & 0x80000000) != 0 ? value - 0x100000000 : value;

  static String _signed(int value) => '$value';

  String _labelOf(int address) => ':label_${address.toRadixString(16)}';

  String _renderOperands(OpInfo info, List<int> insns, int start, int address) {
    final unit = insns[start];
    final a = (unit >> 8) & 0xFF;
    final b = (unit >> 8) & 0xF;
    final c = (unit >> 12) & 0xF;
    switch (info.format) {
      case InsnFormat.f10x:
        return '';
      case InsnFormat.f12x:
        return 'v$b, v$c';
      case InsnFormat.f11n:
        return 'v$b, ${_signed(c == 0 ? 0 : (c > 7 ? c - 16 : c))}';
      case InsnFormat.f11x:
        return 'v$a';
      case InsnFormat.f10t:
        final delta = _s8(a);
        return _labelOf(address + delta * 2);
      case InsnFormat.f20t:
        final delta = _s16(insns[start + 1]);
        return _labelOf(address + delta * 2);
      case InsnFormat.f22x:
        return 'v$a, v${insns[start + 1]}';
      case InsnFormat.f21t:
        final delta = _s16(insns[start + 1]);
        return 'v$a, ${_labelOf(address + delta * 2)}';
      case InsnFormat.f21s:
        return 'v$a, ${_signed(_s16(insns[start + 1]))}';
      case InsnFormat.f21h:
        // 高 16 位字面量:左移 16 位(const-wide/high16 左移 48 位)。
        final high = _s16(insns[start + 1]);
        final shift = info.name.contains('wide') ? 48 : 16;
        return 'v$a, ${_signed(high * (1 << shift))}';
      case InsnFormat.f21c:
        return 'v$a, ${_reference(info, insns[start + 1])}';
      case InsnFormat.f23x:
        return 'v$a, v${insns[start + 1] & 0xFF}, v${(insns[start + 1] >> 8) & 0xFF}';
      case InsnFormat.f22b:
        final literal = _s8((insns[start + 1] >> 8) & 0xFF);
        return 'v$a, v${insns[start + 1] & 0xFF}, ${_signed(literal)}';
      case InsnFormat.f22t:
        final delta = _s16(insns[start + 1]);
        return 'v$b, v$c, ${_labelOf(address + delta * 2)}';
      case InsnFormat.f22s:
        return 'v$b, v$c, ${_signed(_s16(insns[start + 1]))}';
      case InsnFormat.f22c:
        return 'v$b, v$c, ${_reference(info, insns[start + 1])}';
      case InsnFormat.f32x:
        return 'v${insns[start + 1]}, v${insns[start + 2]}';
      case InsnFormat.f30t:
        final delta = _s32(insns[start + 1] | (insns[start + 2] << 16));
        return _labelOf(address + delta * 2);
      case InsnFormat.f31t:
        // switch / fill-array-data 的负载偏移:换算成绝对地址方便对照。
        final delta = _s32(insns[start + 1] | (insns[start + 2] << 16));
        return 'v$a, :payload_${(address + delta * 2).toRadixString(16)}';
      case InsnFormat.f31i:
        return 'v$a, ${_signed(_s32(insns[start + 1] | (insns[start + 2] << 16)))}';
      case InsnFormat.f31c:
        final index = insns[start + 1] | (insns[start + 2] << 16);
        return 'v$a, ${_reference(info, index)}';
      case InsnFormat.f35c:
        return '${_registerList(unit, insns[start + 2])}, ${_reference(info, insns[start + 1])}';
      case InsnFormat.f3rc:
        final first = insns[start + 2];
        final count = a;
        return '{v$first .. v${first + count - 1}}, ${_reference(info, insns[start + 1])}';
      case InsnFormat.f45cc:
      case InsnFormat.f4rcc:
        final proto = insns[start + 3];
        final target = info.format == InsnFormat.f45cc
            ? _registerList(unit, insns[start + 2])
            : '{v${insns[start + 2]} .. v${insns[start + 2] + a - 1}}';
        return '$target, ${_reference(info, insns[start + 1])}, '
            '${_reference(OpInfo('proto', InsnFormat.f21c), proto)}';
      case InsnFormat.f51l:
        final low = insns[start + 1] | (insns[start + 2] << 16);
        final high = insns[start + 3] | (insns[start + 4] << 16);
        // Dart 的 int 是 64 位有符号:`high << 32` 会自然溢出成负数,
        // 与 Dex 的 64 位补码字面量语义一致,不需要额外换算。
        return 'v$a, ${low | (high << 32)}';
    }
  }

  /// 35c 的寄存器列表:`{vC, vD, vE, vF}`,按 G 里的实际个数取。
  String _registerList(int unit, int registersUnit) {
    final count = (unit >> 12) & 0xF;
    final g = (unit >> 8) & 0xF;
    final registers = <String>[
      if (count > 0) 'v${registersUnit & 0xF}',
      if (count > 1) 'v${(registersUnit >> 4) & 0xF}',
      if (count > 2) 'v${(registersUnit >> 8) & 0xF}',
      if (count > 3) 'v${(registersUnit >> 12) & 0xF}',
      if (count > 4) 'v$g',
    ];
    return '{${registers.join(', ')}}';
  }

  /// 把常量池索引渲染成 smali 引用。
  String _reference(OpInfo info, int index) {
    try {
      switch (info.reference) {
        case ReferenceKind.string:
          return '"${_escape(dex.stringAt(index))}"';
        case ReferenceKind.type:
          return dex.typeDescriptor(index);
        case ReferenceKind.field:
          final field = dex.fieldAt(index);
          return '${field.className}->${field.name}:${field.type}';
        case ReferenceKind.method:
          final method = dex.methodAt(index);
          final params = method.proto.parameters.join('');
          return '${method.className}->${method.name}($params)${method.proto.returnType}';
        case ReferenceKind.proto:
          final proto = dex.protoAt(index);
          return '${proto.parameters.join('')}${proto.returnType}';
        case ReferenceKind.methodHandle:
          return 'method-handle@$index';
        case ReferenceKind.callSite:
          return 'call-site@$index';
        case ReferenceKind.none:
          return '0x${index.toRadixString(16)}';
      }
    } catch (_) {
      // 索引越界(被改坏的 dex):原样给出数字,不要因为一条指令失败整个方法。
      return '@0x${index.toRadixString(16)}';
    }
  }

  static String _escape(String value) => value
      .replaceAll('\\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t');
}