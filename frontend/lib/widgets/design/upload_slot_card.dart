import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../common/luxury_card.dart';

/// One upload slot on the Design screen (embroidery design / saree / blouse).
/// Shows a placeholder, a local preview (in-memory bytes), a remote preview URL, or a colour swatch.
class UploadSlotCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData placeholderIcon;
  final Uint8List? previewBytes;
  final String? previewUrl;
  final Color? colorSwatch;
  final bool isUploading;
  final VoidCallback onTap;

  const UploadSlotCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.placeholderIcon,
    required this.onTap,
    this.previewBytes,
    this.previewUrl,
    this.colorSwatch,
    this.isUploading = false,
  });

  bool get _hasContent =>
      previewBytes != null ||
      (previewUrl?.isNotEmpty ?? false) ||
      colorSwatch != null;

  @override
  Widget build(BuildContext context) {
    return LuxuryCard(
      onTap: isUploading ? null : onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildPreview(context),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  _hasContent ? 'Tap to change' : subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (isUploading)
            const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2))
          else
            Icon(
              _hasContent
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              color: _hasContent ? AppColors.success : AppColors.ink,
              size: 26,
            ),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    const size = 64.0;
    final radius = BorderRadius.circular(AppTheme.radiusMedium);

    if (colorSwatch != null) {
      return Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
            color: colorSwatch,
            borderRadius: radius,
            border: Border.all(color: AppColors.borderLight)),
      );
    }
    if (previewBytes != null) {
      return ClipRRect(
        borderRadius: radius,
        // errorBuilder covers non-image picks (e.g. a PDF design file) that can't be decoded
        // as a thumbnail — falls back to the placeholder rather than a raw error box.
        child: Image.memory(
          previewBytes!,
          height: size,
          width: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    if (previewUrl?.isNotEmpty ?? false) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          previewUrl!,
          height: size,
          width: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    const size = 64.0;
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: AppColors.champagne,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Icon(placeholderIcon, color: AppColors.ink, size: 26),
    );
  }
}
