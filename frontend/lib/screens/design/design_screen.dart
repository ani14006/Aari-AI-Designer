import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../services/upload_service.dart';
import '../../state/design_provider.dart';
import '../../widgets/common/luxury_button.dart';
import '../../widgets/common/responsive_page.dart';
import '../../widgets/design/color_picker_sheet.dart';
import '../../widgets/design/upload_slot_card.dart';
import '../../widgets/design/upload_source_sheet.dart';

/// Feature 1-4: upload embroidery design, saree, blouse, then run AI colour analysis + generation.
class DesignScreen extends ConsumerWidget {
  const DesignScreen({super.key});

  Future<void> _handleDesignUpload(BuildContext context, WidgetRef ref) async {
    final source = await showUploadSourceSheet(context, allowFile: true);
    if (source == null) return;
    final picker = UploadPickerService.instance;
    final asset = switch (source) {
      UploadSource.camera => await picker.pickFromCamera(),
      UploadSource.gallery => await picker.pickFromGallery(),
      UploadSource.file => await picker.pickDesignFile(),
      UploadSource.color => null,
    };
    if (asset == null) return;
    await ref.read(designFlowProvider.notifier).uploadEmbroideryDesign(asset);
  }

  Future<void> _handleSareeUpload(BuildContext context, WidgetRef ref) async {
    final source = await showUploadSourceSheet(context, allowColor: true);
    if (source == null || !context.mounted) return;
    if (source == UploadSource.color) {
      final hex =
          await showColorPickerSheet(context, title: 'Choose Saree Colour');
      if (hex != null) ref.read(designFlowProvider.notifier).setSareeColor(hex);
      return;
    }
    final picker = UploadPickerService.instance;
    final asset = source == UploadSource.camera
        ? await picker.pickFromCamera()
        : await picker.pickFromGallery();
    if (asset == null) return;
    await ref.read(designFlowProvider.notifier).uploadSareeImage(asset);
  }

  Future<void> _handleBlouseUpload(BuildContext context, WidgetRef ref) async {
    final source = await showUploadSourceSheet(context, allowColor: true);
    if (source == null || !context.mounted) return;
    if (source == UploadSource.color) {
      final hex =
          await showColorPickerSheet(context, title: 'Choose Blouse Colour');
      if (hex != null) {
        ref.read(designFlowProvider.notifier).setBlouseColor(hex);
      }
      return;
    }
    final picker = UploadPickerService.instance;
    final asset = source == UploadSource.camera
        ? await picker.pickFromCamera()
        : await picker.pickFromGallery();
    if (asset == null) return;
    await ref.read(designFlowProvider.notifier).uploadBlouseImage(asset);
  }

  void _handleNext(BuildContext context) {
    context.push('/order-details');
  }

  Color? _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(designFlowProvider);
    final width = MediaQuery.sizeOf(context).width;
    final hPad = ResponsiveUtils.horizontalPadding(width);

    return Scaffold(
      appBar: AppBar(title: const Text('Design Your Blouse')),
      body: SafeArea(
        child: ResponsivePage(
          maxWidth: Breakpoints.formMaxWidth,
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Upload Your Inspiration',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'We\'ll analyse the colours and generate a photorealistic preview.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                UploadSlotCard(
                  title: 'Embroidery Design',
                  subtitle: 'PNG, JPEG, PDF or take a photo',
                  placeholderIcon: Icons.brush_rounded,
                  previewBytes: state.embroideryPreviewBytes,
                  previewUrl: state.embroideryDesignUrl,
                  isUploading: state.isUploadingEmbroidery,
                  onTap: () => _handleDesignUpload(context, ref),
                ),
                const SizedBox(height: 14),
                UploadSlotCard(
                  title: 'Saree',
                  subtitle: 'Camera, gallery, or pick a colour',
                  placeholderIcon: Icons.checkroom_rounded,
                  previewBytes: state.sareePreviewBytes,
                  previewUrl: state.sareeImageUrl,
                  colorSwatch: _hexToColor(state.sareeColorHex),
                  isUploading: state.isUploadingSaree,
                  onTap: () => _handleSareeUpload(context, ref),
                ),
                const SizedBox(height: 14),
                UploadSlotCard(
                  title: 'Blouse',
                  subtitle: 'Camera, gallery, or pick a colour',
                  placeholderIcon: Icons.dry_cleaning_rounded,
                  previewBytes: state.blousePreviewBytes,
                  previewUrl: state.blouseImageUrl,
                  colorSwatch: _hexToColor(state.blouseColorHex),
                  isUploading: state.isUploadingBlouse,
                  onTap: () => _handleBlouseUpload(context, ref),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 14),
                  Text(state.error!,
                      style: const TextStyle(color: AppColors.error)),
                ],
                const Spacer(),
                LuxuryButton(
                  label: 'Next: Order Details',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: state.canGenerate && !state.isBusy
                      ? () => _handleNext(context)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
