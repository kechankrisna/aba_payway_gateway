package io.github.kechankrisna.payway.checkout

import java.time.LocalDateTime

/**
 * A purchased item. Items are a description only: PayWay does not use their
 * price or quantity for calculation. Up to 50 items.
 *
 * Numbers are encoded as given: `1` as `1`, `1.5` as `1.5`, `1.0` as `1.0`.
 */
public data class PaywayItem(
    public val name: String,
    public val quantity: Number,
    public val price: Number,
)

/** A split of the purchase amount to an ABA account (`payout`). */
public data class PaywayPayout(
    /** ABA account number (`acc`) */
    public val account: String,
    /** amount paid to [account] (`amt`) */
    public val amount: Number,
)

/** Deep links back to your app after paying in ABA Mobile (`return_deeplink`). */
public data class PaywayReturnDeeplink(
    public val iosScheme: String,
    public val androidScheme: String,
)

/**
 * Request of `purchase`. Only [tranId] and [amount] are required; other
 * fields are sent only when set. Values PayWay wants Base64-encoded (items,
 * return URL, deep link, custom fields, payout, additional params) are given
 * as plain values: the SDK encodes them.
 *
 * @property tranId your unique transaction id, max 20 characters
 * @property amount purchase amount, sent without a trailing `.0` (`6.5`, `1`)
 * @property items item descriptions (up to 50)
 * @property customFields shown in transaction list, details and reports;
 *   values may be strings, numbers, booleans, null, maps and lists
 * @property payout split of the amount to ABA accounts
 * @property lifetime payment lifetime in minutes (3 minutes to 30 days)
 * @property additionalParams e.g. `wechat_sub_appid`, `wechat_sub_openid`
 * @property viewType sent, but not part of the hash
 * @property paymentGate set 0 when your profile also has the QR Payment API;
 *   sent, but not part of the hash
 */
public data class PaywayPurchase(
    public val tranId: String,
    public val amount: Number,
    public val items: List<PaywayItem> = emptyList(),
    public val shipping: Number? = null,
    public val firstName: String? = null,
    public val lastName: String? = null,
    public val email: String? = null,
    public val phone: String? = null,
    public val type: PaywayTransactionType? = null,
    public val paymentOption: PaywayPaymentOption? = null,
    public val returnUrl: String? = null,
    public val cancelUrl: String? = null,
    public val continueSuccessUrl: String? = null,
    public val returnDeeplink: PaywayReturnDeeplink? = null,
    public val currency: PaywayCurrency? = null,
    public val customFields: Map<String, Any?>? = null,
    public val returnParams: String? = null,
    public val payout: List<PaywayPayout>? = null,
    public val lifetime: Int? = null,
    public val additionalParams: Map<String, Any?>? = null,
    public val googlePayToken: String? = null,
    public val skipSuccessPage: Boolean? = null,
    public val viewType: PaywayViewType? = null,
    public val paymentGate: Int? = null,
)

/**
 * Filters of `transaction-list-2`; every field is optional.
 *
 * @property fromDate sent as `yyyy-MM-dd HH:mm:ss`, as given (no time zone conversion)
 * @property toDate sent as `yyyy-MM-dd HH:mm:ss`, as given
 * @property statuses statuses to include
 * @property page page number
 * @property pagination records per page; PayWay's default 40, maximum 1000
 */
public data class PaywayTransactionListQuery(
    public val fromDate: LocalDateTime? = null,
    public val toDate: LocalDateTime? = null,
    public val fromAmount: Number? = null,
    public val toAmount: Number? = null,
    public val statuses: List<PaywayPaymentStatus> = emptyList(),
    public val page: Int? = null,
    public val pagination: Int? = null,
)
