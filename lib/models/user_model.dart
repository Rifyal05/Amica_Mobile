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
  final bool hasPin; // Tambahan properti baru

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
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      displayName: json['display_name'] ?? json['username'],
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'],
      bannerUrl: json['banner_url'],
      bio: json['bio'],
      role: json['role'] ?? 'user',
      authProvider: json['auth_provider'],
      isFollowing:
          json['is_following'] ?? json['status']?['is_following'] ?? false,
      hasPin: json['has_pin'] ?? false,
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
    };
  }
}
