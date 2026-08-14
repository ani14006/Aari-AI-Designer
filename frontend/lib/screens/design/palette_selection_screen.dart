import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive.dart';
import '../../state/design_provider.dart';
import '../../widgets/common/buffer_screen.dart';
import '../../widgets/common/luxury_button.dart';
import '../../widgets/common/responsive_page.dart';
import '../../widgets/design/palette_option_card.dart';

const _previewRenderMessages = [
  'Draping the silk…',
  'Weaving the border…',
  'Catching the light…',
  'Nearly there…',
];

/// Shows the 3 AI-generated bead-colour palettes (Complementary / Analogous / Triadic) for the
/// user to pick from before the photorealistic preview is generated.
class PaletteSelectionScreen extends ConsumerWidget {
  const PaletteSelectionScreen({super.key});

  Future<void> _handleGenerate(BuildContext context, WidgetRef ref) async {
    final state = ref.read(designFlowProvider);

    // A real blouse photo lets the new reference-image-faithful pipeline run — the model
    // decides placement itself. A hex-colour-only blouse has no photo to edit, so it falls
    // back to the older text-to-image flow.
    if (state.hasBlousePhoto) {
      await ref.read(designFlowProvider.notifier).visualize();
    } else {
      await ref.read(designFlowProvider.notifier).generateWithSelectedPalette();
    }

    final updated = ref.read(designFlowProvider);
    if (updated.result != null && context.mounted) {
      context.push('/result', extra: updated.result);
    } else if (updated.error != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(updated.error!)));
    }
  }

  Widget _palettesList(
      BuildContext context, WidgetRef ref, DesignFlowState state) {
    return ListView.separated(
      itemCount: state.paletteOptions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) => PaletteOptionCard(
        palette: state.paletteOptions[index],
        isSelected: state.selectedPaletteIndex == index,
        onTap: () => ref.read(designFlowProvider.notifier).selectPalette(index),
      ),
    );
  }

  Widget _palettesRow(
      BuildContext context, WidgetRef ref, DesignFlowState state) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in state.paletteOptions.asMap().entries) ...[
            if (entry.key > 0) const SizedBox(width: 14),
            Expanded(
              child: PaletteOptionCard(
                palette: entry.value,
                isSelected: state.selectedPaletteIndex == entry.key,
                onTap: () => ref
                    .read(designFlowProvider.notifier)
                    .selectPalette(entry.key),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(designFlowProvider);
    if (state.isGenerating) {
      return const BufferScreen(
        messages: _previewRenderMessages,
        subcopy: 'Generating your photorealistic preview',
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final isWide = ResponsiveUtils.isTabletOrWider(width);
    final hPad = ResponsiveUtils.horizontalPadding(width);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose a Palette')),
      body: SafeArea(
        child: ResponsivePage(
          maxWidth:
              isWide ? Breakpoints.paletteMaxWidth : Breakpoints.formMaxWidth,
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('3 palettes, 3 colour theories',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Detected: ${state.detectedSareeColor} saree · ${state.detectedBlouseColor} blouse · ${state.detectedDesignStyle}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                isWide
                    ? _palettesRow(context, ref, state)
                    : Expanded(child: _palettesList(context, ref, state)),
                const SizedBox(height: 16),
                LuxuryButton(
                  label: 'Generate Preview',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: () => _handleGenerate(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
