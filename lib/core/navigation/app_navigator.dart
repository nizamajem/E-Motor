import 'package:flutter/material.dart';

import '../../features/auth/presentation/login_screen.dart';

class AppNavigator {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
  static bool _refreshDialogOpen = false;

  static BuildContext? get _context => key.currentState?.overlay?.context;

  static Future<void> showRefreshDialog(String message) async {
    final context = _context;
    if (context == null || _refreshDialogOpen) return;
    _refreshDialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (navigator.canPop()) {
            navigator.pop();
          }
        });
        return AlertDialog(
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
    _refreshDialogOpen = false;
  }

  static Future<void> navigateToLogin() async {
    final context = key.currentState?.overlay?.context;
    if (context == null) return;

    key.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
