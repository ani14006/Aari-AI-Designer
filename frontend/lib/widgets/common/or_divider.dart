import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A thin "── or continue with ──" divider used between the email/password form and social sign-in.
class OrDivider extends StatelessWidget {
  final String label;

  const OrDivider({super.key, this.label = 'or continue with'});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Row(
      children: [
        Expanded(child: Divider(color: lineColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(letterSpacing: 0.4),
          ),
        ),
        Expanded(child: Divider(color: lineColor, thickness: 1)),
      ],
    );
  }
}
