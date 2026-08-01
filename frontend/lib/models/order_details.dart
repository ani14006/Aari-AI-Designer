/// Order-details captured before AI analysis/generation: occasion, fit, measurements, coverage,
/// budget. Mirrors backend `OrderDetails` schema — every field optional.
class OrderDetails {
  final String? occasion;
  final String? blouseSilhouette;
  final double? bust;
  final double? waist;
  final double? shoulder;
  final double? sleeveLength;
  final double? backNeck;
  final double? frontNeck;
  final String? embroideryCoverage;
  final double? budget;
  final String? stylePreference;

  const OrderDetails({
    this.occasion,
    this.blouseSilhouette,
    this.bust,
    this.waist,
    this.shoulder,
    this.sleeveLength,
    this.backNeck,
    this.frontNeck,
    this.embroideryCoverage,
    this.budget,
    this.stylePreference,
  });

  bool get isEmpty =>
      occasion == null &&
      blouseSilhouette == null &&
      bust == null &&
      waist == null &&
      shoulder == null &&
      sleeveLength == null &&
      backNeck == null &&
      frontNeck == null &&
      embroideryCoverage == null &&
      budget == null &&
      (stylePreference == null || stylePreference!.isEmpty);

  OrderDetails copyWith({
    String? occasion,
    String? blouseSilhouette,
    double? bust,
    double? waist,
    double? shoulder,
    double? sleeveLength,
    double? backNeck,
    double? frontNeck,
    String? embroideryCoverage,
    double? budget,
    String? stylePreference,
  }) {
    return OrderDetails(
      occasion: occasion ?? this.occasion,
      blouseSilhouette: blouseSilhouette ?? this.blouseSilhouette,
      bust: bust ?? this.bust,
      waist: waist ?? this.waist,
      shoulder: shoulder ?? this.shoulder,
      sleeveLength: sleeveLength ?? this.sleeveLength,
      backNeck: backNeck ?? this.backNeck,
      frontNeck: frontNeck ?? this.frontNeck,
      embroideryCoverage: embroideryCoverage ?? this.embroideryCoverage,
      budget: budget ?? this.budget,
      stylePreference: stylePreference ?? this.stylePreference,
    );
  }

  Map<String, dynamic> toJson() => {
        'occasion': occasion,
        'blouse_silhouette': blouseSilhouette,
        'bust': bust,
        'waist': waist,
        'shoulder': shoulder,
        'sleeve_length': sleeveLength,
        'back_neck': backNeck,
        'front_neck': frontNeck,
        'embroidery_coverage': embroideryCoverage,
        'budget': budget,
        'style_preference': stylePreference,
      };
}
