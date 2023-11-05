import 'enumeration.dart';

extension AcceptPaymentOptionParsing on PaywayPaymentOption {
  /// [toText] convert this enumber to text
  String get toText => toString().split(".").last;
}

extension PaywayStringParsing on String {
  /// [fromText] conver text to enum AcceptPaymentOption
  PaywayPaymentOption get toAcceptPaymentOption {
    switch (this) {
      case "cards":
        return PaywayPaymentOption.cards;
      case "abapay":
        return PaywayPaymentOption.abapay;
      case "abapay_deeplink":
        return PaywayPaymentOption.abapay_deeplink;
      default:
        return PaywayPaymentOption.cards;
    }
  }
}
