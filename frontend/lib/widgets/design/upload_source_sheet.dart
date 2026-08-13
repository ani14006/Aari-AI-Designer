import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// What the user picked from the [showUploadSourceSheet] bottom sheet.
enum UploadSource { camera, gallery, file, color }

/// Bottom sheet offering Camera / Gallery (+ optional PDF file / manual colour) options.
/// Returns the chosen [UploadSource], or null if dismissed.
Future<UploadSource?> showUploadSourceSheet(
  BuildContext context, {
  bool allowFile = false,
  bool allowColor = false,
}) {
  return showModalBottomSheet<UploadSource>(
    context: context,
    backgroundColor: Theme.of(context).cardTheme.color,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(4)),
              ),
              _SheetOption(
                icon: Icons.photo_camera_rounded,
                label: 'Take Photo',
                onTap: () => Navigator.pop(context, UploadSource.camera),
              ),
              _SheetOption(
                icon: Icons.photo_library_rounded,
                label: 'Choose from Gallery',
                onTap: () => Navigator.pop(context, UploadSource.gallery),
              ),
              if (allowFile)
                _SheetOption(
                  icon: Icons.description_rounded,
                  label: 'Upload PNG / JPEG / PDF',
                  onTap: () => Navigator.pop(context, UploadSource.file),
                ),
              if (allowColor)
                _SheetOption(
                  icon: Icons.palette_rounded,
                  label: 'Choose Colour Manually',
                  onTap: () => Navigator.pop(context, UploadSource.color),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetOption(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.ink),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      onTap: onTap,
    );
  }
}
