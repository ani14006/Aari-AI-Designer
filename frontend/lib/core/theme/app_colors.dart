import 'package:flutter/material.dart';

/// Editorial luxury colour palette: warm ivory base, near-black "ink" primary, muted gold accent —
/// the same restrained espresso/cream/gold language as the brand's marketing site (Aurelia Aari).
class AppColors {
  AppColors._();

  // Brand accents
  static const Color gold = Color(0xFFC9A24B);
  static const Color antiqueGold = Color(0xFFB08D3F);
  static const Color roseGold = Color(0xFFB76E79);
  static const Color roseGoldLight = Color(0xFFE8C4C4);
  static const Color deepMaroon = Color(0xFF6B1E2E);
  static const Color ivory = Color(0xFFFFFDF8);
  static const Color champagne = Color(0xFFF6EEE0);

  /// Near-black warm espresso — the primary brand/interactive colour (buttons, wordmark,
  /// headings), replacing rose-gold as the app's dominant accent for a more editorial,
  /// less "pink" feel.
  static const Color ink = Color(0xFF241B16);
  static const Color inkMuted = Color(0xFF4A3C33);

  // Light theme surfaces
  static const Color backgroundLight = Color(0xFFFAF7F1);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFEAE3D6);

  // Dark theme surfaces
  static const Color backgroundDark = Color(0xFF15100E);
  static const Color surfaceDark = Color(0xFF1F1815);
  static const Color cardDark = Color(0xFF261D19);
  static const Color borderDark = Color(0xFF3A2E27);

  // Text
  static const Color textPrimaryLight = Color(0xFF2A1F1A);
  static const Color textSecondaryLight = Color(0xFF7A6A5D);
  static const Color textPrimaryDark = Color(0xFFF7EFE3);
  static const Color textSecondaryDark = Color(0xFFC9BAA9);

  // Semantic
  static const Color success = Color(0xFF3E8E5A);
  static const Color error = Color(0xFFB3413B);
  static const Color warning = Color(0xFFD1962F);

  // Home-page redesign palette: a deeper, more muted wine/blush set used specifically by the
  // Home screen so its CTA/badges read as less "pink" than the roseGold accent used elsewhere.
  static const Color wine = Color(0xFF7A3455);
  static const Color softRose = Color(0xFFD9A1B2);
  static const Color lightBlush = Color(0xFFF5E7EB);
  static const Color homeBackground = Color(0xFFFAF7F3);

  // Bead colour swatches referenced across the app
  static const Map<String, Color> beadSwatches = {
    'Antique Gold': Color(0xFFB08D3F),
    'Pearl White': Color(0xFFF4F1EA),
    'Ruby Red': Color(0xFF9B111E),
    'Emerald Green': Color(0xFF0F5132),
    'Crystal': Color(0xFFDDEBF3),
    'Copper': Color(0xFFB56A3C),
    'Silver': Color(0xFFC0C0C8),
    'Black': Color(0xFF16130F),
    'Rose Gold': Color(0xFFB76E79),
  };

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE3C580), Color(0xFFC9A24B), Color(0xFFB08D3F)],
  );

  static const LinearGradient roseGoldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8C4C4), Color(0xFFB76E79)],
  );

  static const LinearGradient heroOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC15100E)],
  );
}
