import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/responsive.dart';
import '../../models/design_model.dart';
import '../common/loading_shimmer.dart';
import '../common/retryable_error.dart';
import '../common/section_header.dart';
import 'recent_design_card.dart';
import 'recent_design_empty_state.dart';

/// "Recent Designs" section: header + responsive body (loading skeletons / grid or carousel of
/// cards / empty state / retryable error). Presentational only — data comes from the caller so
/// the provider wiring stays in HomeScreen.
class RecentDesignsSection extends StatelessWidget {
  final AsyncValue<List<DesignModel>> designsAsync;
  final VoidCallback onRetry;
  final VoidCallback onStartDesigning;
  final VoidCallback? onViewAll;
  final void Function(DesignModel design) onOpenDesign;
  final void Function(DesignModel design) onToggleFavourite;

  const RecentDesignsSection({
    super.key,
    required this.designsAsync,
    required this.onRetry,
    required this.onStartDesigning,
    required this.onOpenDesign,
    required this.onToggleFavourite,
    this.onViewAll,
  });

  static const _cardHeight = 236.0;
  static const _maxCards = 8;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isTabletOrWider = ResponsiveUtils.isTabletOrWider(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent Designs',
          actionLabel: onViewAll != null ? 'View All' : null,
          onAction: onViewAll,
        ),
        const SizedBox(height: 12),
        designsAsync.when(
          loading: () => _LoadingSkeleton(
              isGrid: isTabletOrWider,
              columns: ResponsiveUtils.gridColumns(width)),
          error: (_, __) => RetryableError(
              message: 'Unable to load your recent designs.', onRetry: onRetry),
          data: (designs) {
            if (designs.isEmpty) {
              return RecentDesignEmptyState(
                  onCreateFirstDesign: onStartDesigning);
            }
            final shown = designs.take(_maxCards).toList();
            return isTabletOrWider
                ? _DesignsGrid(
                    designs: shown,
                    columns: ResponsiveUtils.gridColumns(width),
                    onOpenDesign: onOpenDesign,
                    onToggleFavourite: onToggleFavourite,
                  )
                : _DesignsCarousel(
                    designs: shown,
                    onOpenDesign: onOpenDesign,
                    onToggleFavourite: onToggleFavourite,
                  );
          },
        ),
      ],
    );
  }
}

class _DesignsCarousel extends StatelessWidget {
  final List<DesignModel> designs;
  final void Function(DesignModel design) onOpenDesign;
  final void Function(DesignModel design) onToggleFavourite;

  const _DesignsCarousel(
      {required this.designs,
      required this.onOpenDesign,
      required this.onToggleFavourite});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: RecentDesignsSection._cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: designs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final design = designs[index];
          return RecentDesignCard(
            design: design,
            width: 168,
            onTap: () => onOpenDesign(design),
            onToggleFavourite: () => onToggleFavourite(design),
          )
              .animate(delay: (60 * index).ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.12, end: 0, curve: Curves.easeOut);
        },
      ),
    );
  }
}

class _DesignsGrid extends StatelessWidget {
  final List<DesignModel> designs;
  final int columns;
  final void Function(DesignModel design) onOpenDesign;
  final void Function(DesignModel design) onToggleFavourite;

  const _DesignsGrid({
    required this.designs,
    required this.columns,
    required this.onOpenDesign,
    required this.onToggleFavourite,
  });

  static const _spacing = 14.0;

  @override
  Widget build(BuildContext context) {
    // A Wrap of fixed-width cards rather than a fixed-crossAxisCount GridView: when there are
    // fewer designs than `columns` (e.g. just 1), a GridView still reserves the other column
    // slots as blank grid cells, making a sparse history look broken. Wrap just places the real
    // cards left-aligned and lets the rest of the row be plain empty space, like the carousel.
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - _spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: designs.asMap().entries.map((entry) {
            final design = entry.value;
            return SizedBox(
              width: cardWidth,
              height: cardWidth / 0.82,
              child: RecentDesignCard(
                design: design,
                onTap: () => onOpenDesign(design),
                onToggleFavourite: () => onToggleFavourite(design),
              ),
            )
                .animate(delay: (40 * entry.key).ms)
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.08, end: 0, curve: Curves.easeOut);
          }).toList(),
        );
      },
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  final bool isGrid;
  final int columns;

  const _LoadingSkeleton({required this.isGrid, required this.columns});

  @override
  Widget build(BuildContext context) {
    if (!isGrid) {
      return SizedBox(
        height: RecentDesignsSection._cardHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => const LoadingShimmer(
              height: RecentDesignsSection._cardHeight, width: 168),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemCount: columns * 2,
      itemBuilder: (_, __) => const LoadingShimmer(height: double.infinity),
    );
  }
}
