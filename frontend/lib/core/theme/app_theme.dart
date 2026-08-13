import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Central luxury theme definitions consumed by [MaterialApp.theme] / [darkTheme].
class AppTheme {
  AppTheme._();

  static const double radiusLarge = 24;
  static const double radiusMedium = 16;
  static const double radiusSmall = 10;

  /// Cards are flat — a hairline border does all the work, no shadow. Kept as a no-op (rather
  /// than deleting every `boxShadow: AppTheme.softShadow(...)` call site) so every card/tile in
  /// the app loses its shadow from this one change. See [photoShadow] for the app's one
  /// deliberate exception.
  static List<BoxShadow> softShadow(BuildContext context,
      {double strength = 1}) {
    return const [];
  }

  /// The app's one deliberate shadow, reserved for product/preview photography resting on a
  /// surface (the Result screen's generated preview, the Landing hero's image panel) — never
  /// applied to cards, buttons, or chrome.
  static const List<BoxShadow> photoShadow = [
    BoxShadow(
      color: Color.fromRGBO(36, 27, 22, 0.28),
      blurRadius: 40,
      offset: Offset(0, 20),
      spreadRadius: -12,
    ),
  ];

  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.ink,
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
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
        shape: const StadiumBorder(),
        textStyle: AppTextStyles.light.labelLarge
            ?.copyWith(letterSpacing: 0.6, fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.ink, width: 1.4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: const StadiumBorder(),
        textStyle: AppTextStyles.light.labelLarge
            ?.copyWith(letterSpacing: 0.6, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
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
        borderSide: const BorderSide(color: AppColors.ink, width: 1.6),
      ),
    ),
    dividerTheme: const DividerThemeData(
        color: AppColors.borderLight, thickness: 1, space: 32),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.ink
            : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.inkMuted
            : AppColors.borderLight,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedItemColor: AppColors.ink,
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
      primary: AppColors.gold,
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
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.ink,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
        shape: const StadiumBorder(),
        textStyle: AppTextStyles.dark.labelLarge
            ?.copyWith(letterSpacing: 0.6, fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimaryDark,
        side: const BorderSide(color: AppColors.borderDark, width: 1.4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: const StadiumBorder(),
        textStyle: AppTextStyles.dark.labelLarge
            ?.copyWith(letterSpacing: 0.6, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.gold),
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
        borderSide: const BorderSide(color: AppColors.gold, width: 1.6),
      ),
    ),
    dividerTheme: const DividerThemeData(
        color: AppColors.borderDark, thickness: 1, space: 32),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.gold,
      unselectedItemColor: AppColors.textSecondaryDark,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      elevation: 8,
    ),
  );
}
