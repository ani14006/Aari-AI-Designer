import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A subtle, abstract embroidery-hoop-inspired decoration built from shapes only (no image
/// asset exists) — concentric thin-stroke rings plus a couple of stitch-like accent lines.
/// Shared by the Home banner and the Landing page hero.
class EmbroideryMotif extends StatelessWidget {
  final double size;
  final double opacity;

  const EmbroideryMotif({super.key, required this.size, this.opacity = 1});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: size,
        width: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _ring(size, AppColors.antiqueGold.withValues(alpha: 0.22)),
            _ring(size * 0.72, AppColors.gold.withValues(alpha: 0.3)),
            _ring(size * 0.46, AppColors.antiqueGold.withValues(alpha: 0.24)),
            Transform.rotate(
              angle: 0.78,
              child: Container(
                  height: 1.4,
                  width: size * 0.9,
                  color: AppColors.gold.withValues(alpha: 0.32)),
            ),
            Transform.rotate(
              angle: -0.78,
              child: Container(
                  height: 1.4,
                  width: size * 0.9,
                  color: AppColors.antiqueGold.withValues(alpha: 0.2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring(double diameter, Color color) {
    return Container(
      height: diameter,
      width: diameter,
      decoration: BoxDecoration(
          shape: BoxShape.circle, border: Border.all(color: color, width: 1.6)),
    );
  }
}
