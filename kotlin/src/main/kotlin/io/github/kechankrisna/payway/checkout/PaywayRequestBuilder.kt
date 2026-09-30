package io.github.kechankrisna.payway.checkout

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import java.math.BigDecimal
import java.math.BigInteger
import java.time.Clock
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.util.Base64
import kotlin.math.abs

/**
 * Builds the signed request bodies of the PayWay checkout APIs. Every hash
 * is `base64(HMAC-SHA512(values..., api_key))` over the values in the order
 * ABA's docs list them; absent optional values count as empty.
 *
 * Every method takes an optional `requestTime` (`yyyyMMddHHmmss`, UTC);
 * without it, the time is read from [clock].
 */
public class PaywayRequestBuilder(
    public val merchant: PaywayMerchant,
    public val clock: Clock = Clock.systemUTC(),
    public val crypto: PaywayCrypto = DefaultPaywayCrypto,
) {
    /** Form fields of `purchase`, in PayWay's order, with `hash` last. */
    public fun purchase(
        purchase: PaywayPurchase,
        requestTime: String? = null,
    ): Map<String, String> {
        val p = purchase
        val time = requestTime(requestTime)
        // hashed, in the documented order
        val hashed =
            linkedMapOf(
                "req_time" to time,
                "merchant_id" to merchant.merchantId,
                "tran_id" to p.tranId,
                "amount" to formatAmount(p.amount),
                "items" to p.items.takeIf { it.isNotEmpty() }?.let { items -> base64Json(JsonArray(items.map { it.toJson() })) },
                "shipping" to p.shipping?.let(::formatAmount),
                "firstname" to p.firstName,
                "lastname" to p.lastName,
                "email" to p.email,
                "phone" to p.phone,
                "type" to p.type?.value,
                "payment_option" to p.paymentOption?.value,
                "return_url" to p.returnUrl?.let(::base64),
                "cancel_url" to p.cancelUrl,
                "continue_success_url" to p.continueSuccessUrl,
                "return_deeplink" to p.returnDeeplink?.let { base64Json(it.toJson()) },
                "currency" to p.currency?.value,
                "custom_fields" to p.customFields?.let { base64Json(toJsonElement(it)) },
                "return_params" to p.returnParams,
                "payout" to p.payout?.let { payout -> base64Json(JsonArray(payout.map { it.toJson() })) },
                "lifetime" to p.lifetime?.toString(),
                "additional_params" to p.additionalParams?.let { base64Json(toJsonElement(it)) },
                "google_pay_token" to p.googlePayToken,
                "skip_success_page" to p.skipSuccessPage?.let { if (it) "1" else "0" },
            )
        // sent, but not part of the hash
        val unhashed =
            linkedMapOf(
                "view_type" to p.viewType?.value,
                "payment_gate" to p.paymentGate?.toString(),
            )
        return signed(hashed, unhashed)
    }

    /** Body of `check-transaction-2`. */
    public fun checkTransaction(
        tranId: String,
        requestTime: String? = null,
    ): Map<String, String> = tranIdBody(tranId, requestTime)

    /** Body of `transaction-detail`. */
    public fun transactionDetail(
        tranId: String,
        requestTime: String? = null,
    ): Map<String, String> = tranIdBody(tranId, requestTime)

    /** Body of `close-transaction`. */
    public fun closeTransaction(
        tranId: String,
        requestTime: String? = null,
    ): Map<String, String> = tranIdBody(tranId, requestTime)

    /** Body of `transaction-list-2`. */
    public fun transactionList(
        query: PaywayTransactionListQuery = PaywayTransactionListQuery(),
        requestTime: String? = null,
    ): Map<String, String> {
        val time = requestTime(requestTime)
        val hashed =
            linkedMapOf(
                "req_time" to time,
                "merchant_id" to merchant.merchantId,
                "from_date" to query.fromDate?.let(::formatDate),
                "to_date" to query.toDate?.let(::formatDate),
                "from_amount" to query.fromAmount?.let(::formatAmount),
                "to_amount" to query.toAmount?.let(::formatAmount),
                "status" to query.statuses.takeIf { it.isNotEmpty() }?.joinToString(",") { it.value },
                "page" to query.page?.toString(),
                "pagination" to query.pagination?.toString(),
            )
        return signed(hashed)
    }

    /** Body of `exchange-rate`. */
    public fun exchangeRate(requestTime: String? = null): Map<String, String> {
        val time = requestTime(requestTime)
        return linkedMapOf(
            "req_time" to time,
            "merchant_id" to merchant.merchantId,
            "hash" to sign(listOf(time, merchant.merchantId)),
        )
    }

    /**
     * Body of `refund`: `merchant_auth` is the RSA-encrypted
     * `{"mc_id", "tran_id", "refund_amount"}`, which needs
     * [PaywayMerchant.rsaPublicKey]; hash = request_time + merchant_id + merchant_auth.
     *
     * @throws IllegalArgumentException without a valid RSA public key
     */
    public fun refund(
        tranId: String,
        refundAmount: Number,
        requestTime: String? = null,
    ): Map<String, String> {
        val rsaKey = merchant.rsaPublicKey
        require(!rsaKey.isNullOrEmpty()) { "refunds need the RSA public key provided by ABA" }
        val time = requestTime(requestTime)
        val payload =
            JsonObject(
                linkedMapOf(
                    "mc_id" to JsonPrimitive(merchant.merchantId),
                    "tran_id" to JsonPrimitive(tranId),
                    "refund_amount" to jsonNumber(refundAmount),
                ),
            )
        val merchantAuth = crypto.rsaEncrypt(payload.encode(), rsaKey)
        return linkedMapOf(
            "request_time" to time,
            "merchant_id" to merchant.merchantId,
            "merchant_auth" to merchantAuth,
            "hash" to sign(listOf(time, merchant.merchantId, merchantAuth)),
        )
    }

    /** `base64(HMAC-SHA512(concatenated values, api_key))`; null counts as empty. */
    public fun sign(values: Iterable<String?>): String = crypto.hmacSha512Base64(values.joinToString("") { it ?: "" }, merchant.apiKey)

    private fun tranIdBody(
        tranId: String,
        requestTime: String?,
    ): Map<String, String> {
        val time = requestTime(requestTime)
        return linkedMapOf(
            "req_time" to time,
            "merchant_id" to merchant.merchantId,
            "tran_id" to tranId,
            "hash" to sign(listOf(time, merchant.merchantId, tranId)),
        )
    }

    private fun signed(
        hashed: Map<String, String?>,
        unhashed: Map<String, String?> = emptyMap(),
    ): Map<String, String> {
        val body = LinkedHashMap<String, String>()
        for ((key, value) in hashed + unhashed) if (value != null) body[key] = value
        body["hash"] = sign(hashed.values)
        return body
    }

    private fun requestTime(requestTime: String?): String {
        val time = requestTime ?: formatRequestTime(clock.instant())
        require(REQUEST_TIME.matches(time)) { "requestTime must be 14 digits yyyyMMddHHmmss, got \"$time\"" }
        return time
    }

    public companion object {
        private val REQUEST_TIME = Regex("^\\d{14}$")
        private val REQUEST_TIME_FORMAT = DateTimeFormatter.ofPattern("yyyyMMddHHmmss").withZone(ZoneOffset.UTC)
        private val DATE_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")
        private const val MAX_PLAIN_INTEGER = 1e15

        /** `yyyyMMddHHmmss` in UTC, as PayWay requires. */
        public fun formatRequestTime(time: Instant): String = REQUEST_TIME_FORMAT.format(time)

        /** `yyyy-MM-dd HH:mm:ss`, as given (no time zone conversion). */
        public fun formatDate(time: LocalDateTime): String = DATE_FORMAT.format(time)

        /** Amounts without a trailing `.0`: `6` stays `6`, `6.0` becomes `6`, `6.5` stays `6.5`. */
        public fun formatAmount(amount: Number): String =
            when (amount) {
                is Byte, is Short, is Int, is Long, is BigInteger -> {
                    amount.toString()
                }

                is BigDecimal -> {
                    amount.stripTrailingZeros().toPlainString()
                }

                else -> {
                    val value = amount.toDecimalDouble()
                    require(value.isFinite()) { "amount must be finite, got $amount" }
                    if (value == kotlin.math.truncate(value) && abs(value) < MAX_PLAIN_INTEGER) {
                        value.toLong().toString()
                    } else {
                        value.toString()
                    }
                }
            }

        private fun base64(value: String): String = Base64.getEncoder().encodeToString(value.toByteArray(Charsets.UTF_8))

        private fun base64Json(value: kotlinx.serialization.json.JsonElement): String = base64(value.encode())

        private fun PaywayItem.toJson(): JsonObject =
            JsonObject(linkedMapOf("name" to JsonPrimitive(name), "quantity" to jsonNumber(quantity), "price" to jsonNumber(price)))

        private fun PaywayPayout.toJson(): JsonObject =
            JsonObject(linkedMapOf("acc" to JsonPrimitive(account), "amt" to jsonNumber(amount)))

        private fun PaywayReturnDeeplink.toJson(): JsonObject =
            JsonObject(linkedMapOf("ios_scheme" to JsonPrimitive(iosScheme), "android_scheme" to JsonPrimitive(androidScheme)))
    }
}
