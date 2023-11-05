import 'package:dart_payway/dart_payway.dart';

class PaywayCheckTransactionResponse {
  final int status;
  final String description;
  final double amount;
  final double? totalAmount;
  final String apv;
  final String paymentStatus;
  final DateTime? datetime;

  ///
  final PaywayTransactionCurrency? originalCurrency;
  final List<Map<dynamic, dynamic>>? payout;

  final String? tranId;
  final String? firstname;
  final String? lastname;
  final String? phone;
  final String? email;
  final String? paymentType;
  PaywayCheckTransactionResponse({
    this.status = 11,
    this.description = "Unknown Error",
    this.amount = 0.00,
    this.totalAmount,
    this.apv = "",
    this.paymentStatus = "Pending",
    this.datetime,
    this.originalCurrency,
    this.payout,
    this.tranId,
    this.firstname,
    this.lastname,
    this.phone,
    this.email,
    this.paymentType,
  });

  String get message =>
      PaywayCheckTransactionResponseMessage.of(status).message;

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'description': description,
      'amount': amount,
      'total_amount': totalAmount,
      'apv': apv,
      'payment_status': paymentStatus,
      'datetime': datetime?.millisecondsSinceEpoch,
      'original_currency': originalCurrency!.name,
      'payout': payout?.map((x) => x).toList(),
      'tran_id': tranId,
      'firstname': firstname,
      'lastname': lastname,
      'phone': phone,
      'email': email,
      'payment_type': paymentType,
    };
  }

  factory PaywayCheckTransactionResponse.fromMap(Map<String, dynamic> map) {
    return PaywayCheckTransactionResponse(
      status: map['status']?.toInt() ?? -1,
      description: map['description'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      totalAmount: map['total_amount']?.toDouble(),
      apv: map['apv'] ?? '',
      paymentStatus: map['payment_status'] ?? '',
      datetime:
          map['datetime'] == null ? null : DateTime.tryParse(map['datetime']),
      originalCurrency: $PaywayTransactionCurrencyMap[map['original_currency']],
      payout: map['payout'] != null
          ? List<Map<dynamic, dynamic>>.from(map['payout'])
          : null,
      tranId: map['tran_id'],
      firstname: map['firstname'],
      lastname: map['lastname'],
      phone: map['phone'],
      email: map['email'],
      paymentType: map['payment_type'],
    );
  }

  PaywayCheckTransactionResponse copyWith({
    int? status,
    String? description,
    double? amount,
    double? totalAmount,
    String? apv,
    String? paymentStatus,
    DateTime? datetime,
    PaywayTransactionCurrency? originalCurrency,
    List<Map<dynamic, dynamic>>? payout,
    String? tranId,
    String? firstname,
    String? lastname,
    String? phone,
    String? email,
    String? paymentType,
  }) {
    return PaywayCheckTransactionResponse(
      status: status ?? this.status,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      totalAmount: totalAmount ?? this.totalAmount,
      apv: apv ?? this.apv,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      datetime: datetime ?? this.datetime,
      originalCurrency: originalCurrency ?? this.originalCurrency,
      payout: payout ?? this.payout,
      tranId: tranId ?? this.tranId,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      paymentType: paymentType ?? this.paymentType,
    );
  }

  @override
  String toString() {
    return 'PaywayCheckTransactionResponse(status: $status, description: $description, amount: $amount, totalAmount: $totalAmount, apv: $apv, paymentStatus: $paymentStatus, datetime: $datetime, originalCurrency: $originalCurrency, payout: $payout, tranId: $tranId, firstname: $firstname, lastname: $lastname, phone: $phone, email: $email, paymentType: $paymentType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PaywayCheckTransactionResponse &&
        other.status == status &&
        other.description == description &&
        other.amount == amount &&
        other.totalAmount == totalAmount &&
        other.apv == apv &&
        other.paymentStatus == paymentStatus &&
        other.datetime == datetime &&
        other.originalCurrency == originalCurrency &&
        listEquals(other.payout, payout) &&
        other.tranId == tranId &&
        other.firstname == firstname &&
        other.lastname == lastname &&
        other.phone == phone &&
        other.email == email &&
        other.paymentType == paymentType;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        description.hashCode ^
        amount.hashCode ^
        totalAmount.hashCode ^
        apv.hashCode ^
        paymentStatus.hashCode ^
        datetime.hashCode ^
        originalCurrency.hashCode ^
        payout.hashCode ^
        tranId.hashCode ^
        firstname.hashCode ^
        lastname.hashCode ^
        phone.hashCode ^
        email.hashCode ^
        paymentType.hashCode;
  }
}

class PaywayCheckTransactionResponseMessage {
  int value;

  PaywayCheckTransactionResponseMessage._(this.value);

  factory PaywayCheckTransactionResponseMessage.of(int value) =>
      PaywayCheckTransactionResponseMessage._(value);

  String get message {
    switch (value) {
      case 0:
        return "Approved, PRE_AUTH, PREAUTH_APPROVED";
      case 1:
        return "Created";
      case 2:
        return "Pending";
      case 3:
        return "Declined";
      case 4:
        return "Refunded";
      case 5:
        return "Wrong Hash";
      case 6:
        return "tran_id not Found";
      case 11:
        return " Other Server side Error";

      default:
    }
    return "Unknown Error!";
  }
}
