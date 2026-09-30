// Smoke test of the demo screen. No network: the buttons are only rendered.
import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the demo actions', (WidgetTester tester) async {
    await tester.pumpWidget(const PaywayDemoApp());

    expect(find.text('PayWay Checkout Demo'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'purchase'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'check status'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'exchange rates'),
      findsOneWidget,
    );
  });
}
