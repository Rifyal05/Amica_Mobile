import 'dart:io';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:amica/mainpage/widgets/post_card.dart';
import 'package:amica/models/post_model.dart';
import 'package:amica/models/user_model.dart';
import 'package:amica/provider/auth_provider.dart';
import 'package:amica/provider/post_provider.dart';
import 'package:amica/provider/profile_provider.dart';
import 'package:amica/provider/navigation_provider.dart';

@GenerateNiceMocks([
  MockSpec<PostProvider>(),
  MockSpec<AuthProvider>(),
  MockSpec<ProfileProvider>(),
  MockSpec<NavigationProvider>(),
  MockSpec<NavigatorObserver>(),
])
import 'post_card_test.mocks.dart';

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

  late MockPostProvider mockPostProvider;
  late MockAuthProvider mockAuthProvider;
  late MockProfileProvider mockProfileProvider;
  late MockNavigationProvider mockNavigationProvider;
  late MockNavigatorObserver mockNavigatorObserver;

  final dummyAuthor = User(
    id: 'u1',
    username: 'clover',
    displayName: 'Clover User',
    email: 'clover@test.com',
    role: 'user',
    isVerified: true,
  );

  final dummyPost = Post(
    id: 'p1',
    author: dummyAuthor,
    caption: 'Tes Caption #lucky',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    likesCount: 10,
    commentsCount: 5,
    tags: ['lucky'],
    isLiked: false,
    isSaved: false,
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

    mockPostProvider = MockPostProvider();
    mockAuthProvider = MockAuthProvider();
    mockProfileProvider = MockProfileProvider();
    mockNavigationProvider = MockNavigationProvider();
    mockNavigatorObserver = MockNavigatorObserver();

    when(mockAuthProvider.currentUser).thenReturn(dummyAuthor);
  });

  Widget createPostCard() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PostProvider>.value(value: mockPostProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
        ChangeNotifierProvider<ProfileProvider>.value(value: mockProfileProvider),
        ChangeNotifierProvider<NavigationProvider>.value(value: mockNavigationProvider),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PostCard(post: dummyPost),
        ),
        navigatorObservers: [mockNavigatorObserver],
      ),
    );
  }

  group('PostCard Widget Tests', () {
    testWidgets('Tampil informasi dasar', (WidgetTester tester) async {
      await tester.pumpWidget(createPostCard());
      expect(find.text('Clover User'), findsOneWidget);
      expect(find.text('Tes Caption #lucky'), findsOneWidget);
    });

    testWidgets('Tapping tombol Like', (WidgetTester tester) async {
      await tester.pumpWidget(createPostCard());

      final likeBtn = find.byIcon(Icons.favorite_border_rounded);
      await tester.ensureVisible(likeBtn);
      await tester.tap(likeBtn);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(mockPostProvider.toggleLike('p1')).called(1);
      expect(find.text('11'), findsOneWidget);
    });

    testWidgets('Double tap Like', (WidgetTester tester) async {
      await tester.pumpWidget(createPostCard());

      final target = find.text('Tes Caption #lucky');
      await tester.tap(target);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(target);

      await tester.pump(const Duration(seconds: 1));

      verify(mockPostProvider.toggleLike('p1')).called(1);
    });

    testWidgets('Tapping tombol Save', (WidgetTester tester) async {
      await tester.pumpWidget(createPostCard());

      final saveBtn = find.byIcon(Icons.bookmark_border_rounded);
      await tester.tap(saveBtn);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(mockPostProvider.toggleSave('p1')).called(1);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Tapping profil navigasi', (WidgetTester tester) async {
      await tester.pumpWidget(createPostCard());

      await tester.tap(find.text('Clover User'));

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      verify(mockNavigationProvider.setIndex(3)).called(1);
      verify(mockNavigatorObserver.didPush(any, any)).called(greaterThan(0));
    });
  });
}