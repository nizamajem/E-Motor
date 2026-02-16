import 'package:flutter/material.dart';

/// Shared page transition with gentle shared-axis slide + fade + scale.
PageRouteBuilder<T> appRoute<T>(
  Widget page, {
  AxisDirection direction = AxisDirection.left,
}) {
  Offset begin = const Offset(0.12, 0);
  switch (direction) {
    case AxisDirection.right:
      begin = const Offset(-0.12, 0);
      break;
    case AxisDirection.up:
      begin = const Offset(0, 0.1);
      break;
    case AxisDirection.down:
      begin = const Offset(0, -0.1);
      break;
    case AxisDirection.left:
      begin = const Offset(0.12, 0);
      break;
  }

  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final primary = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInOutCubic,
      );
      final slideTween = Tween(begin: begin, end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      final fadeTween = Tween<double>(begin: 0.9, end: 1)
          .chain(CurveTween(curve: Curves.easeOut));
      final scaleTween =
          Tween<double>(begin: 0.98, end: 1).chain(CurveTween(curve: Curves.easeOutCubic));

      final outgoingSlide = Tween(begin: Offset.zero, end: begin * -0.4)
          .chain(CurveTween(curve: Curves.easeInOutCubic));

      return SlideTransition(
        position: primary.drive(slideTween),
        child: FadeTransition(
          opacity: primary.drive(fadeTween),
          child: ScaleTransition(
            scale: primary.drive(scaleTween),
            child: SlideTransition(
              position: secondaryAnimation.drive(outgoingSlide),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}
