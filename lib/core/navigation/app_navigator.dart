import 'package:flutter/material.dart';

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
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        });
        return AlertDialog(
          content: Text(message),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      },
    );
    _refreshDialogOpen = false;
  }
}
