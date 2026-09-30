package io.github.kechankrisna.payway.checkout

/**
 * Merchant credentials provided by ABA Bank.
 *
 * The API key is a secret: keep it on your server, never in an Android or
 * browser app. [toString] leaves it (and the RSA key) out.
 *
 * @property merchantId merchant id provided by ABA (`merchant_id`)
 * @property apiKey API key provided by ABA, keys every request hash
 * @property referer domain whitelisted by ABA, sent as the `Referer` header
 * @property rsaPublicKey RSA public key provided by ABA, PEM (`PUBLIC KEY` or
 *   `RSA PUBLIC KEY`) or bare base64; needed for refunds only
 * @property baseUrl [SANDBOX_URL] or [PRODUCTION_URL]
 */
public data class PaywayMerchant(
    public val merchantId: String,
    public val apiKey: String,
    public val referer: String,
    public val rsaPublicKey: String? = null,
    public val baseUrl: String = SANDBOX_URL,
) {
    /** Keeps the API key out of logs. */
    override fun toString(): String = "PaywayMerchant(merchantId=$merchantId, apiKey=***, referer=$referer, baseUrl=$baseUrl)"

    public companion object {
        /** PayWay checkout sandbox (testing) environment */
        public const val SANDBOX_URL: String = "https://checkout-sandbox.payway.com.kh"

        /** PayWay checkout production (live) environment */
        public const val PRODUCTION_URL: String = "https://checkout.payway.com.kh"
    }
}
