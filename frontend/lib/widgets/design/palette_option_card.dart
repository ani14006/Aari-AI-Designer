import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/palette_option.dart';

/// One selectable palette option card: colour-theory scheme chip, title, description and
/// a row of bead colour swatches.
class PaletteOptionCard extends StatelessWidget {
  final PaletteOption palette;
  final bool isSelected;
  final VoidCallback onTap;

  const PaletteOptionCard({
    super.key,
    required this.palette,
    required this.isSelected,
    required this.onTap,
  });

  Color _swatchColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final outerRadius = BorderRadius.circular(AppTheme.radiusMedium + 4);

    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  palette.scheme,
                  style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5),
                ),
              ),
              const Spacer(),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected ? AppColors.ink : AppColors.borderLight,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(palette.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(palette.description,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Row(
            children: palette.beadRecommendations
                .map((b) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Tooltip(
                        message: b.name,
                        child: Container(
                          height: 28,
                          width: 28,
                          decoration: BoxDecoration(
                            color: _swatchColor(b.hexColor),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.borderLight, width: 1.5),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );

    // Selected state is a double-ring "halo" (gold ring, gap, card border) rather than a single
    // thicker border — the gap is the surrounding page background showing through the padding.
    return InkWell(
      onTap: onTap,
      borderRadius: outerRadius,
      child: Container(
        padding: EdgeInsets.all(isSelected ? 2 : 0),
        decoration: BoxDecoration(
          borderRadius: outerRadius,
          border:
              isSelected ? Border.all(color: AppColors.gold, width: 2) : null,
        ),
        child: card,
      ),
    );
  }
}
