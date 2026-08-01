import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Standard rounded-card container used across Home / Design / Result screens. Uses a soft
/// ambient shadow (rather than a flat border alone) for a more premium, elevated feel.
class LuxuryCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const LuxuryCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppTheme.radiusLarge);
    final padded = Padding(padding: padding, child: child);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: radius,
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: AppTheme.softShadow(context),
      ),
      // Always provide a (transparent) Material here — even when the card itself has no onTap —
      // so any interactive descendant (e.g. a ListTile) finds its nearest Material inside this
      // opaque background rather than behind it, otherwise its ink splash renders invisibly.
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? padded
            : InkWell(borderRadius: radius, onTap: onTap, child: padded),
      ),
    );
  }
}
