import 'package:flutter_test/flutter_test.dart';
import 'package:amica/models/post_model.dart';
import 'package:amica/models/user_model.dart';

void main() {
  group('Post Model Unit Test', () {
    final dummyAuthor = User(
        id: 'u1',
        username: 'auth',
        displayName: 'Author',
        email: 'e@e.com',
        role: 'user'
    );

    test('Post.fromJson harus parsing data standar dengan benar', () {
      final json = {
        'id': 'p1',
        'caption': 'Halo dunia',
        'created_at': '2023-10-10T10:00:00Z',
        'likes_count': 5,
        'comments_count': 2,
        'is_liked': true,
        'is_saved': false,
        'author': {
          'id': 'u1', 'username': 'auth', 'email': 'e@e.com'
        },
        'tags': ['flutter', 'test']
      };

      final post = Post.fromJson(json);

      expect(post.id, 'p1');
      expect(post.caption, 'Halo dunia');
      expect(post.likesCount, 5);
      expect(post.isLiked, true);
      expect(post.author.username, 'auth');
      expect(post.tags.length, 2);
      expect(post.tags.first, 'flutter');
    });

    test('fullImageUrl harus menangani path relatif dan absolute', () {
      final postRelative = Post(
          id: '1', author: dummyAuthor, caption: '', timestamp: DateTime.now(),
          likesCount: 0, commentsCount: 0, tags: [], isLiked: false,
          imageUrl: 'uploads/post.jpg'
      );

      final postAbsolute = Post(
          id: '2', author: dummyAuthor, caption: '', timestamp: DateTime.now(),
          likesCount: 0, commentsCount: 0, tags: [], isLiked: false,
          imageUrl: 'https://cdn.example.com/image.png'
      );

      final postNull = Post(
          id: '3', author: dummyAuthor, caption: '', timestamp: DateTime.now(),
          likesCount: 0, commentsCount: 0, tags: [], isLiked: false,
          imageUrl: null
      );

      expect(postRelative.fullImageUrl, contains('uploads/post.jpg'));
      expect(postAbsolute.fullImageUrl, 'https://cdn.example.com/image.png');
      expect(postNull.fullImageUrl, isNull);
    });

    test('copyWith harus membuat object baru dengan nilai yang diubah tanpa merusak yang lama', () {
      final original = Post(
        id: '1', author: dummyAuthor, caption: 'Old', timestamp: DateTime.now(),
        likesCount: 10, commentsCount: 0, tags: [], isLiked: false,
      );

      final updated = original.copyWith(
          caption: 'New',
          likesCount: 11,
          isLiked: true
      );

      expect(updated.caption, 'New');
      expect(updated.likesCount, 11);
      expect(updated.isLiked, true);

      expect(updated.id, original.id);
      expect(updated.author, original.author);
    });
  });
}