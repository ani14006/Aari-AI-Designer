import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Central luxury theme definitions consumed by [MaterialApp.theme] / [darkTheme].
class AppTheme {
  AppTheme._();

  static const double radiusLarge = 24;
  static const double radiusMedium = 16;
  static const double radiusSmall = 10;

  /// Soft ambient shadow used on cards/tiles throughout the app for a premium, elevated feel —
  /// replaces the old flat border-only look. Warmer + wider in light mode, deeper in dark mode.
  static List<BoxShadow> softShadow(BuildContext context,
      {double strength = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: (isDark ? Colors.black : AppColors.deepMaroon)
            .withValues(alpha: (isDark ? 0.32 : 0.07) * strength),
        blurRadius: 28,
        offset: const Offset(0, 14),
        spreadRadius: -10,
      ),
      BoxShadow(
        color: (isDark ? Colors.black : AppColors.antiqueGold)
            .withValues(alpha: (isDark ? 0.18 : 0.05) * strength),
        blurRadius: 10,
        offset: const Offset(0, 3),
        spreadRadius: -4,
      ),
    ];
  }

  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.roseGold,
      secondary: AppColors.gold,
      surface: AppColors.surfaceLight,
      error: AppColors.error,
    ),
    textTheme: AppTextStyles.light,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
      titleTextStyle: AppTextStyles.light.headlineSmall,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.roseGold,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium)),
        textStyle: AppTextStyles.light.labelLarge,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimaryLight,
        side: const BorderSide(color: AppColors.borderLight, width: 1.4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium)),
        textStyle: AppTextStyles.light.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardLight,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.roseGold, width: 1.6),
      ),
    ),
    dividerTheme: const DividerThemeData(
        color: AppColors.borderLight, thickness: 1, space: 32),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.roseGold
            : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.roseGoldLight
            : AppColors.borderLight,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedItemColor: AppColors.roseGold,
      unselectedItemColor: AppColors.textSecondaryLight,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      elevation: 8,
    ),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.roseGoldLight,
      secondary: AppColors.gold,
      surface: AppColors.surfaceDark,
      error: AppColors.error,
    ),
    textTheme: AppTextStyles.dark,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
      titleTextStyle: AppTextStyles.dark.headlineSmall,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.roseGoldLight,
        foregroundColor: AppColors.textPrimaryLight,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium)),
        textStyle: AppTextStyles.dark.labelLarge,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimaryDark,
        side: const BorderSide(color: AppColors.borderDark, width: 1.4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium)),
        textStyle: AppTextStyles.dark.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardDark,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide:
            const BorderSide(color: AppColors.roseGoldLight, width: 1.6),
      ),
    ),
    dividerTheme: const DividerThemeData(
        color: AppColors.borderDark, thickness: 1, space: 32),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.roseGoldLight,
      unselectedItemColor: AppColors.textSecondaryDark,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      elevation: 8,
    ),
  );
}
