package com.noizu.timely.core.identity

import java.security.MessageDigest
import java.security.SecureRandom
import java.nio.ByteBuffer
import java.util.Locale
import java.util.UUID

/**
 * UUID minting for the sync protocol (SYNC-PROTOCOL.md section 3).
 *
 * Event-like entities (time_span, screenshot, vision_analysis,
 * censored_screenshot, device, mutation_id) use v7 so primary-key inserts stay
 * append-mostly on the server.
 *
 * Name-keyed taxonomy (client, project, ticket, user_settings) uses v5 so two
 * offline devices that vivify the same name converge on the same id with no
 * coordination. This is the single most important trick in the protocol.
 */
object Uuids {

    private val random = SecureRandom()

    /** Lowercase canonical string form, which is what the wire contract requires. */
    fun format(uuid: UUID): String = uuid.toString().lowercase(Locale.ROOT)

    // ---------------------------------------------------------------- v7 ----

    /**
     * UUIDv7: 48-bit big-endian Unix epoch milliseconds, then 4 version bits,
     * 12 bits of randomness, 2 variant bits, and 62 more random bits.
     *
     * Layout (RFC 9562 section 5.7):
     *   0                   1                   2                   3
     *   |         unix_ts_ms (48 bits)          | ver |   rand_a    |
     *   | var |              rand_b (62 bits)                       |
     */
    @JvmOverloads
    fun v7(unixMillis: Long = System.currentTimeMillis()): UUID {
        val randomBytes = ByteArray(10)
        random.nextBytes(randomBytes)

        val timestamp = unixMillis and 0xFFFF_FFFF_FFFFL
        // rand_a is 12 bits, sitting just below the version nibble.
        val randA = ((randomBytes[0].toLong() and 0x0F) shl 8) or (randomBytes[1].toLong() and 0xFF)
        val msb = (timestamp shl 16) or (0x7L shl 12) or randA

        var lsb = 0L
        for (i in 2 until 10) {
            lsb = (lsb shl 8) or (randomBytes[i].toLong() and 0xFF)
        }
        // Variant 10xx in the two most significant bits of the low half.
        lsb = (lsb and 0x3FFF_FFFF_FFFF_FFFFL) or Long.MIN_VALUE

        return UUID(msb, lsb)
    }

    fun v7String(unixMillis: Long = System.currentTimeMillis()): String = format(v7(unixMillis))

    // ---------------------------------------------------------------- v5 ----

    /**
     * UUIDv5: SHA-1 over (namespace bytes || name bytes), with version and
     * variant bits overwritten.
     *
     * SHA-1 is required by RFC 9562 for v5. It is used here as a deterministic
     * derivation function, not as a security primitive -- collision resistance
     * is not the property being relied on, agreement across three independent
     * implementations is.
     */
    fun v5(namespace: UUID, name: String): UUID {
        val digest = MessageDigest.getInstance("SHA-1")
        digest.update(toBytes(namespace))
        digest.update(name.toByteArray(Charsets.UTF_8))
        val hash = digest.digest()

        hash[6] = ((hash[6].toInt() and 0x0F) or 0x50).toByte()   // version 5
        hash[8] = ((hash[8].toInt() and 0x3F) or 0x80).toByte()   // variant 10xx

        val buffer = ByteBuffer.wrap(hash, 0, 16)
        return UUID(buffer.long, buffer.long)
    }

    fun v5String(namespace: UUID, name: String): String = format(v5(namespace, name))

    private fun toBytes(uuid: UUID): ByteArray =
        ByteBuffer.allocate(16)
            .putLong(uuid.mostSignificantBits)
            .putLong(uuid.leastSignificantBits)
            .array()

    fun parse(value: String): UUID = UUID.fromString(value)

    fun parseOrNull(value: String?): UUID? =
        value?.takeIf { it.isNotBlank() }?.let {
            runCatching { UUID.fromString(it) }.getOrNull()
        }
}

/**
 * Deterministic taxonomy ids, per SYNC-PROTOCOL.md section 3.2.
 *
 *   namespace   = workspace_id
 *   client_id   = uuidv5(namespace, "client:"  + canon(name))
 *   project_id  = uuidv5(namespace, "project:" + canon(client_name) + "/" + canon(name))
 *   ticket_id   = uuidv5(namespace, "ticket:"  + canon(client_name) + "/" + canon(project_name) + "/" + canon(name))
 *
 * Note that the *parent* components are canonicalized too, and that a missing
 * parent contributes an empty segment rather than being omitted -- otherwise
 * a client-less project and a project under a client named "" would collide.
 */
object TaxonomyIds {

    // ------------------------------------------------------------- keys ----
    //
    // The key is built even when a component canons to empty -- an absent
    // parent contributes an empty segment ("project:/internal") rather than
    // being omitted. Dropping the segment instead would let a client-less
    // project collide with a project under a client whose name canons to "".

    fun clientKey(name: String): String = "client:" + canon(name)

    fun projectKey(clientName: String, name: String): String =
        "project:" + canon(clientName) + "/" + canon(name)

    fun ticketKey(clientName: String, projectName: String, name: String): String =
        "ticket:" + canon(clientName) + "/" + canon(projectName) + "/" + canon(name)

    fun userSettingsKey(userId: String): String = "user_settings:$userId"

    // -------------------------------------------------------------- ids ----

    fun clientId(workspaceId: UUID, name: String): UUID =
        Uuids.v5(workspaceId, clientKey(name))

    fun projectId(workspaceId: UUID, clientName: String, name: String): UUID =
        Uuids.v5(workspaceId, projectKey(clientName, name))

    fun ticketId(workspaceId: UUID, clientName: String, projectName: String, name: String): UUID =
        Uuids.v5(workspaceId, ticketKey(clientName, projectName, name))

    /** `id` is deterministic: UUIDv5(workspace_id, "user_settings:" + user_id). */
    fun userSettingsId(workspaceId: UUID, userId: String): UUID =
        Uuids.v5(workspaceId, userSettingsKey(userId))

    // ------------------------------------------------- vivification gate ----
    //
    // A name that canons to empty is "no reference", NOT an entity named ""
    // (protocol 3.3 and 6.1 step 5). These are the functions the repository
    // layer must call when turning a user-typed name into a row: they return
    // null rather than minting an id for nothing. The non-null variants above
    // exist for the case where the caller has already established the name is
    // real, and for the conformance fixtures, which pin the key even when the
    // id is null.

    fun clientIdOrNull(workspaceId: UUID, name: String): UUID? =
        Canon.canonOrNull(name)?.let { Uuids.v5(workspaceId, "client:$it") }

    /**
     * A project needs its own name; a null/blank *client* is legal and simply
     * contributes an empty parent segment.
     */
    fun projectIdOrNull(workspaceId: UUID, clientName: String?, name: String): UUID? =
        Canon.canonOrNull(name)?.let {
            Uuids.v5(workspaceId, "project:" + canon(clientName ?: "") + "/" + it)
        }

    fun ticketIdOrNull(
        workspaceId: UUID,
        clientName: String?,
        projectName: String?,
        name: String,
    ): UUID? = Canon.canonOrNull(name)?.let {
        Uuids.v5(
            workspaceId,
            "ticket:" + canon(clientName ?: "") + "/" + canon(projectName ?: "") + "/" + it,
        )
    }

    // String-typed convenience wrappers for the repository layer, which holds
    // ids as lowercase strings to match the wire and the Room columns.

    fun clientIdOrNull(workspaceId: String, name: String): String? =
        clientIdOrNull(Uuids.parse(workspaceId), name)?.let(Uuids::format)

    fun projectIdOrNull(workspaceId: String, clientName: String?, name: String): String? =
        projectIdOrNull(Uuids.parse(workspaceId), clientName, name)?.let(Uuids::format)

    fun ticketIdOrNull(
        workspaceId: String,
        clientName: String?,
        projectName: String?,
        name: String,
    ): String? = ticketIdOrNull(Uuids.parse(workspaceId), clientName, projectName, name)
        ?.let(Uuids::format)

    fun userSettingsId(workspaceId: String, userId: String): String =
        Uuids.format(userSettingsId(Uuids.parse(workspaceId), userId))
}
