import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amica/login/login_page.dart';
import 'provider/font_provider.dart';
import 'provider/navigation_provider.dart';
import 'provider/theme_provider.dart';
import 'provider/auth_provider.dart';
import 'theme/colors.dart';
import 'navigation/main_navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    final authStatus = context.watch<AuthProvider>().isLoggedIn;

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
      title: 'Amica',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: baseTheme,
      darkTheme: baseDarkTheme,
      locale: const Locale('id', 'ID'),
      home: authStatus ? const MainNavigator() : const LoginPage(),
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
