package io.github.kechankrisna.payway.checkout

import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import java.security.GeneralSecurityException
import java.security.MessageDigest
import java.security.SecureRandom
import java.time.Clock
import kotlin.coroutines.cancellation.CancellationException

/** Receives the SDK's request/response log lines (they contain merchant ids and payloads, never the API key). */
public fun interface PaywayLogger {
    public fun log(message: String)
}

/**
 * ABA PayWay Ecommerce Checkout client.
 *
 * ```kotlin
 * val payway = PaywayService(merchant)
 * val status = payway.checkTransaction("order-1001")
 * if (status.isPaid) deliverOrder()
 * ```
 *
 * PayWay business errors (wrong hash, transaction not found, ...) are
 * returned in `status`. A [PaywayException] is thrown only when PayWay could
 * not be reached or did not answer with a status.
 *
 * Run it on your server (Ktor, Spring, ...): the API key is a secret and
 * must never ship in an Android app.
 *
 * @param merchant merchant credentials used to sign
 * @param httpClient HTTP stack (default: [JdkPaywayHttpClient], created on first call)
 * @param clock source of `req_time`
 * @param crypto hashing and RSA
 * @param logger receives request/response logs; nothing is logged without it
 */
public class PaywayService(
    public val merchant: PaywayMerchant,
    httpClient: PaywayHttpClient? = null,
    clock: Clock = Clock.systemUTC(),
    public val crypto: PaywayCrypto = DefaultPaywayCrypto,
    private val logger: PaywayLogger? = null,
) {
    /** Builds the signed request bodies; exposed to support new endpoints. */
    public val requestBuilder: PaywayRequestBuilder = PaywayRequestBuilder(merchant, clock, crypto)

    // created on first use, so verifying a callback starts no HTTP client
    private val http: PaywayHttpClient by lazy { httpClient ?: JdkPaywayHttpClient() }

    /**
     * Creates a payment and returns its KHQR string and ABA Mobile deep link.
     * Only [PaywayPaymentOption.ABAPAY_KHQR_DEEPLINK] answers with JSON; use
     * [checkoutHtml] for every other payment option.
     *
     * @throws IllegalArgumentException for any other payment option
     */
    public suspend fun purchase(purchase: PaywayPurchase): PaywayPurchaseResponse {
        require(purchase.paymentOption == PaywayPaymentOption.ABAPAY_KHQR_DEEPLINK) {
            "only ABAPAY_KHQR_DEEPLINK returns JSON; use checkoutHtml() for the hosted payment page"
        }
        val fields = requestBuilder.purchase(purchase)
        val boundary = "payway" + randomHex(BOUNDARY_BYTES)
        return post(
            PURCHASE_PATH,
            multipart(fields, boundary).toByteArray(Charsets.UTF_8),
            "multipart/form-data; boundary=$boundary",
            fields.toString(),
            PaywayPurchaseResponse::from,
        )
    }

    /**
     * An HTML page that immediately POSTs [purchase] to PayWay, opening its
     * hosted payment page. Serve it from your site or load it in a web view.
     * Every value is HTML-escaped.
     */
    public fun checkoutHtml(purchase: PaywayPurchase): String {
        val inputs =
            requestBuilder.purchase(purchase).entries.joinToString("") { (name, value) ->
                "      <input type=\"hidden\" name=\"${escape(name)}\" value=\"${escape(value)}\">\n"
            }
        val action = escape(url(PURCHASE_PATH))
        return "<!DOCTYPE html>\n" +
            "<html lang=\"en\">\n" +
            "<head>\n" +
            "  <meta charset=\"utf-8\">\n" +
            "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n" +
            "  <title>PayWay</title>\n" +
            "</head>\n" +
            "<body>\n" +
            "  <form method=\"POST\" action=\"$action\" id=\"payway_checkout\">\n" +
            inputs +
            "  </form>\n" +
            "  <script>document.getElementById(\"payway_checkout\").submit();</script>\n" +
            "</body>\n" +
            "</html>\n"
    }

    /** Status of a transaction created within the last 7 days; older ones need [getTransactionDetail]. */
    public suspend fun checkTransaction(tranId: String): PaywayCheckTransactionResponse =
        postJson(CHECK_TRANSACTION_PATH, requestBuilder.checkTransaction(tranId), PaywayCheckTransactionResponse::from)

    /** Details of a transaction, including its payment and refund operations. */
    public suspend fun getTransactionDetail(tranId: String): PaywayTransactionDetailResponse =
        postJson(TRANSACTION_DETAIL_PATH, requestBuilder.transactionDetail(tranId), PaywayTransactionDetailResponse::from)

    /** Cancels an unpaid transaction: later payments are rejected or reversed and no callback is sent. */
    public suspend fun closeTransaction(tranId: String): PaywayStatusResponse =
        postJson(CLOSE_TRANSACTION_PATH, requestBuilder.closeTransaction(tranId), PaywayStatusResponse::from)

    /** Transactions matching [query], one page at a time. */
    public suspend fun getTransactionList(query: PaywayTransactionListQuery = PaywayTransactionListQuery()): PaywayTransactionListResponse =
        postJson(TRANSACTION_LIST_PATH, requestBuilder.transactionList(query), PaywayTransactionListResponse::from)

    /** ABA Bank's latest exchange rates, in riel per unit of each currency. */
    public suspend fun getExchangeRates(): PaywayExchangeRateResponse =
        postJson(EXCHANGE_RATE_PATH, requestBuilder.exchangeRate(), PaywayExchangeRateResponse::from)

    /**
     * Refunds [amount] (full or partial) within 30 days of the transaction.
     *
     * @throws PaywayException of type [PaywayErrorType.ENCRYPTION] without a
     *   valid [PaywayMerchant.rsaPublicKey]
     */
    public suspend fun refund(
        tranId: String,
        amount: Number,
    ): PaywayRefundResponse {
        val body =
            try {
                requestBuilder.refund(tranId, amount)
            } catch (e: IllegalArgumentException) {
                throw PaywayException(PaywayErrorType.ENCRYPTION, "Refunds need a valid merchant RSA public key", cause = e)
            } catch (e: GeneralSecurityException) {
                throw PaywayException(PaywayErrorType.ENCRYPTION, "Refunds need a valid merchant RSA public key", cause = e)
            }
        return postJson(REFUND_PATH, body, PaywayRefundResponse::from)
    }

    /**
     * Whether [body], the JSON PayWay POSTed to your `return_url`, is signed
     * with [signature] (the `X-PayWay-HMAC-SHA512` header). [key] defaults to
     * the merchant API key. Compared in constant time.
     *
     * ```kotlin
     * val body = call.receiveText()
     * val ok = payway.verifyCallback(body, call.request.header(PaywayService.CALLBACK_SIGNATURE_HEADER) ?: "")
     * ```
     */
    public fun verifyCallback(
        body: String,
        signature: String,
        key: String? = null,
    ): Boolean {
        val decoded = decodeObject(body) ?: return false
        val expected = crypto.hmacSha512Base64(PhpValues.callbackSigningString(decoded), key ?: merchant.apiKey)
        return MessageDigest.isEqual(expected.toByteArray(Charsets.UTF_8), signature.trim().toByteArray(Charsets.UTF_8))
    }

    /**
     * Parses a callback body; call [verifyCallback] first.
     *
     * @throws PaywayException of type [PaywayErrorType.INVALID_CALLBACK] when
     *   [body] is not a JSON object
     */
    public fun parseCallback(body: String): PaywayCallback {
        val decoded =
            try {
                Json.parseToJsonElement(body)
            } catch (e: IllegalArgumentException) {
                throw PaywayException(PaywayErrorType.INVALID_CALLBACK, "Callback body is not JSON", cause = e)
            }
        if (decoded !is JsonObject) {
            throw PaywayException(PaywayErrorType.INVALID_CALLBACK, "Callback body is not a JSON object")
        }
        return PaywayCallback.from(decoded)
    }

    private suspend fun <T> postJson(
        path: String,
        body: Map<String, String>,
        parse: (JsonObject) -> T,
    ): T {
        val json = JsonObject(body.mapValues { JsonPrimitive(it.value) }).encode()
        return post(path, json.toByteArray(Charsets.UTF_8), "application/json", json, parse)
    }

    /**
     * POSTs and parses PayWay's reply. PayWay answers errors with a JSON body
     * carrying the real status, possibly with a non-2xx HTTP status, which is
     * parsed like a success; a status nested in `data` is lifted.
     */
    private suspend fun <T> post(
        path: String,
        body: ByteArray,
        contentType: String,
        logBody: String,
        parse: (JsonObject) -> T,
    ): T {
        val url = url(path)
        logger?.log("[PayWay] POST $url $logBody")
        val headers =
            buildMap {
                put("Accept", "application/json")
                put("Content-Type", contentType)
                put("User-Agent", USER_AGENT)
                if (merchant.referer.isNotEmpty()) put("Referer", merchant.referer)
            }

        val response =
            try {
                http.post(url, headers, body)
            } catch (e: CancellationException) {
                // the caller's coroutine was cancelled: let it propagate
                currentCoroutineContext().ensureActive()
                throw transportException(e).also { logger?.log("[PayWay] failed ${it.message}") }
            } catch (e: Exception) {
                throw transportException(e).also { logger?.log("[PayWay] failed ${it.message}") }
            }

        logger?.log("[PayWay] ${response.statusCode} ${response.body}")
        val json = decodeObject(response.body)
        if (json != null) {
            if (json["status"] is JsonObject) return parse(json)
            val status = json.obj("data")?.obj("status")
            if (status != null) return parse(JsonObject(json + ("status" to status)))
        }
        throw PaywayException(PaywayErrorType.UNEXPECTED_RESPONSE, "Unexpected response from PayWay", response.statusCode)
    }

    private fun url(path: String): String = merchant.baseUrl.trimEnd('/') + path

    public companion object {
        /** version of this SDK */
        public const val SDK_VERSION: String = "2.0.0"

        /** sent with every request */
        public const val USER_AGENT: String = "kotlin-payway/$SDK_VERSION"

        /** endpoint of [purchase] and [checkoutHtml] */
        public const val PURCHASE_PATH: String = "/api/payment-gateway/v1/payments/purchase"

        /** endpoint of [checkTransaction] */
        public const val CHECK_TRANSACTION_PATH: String = "/api/payment-gateway/v1/payments/check-transaction-2"

        /** endpoint of [getTransactionDetail] */
        public const val TRANSACTION_DETAIL_PATH: String = "/api/payment-gateway/v1/payments/transaction-detail"

        /** endpoint of [closeTransaction] */
        public const val CLOSE_TRANSACTION_PATH: String = "/api/payment-gateway/v1/payments/close-transaction"

        /** endpoint of [getTransactionList] */
        public const val TRANSACTION_LIST_PATH: String = "/api/payment-gateway/v1/payments/transaction-list-2"

        /** endpoint of [getExchangeRates] */
        public const val EXCHANGE_RATE_PATH: String = "/api/payment-gateway/v1/exchange-rate"

        /** endpoint of [refund] */
        public const val REFUND_PATH: String = "/api/merchant-portal/merchant-access/online-transaction/refund"

        /** header carrying the callback signature */
        public const val CALLBACK_SIGNATURE_HEADER: String = "X-PayWay-HMAC-SHA512"

        private const val BOUNDARY_BYTES = 12
        private val random = SecureRandom()

        private fun randomHex(bytes: Int): String = ByteArray(bytes).also(random::nextBytes).joinToString("") { "%02x".format(it) }

        private fun multipart(
            fields: Map<String, String>,
            boundary: String,
        ): String =
            buildString {
                for ((name, value) in fields) {
                    append("--$boundary\r\nContent-Disposition: form-data; name=\"$name\"\r\n\r\n$value\r\n")
                }
                append("--$boundary--\r\n")
            }

        private fun escape(value: String): String =
            value
                .replace("&", "&amp;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")

        private fun decodeObject(body: String): JsonObject? =
            try {
                Json.parseToJsonElement(body) as? JsonObject
            } catch (_: IllegalArgumentException) {
                null
            }
    }
}
