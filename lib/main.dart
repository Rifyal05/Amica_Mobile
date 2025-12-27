import 'package:amica/provider/bot_provider.dart';
import 'package:amica/provider/chat_provider.dart';
import 'package:amica/provider/comment_provider.dart';
import 'package:amica/provider/notification_provider.dart';
import 'package:amica/provider/post_provider.dart';
import 'package:amica/provider/profile_provider.dart';
import 'package:amica/provider/sdq_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:amica/login/login_page.dart';
import 'package:amica/login/create_password_page.dart';
import 'provider/font_provider.dart';
import 'provider/navigation_provider.dart';
import 'provider/theme_provider.dart';
import 'provider/auth_provider.dart';
import 'theme/colors.dart';
import 'navigation/main_navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize(dotenv.env['ONESIGNAL_APP_ID']!);
  OneSignal.Notifications.requestPermission(true);

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
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(initialThemeMode),
        ),
        ChangeNotifierProvider(
          create: (context) => FontProvider(initialFontScale),
        ),
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SdqProvider()),
        ChangeNotifierProvider(create: (_) => BotProvider()),


      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      key: ValueKey('${isLoggedIn}_$needsPassword'),
      title: 'Amica',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: baseTheme,
      darkTheme: baseDarkTheme,
      locale: const Locale('id', 'ID'),
      home: !isLoggedIn
          ? const LoginPage()
          : (needsPassword ? const CreatePasswordPage() : const MainNavigator()),
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