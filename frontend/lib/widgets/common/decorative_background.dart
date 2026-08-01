import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'glow_blob.dart';

/// Soft gradient + glow-blob atmosphere used behind the Splash and auth (Login/Signup/Forgot
/// Password) screens, so the whole first-impression flow feels premium rather than flat white.
class DecorativeBackground extends StatelessWidget {
  final Widget child;

  const DecorativeBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [AppColors.backgroundDark, AppColors.surfaceDark]
              : [AppColors.ivory, AppColors.backgroundLight],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -70,
            right: -70,
            child: GlowBlob(
                size: 240,
                color: AppColors.gold.withValues(alpha: isDark ? 0.16 : 0.28)),
          ),
          Positioned(
            bottom: -90,
            left: -70,
            child: GlowBlob(
                size: 260,
                color:
                    AppColors.roseGold.withValues(alpha: isDark ? 0.14 : 0.22)),
          ),
          child,
        ],
      ),
    );
  }
}
