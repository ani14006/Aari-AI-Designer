import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../state/history_provider.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/responsive_page.dart';
import '../../widgets/common/retryable_error.dart';
import '../../widgets/home/design_history_card.dart';

/// Feature 10: every design the user has previously generated, with a favourites filter.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool _favouritesOnly = false;

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final width = MediaQuery.sizeOf(context).width;
    final hPad = ResponsiveUtils.horizontalPadding(width);
    final columns = ResponsiveUtils.gridColumns(width);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: SafeArea(
        child: ResponsivePage(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: !_favouritesOnly,
                      onSelected: (_) =>
                          setState(() => _favouritesOnly = false),
                      selectedColor: AppColors.ink,
                      labelStyle: TextStyle(
                          color: !_favouritesOnly ? Colors.white : null,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Favourites'),
                      selected: _favouritesOnly,
                      onSelected: (_) => setState(() => _favouritesOnly = true),
                      selectedColor: AppColors.ink,
                      labelStyle: TextStyle(
                          color: _favouritesOnly ? Colors.white : null,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: history.when(
                    loading: () => GridView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: 6,
                      itemBuilder: (_, __) =>
                          const LoadingShimmer(height: double.infinity),
                    ),
                    error: (_, __) => RetryableError(
                      message: 'Could not load history.',
                      onRetry: () => ref.read(historyProvider.notifier).load(),
                    ),
                    data: (designs) {
                      final filtered = _favouritesOnly
                          ? designs.where((d) => d.isFavourite).toList()
                          : designs;
                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            _favouritesOnly
                                ? 'No favourites yet.'
                                : 'No designs yet — start creating!',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        );
                      }
                      // A Wrap of fixed-width cards rather than a fixed-crossAxisCount
                      // GridView: with fewer designs than `columns` (e.g. filtering down to 1
                      // favourite), a GridView still reserves the other columns as blank grid
                      // cells, making a sparse list look broken.
                      return RefreshIndicator(
                        onRefresh: () =>
                            ref.read(historyProvider.notifier).load(),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            const spacing = 14.0;
                            final cardWidth = (constraints.maxWidth -
                                    spacing * (columns - 1)) /
                                columns;
                            return SingleChildScrollView(
                              padding: const EdgeInsets.only(bottom: 100),
                              child: Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: filtered.asMap().entries.map((entry) {
                                  final design = entry.value;
                                  return SizedBox(
                                    width: cardWidth,
                                    height: cardWidth / 0.72,
                                    child: DesignHistoryCard(
                                      design: design,
                                      onTap: () => context.push('/result',
                                          extra: design),
                                      onToggleFavourite: () => ref
                                          .read(historyProvider.notifier)
                                          .toggleFavourite(design.id),
                                    ),
                                  )
                                      .animate(delay: (40 * entry.key).ms)
                                      .fadeIn(duration: 300.ms)
                                      .slideY(begin: 0.08, end: 0);
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
