import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/design_model.dart';
import '../common/loading_shimmer.dart';

final _dateFormat = DateFormat('d MMM yyyy');

/// A compact, professional "recent design" card for the Home screen: thumbnail, a look-style
/// badge, a title/subtitle derived from real design data (occasion/silhouette/style — never
/// invented), the last-updated date, and the existing favourite toggle.
class RecentDesignCard extends StatelessWidget {
  final DesignModel design;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavourite;
  final double? width;

  const RecentDesignCard({
    super.key,
    required this.design,
    required this.onTap,
    this.onToggleFavourite,
    this.width,
  });

  String get _title =>
      design.occasion.isNotEmpty ? design.occasion : design.lookStyle;

  String get _subtitle {
    if (design.blouseSilhouette.isNotEmpty) {
      return design.blouseSilhouette;
    }
    if (design.detectedDesignStyle.isNotEmpty) {
      return design.detectedDesignStyle;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        hoverColor: AppColors.ink.withValues(alpha: 0.04),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
            boxShadow: AppTheme.softShadow(context, strength: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: CachedNetworkImage(
                      imageUrl: design.previewImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const LoadingShimmer(
                          height: double.infinity,
                          borderRadius: BorderRadius.zero),
                      errorWidget: (_, __, ___) => Container(
                          color: AppColors.champagne,
                          child:
                              const Icon(Icons.image_not_supported_outlined)),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    right: 40,
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: _Badge(label: design.lookStyle)),
                  ),
                  if (onToggleFavourite != null)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Tooltip(
                        message: design.isFavourite
                            ? 'Remove from favourites'
                            : 'Add to favourites',
                        child: GestureDetector(
                          onTap: onToggleFavourite,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.92),
                            child: Icon(
                              design.isFavourite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 16,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (_subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Updated ${_dateFormat.format(design.updatedAt)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.antiqueGold),
      ),
    );
  }
}
