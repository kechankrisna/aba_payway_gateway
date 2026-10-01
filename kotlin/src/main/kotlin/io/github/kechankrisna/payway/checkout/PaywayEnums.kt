package io.github.kechankrisna.payway.checkout

/** Payment method of a purchase (`payment_option`). */
public enum class PaywayPaymentOption(
    /** the value sent to PayWay */
    public val value: String,
) {
    /** card payment */
    CARDS("cards"),

    /** QR code payable with ABA PAY and other KHQR member banks */
    ABAPAY_KHQR("abapay_khqr"),

    /** ABA PAY / KHQR for apps: purchase answers with JSON (QR string, deep link) */
    ABAPAY_KHQR_DEEPLINK("abapay_khqr_deeplink"),

    /** Alipay wallet */
    ALIPAY("alipay"),

    /** WeChat Pay wallet */
    WECHAT("wechat"),

    /** Google Pay wallet; needs a `googlePayToken` when you handle the payment selection */
    GOOGLE_PAY("google_pay"),
}

/** Currency of a purchase. */
public enum class PaywayCurrency(
    /** the value sent to PayWay */
    public val value: String,
) {
    /** US dollar */
    USD("USD"),

    /** Cambodian riel */
    KHR("KHR"),
}

/** Type of a purchase (`type`). */
public enum class PaywayTransactionType(
    /** the value sent to PayWay */
    public val value: String,
) {
    /** full purchase (PayWay's default) */
    PURCHASE("purchase"),

    /** pre-authorization hold, captured later; ABA PAY, KHQR and cards only */
    PRE_AUTH("pre-auth"),
}

/** How the hosted payment page is shown (`view_type`). */
public enum class PaywayViewType(
    /** the value sent to PayWay */
    public val value: String,
) {
    /** redirect the payer to a new tab */
    HOSTED_VIEW("hosted_view"),

    /** bottom sheet on mobile browsers, modal popup on desktop browsers */
    POPUP("popup"),
}

/** Transaction status filter of the transaction list (`status`). */
public enum class PaywayPaymentStatus(
    /** the value sent to PayWay */
    public val value: String,
) {
    /** paid with the full purchase amount */
    APPROVED("APPROVED"),

    /** funds held by a pre-authorization, pending capture */
    PRE_AUTH("PRE-AUTH"),

    /** fully or partially refunded */
    REFUNDED("REFUNDED"),

    /** awaiting payment by the payer */
    PENDING("PENDING"),

    /** declined (spelled `DECLINDED`, as in PayWay's API) */
    DECLINED("DECLINDED"),

    /** cancelled */
    CANCELLED("CANCELLED"),
}

/** `payment_status_code` values of transaction status, details and list. */
public object PaywayPaymentStatusCode {
    /** `0` APPROVED or PRE-AUTH */
    public const val APPROVED: Int = 0

    /** `2` PENDING */
    public const val PENDING: Int = 2

    /** `3` DECLINED */
    public const val DECLINED: Int = 3

    /** `4` REFUNDED */
    public const val REFUNDED: Int = 4

    /** `7` CANCELLED */
    public const val CANCELLED: Int = 7
}
