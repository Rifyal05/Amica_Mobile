import 'user_model.dart';

class Comment {
  final String id;
  final User user;
  final String text;
  final DateTime timestamp;
  final String? parentId;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.user,
    required this.text,
    required this.timestamp,
    this.parentId,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    var list = json['replies'] as List? ?? [];
    List<Comment> repliesList = list.map((i) => Comment.fromJson(i)).toList();

    return Comment(
      id: json['id'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
      text: json['text'] ?? '',
      parentId: json['parent_comment_id'],
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
      replies: repliesList,
    );
  }
}
