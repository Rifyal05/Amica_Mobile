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
  });

  String? get fullImageUrl {
    return ApiConfig.getFullUrl(imageUrl);
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    List<String> parsedTags = [];
    if (json['tags'] != null) {
      parsedTags = List<String>.from(json['tags']);
    }

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
      tags: parsedTags,
      isLiked: json['is_liked'] ?? false,
      isSaved: json['is_saved'] ?? false,
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
    );
  }
}
