import 'package:intl/intl.dart';

class PaywayCheckTransaction {
  final String tranId;
  final String reqTime;

  PaywayCheckTransaction({
    required this.tranId,
    required this.reqTime,
  });

  factory PaywayCheckTransaction.instance() {
    // var format = DateFormat("yMddHms").format(DateTime.now()); //2021 01 23 234559 OR 2021 11 07 132947
    final now = DateTime.now();
    return PaywayCheckTransaction(
      /// merchant: merchant,
      tranId: "${now.microsecondsSinceEpoch}",
      reqTime: "${DateFormat("yMddHms").format(now)}",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tran_id': tranId,
      'req_time': reqTime,
    };
  }

  factory PaywayCheckTransaction.fromMap(Map<String, dynamic> map) {
    return PaywayCheckTransaction(
      tranId: map['tran_id'] ?? '',
      reqTime: map['req_time'] ?? '',
    );
  }

  PaywayCheckTransaction copyWith({
    String? tranId,
    String? reqTime,
  }) {
    return PaywayCheckTransaction(
      tranId: tranId ?? this.tranId,
      reqTime: reqTime ?? this.reqTime,
    );
  }

  @override
  String toString() =>
      'PaywayCheckTransaction(tranId: $tranId, reqTime: $reqTime)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PaywayCheckTransaction &&
        other.tranId == tranId &&
        other.reqTime == reqTime;
  }

  @override
  int get hashCode => tranId.hashCode ^ reqTime.hashCode;
}
