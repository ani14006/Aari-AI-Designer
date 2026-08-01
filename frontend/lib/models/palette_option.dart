import 'bead_recommendation.dart';

/// One of the 3 AI-generated bead-colour palettes, labeled by colour-theory scheme
/// (Complementary / Analogous / Triadic). Mirrors backend `PaletteOption` schema.
class PaletteOption {
  final String scheme;
  final String title;
  final String description;
  final List<BeadRecommendation> beadRecommendations;

  const PaletteOption({
    required this.scheme,
    required this.title,
    required this.description,
    required this.beadRecommendations,
  });

  factory PaletteOption.fromJson(Map<String, dynamic> json) {
    return PaletteOption(
      scheme: json['scheme'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      beadRecommendations: (json['bead_recommendations'] as List? ?? [])
          .map((e) => BeadRecommendation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'scheme': scheme,
        'title': title,
        'description': description,
        'bead_recommendations':
            beadRecommendations.map((b) => b.toJson()).toList(),
      };
}
