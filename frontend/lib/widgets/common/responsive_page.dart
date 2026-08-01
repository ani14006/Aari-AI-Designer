import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// Centres its child and caps its width on large screens (web desktop/laptop) while staying
/// full-width on phones/tablets — used by every screen so content never stretches edge-to-edge
/// on a wide browser window. On native mobile (Android/iOS) the device width is always below
/// the cap, so this is a no-op there and the layout is simply full-width as before.
class ResponsivePage extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsivePage({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
