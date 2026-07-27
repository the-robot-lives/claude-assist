import Foundation
import Testing
@testable import TimelyKit

/// The general invariant: **which keys may this client ever send as an explicit
/// JSON null?**
///
/// Adopted from the Android client, which built it instead of spot-checking
/// `locked_at`. The reasoning is the part worth keeping: auditing one field
/// leaves the *next* presence-sensitive field to be discovered the same way the
/// last two were — by someone hitting it in production. This walks every write
/// path, collects every queued payload, recursively finds every literal null at
/// any depth, and fails if that set escapes the allowlist. It catches a future
/// field that starts always-nulling whether or not anyone remembers the rule,
/// including fields the backend has not made presence-sensitive *yet*.
///
/// The fixes closed two holes. This closes the class.
@Suite("Explicit-null invariant")
struct ExplicitNullInvariantTests {

    /// Keys this client is permitted to send as an explicit null.
    ///
    /// **Adding an entry here is a claim that the server is not
    /// presence-sensitive for that key** — that it reads null and absent the
    /// same way. That is a claim to verify against the backend, not to assume.
    /// Two fields already broke this project by being assumed safe.
    ///
    /// Our list differs from Android's, which is `{"end"}` alone, and the
    /// difference is legitimate rather than a disagreement:
    ///
    /// - `deleted_at`, `ticket_id`, `origin_device_id` are nullable **and
    ///   required** by the contract. Omitting them produces a body that fails
    ///   the schema, so they MUST travel as explicit nulls. Android's repository
    ///   layer builds payloads field by field and supplies them separately;
    ///   TimelyKit encodes whole `Codable` models, so they appear here.
    /// - `end` is shared with Android: sent as null only for a deliberate
    ///   reopen.
    /// - `locked_at` is on **neither** list. Both clients refuse to send it at
    ///   all — see `WirePresence.neverSent`.
    static let allowed: Set<String> = Set([
        // Nullable AND required by the contract — omitting these produces a body
        // that fails the schema. Verified against `timely-api.yaml`.
        "deleted_at",
        "ticket_id",

        // `origin_device_id` stays, and it was nearly removed for a good-sounding
        // reason worth recording. The server DOES substitute the pushing device
        // when the key is absent (`mutations.ex:290`, `:450`), so omitting it
        // looks free.
        //
        // It is not. `wins?/3` (`mutations.ex:517`) reads the RAW PAYLOAD for the
        // LWW tie-break — `payload["origin_device_id"] || ""` — with no such
        // substitution. Omit the key, or send it as null, and the tie-break
        // compares `""` against a real device id and **loses every exact-timestamp
        // tie**. The server substitutes for storage but not for adjudication.
        //
        // So: always send a REAL device id. A null here is a degraded value, not
        // a neutral one — clients should pass a genuine `deviceID` to
        // `recordLocalChange` rather than nil.
        "origin_device_id",

        // Sent as null only for a deliberate reopen, and the server guards a
        // stale one with `base_revision` (matrix rows 6, 7). Shared with Android.
        "end",

    ]).union(appendOnlyNullKeys)

    /// Entities this client may only ever CREATE.
    static let appendOnlyKinds: Set<EntityKind> = [.visionAnalysis, .censoredScreenshot]

    /// Allowlist entries that are permitted **only while** their entities stay
    /// append-only — and that drop out automatically the moment they don't.
    ///
    /// These three are nulls on `vision_analysis` and `censored_screenshot`. A
    /// null on a *create* states a fact about a row being born, so there is no
    /// stale copy to clobber; the risk that makes `locked_at` and
    /// `merged_into_id` dangerous requires an **update** path, and these have
    /// none.
    ///
    /// Android's objection to writing that in a comment was right: *"the entity
    /// is append-only" is a fact about today's code stored in a comment, and
    /// comments don't fail.* So this reads the fact at runtime instead. Flip
    /// `EntityKind.isAppendOnly` for either entity and these keys vanish from
    /// the allowlist, `noUnexpectedExplicitNulls` goes red, and the failure
    /// points at the null list rather than surfacing as a bug in production.
    ///
    /// `appendOnlyAssumptionIsEnforced` below checks the other half: that the
    /// refusal is real, not just declared.
    static var appendOnlyNullKeys: Set<String> {
        let stillAppendOnly = appendOnlyKinds.allSatisfy(\.isAppendOnly)
        return stillAppendOnly ? ["raw_response", "error_message", "span_id"] : []
    }

    /// Every literal null in a payload, at any depth, as a set of key names.
    static func nullKeys(_ value: JSONValue, into found: inout Set<String>) {
        guard let object = value.objectValue else {
            if let array = value.arrayValue {
                for element in array { nullKeys(element, into: &found) }
            }
            return
        }
        for (key, child) in object {
            if child.isNull {
                found.insert(key)
            } else {
                nullKeys(child, into: &found)
            }
        }
    }

    /// Exercise every write path the package offers and collect the payloads.
    private func allQueuedPayloads() async throws -> [(kind: EntityKind, payload: JSONValue)] {
        let store = try TimelyLocalStore()
        let device = Fixed.deviceA
        var clock = 0.0
        func next() -> Date { clock += 60; return Fixed.date(clock) }

        // --- time spans: create, retitle, rebill, reassign, close, reopen ---
        var span = TimeSpan.test(end: nil, serverRevision: 0)
        try await store.recordLocalChange(.create, entity: span, deviceID: device, at: next())

        span.title = "retitled"
        try await store.recordLocalChange(.update, entity: span, deviceID: device, at: next())

        span.isBillable = false
        try await store.recordLocalChange(.update, entity: span, deviceID: device, at: next())

        span.clientName = "Other Co"
        span.clientID = Canon.clientID(workspaceID: Fixed.workspace, name: "Other Co")
        try await store.recordLocalChange(.update, entity: span, deviceID: device, at: next())

        span.end = Fixed.date(5_000)                       // close
        try await store.recordLocalChange(.update, entity: span, deviceID: device, at: next())

        span.end = nil                                     // deliberate reopen
        try await store.recordLocalChange(.update, entity: span, deviceID: device, at: next())

        // --- a span carrying a lock, to prove locked_at never escapes ---
        var locked = TimeSpan.test(serverRevision: 12)
        locked.lockedAt = Fixed.date(900)
        try await store.recordLocalChange(.create, entity: locked, deviceID: device, at: next())
        locked.lockedAt = nil                              // would clear the lock
        try await store.recordLocalChange(.update, entity: locked, deviceID: device, at: next())

        // --- delete (tombstone) ---
        let doomed = TimeSpan.test()
        try await store.recordLocalChange(.create, entity: doomed, deviceID: device, at: next())
        try await store.recordLocalChange(.delete, entity: doomed, deviceID: device, at: next())

        // --- split / merge, as an atomic group ---
        for index in 0..<2 {
            let piece = TimeSpan.test(title: "piece-\(index)")
            try await store.recordLocalChange(
                .create, entity: piece, deviceID: device, batchGroup: "split-1", at: next()
            )
        }

        // --- taxonomy ---
        let client = ClientRecord.minted(
            workspaceID: Fixed.workspace, deviceID: device, name: "Acme"
        )!
        try await store.recordLocalChange(.create, entity: client, deviceID: device, at: next())

        let project = ProjectRecord.minted(
            workspaceID: Fixed.workspace, deviceID: device, clientName: "Acme", name: "Redesign"
        )!
        try await store.recordLocalChange(.create, entity: project, deviceID: device, at: next())

        let ticket = TicketRecord.minted(
            workspaceID: Fixed.workspace, deviceID: device,
            clientName: "Acme", projectName: "Redesign", name: "TL-1"
        )!
        try await store.recordLocalChange(.create, entity: ticket, deviceID: device, at: next())

        // --- evidence ---
        let screenshot = Screenshot.test(spanID: span.id)
        try await store.recordLocalChange(.create, entity: screenshot, deviceID: device, at: next())

        let analysis = VisionAnalysis.test(screenshotID: screenshot.id)
        try await store.recordLocalChange(.create, entity: analysis, deviceID: device, at: next())

        let censored = CensoredScreenshot(
            sync: .local(id: UUID.v7(), workspaceID: Fixed.workspace, deviceID: device),
            screenshotID: screenshot.id,
            spanID: nil,
            capturedAt: Fixed.date(60),
            censoredAt: Fixed.date(90),
            category: .secret,
            confidence: 0.99
        )
        try await store.recordLocalChange(.create, entity: censored, deviceID: device, at: next())

        // --- settings ---
        let settings = UserSettings.minted(
            workspaceID: Fixed.workspace, userID: Fixed.user, deviceID: device
        )
        try await store.recordLocalChange(.create, entity: settings, deviceID: device, at: next())

        let queued = try await store.nextBatch(workspaceID: Fixed.workspace, limit: 200)
        // The atomic group batches separately; take it too so no path is missed.
        let group = try await store.withConnection { connection in
            try connection.query(
                "SELECT entity_kind, payload FROM push_queue WHERE workspace_id = ?1 ORDER BY seq",
                [.uuid(Fixed.workspace)]
            ) { ($0.string(0), $0.string(1)) }
        }

        #expect(!queued.isEmpty)
        return try group.map { row in
            (
                kind: EntityKind(rawValue: row.0) ?? .unknown,
                payload: try TimelyJSON.decode(JSONValue.self, from: row.1)
            )
        }
    }

    // MARK: - The invariant

    @Test("no payload contains an explicit null outside the allowlist")
    func noUnexpectedExplicitNulls() async throws {
        let payloads = try await allQueuedPayloads()
        #expect(payloads.count >= 18, "every write path must be covered — got \(payloads.count)")

        var offenders: [String: Set<EntityKind>] = [:]
        for (kind, payload) in payloads {
            var found: Set<String> = []
            Self.nullKeys(payload, into: &found)
            for key in found.subtracting(Self.allowed) {
                offenders[key, default: []].insert(kind)
            }
        }

        #expect(
            offenders.isEmpty,
            """
            Payloads carried explicit nulls outside the allowlist: \
            \(offenders.map { "\($0.key) (\($0.value.map(\.rawValue).sorted().joined(separator: ", ")))" }.sorted())

            Either omit the key, or — if the server genuinely reads null and \
            absent identically for it — add it to `allowed` with that claim \
            verified against the backend, not assumed.
            """
        )
    }

    /// The specific field that started this. Not covered by the allowlist check
    /// alone, because a key that is never present in *any* form cannot show up
    /// as an offender — so assert its absence directly.
    @Test("locked_at never appears in a payload, in any form")
    func lockedAtNeverAppears() async throws {
        for (kind, payload) in try await allQueuedPayloads() {
            #expect(
                payload["locked_at"] == nil,
                "\(kind.rawValue) payload carried locked_at — this client must never send it"
            )
        }
    }

    /// The enforced half of the append-only claim.
    ///
    /// Three allowlist entries rest on "this client never updates these
    /// entities". That has to be *verified*, not asserted in prose — otherwise
    /// the day someone adds an update path, the null list is silently wrong and
    /// nothing says so. Adapted from Android's `ScreenshotGate.PUSHABLE`, which
    /// makes the same guarantee structural rather than remembered.
    @Test("the append-only assumption behind three allowlist entries is enforced")
    func appendOnlyAssumptionIsEnforced() async throws {
        // 1. The declared set still matches what `EntityKind` marks.
        let declared = Set(EntityKind.allCases.filter(\.isAppendOnly))
        #expect(
            declared == Self.appendOnlyKinds,
            """
            The set of append-only entities changed (\(declared.map(\.rawValue).sorted())). \
            Re-check `appendOnlyNullKeys` — raw_response / error_message / span_id are \
            only safe to send as explicit nulls while their entities are create-only.
            """
        )

        // 2. And the refusal is real: enqueueing an update actually throws,
        //    rather than being merely documented.
        let store = try TimelyLocalStore()
        let screenshot = Screenshot.test()

        let analysis = VisionAnalysis.test(screenshotID: screenshot.id)
        let censored = CensoredScreenshot(
            sync: .local(id: UUID.v7(), workspaceID: Fixed.workspace, deviceID: Fixed.deviceA),
            screenshotID: screenshot.id,
            spanID: nil,
            capturedAt: Fixed.date(60),
            censoredAt: Fixed.date(90),
            category: .secret,
            confidence: 0.99
        )

        var analysisThrew = false
        do { _ = try await store.enqueue(.update, entity: analysis) }
        catch SyncError.immutableEntity { analysisThrew = true }
        catch { }

        var censoredThrew = false
        do { _ = try await store.enqueue(.update, entity: censored) }
        catch SyncError.immutableEntity { censoredThrew = true }
        catch { }

        #expect(analysisThrew, "an update to vision_analysis must be refused at enqueue")
        #expect(censoredThrew, "an update to censored_screenshot must be refused at enqueue")

        // 3. Creates still work — the refusal is targeted, not a blanket ban.
        _ = try await store.enqueue(.create, entity: analysis)
        _ = try await store.enqueue(.create, entity: censored)
        #expect(try await store.queueDepth(workspaceID: Fixed.workspace) == 2)
    }

    /// Negative control: the invariant is worthless if it cannot fail. This
    /// reproduces the exact bug — a payload that always serializes `locked_at` —
    /// and proves the detector catches it.
    @Test("the invariant detects the original bug")
    func negativeControl() throws {
        let buggy = try TimelyJSON.decode(
            JSONValue.self,
            from: #"{"id":"x","locked_at":null,"end":null,"nested":{"deep_field":null}}"#
        )

        var found: Set<String> = []
        Self.nullKeys(buggy, into: &found)

        #expect(found.contains("locked_at"), "must see the top-level offender")
        #expect(found.contains("deep_field"), "must recurse — nulls hide at depth")
        #expect(!found.subtracting(Self.allowed).isEmpty, "must report a violation")
        #expect(found.subtracting(Self.allowed) == ["locked_at", "deep_field"])
    }
}
