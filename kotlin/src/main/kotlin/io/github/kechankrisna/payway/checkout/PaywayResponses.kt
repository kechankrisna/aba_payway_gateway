package io.github.kechankrisna.payway.checkout

import kotlinx.serialization.json.JsonObject

/**
 * The `status` object of PayWay checkout responses. Codes differ per API
 * (e.g. `1` or `5` wrong hash, `6` not found); success is `00` (`0` for
 * purchase). A numeric code is read as its text.
 *
 * @property tranId transaction id, when PayWay returns one
 * @property traceId PayWay log id for debugging, when PayWay returns one
 */
public data class PaywayStatus(
    public val code: String,
    public val message: String,
    public val tranId: String? = null,
    public val traceId: String? = null,
) {
    /** Whether PayWay answered `00` (or `0`). */
    public val isSuccess: Boolean get() = code == "00" || code == "0"

    internal companion object {
        fun from(json: JsonObject?): PaywayStatus {
            val status = json ?: JsonObject(emptyMap())
            return PaywayStatus(
                code = status.string("code"),
                message = status.string("message"),
                tranId = status.optionalString("tran_id", "tranId"),
                traceId = status.optionalString("trace_id", "traceId"),
            )
        }
    }
}

/**
 * JSON response of `purchase` with [PaywayPaymentOption.ABAPAY_KHQR_DEEPLINK].
 * Production sends `qrString`, `qrImage`, `app_store`, `play_store`; the
 * sandbox (and the docs) send `qr_string` and `checkout_qr_url`. Both are read.
 *
 * @property qrString KHQR payload to render as a QR code
 * @property qrImage the KHQR as a PNG `data:` URI (production)
 * @property abapayDeeplink deep link opening ABA Mobile
 * @property checkoutQrUrl hosted page showing the QR code (sandbox)
 * @property appStore App Store link of ABA Mobile (production)
 * @property playStore Google Play link of ABA Mobile (production)
 */
public data class PaywayPurchaseResponse(
    public val status: PaywayStatus,
    public val qrString: String? = null,
    public val qrImage: String? = null,
    public val abapayDeeplink: String? = null,
    public val checkoutQrUrl: String? = null,
    public val appStore: String? = null,
    public val playStore: String? = null,
) {
    /** Whether PayWay accepted the purchase. */
    public val isSuccess: Boolean get() = status.isSuccess

    internal companion object {
        fun from(json: JsonObject): PaywayPurchaseResponse =
            PaywayPurchaseResponse(
                status = PaywayStatus.from(json.obj("status")),
                qrString = json.optionalString("qr_string", "qrString"),
                qrImage = json.optionalString("qr_image", "qrImage"),
                abapayDeeplink = json.optionalString("abapay_deeplink", "abapayDeeplink"),
                checkoutQrUrl = json.optionalString("checkout_qr_url", "checkoutQrUrl"),
                appStore = json.optionalString("app_store", "appStore"),
                playStore = json.optionalString("play_store", "playStore"),
            )
    }
}

/**
 * Status of a transaction, from `check-transaction-2`.
 *
 * @property paymentStatusCode see [PaywayPaymentStatusCode]
 * @property paymentStatus `APPROVED`, `PRE-AUTH`, `PENDING`, `DECLINED`, `REFUNDED` or `CANCELLED`
 * @property transactionDate creation date, `yyyy-MM-dd HH:mm:ss`
 */
public data class PaywayTransactionStatus(
    public val paymentStatusCode: Int?,
    public val paymentStatus: String,
    public val totalAmount: Double,
    public val originalAmount: Double,
    public val refundAmount: Double,
    public val discountAmount: Double,
    public val paymentAmount: Double,
    public val paymentCurrency: String,
    public val apv: String,
    public val transactionDate: String,
) {
    /** Whether the payment is approved (or pre-authorized). */
    public val isApproved: Boolean get() = paymentStatusCode == PaywayPaymentStatusCode.APPROVED

    internal companion object {
        fun from(json: JsonObject): PaywayTransactionStatus =
            PaywayTransactionStatus(
                paymentStatusCode = json.optionalInt("payment_status_code"),
                paymentStatus = json.string("payment_status"),
                totalAmount = json.double("total_amount"),
                originalAmount = json.double("original_amount"),
                refundAmount = json.double("refund_amount"),
                discountAmount = json.double("discount_amount"),
                paymentAmount = json.double("payment_amount"),
                paymentCurrency = json.string("payment_currency"),
                apv = json.string("apv"),
                transactionDate = json.string("transaction_date"),
            )
    }
}

/** Response of `check-transaction-2`. [data] is absent when the request failed. */
public data class PaywayCheckTransactionResponse(
    public val status: PaywayStatus,
    public val data: PaywayTransactionStatus? = null,
) {
    /** Whether PayWay answered `00`. */
    public val isSuccess: Boolean get() = status.isSuccess

    /** Whether the payment is approved (or pre-authorized). */
    public val isPaid: Boolean get() = isSuccess && data?.isApproved == true

    internal companion object {
        fun from(json: JsonObject): PaywayCheckTransactionResponse =
            PaywayCheckTransactionResponse(
                status = PaywayStatus.from(json.obj("status")),
                data = json.obj("data")?.let(PaywayTransactionStatus::from),
            )
    }
}

/** One operation (payment, refund, ...) of a transaction. */
public data class PaywayTransactionOperation(
    public val status: String,
    public val amount: Double,
    public val transactionDate: String,
    public val bankRef: String,
) {
    internal companion object {
        fun from(json: JsonObject): PaywayTransactionOperation =
            PaywayTransactionOperation(
                status = json.string("status"),
                amount = json.double("amount"),
                transactionDate = json.string("transaction_date"),
                bankRef = json.string("bank_ref"),
            )
    }
}

/**
 * A transaction, from transaction details and the transaction list.
 * [transactionOperations] is only filled by transaction details.
 *
 * @property paymentStatusCode see [PaywayPaymentStatusCode]
 * @property paymentType e.g. `ABA Pay`, `KHQR`, `VISA`, `MC`
 * @property cardSource `ONUS`, `OFFUS_DOMESTIC` or `OFFUS_INTERNATIONAL` for cards
 */
public data class PaywayTransaction(
    public val transactionId: String,
    public val paymentStatusCode: Int?,
    public val paymentStatus: String,
    public val originalAmount: Double,
    public val originalCurrency: String,
    public val paymentAmount: Double,
    public val paymentCurrency: String,
    public val totalAmount: Double,
    public val refundAmount: Double,
    public val discountAmount: Double,
    public val apv: String,
    public val transactionDate: String,
    public val firstName: String,
    public val lastName: String,
    public val email: String,
    public val phone: String,
    public val bankRef: String,
    public val paymentType: String,
    public val payerAccount: String,
    public val bankName: String,
    public val cardSource: String,
    public val transactionOperations: List<PaywayTransactionOperation> = emptyList(),
) {
    /** Whether the payment is approved (or pre-authorized). */
    public val isApproved: Boolean get() = paymentStatusCode == PaywayPaymentStatusCode.APPROVED

    internal companion object {
        fun from(json: JsonObject): PaywayTransaction =
            PaywayTransaction(
                transactionId = json.string("transaction_id"),
                paymentStatusCode = json.optionalInt("payment_status_code"),
                paymentStatus = json.string("payment_status"),
                originalAmount = json.double("original_amount"),
                originalCurrency = json.string("original_currency"),
                paymentAmount = json.double("payment_amount"),
                paymentCurrency = json.string("payment_currency"),
                totalAmount = json.double("total_amount"),
                refundAmount = json.double("refund_amount"),
                discountAmount = json.double("discount_amount"),
                apv = json.string("apv"),
                transactionDate = json.string("transaction_date"),
                firstName = json.string("first_name"),
                lastName = json.string("last_name"),
                email = json.string("email"),
                phone = json.string("phone"),
                bankRef = json.string("bank_ref"),
                paymentType = json.string("payment_type"),
                payerAccount = json.string("payer_account"),
                bankName = json.string("bank_name"),
                cardSource = json.string("card_source"),
                transactionOperations = json.objects("transaction_operations").map(PaywayTransactionOperation::from),
            )
    }
}

/** Response of `transaction-detail`. [data] is absent when the request failed. */
public data class PaywayTransactionDetailResponse(
    public val status: PaywayStatus,
    public val data: PaywayTransaction? = null,
) {
    /** Whether PayWay answered `00`. */
    public val isSuccess: Boolean get() = status.isSuccess

    internal companion object {
        fun from(json: JsonObject): PaywayTransactionDetailResponse =
            PaywayTransactionDetailResponse(
                status = PaywayStatus.from(json.obj("status")),
                data = json.obj("data")?.let(PaywayTransaction::from),
            )
    }
}

/** Response of `transaction-list-2`. */
public data class PaywayTransactionListResponse(
    public val status: PaywayStatus,
    /** transactions of this page */
    public val data: List<PaywayTransaction> = emptyList(),
    /** page number */
    public val page: Int? = null,
    /** records per page */
    public val pagination: Int? = null,
) {
    /** Whether PayWay answered `00`. */
    public val isSuccess: Boolean get() = status.isSuccess

    internal companion object {
        fun from(json: JsonObject): PaywayTransactionListResponse =
            PaywayTransactionListResponse(
                status = PaywayStatus.from(json.obj("status")),
                data = json.objects("data").map(PaywayTransaction::from),
                page = json.optionalInt("page"),
                pagination = json.optionalInt("pagination"),
            )
    }
}

/** Response of `close-transaction`: a status only. */
public data class PaywayStatusResponse(
    public val status: PaywayStatus,
) {
    /** Whether PayWay answered `00`. */
    public val isSuccess: Boolean get() = status.isSuccess

    internal companion object {
        fun from(json: JsonObject): PaywayStatusResponse = PaywayStatusResponse(PaywayStatus.from(json.obj("status")))
    }
}

/**
 * Response of `refund`; status codes are `PTL…` for this API.
 *
 * @property grandTotal original purchase amount
 * @property totalRefunded total refunded so far
 * @property transactionStatus transaction status after the refund, e.g. `REFUNDED`
 */
public data class PaywayRefundResponse(
    public val status: PaywayStatus,
    public val grandTotal: Double? = null,
    public val totalRefunded: Double? = null,
    public val currency: String? = null,
    public val transactionStatus: String? = null,
) {
    /** Whether PayWay answered `00`. */
    public val isSuccess: Boolean get() = status.isSuccess

    internal companion object {
        fun from(json: JsonObject): PaywayRefundResponse =
            PaywayRefundResponse(
                status = PaywayStatus.from(json.obj("status")),
                grandTotal = json.optionalDouble("grand_total"),
                totalRefunded = json.optionalDouble("total_refunded"),
                currency = json.optionalString("currency"),
                transactionStatus = json.optionalString("transaction_status"),
            )
    }
}

/** ABA Bank's buy and sell rate of one currency, in riel per unit (e.g. USD sell `4012`). */
public data class PaywayExchangeRate(
    /** ABA sells the currency at this rate */
    public val sell: Double,
    /** ABA buys the currency at this rate */
    public val buy: Double,
)

/**
 * Response of `exchange-rate`: ABA Bank's latest rates in riel.
 *
 * @property rates by lowercase currency code, e.g. `rates["usd"]`
 */
public data class PaywayExchangeRateResponse(
    public val status: PaywayStatus,
    public val rates: Map<String, PaywayExchangeRate> = emptyMap(),
) {
    /** Whether PayWay answered `00`. */
    public val isSuccess: Boolean get() = status.isSuccess

    internal companion object {
        /** Rates are read from `exchange_rates` and from top-level currency keys, as the documented schema shows both. */
        fun from(json: JsonObject): PaywayExchangeRateResponse {
            val rates = linkedMapOf<String, PaywayExchangeRate>()
            for (source in listOfNotNull(json, json.obj("exchange_rates"))) {
                for ((key, value) in source) {
                    if (value is JsonObject && value.optionalString("sell") != null && value.optionalString("buy") != null) {
                        rates[key.lowercase()] = PaywayExchangeRate(value.double("sell"), value.double("buy"))
                    }
                }
            }
            return PaywayExchangeRateResponse(PaywayStatus.from(json.obj("status")), rates)
        }
    }
}

/**
 * The payment result PayWay POSTs (JSON) to your `return_url`. Verify it
 * with [PaywayService.verifyCallback] before trusting it.
 *
 * @property status `0` when the payment succeeded
 * @property returnParams the `returnParams` given at purchase
 * @property transactionDate creation date, `yyyy-MM-dd HH:mm:ss`
 */
public data class PaywayCallback(
    public val tranId: String,
    public val apv: String,
    public val status: String,
    public val returnParams: String,
    public val originalAmount: Double,
    public val originalCurrency: String,
    public val paymentAmount: Double,
    public val paymentCurrency: String,
    public val totalAmount: Double,
    public val discountAmount: Double,
    public val transactionDate: String,
    public val firstName: String,
    public val lastName: String,
    public val email: String,
    public val phone: String,
    public val bankRef: String,
    public val paymentType: String,
    public val payerAccount: String,
    public val bankName: String,
    public val cardSource: String,
) {
    /** Whether the payment succeeded (`status` `0`). */
    public val isSuccess: Boolean get() = status == "0" || status == "00"

    internal companion object {
        fun from(json: JsonObject): PaywayCallback =
            PaywayCallback(
                tranId = json.string("tran_id"),
                apv = json.string("apv"),
                status = json.string("status"),
                returnParams = json.string("return_params"),
                originalAmount = json.double("original_amount"),
                originalCurrency = json.string("original_currency"),
                paymentAmount = json.double("payment_amount"),
                paymentCurrency = json.string("payment_currency"),
                totalAmount = json.double("total_amount"),
                discountAmount = json.double("discount_amount"),
                transactionDate = json.string("transaction_date"),
                firstName = json.string("first_name"),
                lastName = json.string("last_name"),
                email = json.string("email"),
                phone = json.string("phone"),
                bankRef = json.string("bank_ref"),
                paymentType = json.string("payment_type"),
                payerAccount = json.string("payer_account"),
                bankName = json.string("bank_name"),
                cardSource = json.string("card_source"),
            )
    }
}
