import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Shimmering placeholder block, used while previews / lists are loading.
class LoadingShimmer extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const LoadingShimmer(
      {super.key, this.height = 20, this.width, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.cardDark : AppColors.champagne,
      highlightColor: isDark ? AppColors.borderDark : AppColors.ivory,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              borderRadius ?? BorderRadius.circular(AppTheme.radiusSmall),
        ),
      ),
    );
  }
}
