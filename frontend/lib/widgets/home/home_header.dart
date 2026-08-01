import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

/// Compact top header for the Home screen: app name on the left, notification icon on the
/// right, with a subtle bottom border instead of a tall default toolbar/elevation.
class HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  const HomeHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : AppColors.homeBackground,
        border: Border(
            bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight)),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.horizontalPadding(width)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Aari AI Designer',
                      style: Theme.of(context).textTheme.headlineSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: () {},
                    tooltip: 'Notifications',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
