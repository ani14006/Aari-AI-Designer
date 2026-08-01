import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../common/luxury_button.dart';

/// Compact, intentional-looking empty state shown when the user has no designs yet.
class RecentDesignEmptyState extends StatelessWidget {
  final VoidCallback onCreateFirstDesign;

  const RecentDesignEmptyState({super.key, required this.onCreateFirstDesign});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop =
        ResponsiveUtils.isDesktop(MediaQuery.sizeOf(context).width);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: isDesktop ? 200 : 160),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.lightBlush,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: AppTheme.softShadow(context, strength: 0.4),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: const BoxDecoration(
                gradient: AppColors.goldGradient, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(height: 14),
          Text('No designs yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Create your first AI-assisted Aari embroidery design.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          LuxuryButton(
            label: 'Create First Design',
            icon: Icons.add_rounded,
            fullWidth: false,
            color: AppColors.wine,
            onPressed: onCreateFirstDesign,
          ),
        ],
      ),
    );
  }
}
