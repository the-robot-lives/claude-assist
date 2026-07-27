import Foundation
import Testing
@testable import TimelyKit

/// The central product commitment: **the app is fully usable read/write with a
/// dead token and no network.** Sync is background reconciliation, never a
/// precondition for tracking time.
///
/// If any test in this suite fails, a user on a plane cannot start a timer.
@Suite("Offline and expired-token behaviour")
struct OfflineAuthTests {

    // MARK: - Writes never gate on auth

    @Test("local writes succeed with an expired access token")
    func writesWorkWithExpiredToken() async throws {
        let harness = try await SyncHarness(tokens: .expired())

        let span = TimeSpan.test(title: "written while expired")
        let (saved, mutation) = try await harness.store.recordLocalChange(
            .create, entity: span, deviceID: Fixed.deviceA
        )

        #expect(saved.title == "written while expired")
        #expect(try await harness.store.fetch(TimeSpan.self, id: span.id) != nil)
        #expect(try await harness.store.queueDepth(workspaceID: Fixed.workspace) == 1)
        #expect(mutation.mutationID.version == 7)

        // Not one network call was made to save the user's work.
        #expect(harness.transport.requestCount == 0)
    }

    @Test("local writes succeed with no session at all")
    func writesWorkWithNoSession() async throws {
        let harness = try await SyncHarness(tokens: nil)

        let span = TimeSpan.test(title: "written signed out")
        try await harness.store.recordLocalChange(
            .create, entity: span, deviceID: Fixed.deviceA
        )

        #expect(try await harness.store.fetch(TimeSpan.self, id: span.id)?.title == "written signed out")
        #expect(try await harness.store.queueDepth(workspaceID: Fixed.workspace) == 1)
        #expect(harness.transport.requestCount == 0)
    }

    @Test("reads work with no session at all")
    func readsWorkOffline() async throws {
        let harness = try await SyncHarness(tokens: nil)

        try await harness.store.upsertAll((0..<10).map {
            TimeSpan.test(
                title: "span-\($0)",
                start: Fixed.date(Double($0) * 3600),
                end: Fixed.date(Double($0) * 3600 + 1800)
            )
        })

        let timeline = try await harness.store.fetchInRange(
            TimeSpan.self, workspaceID: Fixed.workspace,
            from: Fixed.date(-1), to: Fixed.date(100_000)
        )
        #expect(timeline.count == 10)
        #expect(harness.transport.requestCount == 0)
    }

    /// A whole offline working day: start a timer, stop it, edit it, delete
    /// another — all with a dead token — and everything is queued in order.
    @Test("a full offline working day queues in order")
    func offlineWorkingDay() async throws {
        let harness = try await SyncHarness(tokens: .expired())

        var span = TimeSpan.test(title: "morning", start: Fixed.date(0), end: nil)
        try await harness.store.recordLocalChange(.create, entity: span, deviceID: Fixed.deviceA)

        // Stop the timer.
        span.end = Fixed.date(3600)
        try await harness.store.recordLocalChange(.update, entity: span, deviceID: Fixed.deviceA)

        // Correct the title.
        span.title = "morning — corrected"
        try await harness.store.recordLocalChange(.update, entity: span, deviceID: Fixed.deviceA)

        // Delete a mistake.
        let mistake = TimeSpan.test(title: "mistake")
        try await harness.store.upsert(mistake)
        try await harness.store.recordLocalChange(.delete, entity: mistake, deviceID: Fixed.deviceA)

        #expect(harness.transport.requestCount == 0, "no network was reachable")
        #expect(try await harness.store.queueDepth(workspaceID: Fixed.workspace) == 4)

        let stored = try await harness.store.fetch(TimeSpan.self, id: span.id)
        #expect(stored?.title == "morning — corrected")
        #expect(stored?.isOpen == false)

        let deleted = try await harness.store.fetch(TimeSpan.self, id: mistake.id)
        #expect(deleted?.isDeleted == true)

        // FIFO: the create precedes both updates, which precede the delete.
        let queue = try await harness.store.nextBatch(workspaceID: Fixed.workspace)
        #expect(queue.map(\.operation) == [.create, .update, .update, .delete])
    }

    // MARK: - Sync degrades quietly

    @Test("a sync with no session is a no-op, not an error")
    func syncWithoutSessionIsNoOp() async throws {
        let harness = try await SyncHarness(tokens: nil)
        let span = TimeSpan.test()
        try await harness.store.recordLocalChange(.create, entity: span, deviceID: Fixed.deviceA)

        let outcome = try await harness.engine.sync()

        #expect(outcome.skipped)
        #expect(outcome.reason == .noSession)
        #expect(harness.transport.requestCount == 0)
        // The work is still queued, waiting for a session.
        #expect(try await harness.store.queueDepth(workspaceID: Fixed.workspace) == 1)
    }

    /// A dead refresh token means the user must sign in again — but their data
    /// and their queue are untouched.
    @Test("an expired session does not discard queued work")
    func expiredSessionKeepsQueue() async throws {
        let harness = try await SyncHarness(tokens: .expired())
        let span = TimeSpan.test()
        try await harness.store.recordLocalChange(.create, entity: span, deviceID: Fixed.deviceA)

        // The refresh is rejected: the refresh token itself is dead.
        harness.transport.script([
            .json(401, "{\"code\":\"token_expired\",\"message\":\"refresh rejected\"}")
        ])

        let outcome = try await harness.engine.sync()

        #expect(outcome.skipped)
        #expect(outcome.reason == .sessionExpired)
        #expect(try await harness.store.queueDepth(workspaceID: Fixed.workspace) == 1)
        #expect(try await harness.store.fetch(TimeSpan.self, id: span.id) != nil)
    }

    /// And the app keeps working afterwards.
    @Test("writes still work after the session is declared dead")
    func writesSurviveDeadSession() async throws {
        let harness = try await SyncHarness(tokens: .expired())
        harness.transport.script([.json(401, "{\"code\":\"token_expired\",\"message\":\"no\"}")])
        _ = try await harness.engine.sync()

        let after = TimeSpan.test(title: "after the session died")
        try await harness.store.recordLocalChange(.create, entity: after, deviceID: Fixed.deviceA)

        #expect(try await harness.store.fetch(TimeSpan.self, id: after.id) != nil)
        #expect(try await harness.store.queueDepth(workspaceID: Fixed.workspace) == 1)
    }

    // MARK: - Refresh on 401

    /// The contract's rule for `bearerAuth`: on a 401, refresh once and retry
    /// the original request once.
    @Test("an expired access token refreshes and the request replays")
    func refreshAndReplay() async throws {
        let harness = try await SyncHarness(tokens: .expired())

        harness.transport.respond { request, index in
            let path = request.url?.path ?? ""
            if path.contains("auth/refresh") {
                return .json(200, """
                {"access_token":"new-access","refresh_token":"refresh-2","expires_in":3600}
                """)
            }
            return .json(200, Wire.changesResponse(nextCursor: 5))
            _ = index
        }

        let outcome = try await harness.engine.pull()
        #expect(outcome.cursor == 5)

        // The pull request must have carried the refreshed bearer token.
        let pullRequest = harness.transport.requests.first {
            $0.url?.path.contains("sync/changes") == true
        }
        #expect(
            pullRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer new-access"
        )
    }

    /// A 401 arriving on a token the client believed fresh (revoked session,
    /// clock skew) must still trigger exactly one refresh and one replay.
    @Test("an unexpected 401 refreshes once and replays once")
    func unexpected401RefreshesOnce() async throws {
        let harness = try await SyncHarness(tokens: .fresh())

        harness.transport.respond { request, index in
            let path = request.url?.path ?? ""
            if path.contains("auth/refresh") {
                return .json(200, """
                {"access_token":"rotated","refresh_token":"refresh-2","expires_in":3600}
                """)
            }
            // The first data request 401s; the replay succeeds.
            if index == 0 {
                return .json(401, "{\"code\":\"token_expired\",\"message\":\"expired\"}")
            }
            return .json(200, Wire.changesResponse(nextCursor: 11))
        }

        let outcome = try await harness.engine.pull()

        #expect(outcome.cursor == 11)
        // Exactly three calls: the 401, the refresh, the replay. Not a loop.
        #expect(harness.transport.requestCount == 3)
    }

    /// A refresh storm must collapse into one refresh. The server rotates the
    /// refresh token, so two concurrent refreshes would leave one caller holding
    /// a token the server has already retired.
    @Test("concurrent refreshes collapse into one")
    func concurrentRefreshCollapses() async throws {
        let transport = StubTransport()
        let auth = AuthClient(
            baseURL: URL(string: "https://timely.test")!,
            transport: transport,
            tokenStore: InMemoryTokenStore(tokens: .expired())
        )

        transport.respond { _, _ in
            .json(200, """
            {"access_token":"one-and-only","refresh_token":"refresh-2","expires_in":3600}
            """)
        }

        async let a = auth.refresh()
        async let b = auth.refresh()
        async let c = auth.refresh()
        let results = try await [a, b, c]

        #expect(results.allSatisfy { $0.accessToken == "one-and-only" })
        #expect(transport.requestCount == 1, "three concurrent refreshes must make one call")
    }

    // MARK: - Token custody

    @Test("sign-in stores tokens and sign-out clears them")
    func signInAndOut() async throws {
        let transport = StubTransport()
        let tokenStore = InMemoryTokenStore()
        let auth = AuthClient(
            baseURL: URL(string: "https://timely.test")!,
            transport: transport,
            tokenStore: tokenStore
        )

        transport.script([.json(200, """
        {"access_token":"a","refresh_token":"r","expires_in":3600,
         "user_id":"019318a0-0000-7000-8000-000000000001",
         "workspace_id":"0192f7a1-2b44-7000-8a10-9d3e4f5a6b7c"}
        """)])

        let tokens = try await auth.signIn(email: "keith@example.com", password: "hunter2")
        #expect(tokens.accessToken == "a")
        #expect(tokens.workspaceID == Fixed.workspace)
        #expect(try tokenStore.load() != nil)

        try await auth.signOut()
        #expect(try tokenStore.load() == nil)
    }

    @Test("bad credentials report as invalid rather than as a transport failure")
    func badCredentials() async throws {
        let transport = StubTransport()
        let auth = AuthClient(
            baseURL: URL(string: "https://timely.test")!,
            transport: transport,
            tokenStore: InMemoryTokenStore()
        )
        transport.script([.json(401, "{\"code\":\"invalid\",\"message\":\"nope\"}")])

        await #expect(throws: AuthError.invalidCredentials) {
            try await auth.signIn(email: "a@b.c", password: "wrong")
        }
    }

    /// Signing out must not delete the user's time records. It ends a session,
    /// it is not a request to erase a month of work.
    @Test("sign-out leaves the local store and queue intact")
    func signOutKeepsData() async throws {
        let harness = try await SyncHarness(tokens: .fresh())
        let span = TimeSpan.test(title: "mine")
        try await harness.store.recordLocalChange(.create, entity: span, deviceID: Fixed.deviceA)

        try await harness.auth.signOut()

        #expect(try await harness.store.fetch(TimeSpan.self, id: span.id)?.title == "mine")
        #expect(try await harness.store.queueDepth(workspaceID: Fixed.workspace) == 1)
    }

    /// A refresh response that omits the refresh token is conformant — the
    /// server simply is not rotating it. Reusing the old one is correct.
    @Test("a non-rotating refresh response reuses the existing refresh token")
    func nonRotatingRefresh() async throws {
        let tokenStore = InMemoryTokenStore(tokens: .expired())
        let transport = StubTransport()
        let auth = AuthClient(
            baseURL: URL(string: "https://timely.test")!,
            transport: transport,
            tokenStore: tokenStore
        )

        transport.script([.json(200, """
        {"access_token":"fresh-again","expires_in":3600}
        """)])

        let refreshed = try await auth.refresh()
        #expect(refreshed.accessToken == "fresh-again")
        #expect(refreshed.refreshToken == "refresh-1", "the old refresh token must be retained")
    }

    // MARK: - Recovery

    /// The full arc: work offline, sign in, and everything drains.
    @Test("queued offline work drains once a session returns")
    func offlineWorkDrainsAfterSignIn() async throws {
        let harness = try await SyncHarness(tokens: nil)

        var mutationIDs: [UUID] = []
        for index in 0..<3 {
            let span = TimeSpan.test(title: "offline-\(index)")
            let (_, mutation) = try await harness.store.recordLocalChange(
                .create, entity: span, deviceID: Fixed.deviceA
            )
            mutationIDs.append(mutation.mutationID)
        }

        #expect(try await harness.engine.sync().reason == .noSession)
        #expect(try await harness.store.queueDepth(workspaceID: Fixed.workspace) == 3)

        // The user signs in.
        try await harness.auth.adopt(.fresh())

        let captured = mutationIDs
        harness.transport.respond { request, _ in
            if request.url?.path.contains("sync/mutations") == true {
                return .json(200, Wire.mutationResponse(
                    results: captured.map { Wire.result(mutationID: $0, status: "applied") }
                ))
            }
            return .json(200, Wire.changesResponse(nextCursor: 3))
        }

        let outcome = try await harness.engine.sync()

        #expect(outcome.applied == 3)
        #expect(try await harness.store.queueDepth(workspaceID: Fixed.workspace) == 0)
        #expect(try await harness.store.count(.timeSpan, workspaceID: Fixed.workspace) == 3)
    }
}
