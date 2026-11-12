import 'package:flutter/material.dart';

/// 全局语义色彩,移植自原仓库 core/theme/AIEditorTheme.kt 的 AppSemanticColors。
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.diffAdd,
    required this.diffAddBg,
    required this.diffRemove,
    required this.diffRemoveBg,
    required this.subtleText,
    required this.subtleBorder,
    required this.cardSurface,
    required this.pageBackground,
    required this.mutedSurface,
    required this.capsuleSurface,
    required this.buttonMutedBg,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color diffAdd;
  final Color diffAddBg;
  final Color diffRemove;
  final Color diffRemoveBg;
  final Color subtleText;
  final Color subtleBorder;
  final Color cardSurface;
  final Color pageBackground;
  final Color mutedSurface;
  final Color capsuleSurface;
  final Color buttonMutedBg;

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? diffAdd,
    Color? diffAddBg,
    Color? diffRemove,
    Color? diffRemoveBg,
    Color? subtleText,
    Color? subtleBorder,
    Color? cardSurface,
    Color? pageBackground,
    Color? mutedSurface,
    Color? capsuleSurface,
    Color? buttonMutedBg,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      diffAdd: diffAdd ?? this.diffAdd,
      diffAddBg: diffAddBg ?? this.diffAddBg,
      diffRemove: diffRemove ?? this.diffRemove,
      diffRemoveBg: diffRemoveBg ?? this.diffRemoveBg,
      subtleText: subtleText ?? this.subtleText,
      subtleBorder: subtleBorder ?? this.subtleBorder,
      cardSurface: cardSurface ?? this.cardSurface,
      pageBackground: pageBackground ?? this.pageBackground,
      mutedSurface: mutedSurface ?? this.mutedSurface,
      capsuleSurface: capsuleSurface ?? this.capsuleSurface,
      buttonMutedBg: buttonMutedBg ?? this.buttonMutedBg,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppSemanticColors(
      success: mix(success, other.success),
      onSuccess: mix(onSuccess, other.onSuccess),
      successContainer: mix(successContainer, other.successContainer),
      onSuccessContainer: mix(onSuccessContainer, other.onSuccessContainer),
      warning: mix(warning, other.warning),
      onWarning: mix(onWarning, other.onWarning),
      warningContainer: mix(warningContainer, other.warningContainer),
      onWarningContainer: mix(onWarningContainer, other.onWarningContainer),
      info: mix(info, other.info),
      onInfo: mix(onInfo, other.onInfo),
      infoContainer: mix(infoContainer, other.infoContainer),
      onInfoContainer: mix(onInfoContainer, other.onInfoContainer),
      diffAdd: mix(diffAdd, other.diffAdd),
      diffAddBg: mix(diffAddBg, other.diffAddBg),
      diffRemove: mix(diffRemove, other.diffRemove),
      diffRemoveBg: mix(diffRemoveBg, other.diffRemoveBg),
      subtleText: mix(subtleText, other.subtleText),
      subtleBorder: mix(subtleBorder, other.subtleBorder),
      cardSurface: mix(cardSurface, other.cardSurface),
      pageBackground: mix(pageBackground, other.pageBackground),
      mutedSurface: mix(mutedSurface, other.mutedSurface),
      capsuleSurface: mix(capsuleSurface, other.capsuleSurface),
      buttonMutedBg: mix(buttonMutedBg, other.buttonMutedBg),
    );
  }
}

const lightSemanticColors = AppSemanticColors(
  success: Color(0xFF22C55E),
  onSuccess: Color(0xFFFFFFFF),
  successContainer: Color(0xFFDCFCE7),
  onSuccessContainer: Color(0xFF15803D),
  warning: Color(0xFFF59E0B),
  onWarning: Color(0xFFFFFFFF),
  warningContainer: Color(0xFFFEF3C7),
  onWarningContainer: Color(0xFF92400E),
  info: Color(0xFF0284C7),
  onInfo: Color(0xFFFFFFFF),
  infoContainer: Color(0xFFE0F2FE),
  onInfoContainer: Color(0xFF075985),
  diffAdd: Color(0xFF22C55E),
  diffAddBg: Color(0x2622C55E),
  diffRemove: Color(0xFFEF4444),
  diffRemoveBg: Color(0x26EF4444),
  subtleText: Color(0xFF8E8E93),
  subtleBorder: Color(0xFFE5E5EA),
  cardSurface: Color(0xFFFFFFFF),
  pageBackground: Color(0xFFF8F9FF),
  mutedSurface: Color(0xFFF2F2F7),
  capsuleSurface: Color(0xFFE9E9EB),
  buttonMutedBg: Color(0xFFF0F2F5),
);

const darkSemanticColors = AppSemanticColors(
  success: Color(0xFF4ADE80),
  onSuccess: Color(0xFF052E16),
  successContainer: Color(0x59052E16),
  onSuccessContainer: Color(0xFFBBF7D0),
  warning: Color(0xFFFBBF24),
  onWarning: Color(0xFF78350F),
  warningContainer: Color(0x5978350F),
  onWarningContainer: Color(0xFFFDE68A),
  info: Color(0xFF38BDF8),
  onInfo: Color(0xFF0C4A6E),
  infoContainer: Color(0x590C4A6E),
  onInfoContainer: Color(0xFFBAE6FD),
  diffAdd: Color(0xFF4ADE80),
  diffAddBg: Color(0x334ADE80),
  diffRemove: Color(0xFFF87171),
  diffRemoveBg: Color(0x33F87171),
  subtleText: Color(0xFF94A3B8),
  subtleBorder: Color(0xFF2A3F56),
  cardSurface: Color(0xFF0D1B2E),
  pageBackground: Color(0xFF0B1026),
  mutedSurface: Color(0xFF13273F),
  capsuleSurface: Color(0xFF1E293B),
  buttonMutedBg: Color(0xFF1E293B),
);

extension SemanticColorsX on BuildContext {
  AppSemanticColors get semantic =>
      Theme.of(this).extension<AppSemanticColors>() ?? lightSemanticColors;
}