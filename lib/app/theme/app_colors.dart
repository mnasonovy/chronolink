import 'package:flutter/material.dart';

abstract final class AppColors {
  // Base backgrounds
  static const Color background = Color(0xFFFBF8F4);
  static const Color backgroundSecondary = Color(0xFFF6EFE7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF3ECE3);

  // Brand / accent
  static const Color primary = Color(0xFFD8A46B);
  static const Color primarySoft = Color(0xFFF1D8BC);
  static const Color accent = Color(0xFFF1B97A);

  // Text
  static const Color textPrimary = Color(0xFF3A342E);
  static const Color textSecondary = Color(0xFF7A726A);
  static const Color textMuted = Color(0xFFB2AAA2);

  // Borders / dividers
  static const Color border = Color(0xFFE9DED1);
  static const Color borderStrong = Color(0xFFDCC8B4);

  // States
  static const Color success = Color(0xFF7BAA7B);
  static const Color warning = Color(0xFFE0A458);
  static const Color error = Color(0xFFC96D5D);

  // Special UI
  static const Color fabBackground = Color(0xFFF7E8D4);
  static const Color todayBadge = Color(0xFFF4E5D3);
  static const Color shadow = Color(0x14000000);
}