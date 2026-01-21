import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:amica/main.dart' as app;
import 'package:amica/mainpage/widgets/post_card.dart';
import 'package:amica/firebase_options.dart';

import 'package:amica/provider/auth_provider.dart';
import 'package:amica/provider/post_provider.dart';
import 'package:amica/provider/chat_provider.dart';
import 'package:amica/provider/profile_provider.dart';
import 'package:amica/provider/notification_provider.dart';
import 'package:amica/provider/sdq_provider.dart';
import 'package:amica/provider/theme_provider.dart';
import 'package:amica/provider/font_provider.dart';
import 'package:amica/provider/navigation_provider.dart';
import 'package:amica/provider/comment_provider.dart';
import 'package:amica/provider/bot_provider.dart';
import 'package:amica/provider/moderation_provider.dart';

import 'package:amica/services/auth_service.dart';
import 'package:amica/services/user_service.dart';
import 'package:amica/services/post_service.dart';
import 'package:amica/services/sdq_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Real Post Flow Integration Test', () {
    late AuthProvider authProvider;
    late PostProvider postProvider;
    late SdqProvider sdqProvider;

    late NotificationProvider notificationProvider;
    late ChatProvider chatProvider;
    late ProfileProvider profileProvider;
    late CommentProvider commentProvider;
    late BotProvider botProvider;
    late ModerationProvider moderationProvider;

    setUp(() async {
      HttpOverrides.global = MyHttpOverrides();
      SharedPreferences.setMockInitialValues({});

      try {
        await dotenv.load(fileName: ".env");
      } catch (_) {}

      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (_) {}

      final authService = AuthService();
      final userService = UserService();
      final postService = PostService();
      final sdqService = SdqService();

      authProvider = AuthProvider(
        authService: authService,
        userService: userService,
      );
      postProvider = PostProvider(postService: postService);
      sdqProvider = SdqProvider(service: sdqService);

      notificationProvider = NotificationProvider();
      chatProvider = ChatProvider();
      profileProvider = ProfileProvider();
      commentProvider = CommentProvider();
      botProvider = BotProvider();
      moderationProvider = ModerationProvider();
    });

    testWidgets('Login -> Create Text Post -> Verify Feed', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<PostProvider>.value(value: postProvider),
            ChangeNotifierProvider<NotificationProvider>.value(
              value: notificationProvider,
            ),
            ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
            ChangeNotifierProvider<ProfileProvider>.value(
              value: profileProvider,
            ),
            ChangeNotifierProvider<SdqProvider>.value(value: sdqProvider),
            ChangeNotifierProvider<CommentProvider>.value(
              value: commentProvider,
            ),
            ChangeNotifierProvider<BotProvider>.value(value: botProvider),
            ChangeNotifierProvider<ModerationProvider>.value(
              value: moderationProvider,
            ),
            ChangeNotifierProvider(create: (_) => NavigationProvider()),
            ChangeNotifierProvider(
              create: (_) => ThemeProvider(ThemeMode.light),
            ),
            ChangeNotifierProvider(create: (_) => FontProvider(1.0)),
          ],
          child: const app.MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Username atau Email'),
        'amica_tester',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'Amica.1234',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      final uniqueContent =
          'Real Test Post ${DateTime.now().millisecondsSinceEpoch}';

      await tester.enterText(find.byType(TextField).first, uniqueContent);
      await tester.pump();

      await tester.enterText(find.byType(TextField).last, 'e2e test');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Kirim'));

      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));

      await tester.tap(find.widgetWithText(FilledButton, 'OK, LIHAT FEED'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 3));

      expect(find.text(uniqueContent), findsOneWidget);
      expect(find.byType(PostCard), findsWidgets);
    });
  });
}
