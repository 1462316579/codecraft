import 'package:flutter/material.dart';

/// 终端设置
class TerminalSettings {
  final double fontSize;
  final TerminalFontFamily fontFamily;
  final TerminalCursorStyle cursorStyle;
  final TerminalTheme theme;

  const TerminalSettings({
    this.fontSize = 14.0,
    this.fontFamily = const TerminalFontFamily('monospace', 'Monospace'),
    this.cursorStyle = TerminalCursorStyle.block,
    this.theme = TerminalThemePreset.builtin,
  });

  TerminalSettings copyWith({
    double? fontSize,
    TerminalFontFamily? fontFamily,
    TerminalCursorStyle? cursorStyle,
    TerminalTheme? theme,
  }) {
    return TerminalSettings(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      cursorStyle: cursorStyle ?? this.cursorStyle,
      theme: theme ?? this.theme,
    );
  }
}

/// 终端字体族
class TerminalFontFamily {
  final String family;
  final String displayName;

  const TerminalFontFamily(this.family, this.displayName);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TerminalFontFamily &&
          runtimeType == other.runtimeType &&
          family == other.family;

  @override
  int get hashCode => family.hashCode;
}

/// 终端光标样式
enum TerminalCursorStyle { block, underline, bar }

/// 终端主题
class TerminalTheme {
  final Color background;
  final Color foreground;
  final Color cursor;

  const TerminalTheme({
    required this.background,
    required this.foreground,
    required this.cursor,
  });
}

/// 终端主题预设
class TerminalThemePreset {
  static const TerminalTheme builtin = TerminalTheme(
    background: Color(0xFF1E1E1E),
    foreground: Color(0xFFD4D4D4),
    cursor: Color(0xFF00FF00),
  );
}
