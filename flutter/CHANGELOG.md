## 2.0.0

- Built on `dart_payway` 2.0.0; see its changelog for the new API
  (`PaywayService`, `PaywayPurchase`, ...).
- `PaywayAcceptablePaymentColumn`:
  - takes the `dart_payway` 2.0.0 `PaywayPaymentOption` (`abapayKhqr`,
    `abapayKhqrDeeplink`, ...);
  - offers cards plus ABA KHQR on web and desktop, or the ABA Mobile deep
    link on phones; pass `options` to choose others (Alipay, WeChat Pay,
    Google Pay);
  - texts can be translated with `labels: PaywayPaymentLabels(...)`;
  - `onChanged` is a `ValueChanged<PaywayPaymentOption>`, and a new `value`
    from the parent is followed;
  - works on the web (no `dart:io`).
- Requires Flutter 3.35 / Dart 3.9.

## 1.1.0+2
- add support dart_payway: ^1.1.0+2
- add support payment_type abapway_khqr

## 1.1.0+1
- add support intl > 0.20.0 for flutter_payway and dart_payway

## 0.0.1+1

- add support dart_payway: ^1.0.8+3

## 0.0.1

- Initial version.
