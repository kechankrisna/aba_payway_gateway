package io.github.kechankrisna.payway.checkout

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import java.math.BigDecimal
import java.math.MathContext
import java.math.RoundingMode
import kotlin.math.abs

/**
 * How PHP 8 turns `json_decode($body, true)` values into strings, which is
 * what PayWay's callback signature is computed over.
 */
internal object PhpValues {
    /** `precision` ini default: `(string) $float` */
    private const val STRING_PRECISION = 14

    /** `serialize_precision = -1`: `json_encode($float)`, shortest round trip */
    private const val JSON_PRECISION = 17

    /** `ksort($body)`, then `$b4hash .= $value` with arrays `json_encode`d. */
    fun callbackSigningString(body: JsonObject): String =
        body.keys.sorted().joinToString("") { key ->
            when (val value = body.getValue(key)) {
                is JsonPrimitive -> scalarToString(value)
                else -> jsonEncode(value)
            }
        }

    /** `(string) $value` of a decoded JSON scalar. */
    fun scalarToString(value: JsonPrimitive): String =
        when {
            value is JsonNull -> {
                ""
            }

            value.isString -> {
                value.content
            }

            value.content == "true" -> {
                "1"
            }

            value.content == "false" -> {
                ""
            }

            else -> {
                when (val number = decodeNumber(value.content)) {
                    is Long -> number.toString()
                    else -> gcvt(number.toDouble(), STRING_PRECISION, 'E', shortest = false)
                }
            }
        }

    /** `json_encode($value)` with PHP's default flags. */
    fun jsonEncode(value: JsonElement): String = StringBuilder().also { encode(value, it) }.toString()

    private fun encode(
        value: JsonElement,
        out: StringBuilder,
    ) {
        when (value) {
            is JsonNull -> {
                out.append("null")
            }

            is JsonPrimitive -> {
                when {
                    value.isString -> {
                        quote(value.content, out)
                    }

                    value.content == "true" || value.content == "false" -> {
                        out.append(value.content)
                    }

                    else -> {
                        when (val number = decodeNumber(value.content)) {
                            is Long -> out.append(number)
                            else -> out.append(gcvt(number.toDouble(), JSON_PRECISION, 'e', shortest = true))
                        }
                    }
                }
            }

            is JsonArray -> {
                encodeList(value, out)
            }

            // json_decode turns an object into a PHP array; one keyed 0..n-1
            // (including the empty object) is encoded back as a list
            is JsonObject -> {
                if (value.keys.withIndex().all { (index, key) -> key == index.toString() }) {
                    encodeList(value.values.toList(), out)
                } else {
                    out.append('{')
                    value.entries.forEachIndexed { index, (key, element) ->
                        if (index > 0) out.append(',')
                        quote(key, out)
                        out.append(':')
                        encode(element, out)
                    }
                    out.append('}')
                }
            }
        }
    }

    private fun encodeList(
        values: List<JsonElement>,
        out: StringBuilder,
    ) {
        out.append('[')
        values.forEachIndexed { index, element ->
            if (index > 0) out.append(',')
            encode(element, out)
        }
        out.append(']')
    }

    private fun quote(
        value: String,
        out: StringBuilder,
    ) {
        out.append('"')
        for (char in value) {
            when {
                char == '"' -> out.append("\\\"")
                char == '\\' -> out.append("\\\\")
                char == '/' -> out.append("\\/")
                char == '\b' -> out.append("\\b")
                char == '\u000C' -> out.append("\\f")
                char == '\n' -> out.append("\\n")
                char == '\r' -> out.append("\\r")
                char == '\t' -> out.append("\\t")
                char.code < 0x20 || char.code > 0x7f -> out.append("\\u").append(char.code.toString(16).padStart(4, '0'))
                else -> out.append(char)
            }
        }
        out.append('"')
    }

    /** json_decode: integers that fit in 64 bits are ints, anything else a float. */
    private fun decodeNumber(literal: String): Number {
        val isInteger = literal.none { it == '.' || it == 'e' || it == 'E' }
        return (if (isInteger) literal.toLongOrNull() else null) ?: literal.toDouble()
    }

    /**
     * PHP's `zend_gcvt`: [precision] significant digits (or the shortest
     * round-trip digits when [shortest]), exponential notation below 1e-4 or
     * beyond [precision] integer digits, without a trailing `.0`.
     */
    fun gcvt(
        value: Double,
        precision: Int,
        exponentChar: Char,
        shortest: Boolean,
    ): String {
        if (value.isNaN()) return "NAN"
        if (value.isInfinite()) return if (value > 0) "INF" else "-INF"
        if (value == 0.0) return if (1.0 / value < 0) "-0" else "0"
        val magnitude = abs(value)
        val decimal =
            if (shortest) {
                BigDecimal(magnitude.toString())
            } else {
                BigDecimal(magnitude).round(MathContext(precision, RoundingMode.HALF_EVEN))
            }.stripTrailingZeros()
        val digits = decimal.unscaledValue().toString()
        // position of the decimal point: value = 0.<digits> x 10^point
        val point = digits.length - decimal.scale()
        val sign = if (value < 0) "-" else ""
        val exponential = if (point < 0) point < -3 else point > precision
        val text =
            when {
                exponential -> {
                    val exponent = point - 1
                    val mantissa = digits.take(1) + "." + digits.drop(1).ifEmpty { "0" }
                    "$mantissa$exponentChar${if (exponent < 0) '-' else '+'}${abs(exponent)}"
                }

                point <= 0 -> {
                    "0." + "0".repeat(-point) + digits
                }

                digits.length <= point -> {
                    digits + "0".repeat(point - digits.length)
                }

                else -> {
                    digits.substring(0, point) + "." + digits.substring(point)
                }
            }
        return sign + text
    }
}
