class UploadResult {
  final String url;
  final String publicId;

  const UploadResult({required this.url, required this.publicId});

  factory UploadResult.fromJson(Map<String, dynamic> json) {
    return UploadResult(
      url: json['url'] as String,
      publicId: json['public_id'] as String? ?? '',
    );
  }
}
