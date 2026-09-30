import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_payway/flutter_payway.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('phones get cards and the ABA Mobile deep link', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(_app(const PaywayAcceptablePaymentColumn()));
    expect(find.text('Credit/Debit Card'), findsOneWidget);
    expect(find.text('ABA PAY'), findsOneWidget);
    expect(find.text('Tap to pay with ABA Mobile'), findsOneWidget);
    expect(find.text('ABA KHQR'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('desktop gets the KHQR to scan', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await tester.pumpWidget(_app(const PaywayAcceptablePaymentColumn()));
    expect(find.text('ABA KHQR'), findsOneWidget);
    expect(find.text('ABA PAY'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('tapping selects an option once', (tester) async {
    final changes = <PaywayPaymentOption>[];
    await tester.pumpWidget(
      _app(
        PaywayAcceptablePaymentColumn(
          options: const [
            PaywayPaymentOption.cards,
            PaywayPaymentOption.abapayKhqr,
          ],
          onChanged: changes.add,
        ),
      ),
    );
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsNothing);

    await tester.tap(find.text('ABA KHQR'));
    await tester.pump();
    await tester.tap(find.text('ABA KHQR'));
    await tester.pump();

    expect(changes, [PaywayPaymentOption.abapayKhqr]);
    final tile = tester.widget<ListTile>(
      find.byKey(const ValueKey(PaywayPaymentOption.abapayKhqr)),
    );
    expect(tile.selected, isTrue);
  });

  testWidgets('follows a new value from the parent', (tester) async {
    Widget column(PaywayPaymentOption value) => _app(
      PaywayAcceptablePaymentColumn(
        value: value,
        options: const [
          PaywayPaymentOption.cards,
          PaywayPaymentOption.abapayKhqr,
        ],
      ),
    );
    bool selected(PaywayPaymentOption option) =>
        tester.widget<ListTile>(find.byKey(ValueKey(option))).selected;

    await tester.pumpWidget(column(PaywayPaymentOption.cards));
    expect(selected(PaywayPaymentOption.cards), isTrue);
    await tester.pumpWidget(column(PaywayPaymentOption.abapayKhqr));
    expect(selected(PaywayPaymentOption.abapayKhqr), isTrue);
    expect(selected(PaywayPaymentOption.cards), isFalse);
  });

  testWidgets('every option renders, and labels can be translated', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: PaywayAcceptablePaymentColumn(
            options: PaywayPaymentOption.values,
            labels: const PaywayPaymentLabels(cards: 'កាត', wechat: 'វីឆាត'),
          ),
        ),
      ),
    );
    expect(
      find.byType(ListTile),
      findsNWidgets(PaywayPaymentOption.values.length),
    );
    expect(find.text('កាត'), findsOneWidget);
    expect(find.text('វីឆាត'), findsOneWidget);
  });

  test('the logos are bundled under the package asset keys', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final name in ['ic_cards.png', 'ic_generic.png', 'ic_payway.png']) {
      final bytes = await rootBundle.load(
        'packages/flutter_payway/assets/images/$name',
      );
      expect(bytes.lengthInBytes, greaterThan(0), reason: name);
    }
  });
}
