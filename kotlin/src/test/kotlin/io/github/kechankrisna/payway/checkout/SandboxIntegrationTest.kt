package io.github.kechankrisna.payway.checkout

import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.Assumptions.assumeFalse
import org.junit.jupiter.api.Assumptions.assumeTrue
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.MethodOrderer
import org.junit.jupiter.api.Order
import org.junit.jupiter.api.Tag
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.TestMethodOrder
import java.io.File
import java.net.URI
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * Integration tests against PayWay checkout, run with `./gradlew integrationTest`.
 * They read merchant credentials from `kotlin/.env`, or the file named by
 * `PAYWAY_ENV_FILE`, and are skipped without one.
 *
 * They create a real transaction (0.10 USD, closed afterwards), so a file
 * pointing at production (checkout.payway.com.kh) is refused unless
 * `PAYWAY_ALLOW_PRODUCTION=true`.
 */
@Tag("integration")
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@TestMethodOrder(MethodOrderer.OrderAnnotation::class)
class SandboxIntegrationTest {
    private val envFile = File(System.getenv("PAYWAY_ENV_FILE") ?: ".env")
    private val tranId = "sdk${System.currentTimeMillis()}"
    private lateinit var payway: PaywayService
    private var created = false

    @BeforeAll
    fun setUp() {
        assumeTrue(envFile.isFile, "no ${envFile.path} with PayWay credentials")
        val env = readEnv(envFile)
        val baseUrl = env["ABA_PAYWAY_API_URL"]?.takeIf { it.isNotEmpty() } ?: PaywayMerchant.SANDBOX_URL
        val isProduction = URI(baseUrl).host == URI(PaywayMerchant.PRODUCTION_URL).host
        assumeFalse(
            isProduction && System.getenv("PAYWAY_ALLOW_PRODUCTION") != "true",
            "${envFile.path} points at production; set PAYWAY_ALLOW_PRODUCTION=true to run tests that create real transactions",
        )
        payway =
            PaywayService(
                PaywayMerchant(
                    merchantId = env["ABA_PAYWAY_MERCHANT_ID"].orEmpty(),
                    apiKey = env["ABA_PAYWAY_API_KEY"].orEmpty(),
                    referer = env["ABA_PAYWAY_REFERER_DOMAIN"].orEmpty(),
                    rsaPublicKey = env["ABA_PAYWAY_RSA_PUBLIC_KEY"]?.takeIf { it.isNotEmpty() },
                    baseUrl = baseUrl,
                ),
                logger = { println(it) },
            )
    }

    // close only the transaction this run created, never someone else's
    @AfterAll
    fun tearDown() {
        if (created) runBlocking { payway.closeTransaction(tranId) }
    }

    @Test
    @Order(1)
    fun `purchase with abapay_khqr_deeplink returns a KHQR`() =
        runBlocking {
            val response =
                payway.purchase(
                    PaywayPurchase(
                        tranId = tranId,
                        amount = 0.1,
                        currency = PaywayCurrency.USD,
                        paymentOption = PaywayPaymentOption.ABAPAY_KHQR_DEEPLINK,
                        items = listOf(PaywayItem("test item", 1, 0.1)),
                    ),
                )
            created = true
            assertTrue(response.isSuccess, "${response.status}")
            assertFalse(response.qrString.isNullOrEmpty())
        }

    @Test
    @Order(2)
    fun `the new transaction is pending in check and details`() =
        runBlocking {
            // a new transaction takes a moment to appear
            var check = payway.checkTransaction(tranId)
            repeat(9) {
                if (check.isSuccess) return@repeat
                delay(1_000)
                check = payway.checkTransaction(tranId)
            }
            assertTrue(check.isSuccess, "${check.status}")
            assertEquals(PaywayPaymentStatusCode.PENDING, check.data?.paymentStatusCode)

            val detail = payway.getTransactionDetail(tranId)
            assertTrue(detail.isSuccess, "${detail.status}")
            assertEquals(0.1, detail.data?.totalAmount)
        }

    @Test
    @Order(3)
    fun `the new transaction is in the transaction list`() =
        runBlocking {
            val list =
                payway.getTransactionList(
                    PaywayTransactionListQuery(statuses = listOf(PaywayPaymentStatus.PENDING), pagination = 20),
                )
            assertTrue(list.isSuccess, "${list.status}")
            assertTrue(list.data.any { it.transactionId == tranId }, "$tranId not in ${list.data.map { it.transactionId }}")
        }

    @Test
    @Order(4)
    fun `closing the new transaction succeeds`() =
        runBlocking {
            val closed = payway.closeTransaction(tranId)
            assertTrue(closed.isSuccess, "${closed.status}")
        }

    @Test
    @Order(5)
    fun `check transaction of an unknown id is reported, not thrown`() =
        runBlocking {
            assertFalse(payway.checkTransaction("sdk-unknown-0").isSuccess)
        }

    @Test
    @Order(6)
    fun `exchange rates`() =
        runBlocking {
            val response = payway.getExchangeRates()
            assertTrue(response.isSuccess, "${response.status}")
            val usd = assertNotNull(response.rates["usd"])
            assertTrue(usd.sell > 1000, "rates are riel per unit")
        }

    /** `KEY=value` lines; quotes around the value are removed, `#` lines ignored. */
    private fun readEnv(file: File): Map<String, String> =
        file
            .readLines()
            .map { it.trim() }
            .filter { it.isNotEmpty() && !it.startsWith("#") && '=' in it }
            .associate { line ->
                val key =
                    line
                        .substringBefore('=')
                        .trim()
                        .removePrefix("export ")
                        .trim()
                val value = line.substringAfter('=').trim()
                val unquoted =
                    if (value.length >= 2 && (value.first() == '"' || value.first() == '\'') && value.last() == value.first()) {
                        value.substring(1, value.length - 1).replace("\\n", "\n")
                    } else {
                        value
                    }
                key to unquoted
            }
}
