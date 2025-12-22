import '../services/api_config.dart';

class UserProfileData {
  final String id;
  final String username;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final String? bannerUrl;
  final UserStats stats;
  final UserStatus status;

  UserProfileData({
    required this.id,
    required this.username,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.bannerUrl,
    required this.stats,
    required this.status,
  });

  String? get fullAvatarUrl => ApiConfig.getFullUrl(avatarUrl);
  String? get fullBannerUrl => ApiConfig.getFullUrl(bannerUrl);

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      displayName: json['display_name'] ?? '',
      bio: json['bio'],
      avatarUrl: json['avatar_url'],
      bannerUrl: json['banner_url'],
      stats: UserStats.fromJson(json['stats'] ?? {}),
      status: UserStatus.fromJson(json['status'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'banner_url': bannerUrl,
      'stats': {
        'posts': stats.posts,
        'followers': stats.followers,
        'following': stats.following,
      },
      'status': {
        'is_me': status.isMe,
        'is_following': status.isFollowing,
        'is_saved_posts_public': status.isSavedPostsPublic,
      },
    };
  }
}

class UserStats {
  final int posts;
  final int followers;
  final int following;

  UserStats({
    required this.posts,
    required this.followers,
    required this.following,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      posts: json['posts'] ?? 0,
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
    );
  }
}

class UserStatus {
  final bool isMe;
  final bool isFollowing;
  final bool isSavedPostsPublic;

  UserStatus({
    required this.isMe,
    required this.isFollowing,
    required this.isSavedPostsPublic,
  });

  factory UserStatus.fromJson(Map<String, dynamic> json) {
    return UserStatus(
      isMe: json['is_me'] ?? false,
      isFollowing: json['is_following'] ?? false,
      isSavedPostsPublic: json['is_saved_posts_public'] ?? false,
    );
  }
}
