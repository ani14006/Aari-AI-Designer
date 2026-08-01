import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/bead_recommendation.dart';

/// Displays one recommended bead colour with its swatch and the AI's reasoning.
class BeadColorChip extends StatelessWidget {
  final BeadRecommendation bead;

  const BeadColorChip({super.key, required this.bead});

  Color get _color {
    try {
      final hex = bead.hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppTheme.softShadow(context, strength: 0.6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight, width: 1.5),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bead.name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(bead.reason, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
