import 'package:flutter/material.dart';
import 'package:flutter_payway/flutter_payway.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'flutter_payway',
    theme: ThemeData(colorSchemeSeed: Colors.indigo),
    home: const CheckoutPage(),
  );
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  PaywayPaymentOption? _option;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Checkout')),
    body: Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              for (var i = 1; i <= 3; i++)
                ListTile(title: Text('item $i'), trailing: Text('\$$i.00')),
            ],
          ),
        ),
        PaywayAcceptablePaymentColumn(
          value: _option,
          onChanged: (option) => setState(() => _option = option),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            // your server creates the purchase with dart_payway and returns
            // the deep link, QR string or checkout page to the app
            onPressed: _option == null ? null : () {},
            child: Text(
              _option == null ? 'Choose a payment method' : 'Pay \$6.00',
            ),
          ),
        ),
      ],
    ),
  );
}
