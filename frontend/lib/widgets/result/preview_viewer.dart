import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// The large Result-screen preview: pinch-to-zoom + pan via [PhotoView], with a rotate control
/// and an optional side-by-side "compare with blouse photo" toggle.
class PreviewViewer extends StatefulWidget {
  final String previewImageUrl;
  final String? originalBlouseUrl;

  const PreviewViewer(
      {super.key, required this.previewImageUrl, this.originalBlouseUrl});

  @override
  State<PreviewViewer> createState() => _PreviewViewerState();
}

class _PreviewViewerState extends State<PreviewViewer> {
  int _quarterTurns = 0;
  bool _compareMode = false;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Container(
              color: AppColors.champagne,
              child: _compareMode && widget.originalBlouseUrl != null
                  ? Row(
                      children: [
                        Expanded(
                            child: _rotatedZoomable(widget.originalBlouseUrl!)),
                        Container(width: 2, color: AppColors.ivory),
                        Expanded(
                            child: _rotatedZoomable(widget.previewImageUrl)),
                      ],
                    )
                  : _rotatedZoomable(widget.previewImageUrl),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              children: [
                _ControlButton(
                  icon: Icons.rotate_90_degrees_ccw_rounded,
                  onTap: () =>
                      setState(() => _quarterTurns = (_quarterTurns + 1) % 4),
                ),
                const SizedBox(height: 10),
                if (widget.originalBlouseUrl != null)
                  _ControlButton(
                    icon: _compareMode
                        ? Icons.compare_arrows_rounded
                        : Icons.compare_rounded,
                    active: _compareMode,
                    onTap: () => setState(() => _compareMode = !_compareMode),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rotatedZoomable(String url) {
    return RotatedBox(
      quarterTurns: _quarterTurns,
      child: PhotoView(
        imageProvider: NetworkImage(url),
        backgroundDecoration: const BoxDecoration(color: Colors.transparent),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _ControlButton(
      {required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.ink : Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon,
              size: 20,
              color: active ? Colors.white : AppColors.textPrimaryLight),
        ),
      ),
    );
  }
}
