# Changelog

## 2.0.0

First release of `io.github.kechankrisna:payway-checkout`, the Kotlin/JVM
twin of `dart_payway` 2.0.0 and `kechankrisna/php_payway` 2.0.0 (the version
follows theirs). Replaces the unpublished Kotlin Multiplatform prototype.

- Every checkout API: purchase (KHQR / deep link), hosted payment page HTML,
  check transaction, transaction details, close, transaction list, refund,
  exchange rates.
- Callback verification (`X-PayWay-HMAC-SHA512`, constant-time) and parsing.
- Request hashes and callback signatures reproduce the known answers
  computed with ABA's PHP samples (`spec/test-vectors`).
- Reads both the production (`qrString`, `qrImage`, `app_store`, ...) and
  sandbox (`qr_string`, `checkout_qr_url`) purchase responses; numeric
  status codes; a `status` nested in `data`.
- Business errors are returned in `status`; transport and local failures
  throw `PaywayException` with a `PaywayErrorType` and `isRetryable`.
- `suspend` API on the JDK `HttpClient`, replaceable through
  `PaywayHttpClient`; injectable `Clock`, `PaywayCrypto` and `PaywayLogger`.
