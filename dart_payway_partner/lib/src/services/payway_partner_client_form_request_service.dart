// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:dart_payway_partner/dart_payway_partner.dart';
import 'package:encrypt/encrypt.dart';
import 'package:intl/intl.dart';
import 'package:pointycastle/asymmetric/api.dart';

class PaywayPartnerClientFormRequestService {
  late PaywayPartner partner;
  PaywayPartnerClientFormRequestService({
    required this.partner,
  });

  /// [generateRegisterMerchantFormData]
  ///
  /// allow to pre generate the correct data for form submit when send create request register merchant
  ///
  Map<String, dynamic> generateRegisterMerchantFormData(
      PaywayPartnerRegisterMerchant requestData,
      {String? requestTime}) {
    var encodedRequestData = based64EncodedRequestData(requestData.toMap());

    final _requestTime =
        requestTime ?? DateFormat("yMddHms").format(DateTime.now());
    final clientService = PaywayPartnerClientService(partner);
    final str = clientService.getStr(
        request_time: _requestTime, request_data: encodedRequestData);
    final hash = clientService.getHash(str);

    var map = {
      "request_time": _requestTime.toString(),
      "partner_id": partner.partnerID.toString(),
      "request_data": encodedRequestData.toString(),
      "hash": hash.toString(),
    };
    return map;
  }

  String based64EncodedRequestData(Map<String, dynamic> data) {
    final parser = RSAKeyParser();
    final publicKey = parser.parse(partner.partnerPublicKey) as RSAPublicKey;
    final privateKey = parser.parse(partner.partnerPrivateKey) as RSAPrivateKey;

    final encrypter = Encrypter(RSA(
      publicKey: publicKey,
      privateKey: privateKey,
      digest: RSADigest.SHA256,
    ));
    var source = jsonEncode(data);
    var result = "";

    //Assumes 1024 bit key and encrypts in chunks.
    source.splitByLength(117).forEach((input) {
      var output = encrypter.encrypt(input);
      result += output.base64;
    });

    return result;
  }
}
