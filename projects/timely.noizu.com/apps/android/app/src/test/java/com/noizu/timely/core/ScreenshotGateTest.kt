package com.noizu.timely.core

import com.noizu.timely.data.privacy.ScreenshotGate
import com.noizu.timely.data.remote.TimelyApi
import com.noizu.timely.data.remote.dto.EntityKindDto
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import retrofit2.http.Body
import retrofit2.http.Multipart
import retrofit2.http.PUT
import retrofit2.http.POST
import retrofit2.http.Part

/**
 * The privacy guarantee, asserted structurally.
 *
 * "Android never uploads screenshot bytes" is only worth anything if it cannot
 * be undone by a well-meaning change. These tests fail the build if someone adds
 * an upload endpoint, widens the push allowlist, or flips the device's
 * capture-agent claim -- none of which would be caught by a UI test or noticed
 * in review of a large diff.
 */
class ScreenshotGateTest {

    @Test
    fun `the API surface has no screenshot upload method`() {
        // The test is "can this method SEND bytes", not "does its path mention
        // blobs". The download endpoint's path is `.../blob`, so a substring
        // match on the annotation flags the very method that proves the point.
        val binaryTypes = setOf(
            "okhttp3.RequestBody",
            "okhttp3.MultipartBody",
            "okhttp3.MultipartBody.Part",
            "byte[]",
            "java.io.File",
            "java.io.InputStream",
        )

        val offenders = TimelyApi::class.java.declaredMethods.filter { method ->
            val multipart = method.isAnnotationPresent(Multipart::class.java) ||
                method.parameterAnnotations.any { annotations -> annotations.any { it is Part } }

            val bodyIsBinary = method.parameterAnnotations
                .withIndex()
                .any { (index, annotations) ->
                    annotations.any { it is Body } &&
                        (method.parameterTypes[index].canonicalName ?: "") in binaryTypes
                }

            val namedUpload = method.name.contains("upload", ignoreCase = true)

            multipart || bodyIsBinary || namedUpload
        }

        if (offenders.isNotEmpty()) {
            fail(
                "TimelyApi gained a method that can send bytes to the server: " +
                    offenders.joinToString { it.name } +
                    ". Android is a companion device and must never upload screenshot " +
                    "data. See ScreenshotGate.",
            )
        }
    }

    @Test
    fun `no endpoint writes to a screenshot or blob path`() {
        // Complements the byte-shape check above: a PUT or PATCH against a
        // screenshot resource would be a write even with a JSON body.
        val writeMethods = TimelyApi::class.java.declaredMethods.filter { method ->
            method.isAnnotationPresent(PUT::class.java) ||
                method.isAnnotationPresent(POST::class.java)
        }
        val screenshotWrites = writeMethods.filter { method ->
            method.annotations.any { annotation ->
                val value = annotation.toString()
                value.contains("screenshot") || value.contains("blob")
            }
        }
        assertTrue(
            "no POST/PUT may target a screenshot resource, found: " +
                screenshotWrites.joinToString { it.name },
            screenshotWrites.isEmpty(),
        )
    }

    @Test
    fun `the only blob method is a download`() {
        val blobMethods = TimelyApi::class.java.declaredMethods
            .filter { it.name.contains("Blob", ignoreCase = true) }
        assertEquals(1, blobMethods.size)
        assertEquals("downloadScreenshotBlob", blobMethods.single().name)
        // A download has no @Body: nothing leaves the device.
        assertTrue(
            "the blob method must not carry a request body",
            blobMethods.single().parameterAnnotations.none { annotations ->
                annotations.any { it is Body }
            },
        )
    }

    @Test
    fun `screenshot-bearing entities cannot be pushed`() {
        for (entity in listOf(
            EntityKindDto.SCREENSHOT,
            EntityKindDto.VISION_ANALYSIS,
            EntityKindDto.CENSORED_SCREENSHOT,
            EntityKindDto.DEVICE,
            EntityKindDto.WORKSPACE_POLICY,
        )) {
            assertFalse("$entity must not be pushable", ScreenshotGate.mayPush(entity))
            try {
                ScreenshotGate.require(entity)
                fail("ScreenshotGate.require($entity) should have thrown")
            } catch (expected: ScreenshotGate.NotPushableException) {
                // The failure has to be loud. A silent no-op here is exactly how
                // a privacy regression ships and survives a release.
            }
        }
    }

    @Test
    fun `the allowlist is exactly the five companion-editable entities`() {
        assertEquals(
            setOf(
                EntityKindDto.CLIENT,
                EntityKindDto.PROJECT,
                EntityKindDto.TICKET,
                EntityKindDto.TIME_SPAN,
                EntityKindDto.USER_SETTINGS,
            ),
            ScreenshotGate.PUSHABLE,
        )
    }

    @Test
    fun `this device never claims to be a capture agent`() {
        assertFalse(ScreenshotGate.IS_CAPTURE_AGENT)
        assertTrue(ScreenshotGate.LOCAL_ONLY_SCREENSHOTS)
    }
}
