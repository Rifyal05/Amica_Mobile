import 'dart:io';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:amica/login/login_page.dart';

import 'package:amica/provider/auth_provider.dart';
import 'package:amica/provider/theme_provider.dart';
import 'package:amica/provider/navigation_provider.dart';
import 'package:amica/provider/chat_provider.dart';
import 'package:amica/provider/post_provider.dart';
import 'package:amica/provider/profile_provider.dart';
import 'package:amica/provider/notification_provider.dart';

@GenerateNiceMocks([
  MockSpec<AuthProvider>(),
  MockSpec<ThemeProvider>(),
  MockSpec<NavigationProvider>(),
  MockSpec<ChatProvider>(),
  MockSpec<PostProvider>(),
  MockSpec<ProfileProvider>(),
  MockSpec<NotificationProvider>(),
  MockSpec<NavigatorObserver>(),
])
import 'login_page_test.mocks.dart';

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

  late MockAuthProvider mockAuthProvider;
  late MockThemeProvider mockThemeProvider;
  late MockNavigationProvider mockNavigationProvider;
  late MockChatProvider mockChatProvider;
  late MockPostProvider mockPostProvider;
  late MockProfileProvider mockProfileProvider;
  late MockNotificationProvider mockNotificationProvider;
  late MockNavigatorObserver mockNavigatorObserver;

  setUp(() async {
    HttpOverrides.global = MockHttpOverrides();

    try {
      await Firebase.initializeApp(
        name: '[DEFAULT]',
        options: const FirebaseOptions(
          apiKey: 'fake_api_key',
          appId: 'fake_app_id',
          messagingSenderId: 'fake_sender_id',
          projectId: 'fake_project_id',
        ),
      );
    } catch (_) {}

    mockAuthProvider = MockAuthProvider();
    mockThemeProvider = MockThemeProvider();
    mockNavigationProvider = MockNavigationProvider();
    mockChatProvider = MockChatProvider();
    mockPostProvider = MockPostProvider();
    mockProfileProvider = MockProfileProvider();
    mockNotificationProvider = MockNotificationProvider();
    mockNavigatorObserver = MockNavigatorObserver();

    when(mockThemeProvider.isDarkMode(any)).thenReturn(false);
    when(mockNavigationProvider.selectedIndex).thenReturn(0);
    when(mockChatProvider.unreadMessageCount).thenReturn(0);
    when(mockChatProvider.fetchInbox()).thenAnswer((_) async {});
    when(mockPostProvider.refreshPosts()).thenAnswer((_) async {});
    when(mockAuthProvider.needsPasswordSet).thenReturn(false);
  });

  Widget createLoginPage() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ChangeNotifierProvider<NavigationProvider>.value(value: mockNavigationProvider),
        ChangeNotifierProvider<ChatProvider>.value(value: mockChatProvider),
        ChangeNotifierProvider<PostProvider>.value(value: mockPostProvider),
        ChangeNotifierProvider<ProfileProvider>.value(value: mockProfileProvider),
        ChangeNotifierProvider<NotificationProvider>.value(value: mockNotificationProvider),
      ],
      child: MaterialApp(
        home: const LoginPage(),
        navigatorObservers: [mockNavigatorObserver],
      ),
    );
  }

  group('LoginPage Widget Tests', () {
    testWidgets('UI Components harus muncul', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());
      expect(find.text('Selamat Datang'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Masuk'), findsOneWidget);
    });

    testWidgets('Validasi: Harus muncul SnackBar Error jika kolom kosong', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());
      await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Interaksi: Login Sukses harus memanggil navigasi', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());

      when(mockAuthProvider.attemptLogin('clover', 'pass'))
          .thenAnswer((_) async => {'success': true});

      await tester.enterText(
          find.widgetWithText(TextField, 'Username atau Email'), 'clover');
      await tester.enterText(
          find.widgetWithText(TextField, 'Password'), 'pass');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      verify(mockAuthProvider.attemptLogin('clover', 'pass')).called(1);
      verify(mockNavigatorObserver.didPush(any, any)).called(2);
    });

    testWidgets('Toggle Password: Harus mengubah obscureText', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());

      final passwordFieldFinder = find.widgetWithText(TextField, 'Password');
      TextField passwordField = tester.widget(passwordFieldFinder);
      expect(passwordField.obscureText, true);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      passwordField = tester.widget(passwordFieldFinder);
      expect(passwordField.obscureText, false);
    });
  });
}