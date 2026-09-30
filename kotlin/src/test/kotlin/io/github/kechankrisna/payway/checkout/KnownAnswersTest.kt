package io.github.kechankrisna.payway.checkout

import java.time.LocalDateTime
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Request hashes and callback signatures must equal the known answers in
 * spec/test-vectors, computed with the PHP samples from ABA's docs.
 */
class KnownAnswersTest {
    private val kat = Spec.knownAnswers

    @Test
    fun `purchase with required fields only`() {
        val fields = Spec.builder().purchase(PaywayPurchase(tranId = "order-1001", amount = 6.5))
        assertEquals(
            listOf(
                "req_time" to Spec.REQUEST_TIME,
                "merchant_id" to "ec000002",
                "tran_id" to "order-1001",
                "amount" to "6.5",
                "hash" to kat.getValue("purchase_minimal"),
            ),
            fields.toList(),
        )
    }

    @Test
    fun `purchase with every field`() {
        val fields = Spec.builder().purchase(Spec.fullPurchase())
        assertEquals(kat["purchase_full"], fields["hash"])
        assertEquals(kat["purchase_full_items"], fields["items"])
        assertEquals(kat["purchase_full_return_url"], fields["return_url"])
        assertEquals(kat["purchase_full_return_deeplink"], fields["return_deeplink"])
        assertEquals(kat["purchase_full_payout"], fields["payout"])
        assertEquals("6.5", fields["amount"])
        assertEquals("1", fields["shipping"])
        assertEquals("1", fields["skip_success_page"])
        assertEquals("popup", fields["view_type"])
        assertEquals("0", fields["payment_gate"])
        assertEquals("hash", fields.keys.last())
        // google_pay_token is absent: hashed as empty, not sent
        assertFalse("google_pay_token" in fields)
    }

    @Test
    fun `an explicit request time gives the same hash`() {
        val fields = Spec.builder().purchase(PaywayPurchase("order-1001", 6.5), requestTime = Spec.REQUEST_TIME)
        assertEquals(kat["purchase_minimal"], fields["hash"])
    }

    @Test
    fun `tran id bodies`() {
        val expected =
            listOf(
                "req_time" to Spec.REQUEST_TIME,
                "merchant_id" to "ec000002",
                "tran_id" to "order-1001",
                "hash" to kat.getValue("tran_id_hash"),
            )
        val builder = Spec.builder()
        assertEquals(expected, builder.checkTransaction("order-1001").toList())
        assertEquals(expected, builder.transactionDetail("order-1001").toList())
        assertEquals(expected, builder.closeTransaction("order-1001").toList())
    }

    @Test
    fun `transaction list`() {
        val body =
            Spec.builder().transactionList(
                PaywayTransactionListQuery(
                    fromDate = LocalDateTime.of(2026, 1, 1, 0, 0, 0),
                    toDate = LocalDateTime.of(2026, 1, 31, 23, 59, 59),
                    fromAmount = 1,
                    toAmount = 100.0,
                    statuses = listOf(PaywayPaymentStatus.APPROVED, PaywayPaymentStatus.REFUNDED),
                    page = 2,
                    pagination = 50,
                ),
            )
        assertEquals("2026-01-01 00:00:00", body["from_date"])
        assertEquals("100", body["to_amount"])
        assertEquals("APPROVED,REFUNDED", body["status"])
        assertEquals(kat["list_hash"], body["hash"])
    }

    @Test
    fun `exchange rate`() {
        assertEquals(kat["exchange_hash"], Spec.builder().exchangeRate()["hash"])
    }

    @Test
    fun `callback signatures`() {
        val service = PaywayService(Spec.merchant())
        val body = kat.getValue("callback_body")
        assertTrue(service.verifyCallback(body, kat.getValue("callback_signature")))
        assertTrue(service.verifyCallback(kat.getValue("callback2_body"), kat.getValue("callback2_signature")))
        // header values may carry surrounding whitespace
        assertTrue(service.verifyCallback(body, " ${kat.getValue("callback_signature")}\n"))
        assertFalse(service.verifyCallback(body.replace("0.01", "1000"), kat.getValue("callback_signature")))
        assertFalse(service.verifyCallback(body, "forged"))
        assertFalse(service.verifyCallback(body, kat.getValue("callback_signature"), key = "another-key"))
        assertFalse(service.verifyCallback("not json", kat.getValue("callback_signature")))
        assertFalse(service.verifyCallback("[]", kat.getValue("callback_signature")))
    }
}
