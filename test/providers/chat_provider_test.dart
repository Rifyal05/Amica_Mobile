import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/src/manager.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:amica/provider/chat_provider.dart';
import 'package:amica/services/chat_service.dart';

@GenerateNiceMocks([
  MockSpec<ChatService>(),
  MockSpec<IO.Socket>(),
  MockSpec<Manager>(),
])
import 'chat_provider_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  late ChatProvider chatProvider;
  late MockSocket mockSocket;
  late MockManager mockManager;

  setUp(() async {
    try {
      await Firebase.initializeApp(
        name: '[DEFAULT]',
        options: const FirebaseOptions(
          apiKey: 'fake',
          appId: 'fake',
          messagingSenderId: 'fake',
          projectId: 'fake',
        ),
      );
    } catch (_) {}

    mockSocket = MockSocket();
    mockManager = MockManager();

    when(mockSocket.io).thenReturn(mockManager);
    when(mockManager.options).thenReturn({});
    when(mockSocket.disconnect()).thenReturn(mockSocket);
    when(mockSocket.dispose()).thenReturn(null);

    chatProvider = ChatProvider();
    chatProvider.socket = mockSocket;
  });

  group('ChatProvider Unit Test', () {
    test('Initial State harus kosong', () {
      expect(chatProvider.inbox, isEmpty);
      expect(chatProvider.isLoading, false);
      expect(chatProvider.unreadMessageCount, 0);
    });

    test('sendMessage harus menambahkan pesan dummy ke cache lokal', () {
      const chatId = 'room_1';
      const myUserId = 'user_me';
      const text = 'Halo dunia';

      chatProvider.sendMessage(chatId, text, myUserId, myName: 'Me');

      final messages = chatProvider.getMessages(chatId);
      expect(messages.length, 1);
      expect(messages.first.text, text);
      expect(messages.first.id, startsWith('temp_'));
      expect(messages.first.isDelivered, false);

      verify(mockSocket.emit('send_message', {
        'chat_id': chatId,
        'text': text,
        'type': 'text',
        'reply_to_id': null,
      })).called(1);
    });

    test('markChatAsRead harus emit event ke socket', () {
      chatProvider.markChatAsRead('room_1');
      verify(mockSocket.emit('mark_read', {'chat_id': 'room_1'})).called(1);
    });

    test('sendTyping harus emit event typing', () {
      chatProvider.sendTyping('room_1', true);
      verify(mockSocket.emit('typing', {'chat_id': 'room_1', 'is_typing': true})).called(1);

      chatProvider.sendTyping('room_1', false);
      verify(mockSocket.emit('typing', {'chat_id': 'room_1', 'is_typing': false})).called(1);
    });

    test('clearData harus membersihkan state dan disconnect socket', () {
      chatProvider.socket = mockSocket;
      chatProvider.clearData();

      expect(chatProvider.inbox, isEmpty);
      expect(chatProvider.getTypingUser('any'), isNull);

      verify(mockSocket.disconnect()).called(1);
      verify(mockSocket.dispose()).called(1);
      expect(chatProvider.socket, isNull);
    });
  });
}