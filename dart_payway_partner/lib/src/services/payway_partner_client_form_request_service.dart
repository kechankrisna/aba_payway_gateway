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
  /// ### Example
  ///
  /// `request_time`: 20200211050440
  ///
  /// `request_data`: Uyv+FcEc+QHD3UO/WYhBFH6l02Z0DVTNgrGma8DWXoAGkSxmQUphBFnavaEBDESbg/r+xrE+6aAWtZ+X+MHNMiO3Q8p+y+DDByA+A5V9/UkSs1r4wZ5yRw5wvt9Aqfrr3mqhDJN6EYqtWyxXT3Uk6eJ+Wxi7BHvGOzxbjy1NZ9uSh0hOxJfZ+vljHjr/OldFwYq01Fsq4uuhekZBDYctt7lICf1+rg+g0Mr6YOwBBcTXTdhszMLHlufa3+rM/j4mv3DTR7EODEQLm1zOrPfHM2Yc2Pzlh1kHFMy65gAXYYPTGVxA8v5Y7Zey
  /// fawPgsehWWFsrnIZ87vNg5vSiDrhwUJ62Ep5drEPrXn5rECuyaNBI5iYUDzQrftJP0sXAWbgV6zcdklUzUGA90eg+Fbdd3U6azUhTGGjLTHk5XO4UX8h48JYUzjDg0tPvAH8boHQr/CpKU+XTtvv3ezlcod2s2Iou4ZpmfjTGtkPCTm2KpwkD0hIkEyrD3h6XQY449T/,
  /// 
  /// `partner_id`: /GHeWRMQa2l9H1+TkclWuw==
  /// 
  /// `hash`: 43bde1fdf5b631897172a956c029aa24b57679f75b5ed9a56a10b1b6d799dbb1
  /// 
  Map<String, dynamic> generateRegisterMerchantFormData(
      PaywayPartnerRegisterMerchant requestData,
      {String? requestTime}) {
    var request_data =
        opensslEncrypt(requestData.toMap(), partner.partnerPublicKey);

    final _requestTime =
<<<<<<< HEAD
        requestTime ?? DateFormat("yMMddhhmmss").format(DateTime.now());
=======
        requestTime ?? DateFormat("yyyyMMddHHmmss").format(DateTime.now());
>>>>>>> 771ba39 (fixed: date format)
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
  /// ### Example
  ///
  /// `request_time`: 20200211050440
  ///
  /// `request_data`: a/lHnhQ9Sa4zf9feh9TeVUExcEPiztzyjZd0aoWay+98lPXgNRbDBt42qi4wy2wGIPKWTif4Ha6kkrrmhDq5tVtdADCjP0DOJFassV4cehXuZHfWuFXXUymmCFk0n+C26YliIDLEv0y03t7bRHusBi6YbW/O05pyIk5LOVi0ybA=
  ///
  /// `partner_id`: /GHeWRMQa2l9H1+TkclWuw==
  /// 
  /// `hash`: 43bde1fdf5b631897172a956c029aa24b57679f75b5ed9a56a10b1b6d799dbb1
  /// 
  Map<String, dynamic> generateCheckMerchantFormData(
      PaywayPartnerCheckMerchant requestData,
      {String? requestTime}) {
    final request_data =
        opensslEncrypt(requestData.toMap(), partner.partnerPublicKey);

    final _requestTime =
<<<<<<< HEAD
        requestTime ?? DateFormat("yMMddhhmmss").format(DateTime.now());
=======
        requestTime ?? DateFormat("yyyyMMddHHmmss").format(DateTime.now());
>>>>>>> 771ba39 (fixed: date format)
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
