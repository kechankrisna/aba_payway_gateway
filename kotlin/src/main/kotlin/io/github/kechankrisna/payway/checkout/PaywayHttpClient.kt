package io.github.kechankrisna.payway.checkout

import kotlinx.coroutines.future.await
import java.io.IOException
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.net.http.HttpTimeoutException
import java.security.cert.CertificateException
import java.time.Duration
import javax.net.ssl.SSLPeerUnverifiedException

/** An HTTP reply: status code and body. */
public class PaywayHttpResponse(
    /** HTTP status code */
    public val statusCode: Int,
    /** response body, decoded as UTF-8 */
    public val body: String,
) {
    override fun toString(): String = "PaywayHttpResponse(statusCode=$statusCode, body=$body)"
}

/**
 * Sends one POST request. Implement it to plug in any HTTP stack (OkHttp,
 * Ktor client, a test fake, ...); the default is [JdkPaywayHttpClient].
 */
public fun interface PaywayHttpClient {
    /**
     * POSTs [body] to [url] with [headers] and returns the reply, whatever
     * its status code. Throw when no reply was received: a
     * [PaywayException], or any exception (an [IOException],
     * [HttpTimeoutException], ...), which the service maps to a
     * [PaywayErrorType].
     */
    public suspend fun post(
        url: String,
        headers: Map<String, String>,
        body: ByteArray,
    ): PaywayHttpResponse
}

/**
 * Default [PaywayHttpClient], backed by the JDK's `java.net.http.HttpClient`.
 * TLS certificates are always verified and redirects are not followed.
 *
 * @param client the JDK client to send with, reused for every call
 * @param timeout whole request timeout
 */
public class JdkPaywayHttpClient(
    private val client: HttpClient = defaultClient(),
    private val timeout: Duration = DEFAULT_TIMEOUT,
) : PaywayHttpClient {
    override suspend fun post(
        url: String,
        headers: Map<String, String>,
        body: ByteArray,
    ): PaywayHttpResponse {
        val request =
            HttpRequest
                .newBuilder(URI.create(url))
                .timeout(timeout)
                .POST(HttpRequest.BodyPublishers.ofByteArray(body))
                .apply { headers.forEach { (name, value) -> header(name, value) } }
                .build()
        val response = client.sendAsync(request, HttpResponse.BodyHandlers.ofString(Charsets.UTF_8)).await()
        return PaywayHttpResponse(response.statusCode(), response.body() ?: "")
    }

    public companion object {
        /** default connect and request timeout */
        public val DEFAULT_TIMEOUT: Duration = Duration.ofSeconds(60)

        /** HTTP/1.1 (as PayWay's samples use), 60 s connect timeout, no redirects. */
        public fun defaultClient(): HttpClient =
            HttpClient
                .newBuilder()
                .version(HttpClient.Version.HTTP_1_1)
                .connectTimeout(DEFAULT_TIMEOUT)
                .followRedirects(HttpClient.Redirect.NEVER)
                .build()
    }
}

/** Maps a failure of [PaywayHttpClient.post] to a [PaywayException]. */
internal fun transportException(error: Throwable): PaywayException =
    when {
        error is PaywayException -> {
            error
        }

        error.causes().any { it is HttpTimeoutException || it is java.net.SocketTimeoutException } -> {
            PaywayException(PaywayErrorType.TIMEOUT, "Timeout with PayWay", cause = error)
        }

        error.causes().any { it is CertificateException || it is SSLPeerUnverifiedException } -> {
            PaywayException(PaywayErrorType.BAD_CERTIFICATE, "Bad certificate from PayWay", cause = error)
        }

        error is java.util.concurrent.CancellationException -> {
            PaywayException(PaywayErrorType.CANCELLED, "Request to PayWay was cancelled", cause = error)
        }

        error is IOException -> {
            PaywayException(PaywayErrorType.CONNECTION, "Could not connect to PayWay", cause = error)
        }

        else -> {
            PaywayException(PaywayErrorType.UNKNOWN, "Request to PayWay failed: ${error.message ?: error}", cause = error)
        }
    }

private fun Throwable.causes(): Sequence<Throwable> = generateSequence(this) { it.cause?.takeIf { cause -> cause !== it } }.take(MAX_CAUSES)

private const val MAX_CAUSES = 16
