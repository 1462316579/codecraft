import 'package:flutter/material.dart';

import 'semantic_colors.dart';
import 'tokens.dart';

/// 柔光玻璃风格 ColorScheme。
final lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Brand.violet,
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFEDE9FE).withValues(alpha: 0.7),
  onPrimaryContainer: Brand.onVioletContainer,
  secondary: Color(0xFF6D5BD0),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFE9E5FC).withValues(alpha: 0.7),
  onSecondaryContainer: Color(0xFF3A2C86),
  tertiary: Color(0xFF16A34A),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFDCFCE7).withValues(alpha: 0.7),
  onTertiaryContainer: Color(0xFF15803D),
  error: Color(0xFFDC2626),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFEE2E2).withValues(alpha: 0.7),
  onErrorContainer: Color(0xFF7F1D1D),
  surface: Color(0xFFF8F9FF).withValues(alpha: 0.8),
  onSurface: Color(0xFF1B1B1F),
  surfaceDim: Color(0xFFE9E7F2).withValues(alpha: 0.6),
  surfaceBright: Color(0xFFFFFFFF).withValues(alpha: 0.9),
  surfaceContainerLowest: Color(0xFFFFFFFF).withValues(alpha: 0.7),
  surfaceContainerLow: Color(0xFFFBFAFE).withValues(alpha: 0.75),
  surfaceContainer: Color(0xFFF5F4FA).withValues(alpha: 0.8),
  surfaceContainerHigh: Color(0xFFEFEEF7).withValues(alpha: 0.85),
  surfaceContainerHighest: Color(0xFFE8E6F3).withValues(alpha: 0.9),
  onSurfaceVariant: Color(0xFF49454F),
  outline: Color(0xFFD1D1D6).withValues(alpha: 0.6),
  outlineVariant: Color(0xFFE5E5EA).withValues(alpha: 0.5),
  shadow: Color(0xFF000000).withValues(alpha: 0.08),
  scrim: Color(0xFF000000).withValues(alpha: 0.3),
  inverseSurface: Color(0xFF1B1B1F),
  onInverseSurface: Color(0xFFF5F4FA),
  inversePrimary: Brand.violetLight,
  surfaceTint: Brand.violet.withValues(alpha: 0.1),
);

final darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Brand.violetLight,
  onPrimary: Brand.onVioletLight,
  primaryContainer: Brand.violetDeep.withValues(alpha: 0.7),
  onPrimaryContainer: Brand.violetContainer,
  secondary: Color(0xFFB9A8FC),
  onSecondary: Color(0xFF231956),
  secondaryContainer: Color(0xFF3A2C86).withValues(alpha: 0.7),
  onSecondaryContainer: Color(0xFFE9E5FC),
  tertiary: Color(0xFF22C55E),
  onTertiary: Color(0xFF052E16),
  tertiaryContainer: Color(0xFF14532D).withValues(alpha: 0.7),
  onTertiaryContainer: Color(0xFFBBF7D0),
  error: Color(0xFFF87171),
  onError: Color(0xFF450A0A),
  errorContainer: Color(0xFF7F1D1D).withValues(alpha: 0.7),
  onErrorContainer: Color(0xFFFECACA),
  surface: Color(0xFF0D1B2E).withValues(alpha: 0.75),
  onSurface: Color(0xFFEAF2FF),
  surfaceDim: Color(0xFF07111F).withValues(alpha: 0.6),
  surfaceBright: Color(0xFF24405F).withValues(alpha: 0.8),
  surfaceContainerLowest: Color(0xFF050C17).withValues(alpha: 0.7),
  surfaceContainerLow: Color(0xFF07111F).withValues(alpha: 0.75),
  surfaceContainer: Color(0xFF0D1B2E).withValues(alpha: 0.8),
  surfaceContainerHigh: Color(0xFF13273F).withValues(alpha: 0.85),
  surfaceContainerHighest: Color(0xFF1B3350).withValues(alpha: 0.9),
  onSurfaceVariant: Color(0xFFB8C7DA),
  outline: Color(0xFF64748B).withValues(alpha: 0.6),
  outlineVariant: Color(0xFF334155).withValues(alpha: 0.5),
  shadow: Color(0xFF000000).withValues(alpha: 0.2),
  scrim: Color(0xFF000000).withValues(alpha: 0.5),
  inverseSurface: Color(0xFFE6E1E9),
  onInverseSurface: Color(0xFF1A181E),
  inversePrimary: Brand.violet,
  surfaceTint: Brand.violetLight.withValues(alpha: 0.15),
);

TextTheme _tweak(TextTheme base) => base.copyWith(
      headlineSmall:
          base.headlineSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(height: 24 / 16),
      bodyMedium: base.bodyMedium?.copyWith(height: 21 / 14),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w500, letterSpacing: 0),
    );

ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = isDark ? darkColorScheme : lightColorScheme;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    // 聊天页(以及所有未显式设置 backgroundColor 的页面)共用语义底色。
    // 之前全透明 → 深色模式下透出 Android 窗口的黑底,聊天页因此是一片漆黑。
    scaffoldBackgroundColor:
        isDark ? darkSemanticColors.pageBackground : lightSemanticColors.pageBackground,
    textTheme: _tweak(isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme),
    extensions: [isDark ? darkSemanticColors : lightSemanticColors],
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface.withValues(alpha: 0.7),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.surface.withValues(alpha: 0.7),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.surface.withValues(alpha: 0.7),
        foregroundColor: scheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: scheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}