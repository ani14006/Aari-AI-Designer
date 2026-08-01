/// Gemini's garment-only analysis of the blouse, used by the visualization pipeline.
/// Read-only from the backend's perspective — the app never constructs or sends this.
/// Mirrors backend `GarmentAnalysis` schema.
class GarmentMetadata {
  final String fabricType;
  final String neckline;
  final String sleeveType;
  final String blouseColor;
  final String sareeColor;
  final String lighting;
  final String cameraAngle;
  final String foldAndDrapeNotes;

  const GarmentMetadata({
    required this.fabricType,
    required this.neckline,
    required this.sleeveType,
    required this.blouseColor,
    required this.sareeColor,
    required this.lighting,
    required this.cameraAngle,
    required this.foldAndDrapeNotes,
  });

  factory GarmentMetadata.fromJson(Map<String, dynamic> json) {
    return GarmentMetadata(
      fabricType: json['fabric_type'] as String? ?? '',
      neckline: json['neckline'] as String? ?? '',
      sleeveType: json['sleeve_type'] as String? ?? '',
      blouseColor: json['blouse_color'] as String? ?? '',
      sareeColor: json['saree_color'] as String? ?? '',
      lighting: json['lighting'] as String? ?? '',
      cameraAngle: json['camera_angle'] as String? ?? '',
      foldAndDrapeNotes: json['fold_and_drape_notes'] as String? ?? '',
    );
  }
}
