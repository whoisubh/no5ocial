import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.35,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.45,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
    height: 1.45,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );

  static const TextStyle code = TextStyle(
    fontSize: 12,
    fontFamily: 'monospace',
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  // Theme-aware helpers
  static TextStyle titleOf(BuildContext context) =>
      titleLarge.copyWith(color: AppColors.textOf(context));

  static TextStyle titleMedOf(BuildContext context) =>
      titleMedium.copyWith(color: AppColors.textOf(context));

  static TextStyle bodyOf(BuildContext context) =>
      bodyMedium.copyWith(color: AppColors.textOf(context));

  static TextStyle bodySecOf(BuildContext context) =>
      bodySecondary.copyWith(color: AppColors.textSecOf(context));

  static TextStyle labelSmallOf(BuildContext context) =>
      labelSmall.copyWith(color: AppColors.textSecOf(context));
}
