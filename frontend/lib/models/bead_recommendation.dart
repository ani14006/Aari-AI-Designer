class BeadRecommendation {
  final String name;
  final String hexColor;
  final String reason;

  const BeadRecommendation({
    required this.name,
    required this.hexColor,
    required this.reason,
  });

  factory BeadRecommendation.fromJson(Map<String, dynamic> json) {
    return BeadRecommendation(
      name: json['name'] as String? ?? '',
      hexColor: json['hex_color'] as String? ?? '#C9A24B',
      reason: json['reason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'hex_color': hexColor,
        'reason': reason,
      };
}
