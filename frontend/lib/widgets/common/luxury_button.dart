import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

enum LuxuryButtonVariant { primary, outline, gold }

/// The app's signature call-to-action button: rose-gold gradient fill, pill corners, loading state.
class LuxuryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final LuxuryButtonVariant variant;
  final bool fullWidth;

  /// Optional solid-fill override for the primary/gold variants — when set, the button renders
  /// as a flat solid colour instead of the default gradient. Existing call sites are unaffected.
  final Color? color;

  const LuxuryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = LuxuryButtonVariant.primary,
    this.fullWidth = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2.2, color: Colors.white),
          )
        else ...[
          if (icon != null) ...[Icon(icon, size: 19), const SizedBox(width: 8)],
          Text(label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: variant == LuxuryButtonVariant.outline
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Colors.white,
                  )),
        ],
      ],
    );

    if (variant == LuxuryButtonVariant.outline) {
      return SizedBox(
        width: fullWidth ? double.infinity : null,
        child: OutlinedButton(
            onPressed: disabled ? null : onPressed, child: content),
      );
    }

    final gradient = color != null
        ? null
        : (variant == LuxuryButtonVariant.gold
            ? AppColors.goldGradient
            : AppColors.roseGoldGradient);
    final shadowColor = color ?? AppColors.roseGold;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Opacity(
        opacity: disabled && !isLoading ? 0.55 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: gradient,
            color: color,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: [
              BoxShadow(
                  color: shadowColor.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              onTap: disabled ? null : onPressed,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
