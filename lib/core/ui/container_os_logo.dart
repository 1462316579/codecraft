import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 容器系统类型 → 单色 logo(对齐上游 containerOsLogo):未识别(含 null)返回 null,
/// 由调用方回退通用容器图标。
const Map<String, String> _osLogos = {
  'alpine': 'assets/logos/alpine.svg',
  'centos': 'assets/logos/centos.svg',
  'ubuntu': 'assets/logos/ubuntu.svg',
  'debian': 'assets/logos/debian.svg',
};

Widget? containerOsLogo({
  required String? osId,
  required double size,
  required Color tint,
}) {
  final asset = _osLogos[osId];
  if (asset == null) return null;
  return SvgPicture.asset(
    asset,
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
  );
}