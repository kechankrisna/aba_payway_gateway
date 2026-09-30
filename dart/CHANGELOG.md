## 2.0.0

Rebuilt against the current ABA PayWay Ecommerce Checkout documentation.

### New APIs
- `getTransactionDetail`, `closeTransaction`, `getTransactionList`, `refund`
  (RSA-encrypted `merchant_auth`) and `getExchangeRates`
- `verifyCallback` / `parseCallback`: verify the `X-PayWay-HMAC-SHA512`
  signature of the payment callback, byte for byte like ABA's PHP sample
- `PaywayPurchaseResponse` reads production's field names (`qrString`,
  `qrImage`, `app_store`, `play_store`) as well as the documented sandbox ones
  (`qr_string`, `checkout_qr_url`); `PaywayStatus.traceId`

### Fixes
- `req_time` is UTC `YYYYMMDDHHmmss`; 1.x used a 12-hour local clock
  without zero padding (e.g. `2026102030405` at 15:04:05 on 2 January)
- `checkTransaction` uses the current `check-transaction-2` endpoint (JSON)
  and its `data` / `status` response
- the hosted checkout page hashes `payment_option`, which 1.x sent unsigned,
  escapes every value, and no longer double-encodes `items`
- every purchase field is supported and hashed in the documented order:
  `cancel_url`, `skip_success_page`, `view_type`, `payment_gate`, `payout`,
  `additional_params`, `lifetime`, `google_pay_token`
- `return_url`, `return_deeplink`, `custom_fields`, `payout` and
  `additional_params` are Base64-encoded as the docs require
- **security**: TLS certificates are validated (1.x accepted any
  certificate); `PaywayMerchant.toString()` hides the API key

### Breaking changes
- `PaywayTransactionService` is replaced by `PaywayService`:
  `createTransaction` → `purchase` (KHQR deep link JSON) and
  `generateTransactionCheckoutURI` → `checkoutUri` / `checkoutHtml`
- `PaywayMerchant`: `merchantID` → `merchantId`, `merchantApiKey` →
  `apiKey`, `refererDomain` → `referer`; `merchantApiName` removed;
  `rsaPublicKey` added for refunds
- `PaywayCreateTransaction` → `PaywayPurchase` (`req_time` is generated);
  `PaywayTransactionItem` → `PaywayItem`; `PaywayCheckTransaction` removed
  (pass `tranId`)
- payment options follow the docs: `cards`, `abapayKhqr`,
  `abapayKhqrDeeplink`, `alipay`, `wechat`, `googlePay`; the undocumented
  `abapay`, `abapay_deeplink` and `bakong` are removed
- transaction types are `purchase` and `preAuth` (`refund` was never a
  valid type)
- network failures throw `PaywayException` instead of returning a response
  with an error description
- `PaywayStrings`, `PhoneCodeService`, `EncoderService` and the global
  `debugPrint` / `listEquals` exports are removed
- requires Dart 3.9+ (Flutter 3.35+)

## 1.1.0+2
- fix test case for transaction with option abapay_khqr status check

## 1.1.0+1
- add support intl > 0.20.0 for flutter_payway and dart_payway

## 1.0.8+3

- add support intl > 0.19.0

## 1.0.8+2

- fixed missing returnDeeplink when has

## 1.0.8+1

- fixed missing continueSuccessUrl when has

## 1.0.8

- add support for payment option as checkout_qr_url

## 1.0.7

- fixed kIsWeb

## 1.0.6

- change status int to map for create transaction response

## 1.0.5

- add return_url, return_params and custom_fields

## 1.0.4

- fixed generate web ui link

## 1.0.3

- add document

## 1.0.2

- fixed generate checkout uri from client as data:type/html

## 1.0.1

- test and name from ABA to Payway

## 1.0.0+1

- example usage
- isolate service for different merchant

## 1.0.0

- Initial version.
