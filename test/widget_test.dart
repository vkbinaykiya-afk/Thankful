import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thankful/features/account/screens/cancel_confirm_screen.dart';

void main() {
  testWidgets('Smoke test: trivial app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Cancel confirm shows headline and body', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CancelConfirmScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Thank you for'), findsOneWidget);
    expect(find.textContaining('Twelve times'), findsOneWidget);
    expect(find.text('Keep my subscription'), findsOneWidget);
  });
}
