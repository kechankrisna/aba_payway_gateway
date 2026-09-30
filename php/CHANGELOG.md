# Changelog

## 2.0.0

Rebuilt against the current ABA PayWay Ecommerce Checkout API. The namespace
is still `PhpPayway`, but the API is new: see the README.

### Breaking changes

- The Composer package is renamed `kechankrisna/php_payway` (was
  `aba_payway_gateway/php_payway`):
  `composer remove aba_payway_gateway/php_payway && composer require kechankrisna/php_payway`.
- PHP 8.3+ is required.
- `PaywayTransactionService` is replaced by `PaywayService`; the request and
  response classes are replaced by `Model\Purchase`, `Model\Item`,
  `Model\PurchaseResponse`, `Model\CheckTransactionResponse`, ...
- Enums are PHP enums in `PhpPayway\Enum` (`PaymentOption`, `Currency`,
  `TransactionType`, `PaymentStatus`, ...).
- Errors are thrown as `PaywayException` instead of calling `dd()`.
- Guzzle is no longer required: the default client uses ext-curl, and any
  PSR-18 client can be injected.

### Fixes

- `req_time` is UTC `YmdHis`; 1.x used a 12-hour local clock, so requests
  made after noon were signed with the wrong time.
- Check transaction uses `check-transaction-2`.
- Absent optional fields are hashed as empty strings, in the documented order.
- The production purchase response (`qrString`, `qrImage`) and the sandbox
  one (`qr_string`, `checkout_qr_url`) are both read.

### New

- Transaction details, close transaction, transaction list, refund (RSA
  `merchant_auth`), exchange rates.
- `checkoutHtml()` for PayWay's hosted payment page.
- `verifyCallback()` and `parseCallback()` for the `return_url` callback.
- Payout, return deeplink, custom fields, lifetime, additional params,
  Google Pay token, view type and payment gate on purchase.
