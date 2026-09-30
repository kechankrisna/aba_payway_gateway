import '../payway_enums.dart';
import 'payway_item.dart';
import 'payway_payout.dart';
import 'payway_return_deeplink.dart';

/// Request of `purchase`. Only [tranId] and [amount] are required; every
/// other field is sent only when set.
///
/// Values PayWay wants Base64-encoded (items, return URL, deep link, custom
/// fields, payout, additional params) are given as plain Dart values: the
/// SDK encodes them.
class PaywayPurchase {
  /// your unique transaction id, max 20 characters
  final String tranId;

  /// purchase amount
  final num amount;

  /// item descriptions (up to 50); not used for calculation
  final List<PaywayItem> items;

  /// shipping fee
  final num? shipping;

  /// payer first name
  final String? firstName;

  /// payer last name
  final String? lastName;

  /// payer email
  final String? email;

  /// payer phone
  final String? phone;

  /// [PaywayTransactionType.purchase] (PayWay's default) or
  /// [PaywayTransactionType.preAuth]
  final PaywayTransactionType? type;

  /// payment method; when unset PayWay lets the payer choose
  final PaywayPaymentOption? paymentOption;

  /// PayWay POSTs the payment result here (sent Base64-encoded)
  final String? returnUrl;

  /// where to go when the payer closes or cancels the payment
  final String? cancelUrl;

  /// where to go after the success page
  final String? continueSuccessUrl;

  /// deep links back to your app after paying in ABA Mobile
  final PaywayReturnDeeplink? returnDeeplink;

  /// [PaywayCurrency.usd] or [PaywayCurrency.khr]; default from your profile
  final PaywayCurrency? currency;

  /// extra data shown in the transaction list, details and reports
  final Map<String, Object?>? customFields;

  /// returned as is in the callback to [returnUrl]
  final String? returnParams;

  /// split of the amount to ABA accounts
  final List<PaywayPayout>? payout;

  /// payment lifetime in minutes (3 minutes to 30 days)
  final int? lifetime;

  /// extra parameters, e.g. `wechat_sub_appid` / `wechat_sub_openid`
  final Map<String, Object?>? additionalParams;

  /// Google Pay token, when the merchant handles the payment selection
  final String? googlePayToken;

  /// skip PayWay's success page; overrides the profile setting
  final bool? skipSuccessPage;

  /// how the hosted payment page is shown
  final PaywayViewType? viewType;

  /// set `0` when your profile also has the QR Payment API, to use checkout
  final int? paymentGate;

  /// Creates a [PaywayPurchase].
  const PaywayPurchase({
    required this.tranId,
    required this.amount,
    this.items = const [],
    this.shipping,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.type,
    this.paymentOption,
    this.returnUrl,
    this.cancelUrl,
    this.continueSuccessUrl,
    this.returnDeeplink,
    this.currency,
    this.customFields,
    this.returnParams,
    this.payout,
    this.lifetime,
    this.additionalParams,
    this.googlePayToken,
    this.skipSuccessPage,
    this.viewType,
    this.paymentGate,
  });

  @override
  String toString() =>
      'PaywayPurchase(tranId: $tranId, amount: $amount, currency: ${currency?.value}, paymentOption: ${paymentOption?.value})';
}
