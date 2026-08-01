class UserModel {
  final String id;
  final String supabaseUid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String language;
  final bool darkMode;
  final bool notificationsEnabled;

  const UserModel({
    required this.id,
    required this.supabaseUid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.language,
    required this.darkMode,
    required this.notificationsEnabled,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      supabaseUid: json['supabase_uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      photoUrl: json['photo_url'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      darkMode: json['dark_mode'] as bool? ?? false,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
    );
  }

  UserModel copyWith(
      {String? displayName,
      String? language,
      bool? darkMode,
      bool? notificationsEnabled}) {
    return UserModel(
      id: id,
      supabaseUid: supabaseUid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl,
      language: language ?? this.language,
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
