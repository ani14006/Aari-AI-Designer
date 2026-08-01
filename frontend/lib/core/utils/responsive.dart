import '../constants/app_constants.dart';

/// Small shared helpers for switching layout by screen width (mobile / tablet / desktop).
class ResponsiveUtils {
  ResponsiveUtils._();

  static bool isTabletOrWider(double width) => width >= Breakpoints.tablet;
  static bool isDesktop(double width) => width >= Breakpoints.desktop;

  /// Horizontal page padding: 16 on mobile, 24 on tablet, 32 on desktop.
  static double horizontalPadding(double width) {
    if (width >= Breakpoints.desktop) return AppConstants.spaceXl;
    if (width >= Breakpoints.tablet) return AppConstants.spaceLg;
    return AppConstants.spaceMd;
  }

  /// Recent-designs grid column count for tablet/desktop widths.
  static int gridColumns(double width) {
    if (width >= Breakpoints.wideDesktop) return 4;
    if (width >= Breakpoints.desktop) return 3;
    return 2;
  }
}
