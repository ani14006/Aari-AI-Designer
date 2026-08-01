import 'bead_recommendation.dart';
import 'garment_metadata.dart';
import 'palette_option.dart';
import 'qa_result.dart';
import 'shopping_item.dart';

/// Mirrors the backend `DesignRead` schema — one generated Aari embroidery preview.
class DesignModel {
  final String id;
  final String ownerId;
  final String embroideryDesignUrl;
  final String sareeImageUrl;
  final String sareeColorHex;
  final String blouseImageUrl;
  final String blouseColorHex;
  final String detectedSareeColor;
  final String detectedBlouseColor;
  final String detectedDesignStyle;
  final List<BeadRecommendation> beadRecommendations;
  final List<PaletteOption> paletteOptions;
  final int selectedPaletteIndex;
  final String lookStyle;
  final String previewImageUrl;
  final List<ShoppingItem> shoppingList;
  final double estimatedCost;
  final String occasion;
  final String blouseSilhouette;
  final double bust;
  final double waist;
  final double shoulder;
  final double sleeveLength;
  final double backNeck;
  final double frontNeck;
  final String embroideryCoverage;
  final double budget;
  final String stylePreference;
  final bool isFavourite;
  final bool isSaved;

  /// Visualization pipeline fields — null for designs created via the older text-to-image
  /// /generation/preview flow, populated for designs created via /generation/visualize.
  final GarmentMetadata? garmentMetadata;
  final QaResult? qaResult;
  final int retryCount;

  final DateTime createdAt;
  final DateTime updatedAt;

  const DesignModel({
    required this.id,
    required this.ownerId,
    required this.embroideryDesignUrl,
    required this.sareeImageUrl,
    required this.sareeColorHex,
    required this.blouseImageUrl,
    required this.blouseColorHex,
    required this.detectedSareeColor,
    required this.detectedBlouseColor,
    required this.detectedDesignStyle,
    required this.beadRecommendations,
    required this.paletteOptions,
    required this.selectedPaletteIndex,
    required this.lookStyle,
    required this.previewImageUrl,
    required this.shoppingList,
    required this.estimatedCost,
    required this.occasion,
    required this.blouseSilhouette,
    required this.bust,
    required this.waist,
    required this.shoulder,
    required this.sleeveLength,
    required this.backNeck,
    required this.frontNeck,
    required this.embroideryCoverage,
    required this.budget,
    required this.stylePreference,
    required this.isFavourite,
    required this.isSaved,
    this.garmentMetadata,
    this.qaResult,
    this.retryCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DesignModel.fromJson(Map<String, dynamic> json) {
    return DesignModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String? ?? '',
      embroideryDesignUrl: json['embroidery_design_url'] as String? ?? '',
      sareeImageUrl: json['saree_image_url'] as String? ?? '',
      sareeColorHex: json['saree_color_hex'] as String? ?? '',
      blouseImageUrl: json['blouse_image_url'] as String? ?? '',
      blouseColorHex: json['blouse_color_hex'] as String? ?? '',
      detectedSareeColor: json['detected_saree_color'] as String? ?? '',
      detectedBlouseColor: json['detected_blouse_color'] as String? ?? '',
      detectedDesignStyle: json['detected_design_style'] as String? ?? '',
      beadRecommendations: (json['bead_recommendations'] as List? ?? [])
          .map((e) => BeadRecommendation.fromJson(e as Map<String, dynamic>))
          .toList(),
      paletteOptions: (json['palette_options'] as List? ?? [])
          .map((e) => PaletteOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      selectedPaletteIndex: json['selected_palette_index'] as int? ?? 0,
      lookStyle: json['look_style'] as String? ?? 'Luxury Look',
      previewImageUrl: json['preview_image_url'] as String? ?? '',
      shoppingList: (json['shopping_list'] as List? ?? [])
          .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble() ?? 0,
      occasion: json['occasion'] as String? ?? '',
      blouseSilhouette: json['blouse_silhouette'] as String? ?? '',
      bust: (json['bust'] as num?)?.toDouble() ?? 0,
      waist: (json['waist'] as num?)?.toDouble() ?? 0,
      shoulder: (json['shoulder'] as num?)?.toDouble() ?? 0,
      sleeveLength: (json['sleeve_length'] as num?)?.toDouble() ?? 0,
      backNeck: (json['back_neck'] as num?)?.toDouble() ?? 0,
      frontNeck: (json['front_neck'] as num?)?.toDouble() ?? 0,
      embroideryCoverage: json['embroidery_coverage'] as String? ?? '',
      budget: (json['budget'] as num?)?.toDouble() ?? 0,
      stylePreference: json['style_preference'] as String? ?? '',
      isFavourite: json['is_favourite'] as bool? ?? false,
      isSaved: json['is_saved'] as bool? ?? true,
      garmentMetadata: json['garment_metadata'] != null
          ? GarmentMetadata.fromJson(
              json['garment_metadata'] as Map<String, dynamic>)
          : null,
      qaResult: json['qa_result'] != null
          ? QaResult.fromJson(json['qa_result'] as Map<String, dynamic>)
          : null,
      retryCount: json['retry_count'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  DesignModel copyWith({bool? isFavourite, bool? isSaved, String? lookStyle}) {
    return DesignModel(
      id: id,
      ownerId: ownerId,
      embroideryDesignUrl: embroideryDesignUrl,
      sareeImageUrl: sareeImageUrl,
      sareeColorHex: sareeColorHex,
      blouseImageUrl: blouseImageUrl,
      blouseColorHex: blouseColorHex,
      detectedSareeColor: detectedSareeColor,
      detectedBlouseColor: detectedBlouseColor,
      detectedDesignStyle: detectedDesignStyle,
      beadRecommendations: beadRecommendations,
      paletteOptions: paletteOptions,
      selectedPaletteIndex: selectedPaletteIndex,
      lookStyle: lookStyle ?? this.lookStyle,
      previewImageUrl: previewImageUrl,
      shoppingList: shoppingList,
      estimatedCost: estimatedCost,
      occasion: occasion,
      blouseSilhouette: blouseSilhouette,
      bust: bust,
      waist: waist,
      shoulder: shoulder,
      sleeveLength: sleeveLength,
      backNeck: backNeck,
      frontNeck: frontNeck,
      embroideryCoverage: embroideryCoverage,
      budget: budget,
      stylePreference: stylePreference,
      isFavourite: isFavourite ?? this.isFavourite,
      isSaved: isSaved ?? this.isSaved,
      garmentMetadata: garmentMetadata,
      qaResult: qaResult,
      retryCount: retryCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
