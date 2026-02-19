import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/navigation/app_navigator.dart';
import 'core/session/session_manager.dart';
import 'core/localization/app_localizations.dart';
import 'features/shell/main_shell.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/auth/presentation/login_screen.dart';

class EMotorApp extends StatelessWidget {
  const EMotorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hasSession = SessionManager.instance.token != null;
    final seenOnboarding = SessionManager.instance.onboardingSeen;
    return MaterialApp(
      title: 'Gridwiz E-Motor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: AppNavigator.key,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supported) {
        final code = locale?.languageCode.toLowerCase() ?? 'en';
        if (code == 'id') {
          return const Locale('id');
        }
        if (code == 'en') {
          return const Locale('en');
        }
        return const Locale('en');
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: seenOnboarding
          ? (hasSession ? const MainShell() : const LoginScreen())
          : const OnboardingScreen(),
    );
  }
}
