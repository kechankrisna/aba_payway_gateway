package io.github.kechankrisna.payway.checkout

import com.sun.net.httpserver.HttpServer
import kotlinx.coroutines.runBlocking
import java.net.InetSocketAddress
import java.time.Duration
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

/** The default HTTP client against a local server. */
class JdkPaywayHttpClientTest {
    private val server = HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0)
    private val received = mutableListOf<Pair<Map<String, String>, String>>()

    private val baseUrl get() = "http://127.0.0.1:${server.address.port}"

    init {
        server.createContext("/") { exchange ->
            val headers = exchange.requestHeaders.entries.associate { it.key.lowercase() to it.value.joinToString(",") }
            received += headers to exchange.requestBody.readBytes().toString(Charsets.UTF_8)
            val path = exchange.requestURI.path
            val (status, body) =
                when {
                    path.startsWith("/slow") -> {
                        Thread.sleep(1_000)
                        200 to "{}"
                    }

                    path == "/html" -> {
                        500 to "<html>ស្វាគមន៍</html>"
                    }

                    else -> {
                        400 to """{"status":{"code":"1","message":"Wrong hash"}}"""
                    }
                }
            val bytes = body.toByteArray(Charsets.UTF_8)
            exchange.sendResponseHeaders(status, bytes.size.toLong())
            exchange.responseBody.use { it.write(bytes) }
        }
        server.start()
    }

    @AfterTest
    fun stop() = server.stop(0)

    @Test
    fun `sends headers and body, returns any status`() =
        runBlocking {
            val payway = PaywayService(Spec.merchant().copy(baseUrl = "$baseUrl/"), clock = Spec.clock)
            val response = payway.checkTransaction("order-1001")
            assertEquals("1", response.status.code)
            assertEquals("Wrong hash", response.status.message)

            val (headers, body) = received.single()
            assertEquals("kotlin-payway/2.0.0", headers["user-agent"])
            assertEquals("https://shop.test", headers["referer"])
            assertEquals("application/json", headers["content-type"])
            assertTrue(body.startsWith("""{"req_time":"20260102030405","merchant_id":"ec000002","tran_id":"order-1001","hash":"""))
        }

    @Test
    fun `decodes UTF-8 bodies`() =
        runBlocking {
            val response = JdkPaywayHttpClient().post("$baseUrl/html", emptyMap(), ByteArray(0))
            assertEquals(500, response.statusCode)
            assertEquals("<html>ស្វាគមន៍</html>", response.body)
        }

    @Test
    fun `times out`() {
        val payway = PaywayService(Spec.merchant().copy(baseUrl = "$baseUrl/slow"), JdkPaywayHttpClient(timeout = Duration.ofMillis(200)))
        val error = assertFailsWith<PaywayException> { runBlocking { payway.getExchangeRates() } }
        assertEquals(PaywayErrorType.TIMEOUT, error.type)
    }

    @Test
    fun `connection refused`() {
        // a port that was free a moment ago: nothing listens on it
        val port = java.net.ServerSocket(0, 1, java.net.InetAddress.getLoopbackAddress()).use { it.localPort }
        val payway =
            PaywayService(
                Spec.merchant().copy(baseUrl = "http://127.0.0.1:$port"),
                JdkPaywayHttpClient(timeout = Duration.ofSeconds(10)),
            )
        val error = assertFailsWith<PaywayException> { runBlocking { payway.getExchangeRates() } }
        assertEquals(PaywayErrorType.CONNECTION, error.type)
        assertTrue(error.isRetryable)
    }
}
