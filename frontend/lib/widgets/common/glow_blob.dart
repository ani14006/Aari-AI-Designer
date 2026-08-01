import 'dart:ui';

import 'package:flutter/material.dart';

/// A soft, heavily-blurred colour blob used to add atmosphere/depth behind hero content —
/// purely decorative, ignores pointer events.
class GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const GlowBlob({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: size * 0.35, sigmaY: size * 0.35),
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
