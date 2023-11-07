import 'dart:convert';

import 'package:dart_payway_partner/dart_payway_partner.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class PaywayPartnerService {
  late PaywayPartner partner;

  PaywayPartnerService({required this.partner});

  PaywayPartnerClientService get helper => PaywayPartnerClientService(partner);

  /// ## [registerMerchant]
  ///
  /// register a new merchant
  ///
  /// `merchant` : this information must be field in correctly
  ///
  /// Usage:
  ///
  /// ```dart
  /// final merchant = PaywayPartnerRegisterMerchant(
  ///   pushback_url: 'https://www.mylekha.org/',
  ///   redirect_url: 'https://www.mylekha.org/',
  ///   type: 0,
  ///   register_ref: "Merchant003",
  /// );
  /// var registerResponse = await service.registerMerchant(merchant: merchant);
  /// ```
  Future<PaywayPartnerRegisterMerchantResponse> registerMerchant({
    required PaywayPartnerRegisterMerchant merchant,
    bool enabledLogger = false,
  }) async {
    var res = PaywayPartnerRegisterMerchantResponse(
        url: "",
        token: "",
        status: PaywayPartnerRegisterMerchantResponseStatus(
            code: "PTL06", message: "The Request is Expired"));
    final clientService =
        PaywayPartnerClientFormRequestService(partner: partner);
    Map<String, dynamic> map =
        clientService.generateRegisterMerchantFormData(merchant);

    var formData = FormData.fromMap(map);
    try {
      final client = helper.client;

      if (enabledLogger) {
        debugPrint(json.encode(map));
        client.interceptors.add(dioLoggerInterceptor);
      }

      Response<String> response =
          await client.post("/api/merchant-portal/online-self-activation/new-merchant", data: formData);

      var _map = json.decode(response.data!) as Map<String, dynamic>;
      res = PaywayPartnerRegisterMerchantResponse.fromMap(_map);
    } catch (error, stacktrace) {
      if (enabledLogger) {
        debugPrint("Exception occured: $error stackTrace: $stacktrace");
      }

      res = res.copyWith(
          status: res.status.copyWith(
              code: "PTL46",
              message: PaywayPartnerClientService.handleResponseError(error)));
    }
    return res;
  }

  /// ## [checkMerchant]
  ///
  /// register a new merchant
  ///
  /// `merchant` : this information must be field in correctly
  ///
  /// Usage:
  ///
  /// ```dart
  /// final merchant = PaywayPartnerCheckMerchant(
  ///   register_ref: "Merchant003",
  /// );
  /// var checkResponse = await service.checkMerchant(merchant: merchant);
  /// ```
  Future<PaywayPartnerCheckMerchantResponse> checkMerchant({
    required PaywayPartnerCheckMerchant merchant,
    bool enabledLogger = false,
  }) async {
    var res = PaywayPartnerCheckMerchantResponse(
        data: "",
        status: PaywayPartnerCheckMerchantResponseStatus(
            code: "PTL46", message: "Merchant not found"));
    final clientService =
        PaywayPartnerClientFormRequestService(partner: partner);
    Map<String, dynamic> map =
        clientService.generateCheckMerchantFormData(merchant);

    var formData = FormData.fromMap(map);
    try {
      final client = helper.client;

      if (enabledLogger) {
        debugPrint(json.encode(map));
        client.interceptors.add(dioLoggerInterceptor);
      }

      Response<String> response =
          await client.post("/api/merchant-portal/online-self-activation/get-mc-credential-info", data: formData);

      var _map = json.decode(response.data!) as Map<String, dynamic>;
      res = PaywayPartnerCheckMerchantResponse.fromMap(_map);
    } catch (error, stacktrace) {
      if (enabledLogger) {
        debugPrint("Exception occured: $error stackTrace: $stacktrace");
      }

      res = res.copyWith(
          status: res.status.copyWith(
              code: "PTL46",
              message: PaywayPartnerClientService.handleResponseError(error)));
    }
    return res;
  }
}
