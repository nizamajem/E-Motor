// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_motor/app.dart';

void main() {
  testWidgets('Onboarding shows slides and CTA changes on last page',
      (WidgetTester tester) async {
    await tester.pumpWidget(const EMotorApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome Gridwiz E-Motor'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Swipe through all onboarding pages.
    for (var i = 0; i < 2; i++) {
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 800);
      await tester.pumpAndSettle();
    }

    expect(find.text('Unlock, Ride, Go'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
