package io.github.kechankrisna.payway.checkout

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import java.util.Base64
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

/** Refund encryption and callback signing strings. */
class CryptoTest {
    private val privateKey1024 = Spec.privateKey(Spec.fixture("rsa_1024_private.pem"))

    @Test
    fun `refund encrypts merchant auth with the RSA public key`() {
        val body = Spec.builder().refund("order-1001", 0.5)
        assertEquals(listOf("request_time", "merchant_id", "merchant_auth", "hash"), body.keys.toList())
        assertEquals(Spec.REQUEST_TIME, body["request_time"])
        assertEquals(
            """{"mc_id":"ec000002","tran_id":"order-1001","refund_amount":0.5}""",
            Spec.rsaDecrypt(body.getValue("merchant_auth"), privateKey1024),
        )
        assertEquals(
            DefaultPaywayCrypto.hmacSha512Base64("20260102030405ec000002" + body["merchant_auth"], "test-api-key"),
            body["hash"],
        )
    }

    @Test
    fun `refund accepts X509, PKCS#1 and bare base64 public keys`() {
        val spki = Spec.fixture("rsa_1024_public.pem")
        val bareBase64 = spki.lines().filterNot { it.startsWith("-----") }.joinToString("")
        val keys = listOf(spki, Spec.fixture("rsa_1024_public_pkcs1.pem"), bareBase64, "  $bareBase64\n")
        val pkcs8 = Spec.privateKey(Spec.fixture("rsa_1024_private_pkcs8.pem"))
        for (key in keys) {
            val body = Spec.builder(Spec.merchant(rsaPublicKey = key)).refund("order-1001", 1)
            val json = Json.parseToJsonElement(Spec.rsaDecrypt(body.getValue("merchant_auth"), pkcs8)).jsonObject
            assertEquals("ec000002", json.getValue("mc_id").jsonPrimitive.content)
            assertEquals("1", json.getValue("refund_amount").jsonPrimitive.content)
        }
    }

    @Test
    fun `long payloads are encrypted in key-size chunks`() {
        val data = "x".repeat(300) + "ហាង"
        for ((public, private) in listOf(
            "rsa_1024_public.pem" to "rsa_1024_private.pem",
            "rsa_2048_public.pem" to "rsa_2048_private.pem",
        )) {
            val key = Spec.privateKey(Spec.fixture(private))
            val encrypted = DefaultPaywayCrypto.rsaEncrypt(data, Spec.fixture(public))
            val blockSize = (key.modulus.bitLength() + 7) / 8
            val chunkSize = blockSize - 11
            val bytes = data.toByteArray().size
            assertEquals((bytes + chunkSize - 1) / chunkSize * blockSize, Base64.getDecoder().decode(encrypted).size)
            assertEquals(data, Spec.rsaDecrypt(encrypted, key))
        }
    }

    @Test
    fun `invalid public keys are rejected`() {
        for (key in listOf("", "not base64 !", Base64.getEncoder().encodeToString(byteArrayOf(0x30, 0x03, 0x01, 0x01, 0x00)))) {
            assertFailsWith<IllegalArgumentException> { DefaultPaywayCrypto.parsePublicKey(key) }
        }
    }

    @Test
    fun `HMAC-SHA512 is base64 of the raw digest`() {
        // php -r "echo base64_encode(hash_hmac('sha512', 'message', 'key', true));"
        assertEquals(
            "5Hc4TXyiKd0UJuZLY+vy0269bX5mmmc1Qk5y6mwB0/i1brOcNtgjL1QnmZuNGj+c0RKPxp9NdbQ0IWgQ+jZ+mA==",
            DefaultPaywayCrypto.hmacSha512Base64("message", "key"),
        )
    }

    @Test
    fun `callback signing strings match PHP`() {
        // src/test/resources/php_signing_strings.jsonl, generated with PHP 8
        val lines =
            javaClass
                .getResource("/php_signing_strings.jsonl")!!
                .readText()
                .lines()
                .filter { it.isNotBlank() }
        check(lines.isNotEmpty())
        for (line in lines) {
            val case = Json.parseToJsonElement(line).jsonObject
            val body = Json.parseToJsonElement(case.getValue("body").jsonPrimitive.content).jsonObject
            assertEquals(case.getValue("b4hash").jsonPrimitive.content, DefaultPaywayCrypto.callbackSigningString(body), line)
        }
    }

    @Test
    fun `PHP float to string conversions`() {
        assertEquals("0.3", PhpValues.gcvt(0.1 + 0.2, 14, 'E', shortest = false))
        assertEquals("10", PhpValues.gcvt(10.0, 14, 'E', shortest = false))
        assertEquals("1.0E+15", PhpValues.gcvt(1e15, 14, 'E', shortest = false))
        assertEquals("0.0001", PhpValues.gcvt(0.0001, 14, 'E', shortest = false))
        assertEquals("1.0E-5", PhpValues.gcvt(0.00001, 14, 'E', shortest = false))
        assertEquals("1.0e+20", PhpValues.gcvt(1e20, 17, 'e', shortest = true))
        assertEquals("0.30000000000000004", PhpValues.gcvt(0.1 + 0.2, 17, 'e', shortest = true))
    }
}
