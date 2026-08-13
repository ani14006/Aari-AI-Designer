import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Flat cream/ink background used behind the Splash and auth (Login/Signup/Forgot Password)
/// screens — matches the brand's editorial marketing site, which reads as clean and flat rather
/// than atmospheric; no gradients or glow blobs.
class DecorativeBackground extends StatelessWidget {
  final Widget child;

  const DecorativeBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: child,
    );
  }
}
