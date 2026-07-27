package com.noizu.timely.core.time

import kotlinx.serialization.KSerializer
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import java.time.Instant
import java.time.format.DateTimeFormatter
import java.time.format.DateTimeParseException

/**
 * The wire uses RFC 3339 / ISO 8601 instants ("2026-07-27T09:02:00Z").
 *
 * minSdk is 26, which is exactly where `java.time` became available on Android,
 * so no core-library desugaring is needed.
 */
object InstantSerializer : KSerializer<Instant> {
    override val descriptor: SerialDescriptor =
        PrimitiveSerialDescriptor("java.time.Instant", PrimitiveKind.STRING)

    override fun serialize(encoder: Encoder, value: Instant) {
        encoder.encodeString(DateTimeFormatter.ISO_INSTANT.format(value))
    }

    override fun deserialize(decoder: Decoder): Instant = parse(decoder.decodeString())

    /**
     * The examples in the contract are unquoted YAML timestamps without
     * fractional seconds; real servers commonly emit microseconds and an offset
     * other than Z. Accept the broad ISO form and normalize to an instant.
     */
    fun parse(raw: String): Instant =
        try {
            Instant.parse(raw)
        } catch (_: DateTimeParseException) {
            DateTimeFormatter.ISO_OFFSET_DATE_TIME.parse(raw, Instant::from)
        }
}

fun Instant.toWireString(): String = DateTimeFormatter.ISO_INSTANT.format(this)

fun String.toInstantOrNull(): Instant? =
    takeIf { it.isNotBlank() }?.let { runCatching { InstantSerializer.parse(it) }.getOrNull() }
