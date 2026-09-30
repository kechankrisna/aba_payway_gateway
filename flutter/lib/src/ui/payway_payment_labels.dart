import 'package:flutter/foundation.dart';

/// Texts shown by `PaywayAcceptablePaymentColumn`. Pass your own to
/// translate them.
@immutable
class PaywayPaymentLabels {
  /// Creates labels; every text defaults to English.
  const PaywayPaymentLabels({
    this.cards = 'Credit/Debit Card',
    this.abapayKhqr = 'ABA KHQR',
    this.abapayKhqrSubtitle =
        'Scan to pay with ABA Mobile or any KHQR banking app',
    this.abapayKhqrDeeplink = 'ABA PAY',
    this.abapayKhqrDeeplinkSubtitle = 'Tap to pay with ABA Mobile',
    this.alipay = 'Alipay',
    this.wechat = 'WeChat Pay',
    this.googlePay = 'Google Pay',
  });

  /// title of [PaywayPaymentOption.cards]
  final String cards;

  /// title of [PaywayPaymentOption.abapayKhqr]
  final String abapayKhqr;

  /// subtitle of [PaywayPaymentOption.abapayKhqr]
  final String abapayKhqrSubtitle;

  /// title of [PaywayPaymentOption.abapayKhqrDeeplink]
  final String abapayKhqrDeeplink;

  /// subtitle of [PaywayPaymentOption.abapayKhqrDeeplink]
  final String abapayKhqrDeeplinkSubtitle;

  /// title of [PaywayPaymentOption.alipay]
  final String alipay;

  /// title of [PaywayPaymentOption.wechat]
  final String wechat;

  /// title of [PaywayPaymentOption.googlePay]
  final String googlePay;
}
