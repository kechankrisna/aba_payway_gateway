import 'dart:convert';
import 'package:dart_payway_partner/dart_payway_partner.dart';
import 'package:encrypt/encrypt.dart';
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

    test(
      "test register a new merchant and status should be success",
      () async {
        final merchant = PaywayPartnerRegisterMerchant(
          pushback_url: 'https://www.mylekha.org/',
          redirect_url: 'https://www.mylekha.org/',
          type: 0,
          register_ref: "Merchant003",
        );

        var registerResponse =
            await service.registerMerchant(merchant: merchant);

        expect(
            registerResponse.url.isNotEmpty &&
                registerResponse.token.isNotEmpty,
            true,
            reason: "the url and token should be exist according to docs");

        expect(
            registerResponse.status.tran_id!.isNotEmpty &&
                registerResponse.status.code.isNotEmpty &&
                registerResponse.status.message.isNotEmpty,
            true,
            reason:
                "the status.tran_id,  status.code, status.message should be a string according to docs");
      },
    );

    test(
      "test check a new registered merchant status and expect to see no merchant not found",
      () async {
        final merchant = PaywayPartnerCheckMerchant(
          register_ref: "Merchant003",
        );

        var checkResponse = await service.checkMerchant(merchant: merchant);

        expect(checkResponse.data.isEmpty, true,
            reason:
                "the data should be empty while user not yet complet info according to docs");
      },
    );

    test("test encypted and decryped", () {
      Map<String, dynamic> data = {
        'pushback_url': 'https://www.mylekha.org/',
        'redirect_url': 'https://www.mylekha.org',
        'type': 0,
        'register_ref': 'Merchant001',
      };
      var encypted = PaywayPartnerClientFormRequestService.opensslEncrypt(
          data, service.partner.partnerPublicKey);
      print(encypted);
      var decryped = PaywayPartnerClientFormRequestService.opensslDecrypt(
          encypted, service.partner.partnerPrivateKey) as Map<String, dynamic>;
      print(decryped);

      expect(data, decryped,
          reason:
              "by using encrypted data, so decrypted result should be equal data");
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
