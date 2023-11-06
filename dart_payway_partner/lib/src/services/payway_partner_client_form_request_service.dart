// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:typed_data';

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
    var request_data =
        opensslEncrypt(requestData.toMap(), partner.partnerPublicKey);

    final _requestTime =
        requestTime ?? DateFormat("yMddhhmmss").format(DateTime.now());
    if (_requestTime.length != 14) {
      print("_requestTime $_requestTime");
    }

    /// show the error if incorrect request time format size
    assert(_requestTime.length == 14);

    final clientService = PaywayPartnerClientService(partner);
    final str = clientService.getStr(
        request_time: _requestTime, request_data: request_data);
    final hash = clientService.getHash(str);

    var map = {
      "request_time": _requestTime.toString(),
      "request_data": request_data.toString(),
      "partner_id": partner.partnerID.toString(),
      "hash": hash.toString(),
    };
    return map;
  }

  /// [generateCheckMerchantFormData]
  ///
  /// allow to pre generate the correct data for form submit when send create request check merchant info
  ///
  Map<String, dynamic> generateCheckMerchantFormData(
      PaywayPartnerCheckMerchant requestData,
      {String? requestTime}) {
    final request_data =
        opensslEncrypt(requestData.toMap(), partner.partnerPublicKey);

    final _requestTime =
        requestTime ?? DateFormat("yMddhhmmss").format(DateTime.now());
    if (_requestTime.length != 14) {
      print("_requestTime $_requestTime");
    }

    /// show the error if incorrect request time format size
    assert(_requestTime.length == 14);

    final clientService = PaywayPartnerClientService(partner);
    final str = clientService.getStr(
        request_time: _requestTime, request_data: request_data);
    final hash = clientService.getHash(str);

    var map = {
      "request_time": _requestTime.toString(),
      "request_data": request_data.toString(),
      "partner_id": partner.partnerID.toString(),
      "hash": hash.toString(),
    };
    return map;
  }

  static String opensslEncrypt(Map<String, dynamic> data, String publickey) {
    final parser = RSAKeyParser();

    final encrypter = Encrypter(RSA(
      publicKey: parser.parse(publickey) as RSAPublicKey,
      digest: RSADigest.SHA256,
    ));
    var codeUnits = json.encode(data).codeUnits;
    List<int> source = utf8.encode(String.fromCharCodes(codeUnits));
    List<int> result = [];

    //Assumes 1024 bit key and encrypts in chunks.
    source.splitByLength(117).forEach((input) {
      var output = encrypter.encryptBytes(input);

      result = [...result, ...output.bytes.toList()];
    });

    return base64.encode(result);
  }

  static Object? opensslDecrypt(String data, String privatekey) {
    final parser = RSAKeyParser();

    final encrypter = Encrypter(RSA(
      privateKey: parser.parse(privatekey) as RSAPrivateKey,
      digest: RSADigest.SHA256,
    ));
    final stringChars = String.fromCharCodes(base64.decode(data));
    List<int> source = stringChars.codeUnits;
    String result = "";

    //Assumes 1024 bit key and encrypts in chunks.
    source.splitByLength(128).forEach((input) {
      var encrypted = Encrypted(Uint8List.fromList(input));
      var output = encrypter.decrypt(encrypted);

      result += output;
    });

    return json.decode(result);
  }
}
