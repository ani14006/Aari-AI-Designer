import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum LuxuryButtonVariant { primary, outline, gold }

/// The app's signature call-to-action button: solid-ink pill fill, uppercase tracked label,
/// loading state — matches the brand's editorial marketing-site button style.
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
    final labelColor = variant == LuxuryButtonVariant.outline
        ? AppColors.ink
        : (variant == LuxuryButtonVariant.gold ? AppColors.ink : Colors.white);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: labelColor),
          )
        else ...[
          if (icon != null) ...[Icon(icon, size: 18, color: labelColor), const SizedBox(width: 8)],
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: labelColor,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
          ),
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

    final fillColor =
        color ?? (variant == LuxuryButtonVariant.gold ? AppColors.gold : AppColors.ink);

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Opacity(
        opacity: disabled && !isLoading ? 0.5 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                  color: fillColor.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
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
