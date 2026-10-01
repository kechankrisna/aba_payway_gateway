# @kechankrisna/payway-checkout

Node.js client for the ABA PayWay **Ecommerce Checkout** API. It is the
TypeScript twin of [`dart_payway`](../dart) and
[`kechankrisna/php_payway`](../php): all three are checked against the same
known answers in [`spec/`](../spec).

Node.js 22+, TypeScript types included, no runtime dependencies (it uses the
built-in `fetch` and `node:crypto`).

```sh
npm install @kechankrisna/payway-checkout
```

| API                                                           | Method                             |
| ------------------------------------------------------------- | ---------------------------------- |
| Purchase (KHQR / ABA Mobile deep link)                        | `purchase`                         |
| Purchase on PayWay's hosted page (cards, Alipay, WeChat, ...) | `checkoutHtml`                     |
| Check transaction                                             | `checkTransaction`                 |
| Get a transaction's details                                   | `getTransactionDetail`             |
| Close transaction                                             | `closeTransaction`                 |
| Get transaction list                                          | `getTransactionList`               |
| Refund                                                        | `refund`                           |
| Exchange rate                                                 | `getExchangeRates`                 |
| Verify the payment callback on your `return_url`              | `verifyCallback` + `parseCallback` |

Run it on your server: the API key is a secret, and PayWay only accepts
requests from the domains or IPs ABA whitelisted.

## Setup

```ts
import { PaywayMerchant, PaywayService } from '@kechankrisna/payway-checkout';

const payway = new PaywayService({
  merchant: new PaywayMerchant({
    merchantId: process.env.ABA_PAYWAY_MERCHANT_ID!,
    apiKey: process.env.ABA_PAYWAY_API_KEY!,
    referer: 'https://your-shop.example', // the domain ABA whitelisted
    rsaPublicKey: process.env.ABA_PAYWAY_RSA_PUBLIC_KEY, // refunds only
    baseUrl: PaywayMerchant.SANDBOX_URL, // or PaywayMerchant.PRODUCTION_URL
  }),
});
```

`PaywayMerchant` keeps the API key out of `toString()`, `console.log()` /
`util.inspect()` and `JSON.stringify()`.

## Purchase with KHQR / ABA Mobile

```ts
const response = await payway.purchase({
  tranId: 'order-1001', // unique, max 20 characters
  amount: 6.5,
  items: [
    { name: 'product 1', quantity: 1, price: 1.5 },
    { name: 'product 2', quantity: 2, price: 2.5 },
  ],
  shipping: 1,
  currency: 'USD',
  paymentOption: 'abapay_khqr_deeplink', // or PaymentOption.abapayKhqrDeeplink
  returnUrl: 'https://your-shop.example/payway/callback',
});

if (response.isSuccess) {
  response.qrString; // render as a QR code
  response.abapayDeeplink; // opens ABA Mobile
}
```

Values PayWay wants Base64-encoded (items, return URL, deep link, custom
fields, payout, additional params) are given as plain values: the SDK encodes
them. Enumerations (`PaymentOption`, `Currency`, `TransactionType`,
`ViewType`, `PaymentStatus`, `PaymentStatusCode`) are `const` objects whose
values are also accepted as plain strings.

For cards, Alipay, WeChat Pay, Google Pay and the other options, PayWay shows
its own payment page: serve the HTML from `checkoutHtml()`, which POSTs the
signed purchase to PayWay.

```ts
const html = payway.checkoutHtml({
  tranId: 'order-1002',
  amount: 10,
  paymentOption: 'cards',
});
res.type('html').send(html);
```

## Check, list, close, refund

```ts
const check = await payway.checkTransaction('order-1001');
if (check.isPaid) {
  // deliver the order
}

const detail = await payway.getTransactionDetail('order-1001');
const list = await payway.getTransactionList({
  statuses: ['APPROVED'],
  pagination: 50,
});
await payway.closeTransaction('order-1001');
await payway.refund('order-1001', 2.5); // needs rsaPublicKey
const { rates } = await payway.getExchangeRates(); // riel per unit, e.g. rates.usd.sell
```

## Callback on `return_url`

PayWay POSTs the payment result as JSON, signed in the `X-PayWay-HMAC-SHA512`
header. Verify the **raw** body:

```ts
app.post('/payway/callback', express.text({ type: '*/*' }), (req, res) => {
  if (!payway.verifyCallback(req.body, req.get('x-payway-hmac-sha512'))) {
    return res.sendStatus(401);
  }
  const callback = payway.parseCallback(req.body);
  // confirm with checkTransaction(callback.tranId) before delivering
  res.sendStatus(200);
});
```

## Errors

- PayWay business errors (wrong hash, unknown transaction, ...) are
  **returned** in `response.status`, never thrown; check `response.isSuccess`.
- `PaywayError` is **thrown** when PayWay could not be reached or did not
  answer with a status, and for invalid local input. Branch on `error.type`
  (`connection`, `timeout`, `cancelled`, `badCertificate`,
  `unexpectedResponse`, `encryption`, `invalidCallback`, `unknown`);
  `error.isRetryable` tells whether retrying later may help.
- `purchase()` rejects with a `TypeError` for a payment option other than
  `abapay_khqr_deeplink` (use `checkoutHtml()`).

```ts
try {
  await payway.checkTransaction('order-1001', {
    signal: AbortSignal.timeout(10_000),
  });
} catch (error) {
  if (error instanceof PaywayError && error.isRetryable) {
    // retry later
  }
}
```

## Dependency injection

```ts
new PaywayService({
  merchant,
  fetch: myFetch, // any fetch-compatible client
  clock: () => new Date(), // source of req_time
  crypto: myCrypto, // implements PaywayCrypto
  logger: (line) => log.debug(line), // nothing is logged without it
  timeoutMs: 30_000, // default 60 000
});
```

`payway.requestBuilder` builds the signed bodies, to support endpoints this
package does not wrap yet.

## Tests

```sh
cd node
npm ci
npm run typecheck && npm run lint && npm run format:check
npm run test:unit   # offline, includes the spec/ known answers
npm run build
```

The integration tests create a real 0.10 USD transaction (then close it).
Copy `.env.example` to `.env`, fill in your **sandbox** credentials and run
`npx vitest run test/integration.test.ts`. Use another file with
`PAYWAY_ENV_FILE=...`; credentials pointing at production are skipped unless
`PAYWAY_ALLOW_PRODUCTION=true`.

## License

MIT
