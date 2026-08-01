import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';

/// Centred, editorial-style header used across the auth screens (Login/Signup/Forgot Password):
/// a glowing gradient badge, a letter-spaced gold eyebrow label, a serif title, a subtitle and a
/// thin decorative gold rule — gives every auth screen the same classy, boutique first impression.
class AuthHeader extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;

  const AuthHeader({
    super.key,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 72,
          width: 72,
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                  spreadRadius: -4),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 32),
        ).animate().fadeIn(duration: 500.ms, curve: Curves.easeOut).scale(
              begin: const Offset(0.7, 0.7),
              curve: Curves.easeOutBack,
              duration: 600.ms,
            ),
        const SizedBox(height: 20),
        Text(
          eyebrow,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
                color: AppColors.antiqueGold,
              ),
        )
            .animate()
            .fadeIn(delay: 150.ms, duration: 450.ms)
            .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium,
        )
            .animate()
            .fadeIn(delay: 220.ms, duration: 450.ms)
            .slideY(begin: 0.25, end: 0, curve: Curves.easeOut),
        const SizedBox(height: 14),
        Container(
          height: 3,
          width: 44,
          decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(2)),
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 400.ms)
            .scaleX(begin: 0, end: 1, curve: Curves.easeOut),
        const SizedBox(height: 14),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ).animate().fadeIn(delay: 350.ms, duration: 450.ms),
      ],
    );
  }
}
