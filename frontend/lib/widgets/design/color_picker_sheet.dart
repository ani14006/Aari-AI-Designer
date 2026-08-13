import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../common/luxury_button.dart';

/// A curated saree/blouse fabric colour palette (kept broader than the bead palette).
const List<Color> _fabricPalette = [
  Color(0xFF9B111E), // Ruby Red
  Color(0xFF6B1E2E), // Deep Maroon
  Color(0xFFB08D3F), // Antique Gold
  Color(0xFF0F5132), // Emerald Green
  Color(0xFF1B3B6F), // Royal Blue
  Color(0xFF4B2E83), // Royal Purple
  Color(0xFFB76E79), // Rose Gold
  Color(0xFFF4F1EA), // Ivory
  Color(0xFF16130F), // Black
  Color(0xFFC0C0C8), // Silver
  Color(0xFFD98324), // Mustard
  Color(0xFF3F5D63), // Teal
];

/// Bottom sheet for manually picking a saree/blouse colour. Returns the chosen hex string.
Future<String?> showColorPickerSheet(BuildContext context,
    {required String title}) {
  Color selected = _fabricPalette.first;

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Theme.of(context).cardTheme.color,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: _fabricPalette.map((color) {
                      final isSelected =
                          color.toARGB32() == selected.toARGB32();
                      return GestureDetector(
                        onTap: () => setState(() => selected = color),
                        child: Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.ink
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected
                              ? Icon(Icons.check,
                                  color: _contrastColor(color), size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  LuxuryButton(
                    label: 'Use This Colour',
                    onPressed: () => Navigator.pop(context, _toHex(selected)),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Color _contrastColor(Color color) {
  final luminance = color.computeLuminance();
  return luminance > 0.5 ? Colors.black : Colors.white;
}

String _toHex(Color color) {
  return '#${color.toARGB32().toRadixString(16).substring(2)}';
}
