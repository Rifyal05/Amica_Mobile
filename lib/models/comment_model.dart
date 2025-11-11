import 'package:amica/models/user_model.dart';

class Comment {
  final String id;
  final User user;
  final String text;
  final DateTime timestamp;
  final List<Comment> replies;

  const Comment({
    required this.id,
    required this.user,
    required this.text,
    required this.timestamp,
    this.replies = const [],
  });

  static final List<Comment> dummyComments = [
    Comment(
      id: 'comment_001',
      user: User.dummyUsers[1],
      text: 'Saran yang bagus, terima kasih sudah berbagi!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    Comment(
        id: 'comment_002',
        user: User.dummyUsers[2],
        text: 'Aku juga mengalami hal yang sama. Coba ajak bicara dari hati ke hati saat suasana sedang santai. Biasanya itu sangat membantu untuk membuka percakapan awal.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        replies: [
          Comment(
            id: 'reply_001',
            user: User.dummyUsers[0],
            text: 'Terima kasih atas masukannya! Akan aku coba nanti.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
          )
        ]
    ),
    Comment(
      id: 'comment_003',
      user: User.dummyUsers[3],
      text: 'Penting juga untuk memastikan anak merasa aman dan tidak dihakimi saat bercerita.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];
}