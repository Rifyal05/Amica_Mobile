import 'dart:io';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:amica/mainpage/user_profile_page.dart';
import 'package:amica/models/user_profile_model.dart';
import 'package:amica/provider/auth_provider.dart';
import 'package:amica/provider/profile_provider.dart';
import 'package:amica/provider/navigation_provider.dart';
import 'package:amica/provider/post_provider.dart';
import 'package:amica/provider/chat_provider.dart';
import 'package:amica/provider/notification_provider.dart';

@GenerateNiceMocks([
  MockSpec<AuthProvider>(),
  MockSpec<ProfileProvider>(),
  MockSpec<NavigationProvider>(),
  MockSpec<PostProvider>(),
  MockSpec<ChatProvider>(),
  MockSpec<NotificationProvider>(),
  MockSpec<NavigatorObserver>(),
])
import '../mainpage/user_profile_page_test.mocks.dart';

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

  late MockAuthProvider mockAuth;
  late MockProfileProvider mockProfile;
  late MockNavigationProvider mockNav;
  late MockPostProvider mockPost;
  late MockChatProvider mockChat;
  late MockNotificationProvider mockNotification;
  late MockNavigatorObserver mockNavObserver;

  final dummyPsychologist = UserProfileData(
    id: 'psy_01',
    username: 'dr_clover_mpsi',
    displayName: 'Dr. Clover, M.Psi.',
    bio: 'Pakar kesehatan mental Amica. Mari bicara dari hati ke hati. 🍀',
    stats: UserStats(posts: 25, followers: 1500, following: 200),
    status: UserStatus(isMe: false, isFollowing: false, isSavedPostsPublic: false),
    isVerified: true,
  );

  setUp(() async {
    HttpOverrides.global = MockHttpOverrides();
    try {
      await Firebase.initializeApp(
        name: '[DEFAULT]',
        options: const FirebaseOptions(
          apiKey: 'fake', appId: 'fake', messagingSenderId: 'fake', projectId: 'fake',
        ),
      );
    } catch (_) {}

    mockAuth = MockAuthProvider();
    mockProfile = MockProfileProvider();
    mockNav = MockNavigationProvider();
    mockPost = MockPostProvider();
    mockChat = MockChatProvider();
    mockNotification = MockNotificationProvider();
    mockNavObserver = MockNavigatorObserver();

    when(mockNav.selectedIndex).thenReturn(3);
    when(mockProfile.isLoadingProfile).thenReturn(false);
    when(mockProfile.isLoadingPosts).thenReturn(false);
    when(mockProfile.imagePosts).thenReturn([]);
    when(mockProfile.textPosts).thenReturn([]);
    when(mockProfile.savedPosts).thenReturn([]);

    // Stub errorMessage agar tidak null crash
    when(mockProfile.errorMessage).thenReturn(null);
  });

  Widget createTestWidget(UserProfileData profileData) {
    when(mockProfile.userProfile).thenReturn(profileData);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
        ChangeNotifierProvider<ProfileProvider>.value(value: mockProfile),
        ChangeNotifierProvider<NavigationProvider>.value(value: mockNav),
        ChangeNotifierProvider<PostProvider>.value(value: mockPost),
        ChangeNotifierProvider<ChatProvider>.value(value: mockChat),
        ChangeNotifierProvider<NotificationProvider>.value(value: mockNotification),
      ],
      child: MaterialApp(
        // INJECT MOCK PROVIDER DISINI
        home: UserProfilePage(userId: profileData.id, provider: mockProfile),
        navigatorObservers: [mockNavObserver],
      ),
    );
  }

  group('UserProfilePage Widget Tests (Psychologist Theme)', () {
    testWidgets('Harus menampilkan Badge Psikolog Terverifikasi', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(dummyPsychologist));
      await tester.pump();

      expect(find.text('Dr. Clover, M.Psi.'), findsOneWidget);
      expect(find.text('Psikolog Terverifikasi'), findsOneWidget);
    });

    testWidgets('Harus menampilkan statistik pengikut yang besar', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(dummyPsychologist));
      await tester.pump();

      expect(find.text('1500'), findsOneWidget);
    });

    testWidgets('Klik tombol Ikuti harus memicu toggleFollow', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(dummyPsychologist));
      await tester.pump();

      // Cari button "Ikuti" secara spesifik
      final followBtn = find.widgetWithText(FilledButton, 'Ikuti');
      await tester.ensureVisible(followBtn);
      await tester.tap(followBtn);
      await tester.pump();

      verify(mockProfile.toggleFollow()).called(1);
    });
  });
}