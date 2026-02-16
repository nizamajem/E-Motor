import 'package:flutter/material.dart';

const Duration kDialogDuration = Duration(milliseconds: 220);
const Duration kSnackDuration = Duration(milliseconds: 160);
const Curve kEnterCurve = Curves.easeOutCubic;
const Curve kExitCurve = Curves.easeInCubic;
const double kBackdropOpacity = 0.32;

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'dismiss',
    barrierColor: Colors.black.withValues(alpha: kBackdropOpacity),
    transitionDuration: kDialogDuration,
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return builder(dialogContext);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: kEnterCurve,
        reverseCurve: kExitCurve,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'dismiss',
    barrierColor: Colors.black.withValues(alpha: kBackdropOpacity),
    transitionDuration: kDialogDuration,
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          top: false,
          child: builder(dialogContext),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: kEnterCurve,
        reverseCurve: kExitCurve,
      );
      final offset = Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(curved);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(position: offset, child: child),
      );
    },
  );
}

void showAppSnackBar(BuildContext context, String message,
    {bool isError = false}) {
  final bg = isError ? const Color(0xFFE34A43) : const Color(0xFF1F2937);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: kSnackDuration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: bg,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
