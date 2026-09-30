# dart_payway

Dart client for the ABA PayWay **Ecommerce Checkout** API.

| API | Method |
|---|---|
| Purchase (KHQR / ABA Mobile deep link) | `purchase` |
| Purchase on PayWay's hosted page (cards, Alipay, WeChat, ...) | `checkoutHtml` / `checkoutUri` |
| Check transaction | `checkTransaction` |
| Get a transaction details | `getTransactionDetail` |
| Close transaction | `closeTransaction` |
| Get transaction list | `getTransactionList` |
| Refund | `refund` |
| Exchange rate | `getExchangeRates` |
| Verify the payment callback on your `return_url` | `verifyCallback` + `parseCallback` |

## Setup

```dart
import 'package:dart_payway/dart_payway.dart';

final payway = PaywayService(
  merchant: PaywayMerchant(
    merchantId: 'your merchant id',
    apiKey: 'your API key',
    rsaPublicKey: '-----BEGIN PUBLIC KEY-----...', // only needed for refunds
    referer: 'https://your-whitelisted-domain.com',
    baseApiUrl: PaywayMerchant.sandboxBaseUrl, // or PaywayMerchant.productionBaseUrl
  ),
);
```

Call PayWay from **your server**: the API key is a secret, and PayWay only
accepts requests from whitelisted domains or IPs.

## Take a payment

**KHQR / ABA Mobile** returns JSON you can show in your own UI:

```dart
final response = await payway.purchase(PaywayPurchase(
  tranId: 'order-1001', // unique, max 20 characters
  amount: 12.5,
  currency: PaywayCurrency.usd,
  paymentOption: PaywayPaymentOption.abapayKhqrDeeplink,
  items: const [PaywayItem(name: 'Coffee', quantity: 1, price: 12.5)],
  returnUrl: 'https://your-domain.com/payway/callback',
  returnDeeplink: const PaywayReturnDeeplink(
      iosScheme: 'myapp://paid', androidScheme: 'myapp://paid'),
));
if (response.isSuccess) {
  // render response.qrString as a QR code, or open response.abapayDeeplink
}
```

**Every other payment option** opens PayWay's hosted page. `checkoutHtml`
returns a page that POSTs the signed purchase to PayWay; load
`checkoutUri(purchase)` in a web view, or serve the HTML from your site:

```dart
final uri = payway.checkoutUri(PaywayPurchase(
  tranId: 'order-1002',
  amount: 12.5,
  paymentOption: PaywayPaymentOption.cards,
));
```

Values PayWay wants Base64-encoded (items, return URL, deep link, custom
fields, payout, additional params) are given as plain Dart values: the SDK
encodes and signs them.

## Confirm the payment

```dart
final status = await payway.checkTransaction(tranId: 'order-1001');
if (status.isPaid) {
  // deliver the order
}
```

`checkTransaction` covers the last 7 days; use `getTransactionDetail` for
older transactions and for the list of payment and refund operations.

### Callback on your `return_url`

PayWay POSTs the result as JSON with an `X-PayWay-HMAC-SHA512` signature
header. Verify it before trusting it:

```dart
if (!payway.verifyCallback(body: rawBody, signature: headerValue)) {
  return 401;
}
final callback = payway.parseCallback(rawBody);
if (callback.isSuccess) {
  // mark callback.tranId as paid
}
```

## Other operations

```dart
await payway.closeTransaction(tranId: 'order-1001'); // cancel an unpaid payment
await payway.refund(tranId: 'order-1001', amount: 2.5); // needs rsaPublicKey
final page = await payway.getTransactionList(
  query: PaywayTransactionListQuery(
    fromDate: DateTime(2026, 1, 1),
    statuses: [PaywayPaymentStatus.approved],
    pagination: 100,
  ),
);
final rates = await payway.getExchangeRates(); // riel per unit
print(rates.rates['usd']?.sell);
```

## Errors

- PayWay business errors (wrong hash, transaction not found, ...) are
  **returned** in `response.status`; check `response.isSuccess` and
  `response.status.code`.
- `PaywayException` is **thrown** when PayWay could not be reached or did
  not answer with a status, and for a missing RSA key on refunds. Branch on
  `type` (`connection`, `timeout`, `cancelled`, `badCertificate`,
  `unexpectedResponse`, `encryption`, `invalidCallback`, `unknown`);
  `isRetryable` tells whether retrying later may help.

Every call accepts a `CancelToken` (re-exported from `dio`).

## Dependency injection

```dart
final payway = PaywayService(
  merchant: merchant,
  dio: myDio,                  // your HTTP client, used as is and reused
  clock: () => DateTime.now(), // source of req_time (sent in UTC)
  crypto: myCrypto,            // hashing and RSA
  logger: (line) => log(line), // nothing is logged without it
);
```

## Tests

```sh
dart test -x integration
dart test -t integration
```

The first runs the offline tests. Their expected hashes and callback
signatures come from ABA's own PHP samples
(`spec/test-vectors/php_known_answers.php` at the repository root). The second calls the checkout
sandbox and needs a `.env` (copy `.env.example`).

See the `example` folder for a Flutter demo.
