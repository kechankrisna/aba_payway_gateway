# flutter_payway

Flutter widgets for ABA PayWay checkout, built on
[`dart_payway`](https://pub.dev/packages/dart_payway), which it re-exports.

```yaml
dependencies:
  flutter_payway: ^2.0.0
```

## Payment method picker

`PaywayAcceptablePaymentColumn` lists payment methods with their logos. By
default it offers cards plus ABA PAY: a KHQR to scan on web and desktop, or
a deep link into ABA Mobile on Android and iOS.

```dart
import 'package:flutter_payway/flutter_payway.dart';

PaywayAcceptablePaymentColumn(
  value: option,
  onChanged: (value) => setState(() => option = value),
  // optional
  options: const [PaywayPaymentOption.cards, PaywayPaymentOption.abapayKhqrDeeplink],
  labels: const PaywayPaymentLabels(cards: 'កាត'),
)
```

## Paying

Call PayWay from **your server**, not from the app: the API key is a secret
and must not ship inside an app. Your server uses `dart_payway` (or the PHP
SDK) to create the purchase and returns the result to the app:

- `abapayKhqrDeeplink`: open `abapayDeeplink` with `url_launcher`, or show
  `qrString` as a QR code.
- other options: load the page from `checkoutHtml()` in a web view.

Then confirm the payment on your server with `checkTransaction` or the
callback on your `return_url`. See the
[`dart_payway` README](https://pub.dev/packages/dart_payway).
