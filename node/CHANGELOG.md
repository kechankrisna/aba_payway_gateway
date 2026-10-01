## 2.0.0

- First release, versioned with `dart_payway` and `kechankrisna/php_payway`
  2.0.0 and feature-equal to them: purchase (KHQR / ABA Mobile deep link),
  `checkoutHtml` for the hosted payment page, check transaction, transaction
  details, close transaction, transaction list, refund, exchange rates, and
  callback verification (`verifyCallback`, `parseCallback`).
- Reads both production (`qrString`, `qrImage`, `app_store`, `play_store`)
  and sandbox (`qr_string`, `checkout_qr_url`) purchase responses.
- Typed `PaywayError` (`type`, `isRetryable`); PayWay business errors are
  returned in `status`.
- Injectable `fetch`, clock, crypto and logger; `AbortSignal` and timeout.
- Passes the shared known answers computed with ABA's PHP samples.
