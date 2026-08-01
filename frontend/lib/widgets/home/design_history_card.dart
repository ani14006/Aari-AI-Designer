import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/design_model.dart';
import '../common/loading_shimmer.dart';

/// Compact card used in "Recent Designs" carousels and the History grid.
class DesignHistoryCard extends StatelessWidget {
  final DesignModel design;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavourite;
  final double? width;

  const DesignHistoryCard({
    super.key,
    required this.design,
    required this.onTap,
    this.onToggleFavourite,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.softShadow(context),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: CachedNetworkImage(
                  imageUrl: design.previewImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const LoadingShimmer(
                      height: double.infinity, borderRadius: BorderRadius.zero),
                  errorWidget: (_, __, ___) => Container(
                      color: AppColors.champagne,
                      child: const Icon(Icons.image_not_supported_outlined)),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                  decoration: const BoxDecoration(
                      gradient: AppColors.heroOverlayGradient),
                  child: Text(
                    design.lookStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ),
              if (onToggleFavourite != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onToggleFavourite,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      child: Icon(
                        design.isFavourite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 16,
                        color: AppColors.roseGold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
