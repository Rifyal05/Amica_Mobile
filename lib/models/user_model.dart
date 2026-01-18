import '../services/api_config.dart';

class User {
  final String id;
  final String username;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? bio;
  final String role;
  final String? authProvider;
  final bool isFollowing;
  final bool hasPin;
  final bool isVerified;
  final Map<String, dynamic>? stats;
  bool isAiModerationEnabled;

  User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.bannerUrl,
    this.bio,
    required this.role,
    this.authProvider,
    this.isFollowing = false,
    this.hasPin = false,
    this.isVerified = false,
    this.stats,
    this.isAiModerationEnabled = false,
  });

  String? get fullAvatarUrl => ApiConfig.getFullUrl(avatarUrl);
  String? get fullBannerUrl => ApiConfig.getFullUrl(bannerUrl);

  User copyWith({
    String? id,
    String? username,
    String? displayName,
    String? email,
    String? avatarUrl,
    String? bannerUrl,
    String? bio,
    String? role,
    String? authProvider,
    bool? isFollowing,
    bool? hasPin,
    bool? isVerified,
    Map<String, dynamic>? stats,
    bool? isAiModerationEnabled,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      authProvider: authProvider ?? this.authProvider,
      isFollowing: isFollowing ?? this.isFollowing,
      hasPin: hasPin ?? this.hasPin,
      isVerified: isVerified ?? this.isVerified,
      stats: stats ?? this.stats,
      isAiModerationEnabled:
          isAiModerationEnabled ?? this.isAiModerationEnabled,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      displayName: json['display_name'] ?? json['username'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'],
      bannerUrl: json['banner_url'],
      bio: json['bio'],
      role: json['role'] ?? 'user',
      authProvider: json['auth_provider'],
      isFollowing:
          json['is_following'] ?? json['status']?['is_following'] ?? false,
      hasPin: json['has_pin'] ?? false,
      isVerified: json['is_verified'] ?? false,
      stats: json['stats'],
      isAiModerationEnabled: json['is_ai_moderation_enabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'email': email,
      'avatar_url': avatarUrl,
      'banner_url': bannerUrl,
      'bio': bio,
      'role': role,
      'auth_provider': authProvider,
      'is_following': isFollowing,
      'has_pin': hasPin,
      'is_verified': isVerified,
      'stats': stats,
      'is_ai_moderation_enabled': isAiModerationEnabled,
    };
  }
}
