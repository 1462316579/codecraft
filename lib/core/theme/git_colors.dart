import 'package:flutter/material.dart';

/// 状态码 → 配色(移植自上游 `core/theme/AIEditorTheme.kt` 的 `GitStatusColors`)。
///
/// 与多数 Git 客户端约定一致:新增=绿、修改=琥珀、删除=红、重命名/复制=蓝、未跟踪=灰、
/// 冲突=紫红、类型变更=青。仅取首字符判定,porcelain 的 X/Y 两列统一映射。
abstract final class GitStatusColors {
  static const Color added = Color(0xFF16A34A);
  static const Color modified = Color(0xFFD97706);
  static const Color deleted = Color(0xFFDC2626);
  static const Color renamed = Color(0xFF2563EB);
  static const Color untracked = Color(0xFF94A3B8);
  static const Color conflict = Color(0xFF9333EA);
  static const Color typeChanged = Color(0xFF0891B2);
  static const Color fallback = Color(0xFF64748B);

  static Color background(String code) => switch (code.isEmpty ? '' : code[0]) {
        'A' => added, // 新增
        'M' => modified, // 修改
        'D' => deleted, // 删除
        'R' || 'C' => renamed, // 重命名 / 复制
        '?' => untracked, // 未跟踪
        'U' => conflict, // 冲突
        'T' => typeChanged, // 类型变更
        _ => fallback,
      };

  /// 前景色按背景亮度自适应,避免浅灰等高明度背景配白字导致对比度不足。
  static Color foreground(Color background) =>
      background.computeLuminance() > 0.45 ? const Color(0xFF0F172A) : Colors.white;
}