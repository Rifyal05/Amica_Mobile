import 'package:flutter_test/flutter_test.dart';
import 'package:amica/models/user_model.dart';

void main() {
  group('User Model Unit Test', () {
    final Map<String, dynamic> userJsonFull = {
      'id': '123',
      'username': 'clover',
      'display_name': 'Clover',
      'email': 'clover@example.com',
      'avatar_url': '/avatars/1.png',
      'role': 'admin',
      'is_following': true,
      'has_pin': true,
      'is_verified': true,
      'stats': {'followers': 777},
      'is_ai_moderation_enabled': true,
    };

    final Map<String, dynamic> userJsonMinimal = {
      'id': '456',
      'username': 'lucky_user',
      'email': 'lucky@example.com',
    };

    test('fromJson harus mem-parsing data lengkap dengan benar', () {
      final user = User.fromJson(userJsonFull);

      expect(user.id, '123');
      expect(user.username, 'clover');
      expect(user.displayName, 'Clover');
      expect(user.role, 'admin');
      expect(user.isFollowing, true);
      expect(user.stats?['followers'], 777);
      expect(user.isAiModerationEnabled, true);
    });

    test('fromJson harus menangani default value saat data null', () {
      final user = User.fromJson(userJsonMinimal);

      expect(user.id, '456');
      expect(user.role, 'user');
      expect(user.isFollowing, false);
      expect(user.hasPin, false);
      expect(user.isVerified, false);
      expect(user.isAiModerationEnabled, false);
    });

    test(
      'fromJson logic: displayName harus fallback ke username jika null',
      () {
        final user = User.fromJson(userJsonMinimal);

        expect(user.displayName, 'lucky_user');
      },
    );

    test('fromJson logic: isFollowing harus mendukung nested structure', () {
      final Map<String, dynamic> jsonNested = {
        'id': '789',
        'username': 'test',
        'email': 't@t.com',
        'role': 'user',
        'status': {'is_following': true},
      };

      final user = User.fromJson(jsonNested);
      expect(user.isFollowing, true);
    });

    test('toJson harus mengembalikan Map yang valid', () {
      final user = User(
        id: '1',
        username: 'clover',
        displayName: 'Clover',
        email: 'clover@test.com',
        role: 'user',
      );

      final json = user.toJson();

      expect(json['id'], '1');
      expect(json['username'], 'clover');
      expect(json['email'], 'clover@test.com');
      expect(json['avatar_url'], null);
    });

    test('copyWith harus membuat salinan objek dengan perubahan', () {
      final user = User(
        id: '1',
        username: 'old_clover',
        displayName: 'Old',
        email: 'old@test.com',
        role: 'user',
      );

      final updatedUser = user.copyWith(
        username: 'new_clover',
        isVerified: true,
      );

      expect(updatedUser.username, 'new_clover');
      expect(updatedUser.isVerified, true);

      expect(updatedUser.email, 'old@test.com');
      expect(updatedUser.id, '1');
    });
  });
}
