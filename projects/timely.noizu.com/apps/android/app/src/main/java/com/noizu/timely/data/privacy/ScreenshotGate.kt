package com.noizu.timely.data.privacy

import com.noizu.timely.data.remote.dto.EntityKindDto

/**
 * Android never uploads screenshot bytes.
 *
 * This is a structural guarantee, not a checkbox. A UI toggle can be defaulted
 * wrong, flipped by a bad migration, or bypassed by a new screen that forgets to
 * consult it; the user cannot audit any of that. So the guarantee is spread
 * across three places that all have to be broken at once for bytes to leave the
 * device:
 *
 *   1. [com.noizu.timely.data.remote.TimelyApi] has no upload method. There is
 *      no multipart call, no `@Body RequestBody`, nothing that takes image
 *      bytes. Blob access is download-only.
 *   2. [PUSHABLE] is an allowlist, checked by the push queue on the way in.
 *      `screenshot`, `vision_analysis` and `censored_screenshot` are absent, so
 *      the device cannot enqueue a mutation against them even by accident.
 *   3. The app holds no capture permission at all. There is no MediaProjection,
 *      no FOREGROUND_SERVICE, no PACKAGE_USAGE_STATS in the manifest, so there
 *      are no bytes on this device to upload in the first place.
 *
 * Android is a companion, not a capture agent (apps/README.md). The macOS agent
 * captures; this app reviews what the agent already recorded.
 *
 * Each of the three is pinned by a test in `ScreenshotGateTest`.
 */
object ScreenshotGate {

    /**
     * The entity kinds a companion device may enqueue a mutation for.
     *
     * Deliberately absent, and why:
     *   - `screenshot`: carries the blob fields. A companion has no bytes and no
     *     business changing another device's upload state.
     *   - `vision_analysis`: server-produced model output. Read-only here.
     *   - `censored_screenshot`: a privacy decision made by the capture agent at
     *     capture time; a companion editing it would be rewriting the record of
     *     what was redacted.
     *   - `device`: registered and updated through `/api/v1/devices`, not the
     *     mutation channel, so a device cannot rewrite another device's row.
     */
    val PUSHABLE: Set<EntityKindDto> = setOf(
        EntityKindDto.CLIENT,
        EntityKindDto.PROJECT,
        EntityKindDto.TICKET,
        EntityKindDto.TIME_SPAN,
        EntityKindDto.USER_SETTINGS,
    )

    fun mayPush(entity: EntityKindDto): Boolean = entity in PUSHABLE

    /**
     * Thrown rather than logged. A caller that tries to push a screenshot has a
     * logic error that must not degrade into "silently did nothing" -- silence
     * is how a privacy regression ships and nobody notices for a release.
     */
    class NotPushableException(entity: EntityKindDto) : IllegalArgumentException(
        "Android is a companion device and must not push '$entity' mutations. " +
            "See ScreenshotGate: only ${PUSHABLE.joinToString()} may be enqueued.",
    )

    fun require(entity: EntityKindDto) {
        if (!mayPush(entity)) throw NotPushableException(entity)
    }

    /**
     * This device never holds screenshot bytes, so `local_only_screenshots` is
     * reported as true at registration and is not user-configurable. The privacy
     * screen shows it as a fact about the platform rather than a setting, which
     * is the honest presentation: there is no toggle because there is nothing to
     * toggle.
     */
    const val LOCAL_ONLY_SCREENSHOTS: Boolean = true
    const val IS_CAPTURE_AGENT: Boolean = false
}
