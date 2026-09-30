import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('choosing a payment method enables paying', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    FilledButton button() =>
        tester.widget<FilledButton>(find.byType(FilledButton));

    expect(button().onPressed, isNull);
    await tester.tap(find.text('Credit/Debit Card'));
    await tester.pump();
    expect(button().onPressed, isNotNull);
    expect(find.text('Pay \$6.00'), findsOneWidget);
  });
}
