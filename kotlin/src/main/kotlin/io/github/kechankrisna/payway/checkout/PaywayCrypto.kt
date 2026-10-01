package io.github.kechankrisna.payway.checkout

import kotlinx.serialization.json.JsonObject
import java.math.BigInteger
import java.security.KeyFactory
import java.security.interfaces.RSAPublicKey
import java.security.spec.RSAPublicKeySpec
import java.security.spec.X509EncodedKeySpec
import java.util.Base64
import javax.crypto.Cipher
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

/**
 * Hashing and encryption matching the PHP samples in ABA's checkout docs.
 * Implement it to plug in another backend (an HSM, a KMS, ...); the default
 * is [DefaultPaywayCrypto].
 */
public interface PaywayCrypto {
    /** `base64_encode(hash_hmac('sha512', message, key, true))` */
    public fun hmacSha512Base64(
        message: String,
        key: String,
    ): String

    /** RSA-encrypts [data] (PKCS#1 v1.5, key-size chunks) with [publicKey] and base64s the result. */
    public fun rsaEncrypt(
        data: String,
        publicKey: String,
    ): String
}

/** Default [PaywayCrypto], backed by `javax.crypto` and `java.security`. */
public object DefaultPaywayCrypto : PaywayCrypto {
    /** PKCS#1 v1.5 padding takes 11 bytes of every block */
    private const val PKCS1_PADDING_LENGTH = 11

    override fun hmacSha512Base64(
        message: String,
        key: String,
    ): String {
        val mac = Mac.getInstance("HmacSHA512")
        mac.init(SecretKeySpec(key.toByteArray(Charsets.UTF_8), "HmacSHA512"))
        return Base64.getEncoder().encodeToString(mac.doFinal(message.toByteArray(Charsets.UTF_8)))
    }

    /**
     * Like PHP's `openssl_public_encrypt` with `OPENSSL_PKCS1_PADDING`, in
     * chunks of (key size - 11) bytes, joined and base64-encoded.
     *
     * @throws IllegalArgumentException when [publicKey] is not an RSA public key
     */
    override fun rsaEncrypt(
        data: String,
        publicKey: String,
    ): String {
        val key = parsePublicKey(publicKey)
        val chunkSize = maxOf(1, (key.modulus.bitLength() + 7) / 8 - PKCS1_PADDING_LENGTH)
        val cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding")
        cipher.init(Cipher.ENCRYPT_MODE, key)
        val source = data.toByteArray(Charsets.UTF_8)
        val output = java.io.ByteArrayOutputStream()
        var offset = 0
        while (offset < source.size) {
            val length = minOf(chunkSize, source.size - offset)
            output.write(cipher.doFinal(source, offset, length))
            offset += length
        }
        return Base64.getEncoder().encodeToString(output.toByteArray())
    }

    /**
     * The string PayWay signs a callback with, as in ABA's PHP sample:
     * `ksort` the decoded body, then concatenate its values as PHP converts
     * them to strings, with arrays and objects `json_encode`d using PHP's
     * default flags (`/` escaped as `\/`, non-ASCII as `\uXXXX`).
     */
    public fun callbackSigningString(body: JsonObject): String = PhpValues.callbackSigningString(body)

    /**
     * Parses an RSA public key: PEM `PUBLIC KEY` (X.509 SubjectPublicKeyInfo),
     * PEM `RSA PUBLIC KEY` (PKCS#1), or either as bare base64.
     *
     * @throws IllegalArgumentException when [key] is not an RSA public key
     */
    public fun parsePublicKey(key: String): RSAPublicKey {
        try {
            val der =
                Base64.getDecoder().decode(
                    key
                        .lineSequence()
                        .filterNot { it.trim().startsWith("-----") }
                        .joinToString("")
                        .replace(Regex("\\s"), ""),
                )
            val factory = KeyFactory.getInstance("RSA")
            val sequence = Der(der).sequence()
            val publicKey =
                if (sequence.peekTag() == Der.INTEGER) {
                    // PKCS#1 RSAPublicKey: SEQUENCE { modulus, publicExponent }
                    factory.generatePublic(RSAPublicKeySpec(sequence.integer(), sequence.integer()))
                } else {
                    factory.generatePublic(X509EncodedKeySpec(der))
                }
            return publicKey as RSAPublicKey
        } catch (e: IllegalArgumentException) {
            throw IllegalArgumentException("Invalid RSA public key: ${e.message}", e)
        } catch (e: java.security.GeneralSecurityException) {
            throw IllegalArgumentException("Invalid RSA public key: ${e.message}", e)
        } catch (e: ClassCastException) {
            throw IllegalArgumentException("Invalid RSA public key: not an RSA key", e)
        }
    }
}

/** Minimal DER reader for PKCS#1 public keys. */
private class Der(
    private val bytes: ByteArray,
    private var position: Int = 0,
    private val end: Int = bytes.size,
) {
    fun peekTag(): Int {
        require(position < end) { "truncated DER" }
        return bytes[position].toInt() and 0xff
    }

    fun sequence(): Der {
        val (start, length) = header(SEQUENCE)
        position = start + length
        return Der(bytes, start, start + length)
    }

    fun integer(): BigInteger {
        val (start, length) = header(INTEGER)
        position = start + length
        return BigInteger(bytes.copyOfRange(start, start + length))
    }

    private fun header(expectedTag: Int): Pair<Int, Int> {
        require(peekTag() == expectedTag) { "unexpected DER tag ${peekTag()}" }
        var index = position + 1
        require(index < end) { "truncated DER" }
        var length = bytes[index++].toInt() and 0xff
        if (length and 0x80 != 0) {
            val count = length and 0x7f
            require(count in 1..4 && index + count <= end) { "invalid DER length" }
            length = 0
            repeat(count) { length = (length shl 8) or (bytes[index++].toInt() and 0xff) }
        }
        require(length >= 0 && index + length <= end) { "truncated DER" }
        return index to length
    }

    companion object {
        const val INTEGER = 0x02
        const val SEQUENCE = 0x30
    }
}
