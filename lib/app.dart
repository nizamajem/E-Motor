import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/navigation/app_navigator.dart';
import 'core/session/session_manager.dart';
import 'core/localization/app_localizations.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

class EMotorApp extends StatelessWidget {
  const EMotorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hasSession = SessionManager.instance.token != null;
    return MaterialApp(
      title: 'Gridwiz E-Motor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: AppNavigator.key,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: hasSession ? const DashboardScreen() : const OnboardingScreen(),
    );
  }
}
