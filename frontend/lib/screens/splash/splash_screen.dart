import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/common/decorative_background.dart';

/// Shown briefly on cold start while Supabase resolves the current auth session.
/// Navigation away from here (to /login or /home) is owned entirely by the router's
/// auth redirect in `app_router.dart`, not by this screen.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecorativeBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 96,
                width: 96,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                        spreadRadius: -6),
                  ],
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 44),
              ).animate().fadeIn(duration: 500.ms, curve: Curves.easeOut).scale(
                  begin: const Offset(0.7, 0.7),
                  curve: Curves.easeOutBack,
                  duration: 600.ms),
              const SizedBox(height: 24),
              Text(
                'AARI AI DESIGNER',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(letterSpacing: 3, color: AppColors.antiqueGold),
              )
                  .animate()
                  .fadeIn(delay: 250.ms, duration: 500.ms)
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
              const SizedBox(height: 32),
              const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: AppColors.roseGold),
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
