import 'dart:convert';
import 'package:dart_payway_partner/dart_payway_partner.dart' hide debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
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
  late String referer_id = "Merchant001";

  late PaywayPartnerService service;

  @override
  void initState() {
    service = PaywayPartnerService(
        partner: PaywayPartner(
      partnerName: dotenv.env['ABA_PARTNER_NAME'] ?? '',
      partnerID: dotenv.env['ABA_PARTNER_ID'] ?? '',
      partnerKey: dotenv.env['ABA_PARTNER_KEY'] ?? '',
      partnerPrivateKey: utf8
          .decode(base64.decode(dotenv.env['ABA_PARTNER_PRIVATE_KEY'] ?? "")),
      partnerPublicKey: utf8
          .decode(base64.decode(dotenv.env['ABA_PARTNER_PUBLIC_KEY'] ?? "")),
      baseApiUrl: dotenv.env['ABA_PARTNER_API_URL'] ?? '',
    ));

    super.initState();
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
                onPressed: () async {
                  final merchant = PaywayPartnerRegisterMerchant(
                    pushback_url: 'https://www.mylekha.org/',
                    redirect_url: 'https://www.mylekha.org/',
                    type: 0,
                    register_ref: referer_id,
                  );
                  try {
                    var registerResponse =
                        await service.registerMerchant(merchant: merchant);
                    debugPrint(registerResponse.toJson());
                  } catch (e) {}
                },
                child: Text("register merchant")),
            TextButton(
                onPressed: () async {
                  final merchant = PaywayPartnerCheckMerchant(
                    register_ref: referer_id,
                  );
                  try {
                    var checkResponse =
                        await service.checkMerchant(merchant: merchant);
                    debugPrint(checkResponse.toJson());
                  } catch (e) {}
                },
                child: Text("check merchant"))
          ],
        ),
      ),
    );
  }
}
