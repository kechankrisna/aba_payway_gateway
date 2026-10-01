package io.github.kechankrisna.payway.checkout

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import java.io.ByteArrayOutputStream
import java.io.File
import java.math.BigInteger
import java.security.KeyFactory
import java.security.PrivateKey
import java.security.interfaces.RSAPrivateKey
import java.security.spec.PKCS8EncodedKeySpec
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import java.util.Base64
import javax.crypto.Cipher

/** Access to the shared spec/ folder and the fixed inputs of the known answers. */
object Spec {
    const val REQUEST_TIME = "20260102030405"

    private val dir = File(System.getProperty("payway.specDir") ?: "../spec")

    val knownAnswers: Map<String, String> by lazy {
        Json
            .parseToJsonElement(File(dir, "test-vectors/php_known_answers.json").readText())
            .jsonObject
            .mapValues { it.value.jsonPrimitive.content }
    }

    fun fixture(name: String): String = File(dir, "fixtures/$name").readText()

    val clock: Clock = Clock.fixed(Instant.parse("2026-01-02T03:04:05Z"), ZoneOffset.UTC)

    fun merchant(rsaPublicKey: String? = fixture("rsa_1024_public.pem")): PaywayMerchant =
        PaywayMerchant(
            merchantId = "ec000002",
            apiKey = "test-api-key",
            referer = "https://shop.test",
            rsaPublicKey = rsaPublicKey,
            baseUrl = "https://payway.test",
        )

    fun builder(merchant: PaywayMerchant = merchant()): PaywayRequestBuilder = PaywayRequestBuilder(merchant, clock)

    fun fullPurchase(): PaywayPurchase =
        PaywayPurchase(
            tranId = "order-1001",
            amount = 6.5,
            items = listOf(PaywayItem("product 1", 1, 1.5), PaywayItem("product 2", 2, 2.5)),
            shipping = 1,
            firstName = "Sok",
            lastName = "Dara",
            email = "sok@example.com",
            phone = "012345678",
            type = PaywayTransactionType.PRE_AUTH,
            paymentOption = PaywayPaymentOption.ABAPAY_KHQR_DEEPLINK,
            returnUrl = "https://shop.test/payway/callback",
            cancelUrl = "https://shop.test/cancel",
            continueSuccessUrl = "https://shop.test/done",
            returnDeeplink = PaywayReturnDeeplink("shop://done", "shop://done"),
            currency = PaywayCurrency.USD,
            customFields = mapOf("order" to "1001"),
            returnParams = "order=1001",
            payout = listOf(PaywayPayout("000133879", 1), PaywayPayout("000133880", 1.5)),
            lifetime = 30,
            additionalParams = mapOf("wechat_sub_appid" to "wx1"),
            skipSuccessPage = true,
            viewType = PaywayViewType.POPUP,
            paymentGate = 0,
        )

    /** Private key of a PEM `PRIVATE KEY` (PKCS#8) or `RSA PRIVATE KEY` (PKCS#1). */
    fun privateKey(pem: String): RSAPrivateKey {
        val der = Base64.getMimeDecoder().decode(pem.lines().filterNot { it.startsWith("-----") }.joinToString(""))
        val pkcs8 = if (pem.contains("BEGIN RSA PRIVATE KEY")) wrapPkcs1(der) else der
        return KeyFactory.getInstance("RSA").generatePrivate(PKCS8EncodedKeySpec(pkcs8)) as RSAPrivateKey
    }

    /** Decrypts PKCS#1 v1.5 blocks of the key size, like the PHP test helper. */
    fun rsaDecrypt(
        data: String,
        key: PrivateKey,
    ): String {
        val blockSize = ((key as RSAPrivateKey).modulus.bitLength() + 7) / 8
        val cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding").apply { init(Cipher.DECRYPT_MODE, key) }
        val bytes = Base64.getDecoder().decode(data)
        val out = ByteArrayOutputStream()
        for (offset in bytes.indices step blockSize) out.write(cipher.doFinal(bytes, offset, blockSize))
        return out.toString(Charsets.UTF_8)
    }

    // PrivateKeyInfo { version 0, AlgorithmIdentifier rsaEncryption, OCTET STRING pkcs1 }
    private fun wrapPkcs1(pkcs1: ByteArray): ByteArray {
        val version = byteArrayOf(0x02, 0x01, 0x00)
        val algorithm = BigInteger("300d06092a864886f70d0101010500", 16).toByteArray()
        return der(0x30, version + algorithm + der(0x04, pkcs1))
    }

    private fun der(
        tag: Int,
        content: ByteArray,
    ): ByteArray {
        val length =
            when {
                content.size < 0x80 -> byteArrayOf(content.size.toByte())
                content.size < 0x100 -> byteArrayOf(0x81.toByte(), content.size.toByte())
                else -> byteArrayOf(0x82.toByte(), (content.size shr 8).toByte(), content.size.toByte())
            }
        return byteArrayOf(tag.toByte()) + length + content
    }
}

/** Records requests and answers them with [reply]. */
class FakeHttpClient(
    private val reply: (url: String) -> PaywayHttpResponse,
) : PaywayHttpClient {
    data class Request(
        val url: String,
        val headers: Map<String, String>,
        val body: String,
    )

    val requests: MutableList<Request> = mutableListOf()

    override suspend fun post(
        url: String,
        headers: Map<String, String>,
        body: ByteArray,
    ): PaywayHttpResponse {
        requests += Request(url, headers, body.toString(Charsets.UTF_8))
        return reply(url)
    }

    companion object {
        fun json(
            body: JsonElement,
            statusCode: Int = 200,
        ): FakeHttpClient = FakeHttpClient { PaywayHttpResponse(statusCode, body.toString()) }

        fun json(
            body: String,
            statusCode: Int = 200,
        ): FakeHttpClient = FakeHttpClient { PaywayHttpResponse(statusCode, body) }

        fun failing(error: Exception): FakeHttpClient = FakeHttpClient { throw error }
    }
}
