import 'package:flutter/material.dart';

/// App color palette defined in DESIGN.md for No5ocial's operations console.
abstract final class AppColors {
  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF1F3F6);
  static const Color surfaceMuted = Color(0xFFE9ECEF);

  // Typography
  static const Color textPrimary = Color(0xFF17191C);
  static const Color textSecondary = Color(0xFF656B73);
  static const Color textMuted = Color(0xFF9AA0A6);

  // Borders & Dividers
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFEEF0F2);

  // Brand / Actions
  static const Color ink = Color(0xFF111827);
  static const Color inkLight = Color(0xFF1F2937);
  static const Color accent = Color(0xFF3659D9);
  static const Color accentLight = Color(0xFFEEF2FF);
  static const Color accentHover = Color(0xFF2B47AF);

  // Status Colors (pair with text & icon per DESIGN.md)
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFBBF7D0);

  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFECACA);

  static const Color neutral = Color(0xFF64748B);
  static const Color neutralBg = Color(0xFFF8FAFC);
  static const Color neutralBorder = Color(0xFFE2E8F0);

  // Platform specific accents for chips and subtle badges
  static const Color instagram = Color(0xFFE1306C);
  static const Color instagramBg = Color(0xFFFDF2F5);
  static const Color youtube = Color(0xFFFF0000);
  static const Color youtubeBg = Color(0xFFFFF1F1);
  static const Color linkedin = Color(0xFF0A66C2);
  static const Color linkedinBg = Color(0xFFEFF6FC);
  static const Color x = Color(0xFF0F1419);
  static const Color xBg = Color(0xFFF2F4F6);
}
