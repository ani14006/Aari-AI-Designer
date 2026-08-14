import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';
import '../models/bead_recommendation.dart';
import '../models/design_model.dart';
import '../models/order_details.dart';
import '../models/palette_option.dart';
import '../services/api_service.dart';
import '../services/upload_service.dart';

/// Immutable snapshot of the in-progress "create a design" flow (Design screen -> Result screen).
class DesignFlowState {
  final String? embroideryDesignUrl;
  final Uint8List? embroideryPreviewBytes;

  final String? sareeImageUrl;
  final Uint8List? sareePreviewBytes;
  final String? sareeColorHex;

  final String? blouseImageUrl;
  final Uint8List? blousePreviewBytes;
  final String? blouseColorHex;

  final bool isUploadingEmbroidery;
  final bool isUploadingSaree;
  final bool isUploadingBlouse;
  final bool isAnalyzing;
  final bool isGenerating;
  final String? error;

  final String detectedSareeColor;
  final String detectedBlouseColor;
  final String detectedDesignStyle;
  final List<BeadRecommendation> beadRecommendations;

  final OrderDetails orderDetails;
  final List<PaletteOption> paletteOptions;
  final int selectedPaletteIndex;

  final String lookStyle;
  final DesignModel? result;

  const DesignFlowState({
    this.embroideryDesignUrl,
    this.embroideryPreviewBytes,
    this.sareeImageUrl,
    this.sareePreviewBytes,
    this.sareeColorHex,
    this.blouseImageUrl,
    this.blousePreviewBytes,
    this.blouseColorHex,
    this.isUploadingEmbroidery = false,
    this.isUploadingSaree = false,
    this.isUploadingBlouse = false,
    this.isAnalyzing = false,
    this.isGenerating = false,
    this.error,
    this.detectedSareeColor = '',
    this.detectedBlouseColor = '',
    this.detectedDesignStyle = '',
    this.beadRecommendations = const [],
    this.orderDetails = const OrderDetails(),
    this.paletteOptions = const [],
    this.selectedPaletteIndex = 0,
    this.lookStyle = LookStyles.luxury,
    this.result,
  });

  bool get canGenerate =>
      embroideryDesignUrl != null &&
      (sareeImageUrl != null || sareeColorHex != null) &&
      (blouseImageUrl != null || blouseColorHex != null);

  /// Whether a real blouse photo was uploaded — the new visualization pipeline needs an actual
  /// image to edit, unlike the old text-to-image flow, so a hex-colour-only blouse can't use it.
  bool get hasBlousePhoto =>
      blouseImageUrl != null && blouseImageUrl!.isNotEmpty;

  /// Gates the visualize button: needs everything canGenerate needs, plus a real blouse photo
  /// for the edit pipeline to work with. Placement, scale and orientation are decided by the
  /// model itself — no manual placement step.
  bool get canVisualize => canGenerate && hasBlousePhoto;

  bool get isUploading =>
      isUploadingEmbroidery || isUploadingSaree || isUploadingBlouse;

  bool get isBusy => isUploading || isAnalyzing || isGenerating;

  PaletteOption? get selectedPalette => paletteOptions.isEmpty
      ? null
      : paletteOptions[
          selectedPaletteIndex.clamp(0, paletteOptions.length - 1)];

  DesignFlowState copyWith({
    String? embroideryDesignUrl,
    Uint8List? embroideryPreviewBytes,
    String? sareeImageUrl,
    Uint8List? sareePreviewBytes,
    String? sareeColorHex,
    String? blouseImageUrl,
    Uint8List? blousePreviewBytes,
    String? blouseColorHex,
    bool? isUploadingEmbroidery,
    bool? isUploadingSaree,
    bool? isUploadingBlouse,
    bool? isAnalyzing,
    bool? isGenerating,
    String? error,
    bool clearError = false,
    String? detectedSareeColor,
    String? detectedBlouseColor,
    String? detectedDesignStyle,
    List<BeadRecommendation>? beadRecommendations,
    OrderDetails? orderDetails,
    List<PaletteOption>? paletteOptions,
    int? selectedPaletteIndex,
    String? lookStyle,
    DesignModel? result,
  }) {
    return DesignFlowState(
      embroideryDesignUrl: embroideryDesignUrl ?? this.embroideryDesignUrl,
      embroideryPreviewBytes:
          embroideryPreviewBytes ?? this.embroideryPreviewBytes,
      sareeImageUrl: sareeImageUrl ?? this.sareeImageUrl,
      sareePreviewBytes: sareePreviewBytes ?? this.sareePreviewBytes,
      sareeColorHex: sareeColorHex ?? this.sareeColorHex,
      blouseImageUrl: blouseImageUrl ?? this.blouseImageUrl,
      blousePreviewBytes: blousePreviewBytes ?? this.blousePreviewBytes,
      blouseColorHex: blouseColorHex ?? this.blouseColorHex,
      isUploadingEmbroidery:
          isUploadingEmbroidery ?? this.isUploadingEmbroidery,
      isUploadingSaree: isUploadingSaree ?? this.isUploadingSaree,
      isUploadingBlouse: isUploadingBlouse ?? this.isUploadingBlouse,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isGenerating: isGenerating ?? this.isGenerating,
      error: clearError ? null : (error ?? this.error),
      detectedSareeColor: detectedSareeColor ?? this.detectedSareeColor,
      detectedBlouseColor: detectedBlouseColor ?? this.detectedBlouseColor,
      detectedDesignStyle: detectedDesignStyle ?? this.detectedDesignStyle,
      beadRecommendations: beadRecommendations ?? this.beadRecommendations,
      orderDetails: orderDetails ?? this.orderDetails,
      paletteOptions: paletteOptions ?? this.paletteOptions,
      selectedPaletteIndex: selectedPaletteIndex ?? this.selectedPaletteIndex,
      lookStyle: lookStyle ?? this.lookStyle,
      result: result ?? this.result,
    );
  }
}

class DesignFlowController extends StateNotifier<DesignFlowState> {
  DesignFlowController() : super(const DesignFlowState());

  final _api = ApiService.instance;

  Future<void> uploadEmbroideryDesign(PickedAsset asset) async {
    state = state.copyWith(
        isUploadingEmbroidery: true,
        clearError: true,
        embroideryPreviewBytes: asset.bytes);
    try {
      final result =
          await _api.uploadImage(asset.bytes, asset.fileName, 'designs');
      state = state.copyWith(
          isUploadingEmbroidery: false, embroideryDesignUrl: result.url);
    } catch (e) {
      state = state.copyWith(isUploadingEmbroidery: false, error: readableApiError(e));
    }
  }

  Future<void> uploadSareeImage(PickedAsset asset) async {
    state = state.copyWith(
      isUploadingSaree: true,
      clearError: true,
      sareePreviewBytes: asset.bytes,
      sareeColorHex: '',
    );
    try {
      final result =
          await _api.uploadImage(asset.bytes, asset.fileName, 'sarees');
      state =
          state.copyWith(isUploadingSaree: false, sareeImageUrl: result.url);
    } catch (e) {
      state = state.copyWith(isUploadingSaree: false, error: readableApiError(e));
    }
  }

  void setSareeColor(String hex) {
    state = state.copyWith(
        sareeColorHex: hex,
        sareeImageUrl: '',
        sareePreviewBytes: null,
        clearError: true);
  }

  Future<void> uploadBlouseImage(PickedAsset asset) async {
    state = state.copyWith(
      isUploadingBlouse: true,
      clearError: true,
      blousePreviewBytes: asset.bytes,
      blouseColorHex: '',
    );
    try {
      final result =
          await _api.uploadImage(asset.bytes, asset.fileName, 'blouses');
      state =
          state.copyWith(isUploadingBlouse: false, blouseImageUrl: result.url);
    } catch (e) {
      state = state.copyWith(isUploadingBlouse: false, error: readableApiError(e));
    }
  }

  void setBlouseColor(String hex) {
    state = state.copyWith(
        blouseColorHex: hex,
        blouseImageUrl: '',
        blousePreviewBytes: null,
        clearError: true);
  }

  void setLookStyle(String style) {
    state = state.copyWith(lookStyle: style);
  }

  void setOrderDetails(OrderDetails details) {
    state = state.copyWith(orderDetails: details);
  }

  void selectPalette(int index) {
    state = state.copyWith(selectedPaletteIndex: index);
  }

  /// Step 1: runs AI colour analysis and returns 3 labeled palette options for the user to pick from.
  Future<void> runAnalysis() async {
    if (!state.canGenerate) return;
    state = state.copyWith(isAnalyzing: true, clearError: true);
    try {
      final analysis = await _api.analyzeColors(
        sareeImageUrl: state.sareeImageUrl,
        sareeColorHex: state.sareeColorHex,
        blouseImageUrl: state.blouseImageUrl,
        blouseColorHex: state.blouseColorHex,
        embroideryDesignUrl: state.embroideryDesignUrl,
        orderDetails: state.orderDetails,
      );
      state = state.copyWith(
        isAnalyzing: false,
        detectedSareeColor: analysis['detected_saree_color'] as String,
        detectedBlouseColor: analysis['detected_blouse_color'] as String,
        detectedDesignStyle: analysis['detected_design_style'] as String,
        paletteOptions: analysis['palette_options'] as List<PaletteOption>,
        selectedPaletteIndex: 0,
      );
    } catch (e) {
      state = state.copyWith(isAnalyzing: false, error: readableApiError(e));
    }
  }

  /// Step 2: generates the photorealistic preview + shopping list using the user-selected palette.
  Future<void> generateWithSelectedPalette() async {
    final palette = state.selectedPalette;
    if (palette == null) return;
    state = state.copyWith(
        isGenerating: true,
        clearError: true,
        beadRecommendations: palette.beadRecommendations);
    try {
      final design = await _api.generatePreview(
        embroideryDesignUrl: state.embroideryDesignUrl!,
        sareeImageUrl: state.sareeImageUrl,
        sareeColorHex: state.sareeColorHex,
        blouseImageUrl: state.blouseImageUrl,
        blouseColorHex: state.blouseColorHex,
        detectedSareeColor: state.detectedSareeColor,
        detectedBlouseColor: state.detectedBlouseColor,
        detectedDesignStyle: state.detectedDesignStyle,
        beadRecommendations: palette.beadRecommendations,
        paletteOptions: state.paletteOptions,
        selectedPaletteIndex: state.selectedPaletteIndex,
        lookStyle: state.lookStyle,
        orderDetails: state.orderDetails,
      );
      state = state.copyWith(isGenerating: false, result: design);
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: readableApiError(e));
    }
  }

  /// Generates the photorealistic visualization via the reference-image-faithful edit
  /// pipeline: requires an actual blouse photo (see [canVisualize]). The model decides
  /// placement, scale and orientation itself — no manual placement step. The old
  /// [generateWithSelectedPalette] remains the fallback for hex-colour-only blouses, which have
  /// no real photo for the edit pipeline to work with.
  Future<void> visualize() async {
    final palette = state.selectedPalette;
    if (!state.canVisualize) return;
    state = state.copyWith(
      isGenerating: true,
      clearError: true,
      beadRecommendations:
          palette?.beadRecommendations ?? state.beadRecommendations,
    );
    try {
      final design = await _api.visualize(
        embroideryDesignUrl: state.embroideryDesignUrl!,
        blouseImageUrl: state.blouseImageUrl!,
        sareeImageUrl: state.sareeImageUrl,
        sareeColorHex: state.sareeColorHex,
        lookStyle: state.lookStyle,
        orderDetails: state.orderDetails,
        beadRecommendations:
            palette?.beadRecommendations ?? state.beadRecommendations,
        paletteOptions: state.paletteOptions,
        selectedPaletteIndex: state.selectedPaletteIndex,
      );
      state = state.copyWith(isGenerating: false, result: design);
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: readableApiError(e));
    }
  }

  /// Regenerates the current result in a new look style (Luxury / Bridal / etc.).
  Future<void> regenerate(String lookStyle) async {
    final currentResult = state.result;
    if (currentResult == null) return;
    state = state.copyWith(
        isGenerating: true, clearError: true, lookStyle: lookStyle);
    try {
      final design = await _api.regenerate(currentResult.id, lookStyle);
      state = state.copyWith(isGenerating: false, result: design);
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: readableApiError(e));
    }
  }

  void reset() {
    state = const DesignFlowState();
  }
}

final designFlowProvider =
    StateNotifierProvider.autoDispose<DesignFlowController, DesignFlowState>(
        (ref) {
  return DesignFlowController();
});
