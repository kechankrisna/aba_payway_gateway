import 'dart:convert';
import 'package:dart_payway/dart_payway.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class ABATransaction {
  late ABAMerchant? merchant;
  late String tranID;
  late String reqTime;
  late double? amount;
  List<ABATransactionItem>? items;
  String? firstname;
  String? lastname;
  String? phone;
  String? email;
  String? returnUrl;
  String? continueSuccessUrl;
  String? returnParams;
  double? shipping;
  ABAPaymentOption option;
  ABATransactionType type;
  ABATransactionCurrency currency;

  ABATransaction({
    this.merchant,
    required this.tranID,
    required this.reqTime,
    this.amount,
    this.items,
    this.firstname,
    this.lastname,
    this.phone,
    this.email,
    this.returnUrl,
    this.continueSuccessUrl,
    this.returnParams,
    this.shipping = 0.00,
    this.option = ABAPaymentOption.cards,
    this.type = ABATransactionType.purchase,
    this.currency = ABATransactionCurrency.USD,
  });

  factory ABATransaction.instance(ABAMerchant merchant) {
    // var format = DateFormat("yMddHms").format(DateTime.now()); //2021 01 23 234559 OR 2021 11 07 132947
    final now = DateTime.now();
    return ABATransaction(
      merchant: merchant,
      tranID: "${now.microsecondsSinceEpoch}",
      reqTime: "${DateFormat("yMddHms").format(now)}",
      amount: 0.00,
      items: [],
      firstname: "",
      lastname: "",
      phone: "",
      email: "",
    );
  }

  /// ### [ABATransaction.fromMap]
  factory ABATransaction.fromMap(Map<String, dynamic> map) {
    return ABATransaction(
      merchant: ABAMerchant.fromMap(map),
      tranID: map["tran_id"],
      reqTime: map["req_time"],
      amount: double.tryParse("${map["amount"]}"),
      items: List.from(map['items'] ?? [])
          .map((e) => ABATransactionItem.fromMap(e))
          .toList(),
      firstname: map["firstname"],
      lastname: map["lastname"],
      phone: map["phone"],
      email: map["email"],
      returnUrl: map["return_url"],
      continueSuccessUrl: map["continue_success_url"],
      returnParams: map["return_params"],
      shipping: map["shipping"] ?? 0.00,
      option:
          $ABAPaymentOptionMap[map["payment_option"]] ?? ABAPaymentOption.cards,
      type: $ABATransactionTypeMap[map["type"]] ?? ABATransactionType.purchase,
      currency: $ABATransactionCurrencyMap[map["currency"]] ??
          ABATransactionCurrency.USD,
    );
  }

  double get totalPrice {
    double result = 0;
    this
        .items!
        .fold(result, (dynamic pre, e) => result += e.price! * e.quantity!);
    return result;
  }

  String get encodedReturnUrl => EncoderService.base46_encode(returnUrl);

  String get encodedItem =>
      EncoderService.base46_encode(items!.map((e) => e.toMap()).toList());

  String get hash {
    return ABAClientService(merchant).getHash(
      reqTime: reqTime.toString(),
      tranId: tranID.toString(),
      amount: amount.toString(),
      items: encodedItem.toString(),
      shipping: shipping.toString(),
      firstName: firstname.toString(),
      lastName: lastname.toString(),
      email: email.toString(),
      phone: phone.toString(),
      type: type.name.toString(),
      paymentOption: option.name.toString(),
      currency: currency.name.toString(),
      returnUrl: encodedReturnUrl.toString(),
    );
  }

  /// ### [toMap]
  /// [return] map object
  Map<String, dynamic> toMap() {
    var map = {
      "merchant_id": merchant!.merchantID,
      "req_time": reqTime,
      "tran_id": tranID,
      "amount": amount,
      "items": encodedItem,
      "hash": hash,
      "firstname": firstname,
      "lastname": lastname,
      "phone": phone,
      "email": email,
      "return_url": encodedReturnUrl,
      "continue_success_url": continueSuccessUrl ?? "",
      "return_params": returnParams ?? "",
      "shipping": shipping,
      "type": type.name,
      "payment_option": option.name,
      "currency": currency.name,
    };
    return map;
  }

  Map<String, dynamic> toEncodedMap() {
    var map = {
      "merchant_id": "${merchant!.merchantID}",
      "req_time": reqTime,
      "tran_id": tranID,
      "amount": amount.toString(),
      "items": encodedItem.toString(),
      "hash": hash,
      "firstname": firstname.toString(),
      "lastname": lastname.toString(),
      "phone": phone.toString(),
      "email": email.toString(),
      "return_url": encodedReturnUrl,
      "continue_success_url": continueSuccessUrl ?? "",
      "return_params": returnParams ?? "",
      "shipping": shipping.toString(),
      "type": type.name.toString(),
      "payment_option": option.name.toString(),
      "currency": currency.name.toString(),
    };
    return map;
  }

  /// ## [create]
  /// create a new trasaction
  Future<ABAServerResponse> create() async {
    var res = ABAServerResponse(status: 11);
    Map<String, dynamic> map = this.toEncodedMap();
    map["type"] = "purchase";
    var formData = FormData.fromMap(map);
    try {
      var helper = ABAClientService(merchant);
      var dio = helper.client;
      debugPrint(json.encode(map));
      dio.interceptors.add(dioLoggerInterceptor);
      Response<String> response = await dio.post("/purchase", data: formData);
      // ABAPayment.logger.debug(response);
      var cast = json.decode(response.data!) as Map<String, dynamic>;
      res = ABAServerResponse.fromMap(cast);
      return res;
    } catch (error, stacktrace) {
      print("Exception occured: $error stackTrace: $stacktrace");
      res.description = ABAClientService.handleResponseError(error);
    }
    return ABAServerResponse();
  }

  /// ## [check]
  /// check the current status of this transaction vai its id
  Future<ABAServerResponse> check() async {
    var res = ABAServerResponse(status: 11);
    final _reqTime = reqTime;
    var hash =
        ABAClientService(merchant).getHash(reqTime: _reqTime, tranId: tranID);
    var form = FormData.fromMap({
      "req_time": _reqTime,
      "tran_id": tranID,
      "hash": hash,
      "merchant_id": this.merchant!.merchantID,
    });
    var helper = ABAClientService(merchant);

    try {
      Response<String> response =
          await helper.client.post("/check-transaction", data: form);
      var map = json.decode(response.data!) as Map<String, dynamic>;

      res = ABAServerResponse.fromMap(map);
      return res;
    } catch (error, stacktrace) {
      print("Exception occured: $error stackTrace: $stacktrace");
      res.description = ABAClientService.handleResponseError(error);
    }
    return ABAServerResponse();
  }

  /// ## [validate]
  /// will return true if transaction completed
  /// otherwise false
  Future<bool> validate() async {
    var result = await this.check();
    return (result.status == 0);
  }

  ABATransaction copyWith({
    ABAMerchant? merchant,
    String? tranID,
    String? reqTime,
    double? amount,
    List<ABATransactionItem>? items,
    String? firstname,
    String? lastname,
    String? phone,
    String? email,
    String? returnUrl,
    String? continueSuccessUrl,
    String? returnParams,
    double? shipping,
    ABAPaymentOption? option,
  }) {
    return ABATransaction(
      merchant: merchant ?? this.merchant,
      tranID: tranID ?? this.tranID,
      reqTime: reqTime ?? this.reqTime,
      amount: amount ?? this.amount,
      items: items ?? this.items,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      returnUrl: returnUrl ?? this.returnUrl,
      continueSuccessUrl: continueSuccessUrl ?? this.continueSuccessUrl,
      returnParams: returnParams ?? this.returnParams,
      shipping: shipping ?? this.shipping,
      option: option ?? this.option,
    );
  }

  @override
  String toString() {
    return 'ABATransaction(merchant: $merchant, tranID: $tranID, reqTime: $reqTime, amount: $amount, items: $items, firstname: $firstname, lastname: $lastname, phone: $phone, email: $email, returnUrl: $returnUrl, continueSuccessUrl: $continueSuccessUrl, returnParams: $returnParams, shipping: $shipping, option: $option)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ABATransaction &&
        other.merchant == merchant &&
        other.tranID == tranID &&
        other.reqTime == reqTime &&
        other.amount == amount &&
        listEquals(other.items, items) &&
        other.firstname == firstname &&
        other.lastname == lastname &&
        other.phone == phone &&
        other.email == email &&
        other.returnUrl == returnUrl &&
        other.continueSuccessUrl == continueSuccessUrl &&
        other.returnParams == returnParams &&
        other.shipping == shipping &&
        other.option == option;
  }

  @override
  int get hashCode {
    return merchant.hashCode ^
        tranID.hashCode ^
        reqTime.hashCode ^
        amount.hashCode ^
        items.hashCode ^
        firstname.hashCode ^
        lastname.hashCode ^
        phone.hashCode ^
        email.hashCode ^
        returnUrl.hashCode ^
        continueSuccessUrl.hashCode ^
        returnParams.hashCode ^
        shipping.hashCode ^
        option.hashCode;
  }
}
