import 'enumeration.dart';

extension AcceptPaymentOptionParsing on ABAPaymentOption {
  /// [toText] convert this enumber to text
  String get toText => toString().split(".").last;
}

extension StringParsing on String {
  /// [fromText] conver text to enum AcceptPaymentOption
  ABAPaymentOption get toAcceptPaymentOption {
    switch (this) {
      case "cards":
        return ABAPaymentOption.cards;
      case "abapay":
        return ABAPaymentOption.abapay;
      case "abapay_deeplink":
        return ABAPaymentOption.abapay_deeplink;
      default:
        return ABAPaymentOption.cards;
    }
  }
}
