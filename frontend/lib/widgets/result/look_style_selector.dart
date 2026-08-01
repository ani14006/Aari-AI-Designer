import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Horizontal row of "Regenerate" style presets (Luxury / Traditional / Minimal / Bridal / ...).
class LookStyleSelector extends StatelessWidget {
  final String selected;
  final bool isBusy;
  final ValueChanged<String> onSelected;

  const LookStyleSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: LookStyles.all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final style = LookStyles.all[index];
          final isSelected = style == selected;
          return ChoiceChip(
            label: Text(style),
            selected: isSelected,
            onSelected: isBusy ? null : (_) => onSelected(style),
            selectedColor: AppColors.roseGold,
            backgroundColor: Theme.of(context).cardTheme.color,
            labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                ),
            shape: StadiumBorder(
                side: BorderSide(
                    color: isSelected
                        ? AppColors.roseGold
                        : AppColors.borderLight)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          );
        },
      ),
    );
  }
}
