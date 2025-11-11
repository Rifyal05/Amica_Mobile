import 'package:amica/models/user_model.dart';

class Post {
  final String id;
  final User user;
  final String caption;
  final String? imageUrl;
  final String? assetPath;
  final DateTime timestamp;
  final int likes;
  final int comments;
  final List<String> tags;

  const Post({
    required this.id,
    required this.user,
    required this.caption,
    this.imageUrl,
    this.assetPath,
    required this.timestamp,
    required this.likes,
    required this.comments,
    this.tags = const [],
  });

  static final List<Post> dummyPosts = List.generate(12, (index) {
    final user = User.dummyUsers[index % User.dummyUsers.length];
    final List<String> dummyTags = [
      'parenting', 'pengen_tanya', 'tips_anak', 'cerita_lucu', 'keluarga'
    ];

    bool hasImage = index % 3 != 0;
    bool isLocal = index % 2 != 0 && hasImage;

    return Post(
      id: 'post_$index',
      user: user,
      timestamp: DateTime.now().subtract(Duration(hours: index * 2)),
      caption: hasImage
          ? 'Anakku belakangan ini lebih sering menyendiri setelah pulang sekolah, ada saran?'
          : 'Hanya ingin berbagi sedikit pemikiran hari ini. Terkadang, menjadi orang tua adalah tentang belajar melepaskan. Belajar percaya bahwa kita sudah memberikan bekal yang cukup bagi mereka untuk terbang sendiri. Sulit, tapi juga indah.',
      imageUrl: hasImage && !isLocal
          ? 'https://picsum.photos/seed/${index * 5}/800/${index % 2 == 0 ? 600 : 1200}'
          : null,
      assetPath: isLocal ? 'source/images/test.jpg' : null,
      likes: 1200 - (index * 35),
      comments: 312 - (index * 10),
      tags: [dummyTags[index % dummyTags.length], dummyTags[(index + 1) % dummyTags.length]],
    );
  });
}