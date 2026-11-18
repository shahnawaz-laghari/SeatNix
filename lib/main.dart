import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/splash_screen.dart';
import 'screens/email_verification_link_screen.dart';
import 'services/auth_service.dart';
import 'services/appwrite_backend.dart';
import 'services/language.dart';
import 'services/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initializes the Appwrite client with the public endpoint/project ID.
  // Never place an Appwrite server API key in a mobile app.
  AppwriteBackend.client;
  await languageController.load();
  await themeController.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
            final authService = AppwriteAuthService();
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
              // A new key rebuilds the whole navigation stack when the language or theme changes.
              key: ValueKey('$language-$themeMode'),
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
