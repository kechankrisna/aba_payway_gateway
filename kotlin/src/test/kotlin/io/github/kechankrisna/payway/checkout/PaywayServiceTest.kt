package io.github.kechankrisna.payway.checkout

import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonArray
import kotlinx.serialization.json.putJsonObject
import java.net.ConnectException
import java.net.http.HttpConnectTimeoutException
import java.net.http.HttpTimeoutException
import java.time.Instant
import java.time.ZoneId
import javax.net.ssl.SSLHandshakeException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Offline tests with a fake HTTP client: requests, parsing and errors. */
class PaywayServiceTest {
    private fun service(http: PaywayHttpClient): PaywayService = PaywayService(Spec.merchant(), http, Spec.clock)

    private val ok =
        buildJsonObject {
            putJsonObject("status") {
                put("code", "00")
                put("message", "Success!")
            }
        }

    @Test
    fun `request time is UTC and zero padded`() {
        val local = Instant.parse("2026-01-02T15:04:05Z").atZone(ZoneId.of("Asia/Phnom_Penh"))
        assertEquals("20260102150405", PaywayRequestBuilder.formatRequestTime(local.toInstant()))
        assertEquals("20260903070809", PaywayRequestBuilder.formatRequestTime(Instant.parse("2026-09-03T07:08:09Z")))
    }

    @Test
    fun `invalid request time is rejected`() {
        assertFailsWith<IllegalArgumentException> { Spec.builder().exchangeRate(requestTime = "2026-01-02") }
    }

    @Test
    fun `amounts are formatted like the PHP samples`() {
        assertEquals("6.5", PaywayRequestBuilder.formatAmount(6.5))
        assertEquals("1", PaywayRequestBuilder.formatAmount(1))
        assertEquals("1", PaywayRequestBuilder.formatAmount(1.0))
        assertEquals("0.1", PaywayRequestBuilder.formatAmount(0.1))
        assertEquals("100", PaywayRequestBuilder.formatAmount(100L))
        assertEquals("6.5", PaywayRequestBuilder.formatAmount(java.math.BigDecimal("6.50")))
        assertEquals("0.1", PaywayRequestBuilder.formatAmount(0.1f))
    }

    @Test
    fun `purchase posts multipart and reads the production fields`() =
        runBlocking {
            val http =
                FakeHttpClient.json(
                    buildJsonObject {
                        put("qrString", "000201...")
                        put("qrImage", "data:image/png;base64,iVBORw0KGgo=")
                        put("abapay_deeplink", "abamobilebank://ababank.com?type=payway")
                        put("app_store", "https://itunes.apple.com/app/id968860649")
                        put("play_store", "https://play.google.com/store/apps/details?id=com.paygo24.ibank")
                        putJsonObject("status") {
                            put("code", "00")
                            put("message", "Success!")
                            put("tran_id", "order-1001")
                            put("trace_id", "19b80de5")
                        }
                    },
                )

            val response = service(http).purchase(Spec.fullPurchase())

            assertTrue(response.isSuccess)
            assertEquals("000201...", response.qrString)
            assertTrue(response.qrImage!!.startsWith("data:image/png"))
            assertEquals("abamobilebank://ababank.com?type=payway", response.abapayDeeplink)
            assertEquals("https://itunes.apple.com/app/id968860649", response.appStore)
            assertNotNull(response.playStore)
            assertEquals("19b80de5", response.status.traceId)
            assertEquals("order-1001", response.status.tranId)

            val request = http.requests.single()
            assertEquals("https://payway.test" + PaywayService.PURCHASE_PATH, request.url)
            val contentType = request.headers.getValue("Content-Type")
            assertTrue(contentType.startsWith("multipart/form-data; boundary="), contentType)
            val boundary = contentType.substringAfter("boundary=")
            assertEquals("https://shop.test", request.headers["Referer"])
            assertEquals("kotlin-payway/2.0.0", request.headers["User-Agent"])
            assertEquals("application/json", request.headers["Accept"])
            assertTrue("--$boundary\r\nContent-Disposition: form-data; name=\"tran_id\"\r\n\r\norder-1001\r\n" in request.body)
            assertTrue("name=\"hash\"\r\n\r\n${Spec.knownAnswers["purchase_full"]}\r\n" in request.body)
            assertTrue("name=\"view_type\"\r\n\r\npopup\r\n" in request.body)
            assertTrue(request.body.endsWith("--$boundary--\r\n"))
        }

    @Test
    fun `purchase reads the sandbox field names too`() =
        runBlocking {
            val response =
                service(
                    FakeHttpClient.json(
                        """{"qr_string":"abc","checkout_qr_url":"https://checkout-sandbox.payway.com.kh/qr","status":{"code":"00","message":"Success!"}}""",
                    ),
                ).purchase(PaywayPurchase("x", 1, paymentOption = PaywayPaymentOption.ABAPAY_KHQR_DEEPLINK))
            assertEquals("abc", response.qrString)
            assertEquals("https://checkout-sandbox.payway.com.kh/qr", response.checkoutQrUrl)
        }

    @Test
    fun `purchase needs the deeplink option`() {
        val http = FakeHttpClient.json(ok)
        for (option in listOf(null, PaywayPaymentOption.CARDS, PaywayPaymentOption.ABAPAY_KHQR)) {
            assertFailsWith<IllegalArgumentException> {
                runBlocking { service(http).purchase(PaywayPurchase("x", 1, paymentOption = option)) }
            }
        }
        assertTrue(http.requests.isEmpty())
    }

    @Test
    fun `check transaction posts JSON and lifts a nested status`() =
        runBlocking {
            val http =
                FakeHttpClient.json(
                    """{"data":{"payment_status_code":0,"payment_status":"APPROVED","total_amount":"6.5","status":{"code":"00","message":"Success!"}}}""",
                )

            val response = service(http).checkTransaction("order-1001")

            assertTrue(response.isPaid)
            assertEquals(6.5, response.data?.totalAmount)
            val request = http.requests.single()
            assertEquals("application/json", request.headers["Content-Type"])
            assertEquals("https://payway.test" + PaywayService.CHECK_TRANSACTION_PATH, request.url)
            val body = Json.parseToJsonElement(request.body).jsonObject
            assertEquals(listOf("req_time", "merchant_id", "tran_id", "hash"), body.keys.toList())
            assertEquals("order-1001", body.getValue("tran_id").jsonPrimitive.content)
            assertEquals(Spec.knownAnswers["tran_id_hash"], body.getValue("hash").jsonPrimitive.content)
        }

    @Test
    fun `JSON bodies of every endpoint`() =
        runBlocking {
            val http = FakeHttpClient.json(ok)
            val payway = service(http)
            payway.getTransactionDetail("order-1001")
            payway.closeTransaction("order-1001")
            payway.getTransactionList(PaywayTransactionListQuery(statuses = listOf(PaywayPaymentStatus.DECLINED), pagination = 20))
            payway.getExchangeRates()
            payway.refund("order-1001", 0.5)

            assertEquals(
                listOf(
                    PaywayService.TRANSACTION_DETAIL_PATH,
                    PaywayService.CLOSE_TRANSACTION_PATH,
                    PaywayService.TRANSACTION_LIST_PATH,
                    PaywayService.EXCHANGE_RATE_PATH,
                    PaywayService.REFUND_PATH,
                ).map { "https://payway.test$it" },
                http.requests.map { it.url },
            )
            val bodies = http.requests.map { Json.parseToJsonElement(it.body).jsonObject }
            assertEquals(listOf("req_time", "merchant_id", "status", "pagination", "hash"), bodies[2].keys.toList())
            assertEquals("DECLINDED", bodies[2].getValue("status").jsonPrimitive.content)
            assertEquals(listOf("req_time", "merchant_id", "hash"), bodies[3].keys.toList())
            assertEquals(Spec.knownAnswers["exchange_hash"], bodies[3].getValue("hash").jsonPrimitive.content)
            assertEquals(listOf("request_time", "merchant_id", "merchant_auth", "hash"), bodies[4].keys.toList())
            assertTrue(http.requests.all { it.headers["Content-Type"] == "application/json" })
        }

    @Test
    fun `error status is returned, not thrown, whatever the HTTP status`() =
        runBlocking {
            val response =
                service(
                    FakeHttpClient.json("""{"status":{"code":6,"message":"tran_id not found","tran_id":"x"}}""", 403),
                ).getTransactionDetail("x")
            assertFalse(response.isSuccess)
            assertEquals("6", response.status.code)
            assertEquals("x", response.status.tranId)
            assertNull(response.data)
        }

    @Test
    fun `transaction detail with operations`() =
        runBlocking {
            val response =
                service(
                    FakeHttpClient.json(
                        buildJsonObject {
                            putJsonObject("data") {
                                put("transaction_id", "T1")
                                put("payment_status_code", "0")
                                put("total_amount", 0.1)
                                putJsonArray("transaction_operations") {
                                    add(
                                        buildJsonObject {
                                            put("status", "Completed")
                                            put("amount", 0.1)
                                            put("bank_ref", "FT1")
                                        },
                                    )
                                }
                            }
                            put("status", ok.getValue("status"))
                        },
                    ),
                ).getTransactionDetail("T1")
            val data = assertNotNull(response.data)
            assertTrue(data.isApproved)
            assertEquals(0.1, data.totalAmount)
            assertEquals("FT1", data.transactionOperations.single().bankRef)
            assertEquals(0.1, data.transactionOperations.single().amount)
        }

    @Test
    fun `transaction list`() =
        runBlocking {
            val response =
                service(
                    FakeHttpClient.json(
                        """{"data":[{"transaction_id":"T1","payment_status_code":2,"payment_status":"PENDING","original_amount":"0.10"}],"page":"1","pagination":20,"status":{"code":"00","message":"Success!"}}""",
                    ),
                ).getTransactionList()
            val transaction = response.data.single()
            assertEquals("T1", transaction.transactionId)
            assertEquals(PaywayPaymentStatusCode.PENDING, transaction.paymentStatusCode)
            assertEquals(0.1, transaction.originalAmount)
            assertEquals(1, response.page)
            assertEquals(20, response.pagination)
        }

    @Test
    fun `exchange rates from both layouts`() =
        runBlocking {
            val response =
                service(
                    FakeHttpClient.json(
                        """{"status":{"code":"00","message":"Success"},"exchange_rates":{"usd":{"sell":"4065","buy":"4042"}},"EUR":{"sell":4687.1,"buy":4445.2}}""",
                    ),
                ).getExchangeRates()
            assertTrue(response.isSuccess)
            assertEquals(PaywayExchangeRate(4065.0, 4042.0), response.rates["usd"])
            assertEquals(4687.1, response.rates["eur"]?.sell)
            assertEquals(setOf("usd", "eur"), response.rates.keys)
        }

    @Test
    fun `refund response`() =
        runBlocking {
            val response =
                service(
                    FakeHttpClient.json(
                        """{"grand_total":1,"total_refunded":"0.5","currency":"USD","transaction_status":"REFUNDED","status":{"code":"00","message":"Success"}}""",
                    ),
                ).refund("order-1001", 0.5)
            assertTrue(response.isSuccess)
            assertEquals(1.0, response.grandTotal)
            assertEquals(0.5, response.totalRefunded)
            assertEquals("REFUNDED", response.transactionStatus)
        }

    @Test
    fun `refund without or with an invalid RSA key is an encryption error`() {
        for (key in listOf(null, "", "not a key")) {
            val payway = PaywayService(Spec.merchant(rsaPublicKey = key), FakeHttpClient.json(ok))
            val error = assertFailsWith<PaywayException> { runBlocking { payway.refund("x", 1) } }
            assertEquals(PaywayErrorType.ENCRYPTION, error.type)
            assertFalse(error.isRetryable)
        }
    }

    @Test
    fun `HTML error page is an unexpected response`() {
        val http = FakeHttpClient.json("<html><body>Bad gateway</body></html>", 502)
        val error = assertFailsWith<PaywayException> { runBlocking { service(http).getTransactionList() } }
        assertEquals(PaywayErrorType.UNEXPECTED_RESPONSE, error.type)
        assertEquals(502, error.statusCode)
        assertTrue(error.isRetryable)
    }

    @Test
    fun `JSON without a status is an unexpected response`() {
        for (body in listOf("", "[]", """{"message":"Unauthenticated."}""", """{"status":"ok"}""")) {
            val error = assertFailsWith<PaywayException> { runBlocking { service(FakeHttpClient.json(body, 401)).getExchangeRates() } }
            assertEquals(PaywayErrorType.UNEXPECTED_RESPONSE, error.type)
            assertFalse(error.isRetryable)
        }
    }

    @Test
    fun `transport failures are mapped to error types`() {
        val cases =
            listOf(
                ConnectException("refused") to PaywayErrorType.CONNECTION,
                java.net.UnknownHostException("payway.test") to PaywayErrorType.CONNECTION,
                HttpTimeoutException("slow") to PaywayErrorType.TIMEOUT,
                HttpConnectTimeoutException("slow") to PaywayErrorType.TIMEOUT,
                SSLHandshakeException("bad").apply { initCause(java.security.cert.CertificateException("untrusted")) } to
                    PaywayErrorType.BAD_CERTIFICATE,
                java.util.concurrent.CancellationException("cancelled") to PaywayErrorType.CANCELLED,
                IllegalStateException("boom") to PaywayErrorType.UNKNOWN,
                PaywayException(PaywayErrorType.TIMEOUT, "custom") to PaywayErrorType.TIMEOUT,
            )
        for ((failure, type) in cases) {
            val error = assertFailsWith<PaywayException> { runBlocking { service(FakeHttpClient.failing(failure)).closeTransaction("x") } }
            assertEquals(type, error.type, "$failure")
        }
        assertTrue(PaywayException(PaywayErrorType.CONNECTION, "x").isRetryable)
        assertTrue(PaywayException(PaywayErrorType.TIMEOUT, "x").isRetryable)
    }

    @Test
    fun `checkout HTML escapes every value and posts to PayWay`() {
        val html =
            PaywayService(Spec.merchant(), clock = Spec.clock).checkoutHtml(
                PaywayPurchase("x", 1, firstName = "\"><script>alert(1)</script>", lastName = "O'Neil & <Co>"),
            )
        assertFalse("<script>alert" in html)
        assertTrue("value=\"&quot;&gt;&lt;script&gt;alert(1)&lt;/script&gt;\"" in html)
        assertTrue("value=\"O&#39;Neil &amp; &lt;Co&gt;\"" in html)
        assertTrue("action=\"https://payway.test${PaywayService.PURCHASE_PATH}\"" in html)
        assertTrue("name=\"hash\"" in html)
        assertTrue("<script>document.getElementById(\"payway_checkout\").submit();</script>" in html)
    }

    @Test
    fun `parse callback`() {
        val payway = PaywayService(Spec.merchant())
        val callback = payway.parseCallback(Spec.knownAnswers.getValue("callback_body"))
        assertEquals("9065703303", callback.tranId)
        assertTrue(callback.isSuccess)
        assertEquals(0.01, callback.totalAmount)
        assertEquals("ABA Pay", callback.paymentType)
        assertEquals("""{"order_id":"123","amount":100,"client_id":"1234567890"}""", callback.returnParams)

        for (body in listOf("[]", "not json", "\"x\"")) {
            val error = assertFailsWith<PaywayException> { payway.parseCallback(body) }
            assertEquals(PaywayErrorType.INVALID_CALLBACK, error.type)
        }
    }

    @Test
    fun `the API key never appears in toString`() {
        val merchant = Spec.merchant()
        assertFalse("test-api-key" in merchant.toString())
        assertTrue("apiKey=***" in merchant.toString())
        assertFalse("test-api-key" in PaywayService(merchant).toString())
    }

    @Test
    fun `logger receives requests and responses`() =
        runBlocking {
            val lines = mutableListOf<String>()
            PaywayService(Spec.merchant(), FakeHttpClient.json(ok), Spec.clock, logger = { lines += it }).checkTransaction("order-1001")
            assertEquals(2, lines.size)
            assertTrue(lines[0].startsWith("[PayWay] POST https://payway.test"))
            assertTrue(lines[1].startsWith("[PayWay] 200 "))
            assertFalse(lines.any { "test-api-key" in it })
        }

    @Test
    fun `version matches the Gradle version`() {
        assertEquals(System.getProperty("payway.version"), PaywayService.SDK_VERSION)
        assertEquals("kotlin-payway/${PaywayService.SDK_VERSION}", PaywayService.USER_AGENT)
    }
}
