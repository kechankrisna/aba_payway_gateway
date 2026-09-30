import '../payway_enums.dart';

/// Filters of `transaction-list`; every field is optional.
class PaywayTransactionListQuery {
  /// start of the period (`YYYY-MM-DD HH:mm:ss`); PayWay's default is today
  /// at 00:00:00. Sent as given, without time zone conversion.
  final DateTime? fromDate;

  /// end of the period (`YYYY-MM-DD HH:mm:ss`); PayWay's default is now
  final DateTime? toDate;

  /// minimum amount
  final num? fromAmount;

  /// maximum amount
  final num? toAmount;

  /// statuses to include
  final List<PaywayPaymentStatus> statuses;

  /// page number
  final int? page;

  /// records per page; PayWay's default is 40, maximum 1000
  final int? pagination;

  /// Creates a [PaywayTransactionListQuery].
  const PaywayTransactionListQuery({
    this.fromDate,
    this.toDate,
    this.fromAmount,
    this.toAmount,
    this.statuses = const [],
    this.page,
    this.pagination,
  });
}
