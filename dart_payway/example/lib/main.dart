import 'dart:convert';
import 'dart:io';
import 'package:dart_payway/dart_payway.dart' hide debugPrint, kIsWeb;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();

  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late PaywayTransactionService service;
  String? tranID = null;
  @override
  void initState() {
    service = PaywayTransactionService(
        merchant: PaywayMerchant(
      merchantID: dotenv.env['ABA_PAYWAY_MERCHANT_ID'] ?? '',
      merchantApiName: dotenv.env['ABA_PAYWAY_MERCHANT_NAME'] ?? '',
      merchantApiKey: dotenv.env['ABA_PAYWAY_API_KEY'] ?? '',
      baseApiUrl: dotenv.env['ABA_PAYWAY_API_URL'] ?? '',
      refererDomain: "http://localhost",
    ));
    super.initState();
    kIsWeb;
  }

  Future<void> createTransaction() async {
    setState(() {
      tranID = service.uniqueTranID();
    });
    var transaction = PaywayCreateTransaction(
      amount: 10.00,
      items: [
        PaywayTransactionItem(name: "ទំនិញ 1", price: 2, quantity: 1),
        PaywayTransactionItem(name: "ទំនិញ 2", price: 3, quantity: 1),
        PaywayTransactionItem(name: "ទំនិញ 3", price: 5, quantity: 1),
      ],
      reqTime: service.uniqueReqTime(),
      tranId: tranID!,
      email: 'support@mylekha.app',
      firstname: 'Miss',
      lastname: 'My Lekha',
      phone: '010464144',
      option: PaywayPaymentOption.abapay_khqr_deeplink,
      shipping: 0.0,
      returnUrl:
          "https://xdgacmihblkqdexzbmkw.supabase.co/functions/v1/payway_checkout_success",
      continueSuccessUrl: "https://mylekha.app",
      returnParams: EncoderService.base64_encode(
          {"booking_id": "0032153b-8df2-40a3-b533-37622e7ecd37"}),
      customFields: EncoderService.base64_encode(
          {"booking_id": "0032153b-8df2-40a3-b533-37622e7ecd37"}),
    );

    try {
      var createResponse = await service.createTransaction(
          transaction: transaction, enabledLogger: true);
      debugPrint(createResponse.toString());
    } catch (e) {}
  }

  Future<void> checkTransaction() async {
    final transaction = PaywayCheckTransaction(
      reqTime: service.uniqueReqTime(),
      tranId: tranID!,
    );
    try {
      var createResponse = await service.checkTransaction(
          transaction: transaction, enabledLogger: true);
      debugPrint(createResponse.toString());
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(
                onPressed: createTransaction,
                child: Text("create Transaction")),
            TextButton(
                onPressed: checkTransaction, child: Text("check Transaction"))
          ],
        ),
      ),
    );
  }
}
