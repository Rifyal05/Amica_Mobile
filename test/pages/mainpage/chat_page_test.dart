import 'dart:io';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:amica/mainpage/chat_page.dart';
import 'package:amica/models/messages_model.dart';
import 'package:amica/models/user_model.dart';
import 'package:amica/provider/chat_provider.dart';
import 'package:amica/provider/auth_provider.dart';

@GenerateNiceMocks([
  MockSpec<ChatProvider>(),
  MockSpec<AuthProvider>(),
  MockSpec<NavigatorObserver>(),
])
import '../mainpage/chat_page_test.mocks.dart';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  late MockChatProvider mockChatProvider;
  late MockAuthProvider mockAuthProvider;
  late MockNavigatorObserver mockNavigatorObserver;

  final dummyMe = User(
    id: 'my_id',
    username: 'clover',
    displayName: 'Clover Me',
    email: 'me@test.com',
    role: 'user',
  );

  final messageFromOther = ChatMessage(
    id: 'msg_1',
    chatId: 'chat_123',
    senderId: 'other_id',
    senderName: 'Friend',
    text: 'Halo Clover!',
    type: 'text',
    time: DateTime.now(),
    sentAt: DateTime.now(),
    isRead: true,
  );

  final messageFromMe = ChatMessage(
    id: 'msg_2',
    chatId: 'chat_123',
    senderId: 'my_id',
    senderName: 'Clover Me',
    text: 'Hai juga!',
    type: 'text',
    time: DateTime.now(),
    sentAt: DateTime.now(),
    isRead: false,
  );

  setUp(() async {
    HttpOverrides.global = MockHttpOverrides();
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

    mockChatProvider = MockChatProvider();
    mockAuthProvider = MockAuthProvider();
    mockNavigatorObserver = MockNavigatorObserver();

    when(mockAuthProvider.currentUser).thenReturn(dummyMe);
    when(mockAuthProvider.isLoggedIn).thenReturn(true);
    when(mockAuthProvider.token).thenReturn('fake_token');

    when(mockChatProvider.getMessages('chat_123')).thenReturn([
      messageFromMe,
      messageFromOther,
    ]);
  });

  Widget createChatPage() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ChatProvider>.value(value: mockChatProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
      ],
      child: MaterialApp(
        home: const ChatPage(
          chatId: 'chat_123',
          chatName: 'Ruang Obrolan',
        ),
        navigatorObservers: [mockNavigatorObserver],
      ),
    );
  }

  group('ChatPage Widget Tests', () {
    testWidgets('Harus menampilkan nama chat dan daftar pesan', (WidgetTester tester) async {
      await tester.pumpWidget(createChatPage());
      await tester.pump();

      expect(find.text('Ruang Obrolan'), findsOneWidget);
      expect(find.text('Halo Clover!'), findsOneWidget);
      expect(find.text('Hai juga!'), findsOneWidget);
    });

    testWidgets('Mengetik teks dan menekan tombol kirim harus memicu sendMessage', (WidgetTester tester) async {
      await tester.pumpWidget(createChatPage());

      final inputField = find.byType(TextField);
      await tester.enterText(inputField, 'Pesan Baru');
      await tester.pump();

      final sendButton = find.byIcon(Icons.send);
      await tester.tap(sendButton);
      await tester.pump();

      verify(mockChatProvider.sendMessage(
        'chat_123',
        'Pesan Baru',
        'my_id',
        myName: anyNamed('myName'),
        myAvatar: anyNamed('myAvatar'),
        replyToId: anyNamed('replyToId'),
      )).called(1);

      expect(find.text('Pesan Baru'), findsNothing);
    });

    testWidgets('Harus menampilkan status sedang mengetik jika ada user typing', (WidgetTester tester) async {
      when(mockChatProvider.getTypingUser('chat_123')).thenReturn('Friend');

      await tester.pumpWidget(createChatPage());
      await tester.pump();

      expect(find.text('Sedang mengetik...'), findsOneWidget);
    });

    testWidgets('Long press pada pesan harus menampilkan menu aksi (Reply/Copy/Delete)', (WidgetTester tester) async {
      await tester.pumpWidget(createChatPage());
      await tester.pump();

      await tester.longPress(find.text('Hai juga!'));
      await tester.pumpAndSettle();

      expect(find.text('Balas'), findsOneWidget);
      expect(find.text('Salin Teks'), findsOneWidget);
      expect(find.text('Hapus Pesan'), findsOneWidget);
    });
  });
}