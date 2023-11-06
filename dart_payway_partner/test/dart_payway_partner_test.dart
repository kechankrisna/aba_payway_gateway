import 'dart:convert';

import 'package:dart_payway_partner/dart_payway_partner.dart';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart';
import 'package:encrypt/encrypt_io.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:io' as io;
import 'package:pointycastle/asymmetric/api.dart';

void main() {
  group("load env and test", () {
    late PaywayPartnerService service;
    setUpAll(() {
      io.HttpOverrides.global = null;

      var env = DotEnv(includePlatformEnvironment: true)..load();

      service = PaywayPartnerService(
          partner: PaywayPartner(
        partnerName: env['ABA_PARTNER_NAME'] ?? '',
        partnerID: env['ABA_PARTNER_ID'] ?? '',
        partnerKey: env['ABA_PARTNER_KEY'] ?? '',
        partnerPrivateKey:
            utf8.decode(base64.decode(env['ABA_PARTNER_PRIVATE_KEY'] ?? "")),
        partnerPublicKey:
            utf8.decode(base64.decode(env['ABA_PARTNER_PUBLIC_KEY'] ?? "")),
        baseApiUrl: env['ABA_PARTNER_API_URL'] ?? '',
      ));
    });

    test("test register merchant", () async {
      var json = {
        'pushback_url': 'https://www.mylekha.org/',
        'redirect_url': 'https://www.mylekha.org/',
        'type': 0,
        'register_ref': "Merchant002"
      };
      var requestData = PaywayPartnerRegisterMerchant.fromMap(json);
      var reqService =
          PaywayPartnerClientFormRequestService(partner: service.partner);

      var map = reqService.generateRegisterMerchantFormData(requestData);
      print(map);
      var formData = FormData.fromMap(map);
      final client = PaywayPartnerClientService(service.partner).client;
      client.interceptors.add(dioLoggerInterceptor);
      try {
        Response response = await client.post("/new-merchant", data: formData);

        print(response);
      } catch (e) {
        print(e as DioException);
      }
    });

    test("test date", () {
      var errtime = "2023110615173";

      /// var t = DateTime.tryParse(errtime + "0")!;
      var r = DateFormat("yMddhhmmss").format(DateTime.now());
      print(errtime.length);
      print(r.length);
      print(r);
    });

    test("test generated encode", () {
      var data = {
        'pushback_url': 'https://www.mylekha.org/',
        'redirect_url': 'https://www.mylekha.org',
        'type': 0,
        'register_ref': 'Merchant001',
      };
      /// var requestData = PaywayPartnerRegisterMerchant.fromMap(data);
      /// var reqService =
      ///     PaywayPartnerClientFormRequestService(partner: service.partner);
      var encypted = PaywayPartnerClientFormRequestService.opensslEncrypt(
          data, service.partner.partnerPublicKey);
      print(encypted);
      var decryped = PaywayPartnerClientFormRequestService.opensslDecrypt(
          encypted, service.partner.partnerPrivateKey);
      print(decryped);

      /// var output = reqService.generateRegisterMerchantFormData(requestData);

      /// print(output);
    });

    test("test", () async {
      print(service.partner.partnerPublicKey.length);

      final publicKey = <RSAPublicKey>() {
        final parser = RSAKeyParser();
        return parser.parse(service.partner.partnerPublicKey) as RSAPublicKey;
      }();
      final privateKey = <RSAPublicKey>() {
        final parser = RSAKeyParser();
        return parser.parse(service.partner.partnerPrivateKey) as RSAPrivateKey;
      }();

      final encrypter = Encrypter(RSA(
        publicKey: publicKey,
        privateKey: privateKey,
        digest: RSADigest.SHA256,
      ));

      var data = {
        'pushback_url': 'xxxxxxxxxxxxxxxxxxx',
        'redirect_url': 'xxxxxxxxxxxxxxxxxxx',
        'type': 0,
        'register_ref': 'Merchant001'
      };
      var source = jsonEncode(data);

      var x = encrypter.encrypt(source);
      print(x.base64);
      expect(1, 1);
    });
  });
}
