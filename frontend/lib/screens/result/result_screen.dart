import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/design_model.dart';
import '../../services/api_service.dart';
import '../../services/gallery_download/gallery_download.dart';
import '../../widgets/common/luxury_button.dart';
import '../../widgets/common/responsive_page.dart';
import '../../widgets/result/bead_color_chip.dart';
import '../../widgets/result/look_style_selector.dart';
import '../../widgets/result/preview_viewer.dart';
import '../../widgets/result/shopping_list_tile.dart';

/// Feature 5-9: photorealistic preview, bead recommendations, shopping list, regenerate,
/// download / share / buy materials / save+favourite.
class ResultScreen extends ConsumerStatefulWidget {
  final DesignModel design;

  const ResultScreen({super.key, required this.design});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  late DesignModel _design;
  bool _isRegenerating = false;
  bool _isBuyingMaterials = false;
  bool _isDownloading = false;
  bool _isSharingWhatsapp = false;

  final _api = ApiService.instance;

  @override
  void initState() {
    super.initState();
    _design = widget.design;
  }

  Future<void> _regenerate(String lookStyle) async {
    setState(() => _isRegenerating = true);
    try {
      final updated = await _api.regenerate(_design.id, lookStyle);
      setState(() => _design = updated);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isRegenerating = false);
    }
  }

  Future<void> _toggleFavourite() async {
    try {
      final updated = await _api.updateDesign(_design.id,
          isFavourite: !_design.isFavourite);
      setState(() => _design = updated);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _buyMaterials() async {
    setState(() => _isBuyingMaterials = true);
    try {
      final launched = await launchUrl(
        Uri.parse(AppConstants.materialsShopUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the shop.')),
        );
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isBuyingMaterials = false);
    }
  }

  Future<Uint8List> _downloadPreviewBytes() async {
    final response = await Dio().get<List<int>>(
      _design.previewImageUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }

  Future<void> _download() async {
    setState(() => _isDownloading = true);
    try {
      final bytes = await _downloadPreviewBytes();
      await saveImageBytes(bytes, 'aari_design_${_design.id}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                kIsWeb ? 'Downloaded.' : 'Saved to your gallery.')));
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _share() async {
    try {
      await Share.share(
        'Check out my Aari embroidery design! ${_design.previewImageUrl}',
        subject: 'My Aari AI Designer preview',
      );
    } catch (e) {
      _showError(e);
    }
  }

  /// WhatsApp's `wa.me` deep link can only pre-fill text, never attach an image — sharing the
  /// actual preview PNG requires handing it to WhatsApp through the platform's native share
  /// sheet instead (the same mechanism apps use to share to any target app), with the design
  /// details as the accompanying caption. On mobile, that share sheet lists WhatsApp directly
  /// and attaches the image automatically.
  ///
  /// On web there's no such share sheet — browsers only expose the image to WhatsApp via the
  /// Web Share API (`navigator.share`), which desktop Chrome/macOS doesn't reliably support for
  /// files, and which silently falls back to just downloading the file if unsupported. Rather
  /// than leave that ambiguous, web explicitly downloads the image and opens the WhatsApp chat
  /// with the caption pre-filled, telling the user to attach the just-downloaded file — the
  /// closest deterministic equivalent achievable from a browser.
  Future<void> _shareViaWhatsapp() async {
    setState(() => _isSharingWhatsapp = true);
    try {
      final message = await _api.getWhatsappMessage(_design.id);
      final bytes = await _downloadPreviewBytes();

      if (kIsWeb) {
        await saveImageBytes(bytes, 'aari_design_${_design.id}');
        final uri =
            Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Image downloaded — attach it in the WhatsApp chat that just opened.'),
            duration: Duration(seconds: 5),
          ));
        }
        return;
      }

      final file = XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: 'aari_design_${_design.id}.png',
      );
      await Share.shareXFiles([file], text: message);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isSharingWhatsapp = false);
    }
  }

  void _showError(Object e) {
    final message = e is ApiException ? e.message : e.toString();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Design'),
        actions: [
          IconButton(
            icon: Icon(
              _design.isFavourite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: AppColors.ink,
            ),
            onPressed: _toggleFavourite,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsivePage(
          maxWidth: Breakpoints.resultMaxWidth,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.horizontalPadding(
                  MediaQuery.sizeOf(context).width),
              20,
              ResponsiveUtils.horizontalPadding(
                  MediaQuery.sizeOf(context).width),
              20,
            ),
            children: [
              Opacity(
                opacity: _isRegenerating ? 0.5 : 1,
                child: PreviewViewer(
                  previewImageUrl: _design.previewImageUrl,
                  originalBlouseUrl: _design.blouseImageUrl.isNotEmpty
                      ? _design.blouseImageUrl
                      : null,
                ),
              )
                  .animate(key: ValueKey(_design.previewImageUrl))
                  .fadeIn(duration: 450.ms, curve: Curves.easeOut)
                  .scale(
                      begin: const Offset(0.97, 0.97), curve: Curves.easeOut),
              if (_isRegenerating)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(color: AppColors.ink),
                ),
              if (_design.qaResult != null) ...[
                const SizedBox(height: 10),
                _FidelityBadge(score: _design.qaResult!.overallScore),
              ],
              const SizedBox(height: 20),
              Text('Regenerate',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              LookStyleSelector(
                selected: _design.lookStyle,
                isBusy: _isRegenerating,
                onSelected: _regenerate,
              ),
              const SizedBox(height: 28),
              Text('Recommended Bead Colours',
                  style: Theme.of(context).textTheme.titleMedium),
              if (_design.paletteOptions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Builder(builder: (context) {
                  final palette = _design.paletteOptions[_design
                      .selectedPaletteIndex
                      .clamp(0, _design.paletteOptions.length - 1)];
                  return Text(
                    '${palette.scheme} harmony · ${palette.title}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.ink),
                  );
                }),
              ],
              const SizedBox(height: 10),
              ...(_design.beadRecommendations.asMap().entries.map((entry) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: BeadColorChip(bead: entry.value),
                  )
                      .animate(delay: (80 * entry.key).ms)
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.06, end: 0, curve: Curves.easeOut))),
              const SizedBox(height: 18),
              Text('Material List',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              ...(_design.shoppingList.asMap().entries.map(
                    (entry) => ShoppingListTile(item: entry.value)
                        .animate(delay: (50 * entry.key).ms)
                        .fadeIn(duration: 250.ms),
                  )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Estimated Cost',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    formatCurrency(_design.estimatedCost),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: _design.budget > 0 &&
                                  _design.estimatedCost > _design.budget
                              ? AppColors.error
                              : AppColors.ink,
                        ),
                  ),
                ],
              ),
              if (_design.budget > 0) ...[
                const SizedBox(height: 4),
                Text(
                  _design.estimatedCost > _design.budget
                      ? 'Over your ${formatCurrency(_design.budget)} budget'
                      : 'Within your ${formatCurrency(_design.budget)} budget',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _design.estimatedCost > _design.budget
                            ? AppColors.error
                            : AppColors.success,
                      ),
                ),
              ],
              const SizedBox(height: 28),
              LuxuryButton(
                label: 'Buy Materials',
                icon: Icons.shopping_bag_rounded,
                isLoading: _isBuyingMaterials,
                onPressed: _buyMaterials,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LuxuryButton(
                      label: 'Download',
                      icon: Icons.download_rounded,
                      variant: LuxuryButtonVariant.outline,
                      isLoading: _isDownloading,
                      onPressed: _download,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LuxuryButton(
                      label: 'Share',
                      icon: Icons.share_rounded,
                      variant: LuxuryButtonVariant.outline,
                      onPressed: _share,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LuxuryButton(
                label: 'Share via WhatsApp',
                icon: Icons.chat_rounded,
                variant: LuxuryButtonVariant.outline,
                isLoading: _isSharingWhatsapp,
                onPressed: _shareViaWhatsapp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small badge surfacing Gemini's soft fidelity review of how closely the generated preview
/// preserved the reference embroidery — not a general beauty score.
class _FidelityBadge extends StatelessWidget {
  final double score;

  const _FidelityBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 70
        ? AppColors.success
        : (score >= 50 ? AppColors.warning : AppColors.error);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              'Design fidelity: ${score.round()}%',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
