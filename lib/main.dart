import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'firebase_options.dart';
import 'login/login_page.dart';
import 'login/create_password_page.dart';
import 'mainpage/chat_page.dart';
import 'mainpage/post_detail_page.dart';
import 'mainpage/moderation_list_page.dart';
import 'navigation/main_navigator.dart';
import 'provider/font_provider.dart';
import 'provider/navigation_provider.dart';
import 'provider/theme_provider.dart';
import 'provider/auth_provider.dart';
import 'provider/post_provider.dart';
import 'provider/profile_provider.dart';
import 'provider/comment_provider.dart';
import 'provider/chat_provider.dart';
import 'provider/notification_provider.dart';
import 'provider/sdq_provider.dart';
import 'provider/bot_provider.dart';
import 'provider/moderation_provider.dart';
import 'theme/colors.dart';
import 'services/chat_service.dart'; // Import ChatService

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final cacheManager = DefaultCacheManager();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('id_ID', null);

  OneSignal.Debug.setLogLevel(OSLogLevel.none);
  OneSignal.initialize(dotenv.env['ONESIGNAL_APP_ID']!);
  OneSignal.Notifications.requestPermission(true);

  OneSignal.Notifications.addClickListener((event) {
    final data = event.notification.additionalData;

    if (data != null) {
      if (data['type'] == 'chat' && data.containsKey('message_id')) {
        final msgId = data['message_id'];
        ChatService().markDeliveredBackground(msgId);
      }
      Future.delayed(const Duration(milliseconds: 500), () {
        final navigator = navigatorKey.currentState;

        if (navigator == null) return;

        if (data['type'] == 'chat') {
          final String chatId = data['chat_id'];
          final String chatName = event.notification.title ?? "Chat";

          navigator.push(
            MaterialPageRoute(
              builder: (_) => ChatPage(
                chatId: chatId,
                chatName: chatName,
                isGroup:
                    data['is_group'].toString() == 'true' ||
                    data['is_group'] == true,
              ),
            ),
          );
        } else if (data['type'] == 'post' ||
            data['type'] == 'like' ||
            data['type'] == 'comment') {
          final String? postId = data['reference_id'];
          if (postId != null) {
            _navigateToPost(navigator.context, postId);
          }
        } else if (data['type'] == 'post_rejected' ||
            data['type'] == 'moderation_update') {
          navigator.push(
            MaterialPageRoute(builder: (_) => const ModerationListPage()),
          );
        }
      });
    }
  });

  final prefs = await SharedPreferences.getInstance();
  final themeIndex = prefs.getInt('themeMode') ?? ThemeMode.system.index;
  final initialThemeMode = ThemeMode.values[themeIndex];
  final initialFontScale = prefs.getDouble('fontScale') ?? 1.0;

  final authProvider = AuthProvider();
  await authProvider.checkAuthStatus();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(initialThemeMode)),
        ChangeNotifierProvider(create: (_) => FontProvider(initialFontScale)),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SdqProvider()),
        ChangeNotifierProvider(create: (_) => BotProvider()),
        ChangeNotifierProvider(create: (_) => ModerationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

void _navigateToPost(BuildContext context, String postId) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final postProvider = context.read<PostProvider>();
    final post = await postProvider.getPostById(postId);

    if (context.mounted) Navigator.pop(context);

    if (post != null && context.mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => PostDetailPage(post: post)));
    }
  } catch (e) {
    if (context.mounted) Navigator.pop(context);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleIncomingLink(uri);
    });
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleIncomingLink(uri);
    });
  }

  void _handleIncomingLink(Uri uri) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;

    if (uri.scheme == 'amica' && uri.host == 'join') {
      final chatId = uri.pathSegments.last;
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ChatPage(
            chatId: chatId,
            chatName: "Undangan Grup",
            isGroup: true,
          ),
        ),
      );
    }

    bool isPostLink =
        (uri.scheme == 'amica' && uri.host == 'post') ||
        (uri.pathSegments.contains('post') && uri.pathSegments.isNotEmpty);

    if (isPostLink) {
      String rawId = uri.pathSegments.last;
      final String postId = rawId.replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '');
      _navigateToPost(navigatorKey.currentContext!, postId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final fontProvider = context.watch<FontProvider>();
    final authProvider = context.watch<AuthProvider>();

    final isLoggedIn = authProvider.isLoggedIn;
    final needsPassword = authProvider.needsPasswordSet;

    final baseTheme = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primarySeedLight,
        brightness: Brightness.light,
      ),
    );

    final baseDarkTheme = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primarySeedDark,
        brightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      navigatorKey: navigatorKey,
      key: ValueKey('${isLoggedIn}_$needsPassword'),
      title: 'Amica',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: baseTheme,
      darkTheme: baseDarkTheme,
      locale: const Locale('id', 'ID'),
      home: !isLoggedIn
          ? const LoginPage()
          : (needsPassword
                ? const CreatePasswordPage()
                : const MainNavigator()),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(fontProvider.fontScale)),
          child: child!,
        );
      },
    );
  }
}
