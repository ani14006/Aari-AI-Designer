import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../state/history_provider.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/recent_designs_section.dart';
import '../../widgets/home/start_designing_banner.dart';

/// Home screen: compact header, "Start Designing" banner, and the Recent Designs section.
/// Kept deliberately simple — no Templates/Quick Actions/etc. sections for now.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _goToDesign(BuildContext context) => context.push('/design');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = ResponsiveUtils.horizontalPadding(width);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? null : AppColors.homeBackground,
      appBar: const HomeHeader(),
      body: RefreshIndicator(
        onRefresh: () => ref.read(historyProvider.notifier).load(),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
            child: ListView(
              padding: EdgeInsets.fromLTRB(horizontalPadding,
                  AppConstants.spaceLg, horizontalPadding, 110),
              children: [
                StartDesigningBanner(
                    onStartDesigning: () => _goToDesign(context)),
                const SizedBox(height: AppConstants.spaceXl),
                RecentDesignsSection(
                  designsAsync: history,
                  onRetry: () => ref.read(historyProvider.notifier).load(),
                  onStartDesigning: () => _goToDesign(context),
                  onViewAll: () => context.push('/history'),
                  onOpenDesign: (design) =>
                      context.push('/result', extra: design),
                  onToggleFavourite: (design) => ref
                      .read(historyProvider.notifier)
                      .toggleFavourite(design.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
