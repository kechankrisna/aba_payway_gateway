/// Payment method of a purchase (`payment_option`).
enum PaywayPaymentOption {
  /// card payment
  cards('cards'),

  /// QR code payable with ABA PAY and other KHQR member banks
  abapayKhqr('abapay_khqr'),

  /// ABA PAY / KHQR for apps: the purchase API answers with JSON holding
  /// `qr_string`, `abapay_deeplink` and `checkout_qr_url`
  abapayKhqrDeeplink('abapay_khqr_deeplink'),

  /// Alipay wallet
  alipay('alipay'),

  /// WeChat Pay wallet
  wechat('wechat'),

  /// Google Pay wallet; needs a `googlePayToken` when the merchant handles
  /// the payment selection
  googlePay('google_pay');

  const PaywayPaymentOption(this.value);

  /// the value sent to PayWay
  final String value;
}

/// Type of a purchase (`type`).
enum PaywayTransactionType {
  /// full purchase (PayWay's default)
  purchase('purchase'),

  /// pre-authorization hold, captured later; ABA PAY, KHQR and cards only
  preAuth('pre-auth');

  const PaywayTransactionType(this.value);

  /// the value sent to PayWay
  final String value;
}

/// Currency of a purchase.
enum PaywayCurrency {
  /// US dollar
  usd('USD'),

  /// Cambodian riel
  khr('KHR');

  const PaywayCurrency(this.value);

  /// the value sent to PayWay
  final String value;
}

/// How the hosted payment page is shown (`view_type`).
enum PaywayViewType {
  /// redirect the payer to a new tab
  hostedView('hosted_view'),

  /// bottom sheet on mobile browsers, modal popup on desktop browsers
  popup('popup');

  const PaywayViewType(this.value);

  /// the value sent to PayWay
  final String value;
}

/// Transaction status filter of the transaction list (`status`).
enum PaywayPaymentStatus {
  /// paid with the full purchase amount
  approved('APPROVED'),

  /// funds held by a pre-authorization, pending capture
  preAuth('PRE-AUTH'),

  /// fully or partially refunded
  refunded('REFUNDED'),

  /// awaiting payment by the payer
  pending('PENDING'),

  /// declined (spelled as in PayWay's API)
  declined('DECLINDED'),

  /// cancelled
  cancelled('CANCELLED');

  const PaywayPaymentStatus(this.value);

  /// the value sent to PayWay
  final String value;
}

/// `payment_status_code` values of transaction details, status and list.
abstract final class PaywayPaymentStatusCode {
  /// `0` APPROVED or PRE-AUTH
  static const int approved = 0;

  /// `2` PENDING
  static const int pending = 2;

  /// `3` DECLINED
  static const int declined = 3;

  /// `4` REFUNDED
  static const int refunded = 4;

  /// `7` CANCELLED
  static const int cancelled = 7;
}
