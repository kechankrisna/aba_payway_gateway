# payway-checkout (Kotlin/JVM)

Kotlin/JVM client for the ABA PayWay **Ecommerce Checkout** API. It is the
Kotlin twin of [`dart_payway`](../dart) and [`php_payway`](../php): all three
are checked against the same known answers in [`spec/`](../spec).

```kotlin
// build.gradle.kts
dependencies {
    implementation("io.github.kechankrisna:payway-checkout:2.0.0")
}
```

Requires JDK 17+. Dependencies: `kotlinx-coroutines-core` and
`kotlinx-serialization-json`. The default HTTP client is the JDK's
`java.net.http.HttpClient`; no OkHttp or Ktor client is needed.

> **Server-side only.** Use it from your backend (Ktor, Spring, Micronaut,
> ...). The API key signs every request and must never ship in an Android
> app, and PayWay only accepts requests from whitelisted domains or IPs.

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

API calls are `suspend` functions.

## Setup

```kotlin
import io.github.kechankrisna.payway.checkout.PaywayMerchant
import io.github.kechankrisna.payway.checkout.PaywayService

val payway = PaywayService(
    PaywayMerchant(
        merchantId = System.getenv("ABA_PAYWAY_MERCHANT_ID"),
        apiKey = System.getenv("ABA_PAYWAY_API_KEY"),
        referer = "https://your-shop.example",              // the domain ABA whitelisted
        rsaPublicKey = System.getenv("ABA_PAYWAY_RSA_PUBLIC_KEY"), // refunds only
        baseUrl = PaywayMerchant.SANDBOX_URL,               // or PRODUCTION_URL
    ),
)
```

Every other constructor argument is optional and injectable: a
`PaywayHttpClient` (`JdkPaywayHttpClient` by default; implement the one-method
interface to use OkHttp, a Ktor client or a test fake), a `java.time.Clock`, a
`PaywayCrypto` and a `PaywayLogger`. `PaywayMerchant.toString()` never shows
the API key.

## Purchase with KHQR / ABA Mobile

```kotlin
val response = payway.purchase(
    PaywayPurchase(
        tranId = "order-1001",
        amount = 6.5,
        items = listOf(PaywayItem("product 1", 1, 1.5), PaywayItem("product 2", 2, 2.5)),
        shipping = 1,
        currency = PaywayCurrency.USD,
        paymentOption = PaywayPaymentOption.ABAPAY_KHQR_DEEPLINK,
        returnUrl = "https://your-shop.example/payway/callback",
    ),
)
if (response.isSuccess) {
    response.qrString        // render as a QR code
    response.abapayDeeplink  // opens ABA Mobile
}
```

`purchase` only accepts `ABAPAY_KHQR_DEEPLINK` (the only option PayWay answers
with JSON). For cards, Alipay, WeChat Pay, Google Pay and the other options,
PayWay shows its own payment page: serve the HTML from `checkoutHtml()`, which
POSTs the signed purchase to PayWay. Every value in it is HTML-escaped.

```kotlin
call.respondText(
    payway.checkoutHtml(PaywayPurchase("order-1002", 10, paymentOption = PaywayPaymentOption.CARDS)),
    ContentType.Text.Html,
)
```

## Check, list, close, refund

```kotlin
val check = payway.checkTransaction("order-1001")
if (check.isPaid) { /* deliver the order */ }

val detail = payway.getTransactionDetail("order-1001")
val list = payway.getTransactionList(PaywayTransactionListQuery(statuses = listOf(PaywayPaymentStatus.APPROVED)))
payway.closeTransaction("order-1001")
payway.refund("order-1001", 2.5)
val usd = payway.getExchangeRates().rates["usd"] // riel per unit, e.g. usd?.sell
```

## Errors

PayWay business errors (wrong hash, unknown transaction, ...) are returned in
`response.status`, never thrown. A `PaywayException` is thrown only when PayWay
could not be reached or did not answer with a status, or for invalid local
input (a missing RSA key for refunds). Its `type` is a `PaywayErrorType`
(`CONNECTION`, `TIMEOUT`, `CANCELLED`, `BAD_CERTIFICATE`,
`UNEXPECTED_RESPONSE`, `ENCRYPTION`, `INVALID_CALLBACK`, `UNKNOWN`) and
`isRetryable` tells whether to try again. Cancelling the calling coroutine
throws the usual `CancellationException`.

## Callback on `return_url`

```kotlin
post("/payway/callback") {
    val body = call.receiveText()
    val signature = call.request.header(PaywayService.CALLBACK_SIGNATURE_HEADER) ?: ""
    if (!payway.verifyCallback(body, signature)) {
        return@post call.respond(HttpStatusCode.Unauthorized)
    }
    val callback = payway.parseCallback(body)
    // confirm with checkTransaction(callback.tranId) before delivering
    call.respond(HttpStatusCode.OK)
}
```

## Tests

```bash
cd kotlin
./gradlew build            # compile (warnings are errors), ktlint, offline tests
./gradlew ktlintFormat     # fix formatting
./gradlew integrationTest  # sandbox tests, need kotlin/.env
```

The offline tests reproduce `spec/test-vectors/php_known_answers.json`.
Integration tests create a real 0.10 USD transaction (then close it). Copy
`kotlin/.env.example` to `kotlin/.env`, fill in your **sandbox** credentials
and run `./gradlew integrationTest`. Use another file with
`PAYWAY_ENV_FILE=...`; a file pointing at production is skipped unless
`PAYWAY_ALLOW_PRODUCTION=true`.

See [CHANGELOG.md](CHANGELOG.md). MIT licensed.
