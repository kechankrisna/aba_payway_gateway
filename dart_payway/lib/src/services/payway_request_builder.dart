import 'dart:convert';

import '../models/payway_merchant.dart';
import '../models/requests/payway_purchase.dart';
import '../models/requests/payway_transaction_list_query.dart';
import 'payway_crypto.dart';

/// returns the current time; injectable so `req_time` can be tested
typedef PaywayClock = DateTime Function();

/// Builds the signed request bodies of the PayWay checkout APIs.
///
/// Every hash is `base64(HMAC-SHA512(values..., api_key))` over the values
/// in the order the docs list them; absent optional values count as empty.
class PaywayRequestBuilder {
  /// merchant credentials used to sign
  final PaywayMerchant merchant;

  /// source of `req_time`
  final PaywayClock clock;

  /// hashing and encryption
  final PaywayCrypto crypto;

  /// Creates a builder for [merchant]; [clock] defaults to `DateTime.now`.
  PaywayRequestBuilder({
    required this.merchant,
    PaywayClock? clock,
    this.crypto = const PaywayCrypto(),
  }) : clock = clock ?? DateTime.now;

  /// Form fields of `purchase`, in PayWay's order, with `hash`.
  Map<String, String> purchase(PaywayPurchase p, {String? requestTime}) {
    final time = _requestTime(requestTime);
    String? b64Json(Object? value) =>
        value == null ? null : base64.encode(utf8.encode(json.encode(value)));

    // hashed, in the documented order
    final hashed = <String, String?>{
      'req_time': time,
      'merchant_id': merchant.merchantId,
      'tran_id': p.tranId,
      'amount': formatAmount(p.amount),
      'items': p.items.isEmpty
          ? null
          : b64Json([for (final item in p.items) item.toJson()]),
      'shipping': p.shipping == null ? null : formatAmount(p.shipping!),
      'firstname': p.firstName,
      'lastname': p.lastName,
      'email': p.email,
      'phone': p.phone,
      'type': p.type?.value,
      'payment_option': p.paymentOption?.value,
      'return_url': p.returnUrl == null
          ? null
          : base64.encode(utf8.encode(p.returnUrl!)),
      'cancel_url': p.cancelUrl,
      'continue_success_url': p.continueSuccessUrl,
      'return_deeplink': b64Json(p.returnDeeplink?.toJson()),
      'currency': p.currency?.value,
      'custom_fields': b64Json(p.customFields),
      'return_params': p.returnParams,
      'payout': p.payout == null
          ? null
          : b64Json([for (final payout in p.payout!) payout.toJson()]),
      'lifetime': p.lifetime?.toString(),
      'additional_params': b64Json(p.additionalParams),
      'google_pay_token': p.googlePayToken,
      'skip_success_page': p.skipSuccessPage == null
          ? null
          : (p.skipSuccessPage! ? '1' : '0'),
    };
    // sent but not part of the hash
    final unhashed = <String, String?>{
      'view_type': p.viewType?.value,
      'payment_gate': p.paymentGate?.toString(),
    };
    return {
      for (final e in hashed.entries)
        if (e.value != null) e.key: e.value!,
      for (final e in unhashed.entries)
        if (e.value != null) e.key: e.value!,
      'hash': sign(hashed.values),
    };
  }

  /// Body of `check-transaction-2`.
  Map<String, String> checkTransaction(String tranId, {String? requestTime}) =>
      _tranIdBody(tranId, requestTime);

  /// Body of `transaction-detail`.
  Map<String, String> transactionDetail(String tranId, {String? requestTime}) =>
      _tranIdBody(tranId, requestTime);

  /// Body of `close-transaction`.
  Map<String, String> closeTransaction(String tranId, {String? requestTime}) =>
      _tranIdBody(tranId, requestTime);

  /// Body of `transaction-list-2`.
  Map<String, String> transactionList(
    PaywayTransactionListQuery q, {
    String? requestTime,
  }) {
    final time = _requestTime(requestTime);
    final hashed = <String, String?>{
      'req_time': time,
      'merchant_id': merchant.merchantId,
      'from_date': q.fromDate == null ? null : formatDate(q.fromDate!),
      'to_date': q.toDate == null ? null : formatDate(q.toDate!),
      'from_amount': q.fromAmount == null ? null : formatAmount(q.fromAmount!),
      'to_amount': q.toAmount == null ? null : formatAmount(q.toAmount!),
      'status': q.statuses.isEmpty
          ? null
          : q.statuses.map((s) => s.value).join(','),
      'page': q.page?.toString(),
      'pagination': q.pagination?.toString(),
    };
    return {
      for (final e in hashed.entries)
        if (e.value != null) e.key: e.value!,
      'hash': sign(hashed.values),
    };
  }

  /// Body of `exchange-rate`.
  Map<String, String> exchangeRate({String? requestTime}) {
    final time = _requestTime(requestTime);
    return {
      'req_time': time,
      'merchant_id': merchant.merchantId,
      'hash': sign([time, merchant.merchantId]),
    };
  }

  /// Body of `refund`. `merchant_auth` is the RSA-encrypted
  /// `{"mc_id", "tran_id", "refund_amount"}`, which needs the merchant's
  /// RSA public key.
  Map<String, String> refund(
    String tranId,
    num refundAmount, {
    String? requestTime,
  }) {
    final rsaKey = merchant.rsaPublicKey;
    if (rsaKey == null || rsaKey.isEmpty) {
      throw ArgumentError.value(
        null,
        'merchant.rsaPublicKey',
        'refunds need the RSA public key provided by ABA',
      );
    }
    final time = _requestTime(requestTime);
    final merchantAuth = crypto.rsaEncrypt(
      json.encode({
        'mc_id': merchant.merchantId,
        'tran_id': tranId,
        'refund_amount': refundAmount,
      }),
      rsaKey,
    );
    return {
      'request_time': time,
      'merchant_id': merchant.merchantId,
      'merchant_auth': merchantAuth,
      'hash': sign([time, merchant.merchantId, merchantAuth]),
    };
  }

  /// `base64(HMAC-SHA512(concatenated values, api_key))`; null counts as empty
  String sign(Iterable<String?> values) => crypto.hmacSha512Base64(
    values.map((v) => v ?? '').join(),
    merchant.apiKey,
  );

  Map<String, String> _tranIdBody(String tranId, String? requestTime) {
    final time = _requestTime(requestTime);
    return {
      'req_time': time,
      'merchant_id': merchant.merchantId,
      'tran_id': tranId,
      'hash': sign([time, merchant.merchantId, tranId]),
    };
  }

  String _requestTime(String? requestTime) {
    final time = requestTime ?? formatRequestTime(clock());
    if (!RegExp(r'^\d{14}$').hasMatch(time)) {
      throw ArgumentError.value(
        time,
        'requestTime',
        'must be 14 digits: YYYYMMDDHHmmss',
      );
    }
    return time;
  }

  /// `YYYYMMDDHHmmss` in UTC, as PayWay requires
  static String formatRequestTime(DateTime time) {
    final utc = time.toUtc();
    return '${_pad(utc.year, 4)}${_pad(utc.month)}${_pad(utc.day)}'
        '${_pad(utc.hour)}${_pad(utc.minute)}${_pad(utc.second)}';
  }

  /// `YYYY-MM-DD HH:mm:ss`, as given (no time zone conversion)
  static String formatDate(DateTime time) =>
      '${_pad(time.year, 4)}-${_pad(time.month)}-${_pad(time.day)} '
      '${_pad(time.hour)}:${_pad(time.minute)}:${_pad(time.second)}';

  /// amounts without a trailing `.0`: `6` stays `6`, `6.5` stays `6.5`
  static String formatAmount(num amount) =>
      amount == amount.truncateToDouble() && amount.abs() < 1e15
      ? amount.toInt().toString()
      : amount.toString();

  static String _pad(int value, [int width = 2]) =>
      value.toString().padLeft(width, '0');
}
