import 'package:intl/intl.dart';
import 'package:dart_payway/dart_payway.dart';

class PaywayCreateTransaction {
  final String tranId;
  final String reqTime;
  final double amount;
  final List<PaywayTransactionItem> items;
  final String firstname;
  final String lastname;
  final String phone;
  final String email;
  final String? returnUrl;
  final String? continueSuccessUrl;
  final String? returnParams;
  final double? shipping;
  ABAPaymentOption option;
  ABATransactionType type;
  ABATransactionCurrency currency;

  PaywayCreateTransaction({
    required this.tranId,
    required this.reqTime,
    required this.amount,
    required this.items,
    required this.firstname,
    required this.lastname,
    required this.phone,
    required this.email,
    this.returnUrl,
    this.continueSuccessUrl,
    this.returnParams,
    this.shipping,
    this.option = ABAPaymentOption.cards,
    this.type = ABATransactionType.purchase,
    this.currency = ABATransactionCurrency.USD,
  });

  factory PaywayCreateTransaction.instance() {
    // var format = DateFormat("yMddHms").format(DateTime.now()); //2021 01 23 234559 OR 2021 11 07 132947
    final now = DateTime.now();
    return PaywayCreateTransaction(
      /// merchant: merchant,
      tranId: "${now.microsecondsSinceEpoch}",
      reqTime: "${DateFormat("yMddHms").format(now)}",
      amount: 0.00,
      items: [],
      firstname: "",
      lastname: "",
      phone: "",
      email: "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tran_id': tranId,
      'req_time': reqTime,
      'amount': amount,
      'items': items.map((x) => x.toMap()).toList(),
      'firstname': firstname,
      'lastname': lastname,
      'phone': phone,
      'email': email,
      'return_url': returnUrl ?? '',
      'continue_success_url': continueSuccessUrl ?? '',
      'return_params': returnParams ?? '',
      'shipping': shipping,
      'type': type.name,
      'payment_option': option.name,
      'currency': currency.name,
    };
  }

  factory PaywayCreateTransaction.fromMap(Map<String, dynamic> map) {
    return PaywayCreateTransaction(
      tranId: map['tran_id'] ?? '',
      reqTime: map['req_time'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      items: List<PaywayTransactionItem>.from(
          map['items']?.map((x) => PaywayTransactionItem.fromMap(x))),
      firstname: map['firstname'] ?? '',
      lastname: map['lastname'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      returnUrl: map['return_url'],
      continueSuccessUrl: map['continue_success_url'] ?? '',
      returnParams: map['return_params'],
      shipping: map['shipping']?.toDouble(),
      option:
          $ABAPaymentOptionMap[map["payment_option"]] ?? ABAPaymentOption.cards,
      type: $ABATransactionTypeMap[map["type"]] ?? ABATransactionType.purchase,
      currency: $ABATransactionCurrencyMap[map["currency"]] ??
          ABATransactionCurrency.USD,
    );
  }

  PaywayCreateTransaction copyWith({
    String? tranId,
    String? reqTime,
    double? amount,
    List<PaywayTransactionItem>? items,
    String? firstname,
    String? lastname,
    String? phone,
    String? email,
    String? returnUrl,
    String? continueSuccessUrl,
    String? returnParams,
    double? shipping,
    ABAPaymentOption? option,
    ABATransactionType? type,
    ABATransactionCurrency? currency,
  }) {
    return PaywayCreateTransaction(
      tranId: tranId ?? this.tranId,
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
      type: type ?? this.type,
      currency: currency ?? this.currency,
    );
  }

  @override
  String toString() {
    return 'PaywayTransaction(tranId: $tranId, reqTime: $reqTime, amount: $amount, items: $items, firstname: $firstname, lastname: $lastname, phone: $phone, email: $email, returnUrl: $returnUrl, continueSuccessUrl: $continueSuccessUrl, returnParams: $returnParams, shipping: $shipping, option: $option, type: $type, currency: $currency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PaywayCreateTransaction &&
        other.tranId == tranId &&
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
        other.option == option &&
        other.type == type &&
        other.currency == currency;
  }

  @override
  int get hashCode {
    return tranId.hashCode ^
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
        option.hashCode ^
        type.hashCode ^
        currency.hashCode;
  }
}
