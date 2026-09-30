// Demo only: this app embeds the merchant API key to call the PayWay sandbox
// directly. In production, call PayWay from your server and never ship the
// API key inside an app.
//
// Run with the package's sandbox .env:
//   flutter run --dart-define-from-file=../.env
import 'package:dart_payway/dart_payway.dart';
import 'package:flutter/material.dart';

void main() => runApp(const PaywayDemoApp());

// values from --dart-define-from-file; empty when not provided
const _apiUrl = String.fromEnvironment('ABA_PAYWAY_API_URL');
const _merchantId = String.fromEnvironment('ABA_PAYWAY_MERCHANT_ID');
const _apiKey = String.fromEnvironment('ABA_PAYWAY_API_KEY');
const _referer = String.fromEnvironment('ABA_PAYWAY_REFERER_DOMAIN');

/// Demo of the dart_payway SDK.
class PaywayDemoApp extends StatelessWidget {
  /// Creates the demo app.
  const PaywayDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayWay Checkout Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const PaywayDemoPage(),
    );
  }
}

/// Buttons calling each API and a log of the results.
class PaywayDemoPage extends StatefulWidget {
  /// Creates the demo page.
  const PaywayDemoPage({super.key});

  @override
  State<PaywayDemoPage> createState() => _PaywayDemoPageState();
}

class _PaywayDemoPageState extends State<PaywayDemoPage> {
  final payway = PaywayService(
    merchant: PaywayMerchant(
      merchantId: _merchantId,
      apiKey: _apiKey,
      referer: _referer,
      baseApiUrl: _apiUrl.isEmpty ? PaywayMerchant.sandboxBaseUrl : _apiUrl,
    ),
  );
  final log = <String>[];
  String? lastTranId;

  Future<void> run(String label, Future<String> Function() action) async {
    setState(() => log.insert(0, '$label…'));
    String result;
    try {
      result = await action();
    } on PaywayException catch (e) {
      result = '$e';
    }
    setState(() => log[0] = '$label: $result');
  }

  Future<String> purchase() async {
    final tranId = 'demo${DateTime.now().millisecondsSinceEpoch}';
    final response = await payway.purchase(
      PaywayPurchase(
        tranId: tranId,
        amount: 0.1,
        currency: PaywayCurrency.usd,
        paymentOption: PaywayPaymentOption.abapayKhqrDeeplink,
        items: const [PaywayItem(name: 'Coffee', quantity: 1, price: 0.1)],
      ),
    );
    if (response.isSuccess) lastTranId = tranId;
    // open response.abapayDeeplink or render response.qrString as a QR code
    return '${response.status.code} ${response.status.message} '
        'deeplink=${response.abapayDeeplink != null}';
  }

  Future<String> checkStatus() async {
    final tranId = lastTranId;
    if (tranId == null) return 'create a purchase first';
    final response = await payway.checkTransaction(tranId: tranId);
    return response.isSuccess
        ? '${response.data?.paymentStatus} (${response.data?.totalAmount})'
        : '${response.status.code} ${response.status.message}';
  }

  Future<String> exchangeRates() async {
    final response = await payway.getExchangeRates();
    final usd = response.rates['usd'];
    return usd == null
        ? '${response.status.code} ${response.status.message}'
        : 'USD sell ${usd.sell} / buy ${usd.buy} riel';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PayWay Checkout Demo')),
      body: Column(
        children: [
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () => run('purchase (KHQR)', purchase),
                child: const Text('purchase'),
              ),
              OutlinedButton(
                onPressed: () => run('check status', checkStatus),
                child: const Text('check status'),
              ),
              OutlinedButton(
                onPressed: () => run('exchange rates', exchangeRates),
                child: const Text('exchange rates'),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [for (final line in log) Text(line)],
            ),
          ),
        ],
      ),
    );
  }
}
