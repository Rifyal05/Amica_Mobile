import 'package:flutter_test/flutter_test.dart';
// Sesuaikan import ini dengan nama file asli di foldermu
// Biasanya dipisah: chat_model.dart (ChatRoom) dan messages_model.dart (ChatMessage)
import 'package:amica/models/chat_model.dart';
import 'package:amica/models/messages_model.dart';

void main() {
  group('Chat Models Unit Test', () {

    // --- TEST UNTUK CHAT ROOM ---
    group('ChatRoom Tests', () {
      test('ChatRoom.fromJson harus parsing data lengkap dengan benar', () {
        final json = {
          'id': 'room1',
          'name': 'Grup Belajar',
          'image_url': 'group.jpg',
          'last_message_text': 'Halo semua',
          'last_sender_name': 'Budi',
          'last_message_time': '2023-10-27T10:00:00Z',
          'unread_count': 5,
          'is_group': true,
          'is_hidden': false,
          'target_user': {'is_verified': true},
          'is_blocked_by_me': false,
        };

        final room = ChatRoom.fromJson(json);

        expect(room.id, 'room1');
        expect(room.name, 'Grup Belajar');
        expect(room.unreadCount, 5);
        expect(room.isGroup, true);
        expect(room.lastMessage, 'Halo semua');
        expect(room.lastMessageTime, isNotNull);
        expect(room.isVerified, true);
      });

      test('ChatRoom.fromJson harus aman terhadap null values', () {
        final json = {
          'id': 'room2',
          // name null -> default 'Unknown'
          // unread_count null -> default 0
          // is_group null -> default false
        };

        final room = ChatRoom.fromJson(json);

        expect(room.id, 'room2');
        expect(room.name, 'Unknown');
        expect(room.unreadCount, 0);
        expect(room.isGroup, false);
        expect(room.lastMessageTime, isNull);
      });
    });

    // --- TEST UNTUK CHAT MESSAGE ---
    group('ChatMessage Tests', () {
      test('ChatMessage.fromJson harus parsing data standar', () {
        final json = {
          'id': 'msg1',
          'chat_id': 'room1',
          'sender_id': 'user1',
          'text': 'Tes pesan',
          'type': 'text',
          'sent_at': '2023-10-27T10:00:00Z',
          'is_read': true,
          'sender_is_verified': true
        };

        final msg = ChatMessage.fromJson(json);

        expect(msg.id, 'msg1');
        expect(msg.chatId, 'room1');
        expect(msg.text, 'Tes pesan');
        expect(msg.isRead, true);
        expect(msg.senderIsVerified, true);
      });

      test('senderAvatar harus menangani URL relatif dan absolute', () {
        final msgRelative = ChatMessage(
            id: '1', chatId: 'c1', type: 'text', time: DateTime.now(), sentAt: DateTime.now(), isRead: false,
            senderAvatar: 'uploads/avatar.jpg'
        );

        final msgAbsolute = ChatMessage(
            id: '2', chatId: 'c1', type: 'text', time: DateTime.now(), sentAt: DateTime.now(), isRead: false,
            senderAvatar: 'https://cdn.com/avatar.png'
        );

        expect(msgRelative.senderAvatar, contains('uploads/avatar.jpg'));
        expect(msgAbsolute.senderAvatar, 'https://cdn.com/avatar.png');
      });

      test('copyWith harus mengubah status pesan tanpa merusak data lain', () {
        final original = ChatMessage(
          id: 'msg1',
          chatId: 'c1',
          text: 'Lama',
          type: 'text',
          time: DateTime.now(),
          sentAt: DateTime.now(),
          isRead: false,
          isDelivered: false,
        );

        final updated = original.copyWith(
            isRead: true,
            isDelivered: true,
            text: 'Baru' // Misalnya pesan diedit
        );

        expect(updated.isRead, true);
        expect(updated.isDelivered, true);
        expect(updated.text, 'Baru');

        // Data lama harus tetap sama
        expect(updated.id, original.id);
        expect(updated.chatId, original.chatId);
      });
    });

  });
}