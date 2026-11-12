import 'package:flutter/material.dart';

/// 设计令牌:逐值移植自原仓库 core/theme/AIEditorTheme.kt。
abstract final class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class Radii {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 10;
  static const double mdLarge = 12;
  static const double lg = 14;
  static const double xl = 16;
  static const double pill = 999;
}

abstract final class Brand {
  static const Color blue = Color(0xFF2563EB);
  static const Color sky = Color(0xFF38BDF8);
  static const Color iconGray = Color(0xFF64748B);
  static const Color orange = Color(0xFFF57C00);

  /// 强调色(紫罗兰,对齐新版设计的图标/按钮/选中态)。
  static const Color violet = Color(0xFF7C5CF6);
  static const Color violetContainer = Color(0xFFEDE9FE);
  static const Color onVioletContainer = Color(0xFF4C1D95);
  static const Color violetLight = Color(0xFFA78BFA);
  static const Color onVioletLight = Color(0xFF2E1065);
  static const Color violetDeep = Color(0xFF4C1D95);
}