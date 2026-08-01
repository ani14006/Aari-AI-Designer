import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class LuxuryNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const LuxuryNavItem(
      {required this.icon, required this.activeIcon, required this.label});
}

/// A floating, pill-shaped bottom navigation bar — replaces the flat Material default with a
/// softly-shadowed rounded surface and a gliding gold-gradient indicator behind the active tab.
class LuxuryBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LuxuryNavItem> items;

  const LuxuryBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      // Row (not Center/Align) so this only caps width — Center would expand to fill whatever
      // (loose but large) height Scaffold gives the bottomNavigationBar slot and vertically
      // centre the pill inside that whole space, making it appear to float mid-page.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight),
                boxShadow: AppTheme.softShadow(context, strength: 1.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == currentIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 4),
                        decoration: BoxDecoration(
                          gradient:
                              isSelected ? AppColors.roseGoldGradient : null,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: 22,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight),
                            ),
                            const SizedBox(height: 3),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 220),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                              ),
                              child: Text(item.label),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
