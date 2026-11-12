import 'package:flutter/material.dart';

import '../log/file_logger.dart';

/// 日志等级主题色(逐值移植自上游 `core/theme/AIEditorTheme.kt` 的 `LogLevelColors`)。
abstract final class LogLevelColors {
  static const Color verbose = Color(0xFF94A3B8);
  static const Color debug = Color(0xFF3B82F6);
  static const Color info = Color(0xFF22C55E);
  static const Color warn = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color none = Color(0xFF64748B);

  static Color of(LogLevel level) => switch (level) {
        LogLevel.verbose => verbose,
        LogLevel.debug => debug,
        LogLevel.info => info,
        LogLevel.warn => warn,
        LogLevel.error => error,
        LogLevel.none => none,
      };
}
