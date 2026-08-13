import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../common/embroidery_motif.dart';
import '../common/luxury_button.dart';

/// The Home screen's primary CTA banner. Kept compact (not a large empty hero) with a soft
/// blush background, a subtle embroidery-hoop-inspired line motif (no external image asset
/// is available), and a wine-coloured "Start Designing" button.
class StartDesigningBanner extends StatelessWidget {
  final VoidCallback onStartDesigning;

  const StartDesigningBanner({super.key, required this.onStartDesigning});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = ResponsiveUtils.isTabletOrWider(width);
    final isSmallMobile = width < 400;

    final content = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.champagne, AppColors.backgroundLight],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppTheme.softShadow(context, strength: 0.5),
      ),
      padding: EdgeInsets.all(isWide ? 32 : 24),
      child: isWide
          ? SizedBox(
              height: 280,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                      flex: 6,
                      child: _BannerText(
                          isSmallMobile: false,
                          onStartDesigning: onStartDesigning)),
                  const SizedBox(width: 24),
                  const Expanded(
                      flex: 5,
                      child: Center(child: EmbroideryMotif(size: 220))),
                ],
              ),
            )
          : Stack(
              children: [
                const Positioned(
                    top: -10,
                    right: -10,
                    child: EmbroideryMotif(size: 100, opacity: 0.5)),
                _BannerText(
                    isSmallMobile: isSmallMobile,
                    onStartDesigning: onStartDesigning),
              ],
            ),
    );

    return content
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }
}

class _BannerText extends StatelessWidget {
  final bool isSmallMobile;
  final VoidCallback onStartDesigning;

  const _BannerText(
      {required this.isSmallMobile, required this.onStartDesigning});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'AARI AI DESIGNER',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.antiqueGold,
                ),
          ),
          const SizedBox(height: AppConstants.spaceSm),
          Text(
            'Create Your Dream Blouse',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: AppConstants.spaceSm),
          Text(
            'Visualise your Aari embroidery design on your saree and blouse before starting the work.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppConstants.spaceMd),
          LuxuryButton(
            label: 'Start Designing',
            icon: Icons.auto_awesome_rounded,
            fullWidth: isSmallMobile,
            onPressed: onStartDesigning,
          ),
          const SizedBox(height: AppConstants.spaceSm),
          Text(
            'Upload your saree, blouse fabric, and inspiration image.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
