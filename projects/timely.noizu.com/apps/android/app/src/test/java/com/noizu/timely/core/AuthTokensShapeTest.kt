package com.noizu.timely.core

import com.noizu.timely.data.remote.dto.AuthTokensDto
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The auth response field names, pinned.
 *
 * The backend confirmed every body in `auth_controller.ex` and
 * `sso_controller.ex` returns `access_token` / `refresh_token`, and that nothing
 * returns a bare `token`. `token` is real, but as an inbound REQUEST parameter
 * on the magic-link and verify-email endpoints -- never as a response field.
 *
 * This test exists because the previous DTO tolerated both, which would have
 * silently accepted a shape the server never sends and hidden a contract break
 * instead of reporting it.
 */
class AuthTokensShapeTest {

    private val json = Json { ignoreUnknownKeys = true; explicitNulls = false }

    @Test
    fun `the real response shape decodes`() {
        val decoded = json.decodeFromString(
            AuthTokensDto.serializer(),
            """
            {"access_token":"at-123","refresh_token":"rt-456","expires_in":3600,
             "token_type":"Bearer",
             "user":{"id":"user-1","email":"a@b.c","organization_id":"ws-1"}}
            """.trimIndent(),
        )

        assertEquals("at-123", decoded.accessToken)
        assertEquals("rt-456", decoded.refreshToken)
        assertEquals("user-1", decoded.user?.id)
        assertEquals("ws-1", decoded.user?.workspaceId)
    }

    @Test
    fun `a bare token field is NOT accepted as an access token`() {
        // If the server ever regressed to sending `token`, this must surface as
        // a null access token -- and therefore a visible sign-in failure --
        // rather than being quietly absorbed.
        val decoded = json.decodeFromString(
            AuthTokensDto.serializer(),
            """{"token":"at-123","refresh_token":"rt-456"}""",
        )

        assertNull(
            "AuthTokensDto must not resurrect the tolerant `token` alternate",
            decoded.accessToken,
        )
    }

    @Test
    fun `the DTO declares no token alternate`() {
        val names = AuthTokensDto::class.java.declaredFields.map { it.name }
        assertTrue(
            "a `token` property reappeared on AuthTokensDto: $names",
            names.none { it == "token" },
        )
        assertTrue(names.contains("accessToken"))
        assertTrue(names.contains("refreshToken"))
    }
}
