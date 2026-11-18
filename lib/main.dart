import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/splash_screen.dart';
import 'screens/email_verification_link_screen.dart';
import 'services/auth_service.dart';
import 'services/appwrite_backend.dart';
import 'services/error_notifier.dart';
import 'services/language.dart';
import 'services/settings_store.dart';
import 'services/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initializes the Appwrite client with the public endpoint/project ID.
  // Never place an Appwrite server API key in a mobile app.
  AppwriteBackend.client;
  await languageController.load();
  await themeController.load();
  ErrorNotifier.setPushEnabled(await SettingsStore.pushNotifications);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Keep one service instance across rebuilds instead of recreating it on
  // every theme/language update.
  static final AuthService _authService = AppwriteAuthService();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageController,
      builder: (context, language, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeController,
          builder: (context, themeMode, _) {
            final lightTheme = ThemeData(
              colorScheme: .fromSeed(seedColor: Colors.deepPurple),
            );
            final darkTheme = ThemeData(
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: const Color(0xFF121416),
            );
            final authService = _authService;
            final query = Uri.base.queryParameters;
            final verificationUserId = query['userId'];
            final verificationSecret = query['secret'];
            final Widget startScreen;
            if (kIsWeb &&
                verificationUserId != null &&
                verificationSecret != null) {
              startScreen = EmailVerificationLinkScreen(
                authService: authService,
                userId: verificationUserId,
                secret: verificationSecret,
              );
            } else {
              startScreen = SplashScreen(authService: authService);
            }
            return MaterialApp(
              // Only language changes rebuild the navigation stack so Text
              // widgets re-translate. Theme changes update MaterialApp in place.
              key: ValueKey(language),
              title: 'SeatNix',
              debugShowCheckedModeBanner: false,
              locale: Locale(language),
              supportedLocales: const [Locale('en'), Locale('ur')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: _withLanguageFont(lightTheme, language),
              darkTheme: _withLanguageFont(darkTheme, language),
              themeMode: themeMode,
              // Animate color changes so switching theme is smooth instead of
              // swapping every surface in a single jarring frame.
              builder: (context, child) => AnimatedTheme(
                data: Theme.of(context),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: child ?? const SizedBox.shrink(),
              ),
              home: startScreen,
            );
          },
        );
      },
    );
  }

  ThemeData _withLanguageFont(ThemeData theme, String language) {
    if (language != languageUrdu) return theme;
    return theme.copyWith(
      textTheme: theme.textTheme.apply(
        fontFamily: GoogleFonts.notoSansArabic().fontFamily,
      ),
    );
  }
}
