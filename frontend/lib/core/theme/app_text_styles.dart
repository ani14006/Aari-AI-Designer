import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Elegant serif display type paired with a clean sans body — the editorial-fashion feel.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _display(double size,
      {FontWeight weight = FontWeight.w600, required Color color}) {
    return GoogleFonts.playfairDisplay(
        fontSize: size, fontWeight: weight, color: color, letterSpacing: 0.2);
  }

  static TextStyle _body(double size,
      {FontWeight weight = FontWeight.w400, required Color color}) {
    return GoogleFonts.manrope(
        fontSize: size, fontWeight: weight, color: color, height: 1.45);
  }

  static TextTheme light = TextTheme(
    displayLarge: _display(40,
        weight: FontWeight.w700, color: AppColors.textPrimaryLight),
    displayMedium: _display(32,
        weight: FontWeight.w700, color: AppColors.textPrimaryLight),
    headlineLarge: _display(26, color: AppColors.textPrimaryLight),
    headlineMedium: _display(22, color: AppColors.textPrimaryLight),
    headlineSmall: _display(18, color: AppColors.textPrimaryLight),
    titleLarge:
        _body(18, weight: FontWeight.w700, color: AppColors.textPrimaryLight),
    titleMedium:
        _body(16, weight: FontWeight.w600, color: AppColors.textPrimaryLight),
    titleSmall:
        _body(14, weight: FontWeight.w600, color: AppColors.textPrimaryLight),
    bodyLarge: _body(16, color: AppColors.textPrimaryLight),
    bodyMedium: _body(14, color: AppColors.textSecondaryLight),
    bodySmall: _body(12, color: AppColors.textSecondaryLight),
    labelLarge:
        _body(15, weight: FontWeight.w600, color: AppColors.textPrimaryLight),
  );

  static TextTheme dark = TextTheme(
    displayLarge:
        _display(40, weight: FontWeight.w700, color: AppColors.textPrimaryDark),
    displayMedium:
        _display(32, weight: FontWeight.w700, color: AppColors.textPrimaryDark),
    headlineLarge: _display(26, color: AppColors.textPrimaryDark),
    headlineMedium: _display(22, color: AppColors.textPrimaryDark),
    headlineSmall: _display(18, color: AppColors.textPrimaryDark),
    titleLarge:
        _body(18, weight: FontWeight.w700, color: AppColors.textPrimaryDark),
    titleMedium:
        _body(16, weight: FontWeight.w600, color: AppColors.textPrimaryDark),
    titleSmall:
        _body(14, weight: FontWeight.w600, color: AppColors.textPrimaryDark),
    bodyLarge: _body(16, color: AppColors.textPrimaryDark),
    bodyMedium: _body(14, color: AppColors.textSecondaryDark),
    bodySmall: _body(12, color: AppColors.textSecondaryDark),
    labelLarge:
        _body(15, weight: FontWeight.w600, color: AppColors.textPrimaryDark),
  );
}
