import 'package:flutter/material.dart';

/// App color palette defined in DESIGN.md for no5ocial's operations console.
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
  static const Color facebook = Color(0xFF1877F2);
  static const Color facebookBg = Color(0xFFEFF6FF);
  static const Color threads = Color(0xFF101010);
  static const Color threadsBg = Color(0xFFF1F5F9);

  // Executive Dark Cards & Highlights
  static const Color darkCard = Color(0xFF0C1017);
  static const Color darkCardSurface = Color(0xFF161E2E);
  static const Color darkCardBorder = Color(0xFF27354A);

  // Ambient Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x04000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> glowShadow = [
    BoxShadow(color: Color(0x1F3659D9), blurRadius: 16, offset: Offset(0, 4)),
  ];

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1117), Color(0xFF161E2E), Color(0xFF1F293D)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3659D9), Color(0xFF4F70ED)],
  );

  // Dynamic theme-aware resolvers
  static Color surfaceOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF101522) : surface;

  static Color surfaceSecOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF161D2E) : surfaceSecondary;

  static Color bgOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0A0D14) : background;

  static Color borderOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF222C40) : border;

  static Color textOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.white : textPrimary;

  static Color textSecOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : textSecondary;
}
