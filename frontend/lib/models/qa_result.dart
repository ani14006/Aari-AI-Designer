/// Gemini's soft-reviewer fidelity assessment of a generated visualization — how faithfully it
/// preserved the reference embroidery, not a general beauty/quality score. Read-only from the
/// backend's perspective. Mirrors backend `QAScoreBreakdown` schema.
class QaResult {
  final double patternSimilarity;
  final double colorSimilarity;
  final double beadPreservation;
  final double geometryPreservation;
  final double garmentPreservation;
  final double overallScore;
  final String notes;

  const QaResult({
    required this.patternSimilarity,
    required this.colorSimilarity,
    required this.beadPreservation,
    required this.geometryPreservation,
    required this.garmentPreservation,
    required this.overallScore,
    this.notes = '',
  });

  factory QaResult.fromJson(Map<String, dynamic> json) {
    return QaResult(
      patternSimilarity: (json['pattern_similarity'] as num?)?.toDouble() ?? 0,
      colorSimilarity: (json['color_similarity'] as num?)?.toDouble() ?? 0,
      beadPreservation: (json['bead_preservation'] as num?)?.toDouble() ?? 0,
      geometryPreservation:
          (json['geometry_preservation'] as num?)?.toDouble() ?? 0,
      garmentPreservation:
          (json['garment_preservation'] as num?)?.toDouble() ?? 0,
      overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }
}
