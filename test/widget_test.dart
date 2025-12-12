// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_motor/main.dart';

void main() {
  testWidgets('Onboarding shows slides and CTA changes on last page',
      (WidgetTester tester) async {
    await tester.pumpWidget(const EMotorApp());

    expect(find.text('E-Motor'), findsWidgets);
    expect(find.text('Sewa Instan & Fleksibel'), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);

    // Swipe through all onboarding pages.
    for (var i = 0; i < 2; i++) {
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 800);
      await tester.pumpAndSettle();
    }

    expect(find.text('Premium & Selalu Siap'), findsOneWidget);
    expect(find.text('Mulai Sekarang'), findsOneWidget);
  });
}
