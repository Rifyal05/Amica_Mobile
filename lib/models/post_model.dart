import '../services/api_config.dart';
import 'user_model.dart';

class Post {
  final String id;
  final User author;
  final String caption;
  final String? imageUrl;
  final DateTime timestamp;
  final int likesCount;
  final int commentsCount;
  final List<String> tags;
  final bool isLiked;
  final bool isSaved;
  final String moderationStatus;
  final Map<String, dynamic>? moderationDetails;
  final DateTime? expiresAt;
  final String? appealStatus;
  final String? adminNote;

  Post({
    required this.id,
    required this.author,
    required this.caption,
    this.imageUrl,
    required this.timestamp,
    required this.likesCount,
    required this.commentsCount,
    required this.tags,
    required this.isLiked,
    this.isSaved = false,
    this.moderationStatus = 'approved',
    this.moderationDetails,
    this.expiresAt,
    this.appealStatus,
    this.adminNote,
  });

  String? get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    if (imageUrl!.startsWith('http')) return imageUrl;

    String cleanPath = imageUrl!.startsWith('/')
        ? imageUrl!.substring(1)
        : imageUrl!;

    return '${ApiConfig.baseUrl}/$cleanPath';
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? '',
      author: User.fromJson(json['author'] ?? {}),
      caption: json['caption'] ?? '',
      imageUrl: json['image_url'],
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      isLiked: json['is_liked'] ?? false,
      isSaved: json['is_saved'] ?? false,
      moderationStatus: json['status'] ?? 'approved',
      moderationDetails: json['moderation_details'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at']).toLocal()
          : null,
      appealStatus: json['appeal_status'],
      adminNote: json['admin_note'],
    );
  }

  Post copyWith({
    String? id,
    User? author,
    String? caption,
    String? imageUrl,
    DateTime? timestamp,
    int? likesCount,
    int? commentsCount,
    List<String>? tags,
    bool? isLiked,
    bool? isSaved,
    String? moderationStatus,
    Map<String, dynamic>? moderationDetails,
    DateTime? expiresAt,
    String? appealStatus,
    String? adminNote,
  }) {
    return Post(
      id: id ?? this.id,
      author: author ?? this.author,
      caption: caption ?? this.caption,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      tags: tags ?? this.tags,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      moderationDetails: moderationDetails ?? this.moderationDetails,
      expiresAt: expiresAt ?? this.expiresAt,
      appealStatus: appealStatus ?? this.appealStatus,
      adminNote: adminNote ?? this.adminNote,
    );
  }
}
