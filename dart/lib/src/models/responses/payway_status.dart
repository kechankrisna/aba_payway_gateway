import 'package:json_annotation/json_annotation.dart';

import '../json_converters.dart';

part 'payway_status.g.dart';

/// The `status` object of PayWay checkout responses.
///
/// Codes differ per API (e.g. `1` or `5` wrong hash, `6` not found); see
/// each API's documentation. Success is `00` (`0` for purchase).
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class PaywayStatus {
  /// status code
  @JsonKey(fromJson: stringFromJson)
  final String code;

  /// human readable status message
  @JsonKey(fromJson: stringFromJson)
  final String message;

  /// transaction id, when PayWay returns one
  @JsonKey(fromJson: nullableStringFromJson)
  final String? tranId;

  /// PayWay log id for debugging, when PayWay returns one
  @JsonKey(fromJson: nullableStringFromJson)
  final String? traceId;

  /// Creates a [PaywayStatus].
  const PaywayStatus({
    required this.code,
    required this.message,
    this.tranId,
    this.traceId,
  });

  /// Whether PayWay answered `00` (or `0`).
  bool get isSuccess => code == '00' || code == '0';

  /// Parses PayWay JSON.
  factory PaywayStatus.fromJson(Map<String, dynamic> json) =>
      _$PaywayStatusFromJson(json);

  /// PayWay's JSON form; absent ids are left out.
  Map<String, dynamic> toJson() => _$PaywayStatusToJson(this);

  @override
  String toString() =>
      'PaywayStatus(code: $code, message: $message, tranId: $tranId, traceId: $traceId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaywayStatus &&
          other.code == code &&
          other.message == message &&
          other.tranId == tranId &&
          other.traceId == traceId;

  @override
  int get hashCode => Object.hash(code, message, tranId, traceId);
}
