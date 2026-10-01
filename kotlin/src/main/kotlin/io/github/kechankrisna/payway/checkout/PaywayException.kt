package io.github.kechankrisna.payway.checkout

/** What went wrong in a [PaywayException]. */
public enum class PaywayErrorType {
    /** PayWay could not be reached (DNS, refused connection, offline, ...) */
    CONNECTION,

    /** the request took longer than the configured timeout */
    TIMEOUT,

    /**
     * the HTTP request was cancelled while the calling coroutine was still
     * active; cancelling the coroutine itself throws `CancellationException`
     */
    CANCELLED,

    /** PayWay's TLS certificate was rejected */
    BAD_CERTIFICATE,

    /** PayWay answered without a PayWay `status` (e.g. an HTML page) */
    UNEXPECTED_RESPONSE,

    /** the refund payload could not be encrypted (missing or invalid RSA key) */
    ENCRYPTION,

    /** a callback body is not the JSON object PayWay sends */
    INVALID_CALLBACK,

    /** any other failure; see [PaywayException.cause] */
    UNKNOWN,
}

/**
 * Thrown when PayWay could not be reached or did not answer with a PayWay
 * status, and for invalid local input such as a missing RSA key. Branch on
 * [type].
 *
 * PayWay business errors (wrong hash, transaction not found, ...) are not
 * thrown: they are returned in the response `status`.
 *
 * @property type what went wrong
 * @property statusCode HTTP status code, when a response was received
 */
public class PaywayException(
    public val type: PaywayErrorType,
    message: String,
    public val statusCode: Int? = null,
    cause: Throwable? = null,
) : RuntimeException(message, cause) {
    /** Whether retrying the same call later may succeed. */
    public val isRetryable: Boolean
        get() =
            when (type) {
                PaywayErrorType.CONNECTION, PaywayErrorType.TIMEOUT -> true
                PaywayErrorType.UNEXPECTED_RESPONSE -> (statusCode ?: 0) >= 500
                else -> false
            }

    override fun toString(): String =
        if (statusCode == null) {
            "PaywayException($type): $message"
        } else {
            "PaywayException($type): $message (HTTP $statusCode)"
        }
}
