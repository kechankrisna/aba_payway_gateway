package io.github.kechankrisna.payway.checkout

import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.JsonUnquotedLiteral
import java.math.BigDecimal
import java.math.BigInteger

/**
 * Lenient readers for PayWay JSON: strings and numbers are read whatever
 * type PayWay actually sends.
 */
internal fun JsonObject.string(vararg keys: String): String = optionalString(*keys) ?: ""

/** First present key wins; numbers and booleans are read as their text. */
internal fun JsonObject.optionalString(vararg keys: String): String? {
    for (key in keys) {
        val value = this[key]
        if (value is JsonPrimitive && value !is JsonNull) return value.content
    }
    return null
}

internal fun JsonObject.double(key: String): Double = optionalDouble(key) ?: 0.0

internal fun JsonObject.optionalDouble(key: String): Double? =
    (this[key] as? JsonPrimitive)
        ?.takeIf {
            it !is JsonNull
        }?.content
        ?.trim()
        ?.toDoubleOrNull()

internal fun JsonObject.optionalInt(key: String): Int? {
    val text = (this[key] as? JsonPrimitive)?.takeIf { it !is JsonNull }?.content?.trim() ?: return null
    return text.toIntOrNull() ?: text.toDoubleOrNull()?.takeIf { it.isFinite() }?.toInt()
}

internal fun JsonObject.obj(key: String): JsonObject? = this[key] as? JsonObject

internal fun JsonObject.objects(key: String): List<JsonObject> =
    when (val value = this[key]) {
        is JsonArray -> value.filterIsInstance<JsonObject>()
        is JsonObject -> value.values.filterIsInstance<JsonObject>()
        else -> emptyList()
    }

/** Plain Kotlin values (maps, lists, strings, numbers, booleans, null) as JSON. */
internal fun toJsonElement(value: Any?): JsonElement =
    when (value) {
        null -> JsonNull
        is JsonElement -> value
        is String -> JsonPrimitive(value)
        is Boolean -> JsonPrimitive(value)
        is Number -> jsonNumber(value)
        is Map<*, *> -> JsonObject(value.entries.associate { (k, v) -> k.toString() to toJsonElement(v) })
        is Iterable<*> -> JsonArray(value.map(::toJsonElement))
        is Array<*> -> JsonArray(value.map(::toJsonElement))
        else -> throw IllegalArgumentException("cannot encode ${value::class.qualifiedName} as JSON")
    }

/** Integers as integers and floating point as JSON numbers (`1.5`, `1.0`), as PHP and Dart encode them. */
@OptIn(ExperimentalSerializationApi::class)
internal fun jsonNumber(value: Number): JsonPrimitive =
    when (value) {
        is Byte, is Short, is Int, is Long -> {
            JsonPrimitive(value.toLong())
        }

        is BigInteger -> {
            JsonUnquotedLiteral(value.toString())
        }

        is BigDecimal -> {
            JsonUnquotedLiteral(value.toPlainString())
        }

        else -> {
            val double = value.toDecimalDouble()
            require(double.isFinite()) { "JSON numbers must be finite, got $value" }
            JsonPrimitive(double)
        }
    }

/** A `Float` as the decimal it prints as (`0.1f` is `0.1`, not `0.10000000149011612`). */
internal fun Number.toDecimalDouble(): Double = if (this is Float) toString().toDouble() else toDouble()

/** JSON without escaping `/` or non-ASCII, like PHP's `JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE`. */
internal fun JsonElement.encode(): String = Json.encodeToString(JsonElement.serializer(), this)
