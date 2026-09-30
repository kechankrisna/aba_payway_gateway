# php_payway

PHP client for the ABA PayWay **Ecommerce Checkout** API. It is the PHP twin of
[`dart_payway`](../dart): both are checked against the same known answers in
[`spec/`](../spec).

```bash
composer require kechankrisna/php_payway
```

Requires PHP 8.3+ with `ext-json` and `ext-openssl`. The default HTTP client
uses `ext-curl`; you can pass any PSR-18 client instead.

| API | Method |
|---|---|
| Purchase (KHQR / ABA Mobile deep link) | `purchase` |
| Purchase on PayWay's hosted page (cards, Alipay, WeChat, ...) | `checkoutHtml` |
| Check transaction | `checkTransaction` |
| Get a transaction's details | `getTransactionDetail` |
| Close transaction | `closeTransaction` |
| Get transaction list | `getTransactionList` |
| Refund | `refund` |
| Exchange rate | `getExchangeRates` |
| Verify the payment callback on your `return_url` | `verifyCallback` + `parseCallback` |

Run it on your server: the API key is a secret.

## Setup

```php
use PhpPayway\PaywayMerchant;
use PhpPayway\PaywayService;

$payway = new PaywayService(new PaywayMerchant(
    merchantId: $_ENV['ABA_PAYWAY_MERCHANT_ID'],
    apiKey: $_ENV['ABA_PAYWAY_API_KEY'],
    referer: 'https://your-shop.example',       // the domain ABA whitelisted
    rsaPublicKey: $_ENV['ABA_PAYWAY_RSA_PUBLIC_KEY'] ?? null, // refunds only
    baseApiUrl: PaywayMerchant::SANDBOX_URL,     // or PRODUCTION_URL
));
```

Every other constructor argument is optional and injectable: an `HttpClient`
(`CurlHttpClient` by default, or `Psr18HttpClient` around any PSR-18 client),
a PSR-20 clock, a `PaywayCrypto` and a PSR-3 logger.

## Purchase with KHQR / ABA Mobile

```php
use PhpPayway\Enum\Currency;
use PhpPayway\Enum\PaymentOption;
use PhpPayway\Model\Item;
use PhpPayway\Model\Purchase;

$response = $payway->purchase(new Purchase(
    tranId: 'order-1001',
    amount: 6.5,
    items: [new Item('product 1', 1, 1.5), new Item('product 2', 2, 2.5)],
    shipping: 1,
    currency: Currency::USD,
    paymentOption: PaymentOption::AbapayKhqrDeeplink,
    returnUrl: 'https://your-shop.example/payway/callback',
));

if ($response->isSuccess()) {
    $response->qrString;       // render as a QR code
    $response->abapayDeeplink; // opens ABA Mobile
}
```

For cards, Alipay, WeChat Pay, Google Pay and the other options, PayWay shows
its own payment page: serve the HTML from `checkoutHtml()`, which POSTs the
signed purchase to PayWay.

```php
echo $payway->checkoutHtml(new Purchase('order-1002', 10, paymentOption: PaymentOption::Cards));
```

## Check, list, close, refund

```php
$check = $payway->checkTransaction('order-1001');
if ($check->isPaid()) { /* deliver the order */ }

$detail = $payway->getTransactionDetail('order-1001');
$list = $payway->getTransactionList(new TransactionListQuery(statuses: [PaymentStatus::Approved]));
$payway->closeTransaction('order-1001');
$payway->refund('order-1001', 2.5);
$rates = $payway->getExchangeRates()->rates; // riel per unit, e.g. $rates['usd']->sell
```

## Errors

PayWay business errors (wrong hash, unknown transaction, ...) are returned in
`$response->status`, never thrown. A `PhpPayway\Exception\PaywayException` is
thrown only when PayWay could not be reached or did not answer with a status;
its `type` is an `ErrorType` and `isRetryable()` tells whether to try again.

## Callback on `return_url`

```php
$body = file_get_contents('php://input');
$signature = $_SERVER['HTTP_X_PAYWAY_HMAC_SHA512'] ?? '';
if (!$payway->verifyCallback($body, $signature)) {
    http_response_code(401);
    exit;
}
$callback = $payway->parseCallback($body);
// confirm with checkTransaction($callback->tranId) before delivering
```

## Tests

From the repository root:

```bash
composer install
composer test:unit   # offline, includes the spec/ known answers
composer analyse     # PHPStan, level max
composer cs          # coding style
```

Integration tests create real 0.10 USD transactions (then close them). Copy
`php/.env.example` to `php/.env`, fill in your **sandbox** credentials and run
`composer test -- --group integration`. Use another file with
`PAYWAY_ENV_FILE=...`; a file pointing at production is skipped unless
`PAYWAY_ALLOW_PRODUCTION=true`.

See [CHANGELOG.md](CHANGELOG.md) for the changes from 1.x.
