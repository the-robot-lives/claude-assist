import Foundation
import Testing
@testable import TimelyKit

/// Byte-level assertions about what actually goes on the wire.
///
/// These exist because a round-trip test cannot see the difference that matters
/// here. `"end": null` and an absent `end` both decode to `nil`, so a
/// decode/encode/decode cycle is green either way — while the server treats the
/// two as different instructions:
///
/// - `"end": null` on a **closed** span is a deliberate reopen (matrix row 7,
///   allowed only when `base_revision` is current; row 6 rejects it otherwise
///   with `span_reopen_forbidden`).
/// - `end` **absent** is a partial update that does not touch the field.
///
/// Swift's `encode(_:forKey:)` writes an explicit null for a nil Optional;
/// only `encodeIfPresent` omits the key. So the distinction is one method call
/// wide, and nothing else in the type system defends it.
@Suite("Wire presence: null vs absent")
struct WirePresenceTests {

    private func payloadJSON(_ span: TimeSpan) throws -> String {
        try TimelyJSON.encodeToString(span)
    }

    // MARK: - What TimelyKit actually emits

    /// An open span emits an explicit null, not an omission.
    ///
    /// This is correct **for the full-document writes TimelyKit performs**: the
    /// payload is the client's entire row, so `end: null` is an accurate
    /// statement of "my copy of this span is open", not an accidental reopen.
    /// The distinction is pinned here so a future change to `encodeIfPresent`
    /// is a deliberate decision rather than a silent one.
    @Test("an open span emits an explicit null end")
    func openSpanEmitsExplicitNull() throws {
        let span = TimeSpan.test(end: nil)
        let json = try payloadJSON(span)

        #expect(json.contains("\"end\":null"), "got: \(json)")
    }

    @Test("a closed span emits a timestamp")
    func closedSpanEmitsTimestamp() throws {
        let span = TimeSpan.test(end: Fixed.date(3600))
        let json = try payloadJSON(span)

        #expect(!json.contains("\"end\":null"))
        #expect(json.contains("\"end\":\""))
    }

    // MARK: - The three cases, at the byte level

    /// **Case 1 — value present.** A closed span sends its timestamp.
    @Test("a closed span sends end as a value")
    func closedSpanSendsValue() async throws {
        let store = try TimelyLocalStore()
        let span = TimeSpan.test(end: Fixed.date(3600))

        let (_, mutation) = try await store.recordLocalChange(
            .create, entity: span, deviceID: Fixed.deviceA
        )
        let json = try TimelyJSON.encodeToString(mutation.payload)

        #expect(mutation.payload["end"]?.dateValue == Fixed.date(3600))
        #expect(!json.contains("\"end\":null"))
    }

    /// **Case 2 — omitted.** An ordinary edit of a span this client shows as
    /// open must NOT carry `end`. The server tests `Map.has_key?` before it
    /// looks at the value, so an absent key means "leave the interval alone"
    /// and the edit merges even against a row closed on another device.
    ///
    /// This is the case that used to be wrong.
    @Test("an ordinary edit of an open span omits end entirely")
    func ordinaryEditOmitsEnd() async throws {
        let store = try TimelyLocalStore()

        var span = TimeSpan.test(end: nil, serverRevision: 40)
        try await store.upsert(span)

        span.title = "renamed while open"
        let (_, mutation) = try await store.recordLocalChange(
            .update, entity: span, deviceID: Fixed.deviceA
        )
        let json = try TimelyJSON.encodeToString(mutation.payload)

        #expect(mutation.payload["end"] == nil, "the key must be absent, not null")
        #expect(!json.contains("\"end\""), "byte level: no end key at all — got \(json)")
        #expect(json.contains("\"title\":\"renamed while open\""))
    }

    /// **Case 3 — explicit null.** A deliberate reopen, and only that, sends
    /// `"end": null` — the instruction the server acts on for rows 6 and 7.
    @Test("a deliberate reopen sends an explicit null end")
    func deliberateReopenSendsNull() async throws {
        let store = try TimelyLocalStore()

        var span = TimeSpan.test(end: Fixed.date(3600), serverRevision: 40)
        try await store.upsert(span)

        span.end = nil                                    // the user reopens it
        let (_, mutation) = try await store.recordLocalChange(
            .update, entity: span, deviceID: Fixed.deviceA
        )
        let json = try TimelyJSON.encodeToString(mutation.payload)

        #expect(mutation.payload["end"]?.isNull == true)
        #expect(json.contains("\"end\":null"), "byte level: explicit null — got \(json)")
    }

    /// `locked_at` is never sent, in any form — not even for what looks like a
    /// deliberate clear.
    ///
    /// It is presence-sensitive the same way `end` is (the server's
    /// `clearing_lock?` test is `Map.has_key? and value == nil`), but unlike
    /// `end` there is **no `base_revision` guard** on the escape hatch, and no
    /// lock/unlock affordance exists on any Apple surface to derive real intent
    /// from. A "deliberate clear" inferred from the stored row would still be
    /// inferred, and a stale admin would clear a real lock. So the client stays
    /// silent about a field it has no standing to speak on.
    @Test("locked_at is never sent, even when it looks deliberate")
    func lockedAtIsNeverSent() async throws {
        let store = try TimelyLocalStore()

        // Ordinary edit of a span that was never locked.
        var unlocked = TimeSpan.test(serverRevision: 40)
        try await store.upsert(unlocked)
        unlocked.title = "edited"
        let (_, ordinary) = try await store.recordLocalChange(
            .update, entity: unlocked, deviceID: Fixed.deviceA, at: Fixed.date(10_000)
        )
        #expect(ordinary.payload["locked_at"] == nil)

        // A locked span whose lock the caller clears — still omitted. This is
        // the case that used to unlock an approved day by accident.
        var locked = TimeSpan.test(serverRevision: 41)
        locked.lockedAt = Fixed.date(900)
        try await store.upsert(locked)

        locked.lockedAt = nil
        let (_, cleared) = try await store.recordLocalChange(
            .update, entity: locked, deviceID: Fixed.deviceA, at: Fixed.date(20_000)
        )
        let clearedJSON = try TimelyJSON.encodeToString(cleared.payload)
        #expect(cleared.payload["locked_at"] == nil)
        #expect(!clearedJSON.contains("locked_at"), "got \(clearedJSON)")

        // And a span that still carries its lock does not send the value either
        // — sending it would let a stale copy reassert a lock it cannot see.
        var stillLocked = TimeSpan.test(serverRevision: 42)
        stillLocked.lockedAt = Fixed.date(900)
        try await store.upsert(stillLocked)
        stillLocked.title = "edited while locked"
        let (_, held) = try await store.recordLocalChange(
            .update, entity: stillLocked, deviceID: Fixed.deviceA, at: Fixed.date(30_000)
        )
        #expect(held.payload["locked_at"] == nil)
    }

    /// `merged_into_id` is the third field of this family, found by the
    /// explicit-null invariant. It is plain `@castable` server-side with no
    /// presence check, so a null sets the column — a client that has not pulled
    /// a merge would un-merge the row, and the resolver follows that pointer to
    /// redirect references.
    @Test("merged_into_id is never sent on taxonomy rows")
    func mergedIntoIDIsNeverSent() async throws {
        let store = try TimelyLocalStore()

        let client = ClientRecord.minted(
            workspaceID: Fixed.workspace, deviceID: Fixed.deviceA, name: "Acme"
        )!
        let (_, mutation) = try await store.recordLocalChange(
            .create, entity: client, deviceID: Fixed.deviceA
        )
        let json = try TimelyJSON.encodeToString(mutation.payload)

        #expect(mutation.payload["merged_into_id"] == nil)
        #expect(!json.contains("merged_into_id"), "got \(json)")
    }

    /// A brand-new open span has cleared nothing — there is no prior row, so it
    /// is not a reopen and `end` is simply absent. The server defaults the
    /// column to NULL for a create anyway.
    @Test("a newly created open span is not treated as a reopen")
    func newOpenSpanIsNotAReopen() async throws {
        let store = try TimelyLocalStore()
        let span = TimeSpan.test(end: nil)

        let (_, mutation) = try await store.recordLocalChange(
            .create, entity: span, deviceID: Fixed.deviceA
        )
        #expect(mutation.payload["end"] == nil)
    }

    /// A reopen followed by another edit: the reopen asserts itself once, then
    /// subsequent edits fall back to silence. Otherwise every later edit would
    /// re-assert a reopen the server has already applied.
    ///
    /// The explicit `at:` timestamps matter. `Fixed.date` is anchored in 2027,
    /// ahead of the wall clock this test runs under, so letting
    /// `recordLocalChange` default to `Date()` would make each edit *lose* LWW
    /// against the row it just wrote — the second write would silently not land
    /// and the test would be measuring the wrong thing.
    @Test("only the reopening edit sends the null")
    func onlyTheReopenAsserts() async throws {
        let store = try TimelyLocalStore()

        var span = TimeSpan.test(end: Fixed.date(3600), serverRevision: 40)
        try await store.upsert(span)

        span.end = nil
        let (reopened, first) = try await store.recordLocalChange(
            .update, entity: span, deviceID: Fixed.deviceA, at: Fixed.date(10_000)
        )
        #expect(first.payload["end"]?.isNull == true, "the reopen asserts")

        var again = reopened
        again.title = "edited after reopening"
        let (_, second) = try await store.recordLocalChange(
            .update, entity: again, deviceID: Fixed.deviceA, at: Fixed.date(20_000)
        )
        #expect(second.payload["end"] == nil, "the follow-up edit stays silent")
    }

    /// The narrowness is the design. Omitting nils globally would drop these
    /// too, and they are nullable **and required** — a body without them fails
    /// the contract's own schema.
    @Test("the presence rule does not leak into other nullable fields")
    func ruleDoesNotLeak() async throws {
        let store = try TimelyLocalStore()
        let span = TimeSpan.test(end: nil)

        let (_, mutation) = try await store.recordLocalChange(
            .create, entity: span, deviceID: Fixed.deviceA
        )
        let json = try TimelyJSON.encodeToString(mutation.payload)

        #expect(json.contains("\"deleted_at\":null"), "got \(json)")
        #expect(json.contains("\"ticket_id\":null"), "got \(json)")
        #expect(json.contains("\"origin_device_id\":"))
        // ...while the two presence-sensitive keys are gone.
        #expect(!json.contains("\"end\""))
        #expect(!json.contains("\"locked_at\""))
    }

    /// `base_revision` is what separates a legitimate reopen from a stale one,
    /// so it has to be accurate on every mutation TimelyKit sends.
    @Test("base_revision reflects what the client had seen")
    func baseRevisionIsAccurate() async throws {
        let store = try TimelyLocalStore()

        // Never acknowledged by the server — nothing to cite.
        let fresh = TimeSpan.test(serverRevision: 0)
        try await store.upsert(fresh)
        #expect(try await store.enqueue(.create, entity: fresh).baseRevision == nil)

        // Server-acknowledged — cite exactly what we saw.
        let seen = TimeSpan.test(serverRevision: 91)
        try await store.upsert(seen)
        #expect(try await store.enqueue(.update, entity: seen).baseRevision == 91)
    }

    /// A span the client believes open, whose `server_revision` it is current
    /// on, is a genuine reopen assertion — and the server should accept it.
    /// A stale one is the case row 6 rejects, and TimelyKit surfaces that
    /// rejection rather than retrying it forever.
    @Test("a stale reopen rejection is terminal and surfaced")
    func staleReopenIsSurfaced() async throws {
        let harness = try await SyncHarness()

        var span = TimeSpan.test(end: Fixed.date(3600), serverRevision: 40)
        try await harness.store.upsert(span)
        span.end = nil                                   // the user reopens locally
        let queued = try await harness.store.enqueue(.update, entity: span)

        harness.transport.script([
            .json(200, Wire.mutationResponse(results: [
                Wire.result(
                    mutationID: queued.mutationID,
                    status: "rejected",
                    reason: "span_reopen_forbidden"
                )
            ]))
        ])

        let outcome = try await harness.engine.push()

        #expect(outcome.rejected == 1)
        #expect(try await harness.store.queueDepth(workspaceID: Fixed.workspace) == 0)

        let pending = try await harness.store.pendingOutcomes(workspaceID: Fixed.workspace)
        #expect(pending.first?.reason == .spanReopenForbidden)
    }

    // MARK: - Other nullable-but-required fields

    /// The contract declares several fields nullable **and** required. The
    /// synthesized encoder would omit them when nil, producing a body that
    /// fails the contract's own schema — so these must stay explicit nulls.
    @Test("nullable-but-required fields stay present as nulls")
    func nullableRequiredFieldsStayPresent() throws {
        let span = TimeSpan.test()
        let json = try payloadJSON(span)

        for key in ["deleted_at", "ticket_id", "locked_at"] {
            #expect(json.contains("\"\(key)\":null"), "\(key) must be an explicit null — got: \(json)")
        }
    }

    /// The wire names are `start` / `end`. `start_at` / `end_at` are the SQL
    /// column names and must never appear in a payload — the backend hit
    /// exactly this confusion inside its own reopen guard.
    @Test("wire names are start/end, never start_at/end_at")
    func wireNamesAreNotColumnNames() throws {
        let json = try payloadJSON(TimeSpan.test())

        #expect(json.contains("\"start\":"))
        #expect(!json.contains("start_at"))
        #expect(!json.contains("end_at"))
    }

    // MARK: - Server-owned fields

    /// Server-owned fields must never appear in a pushed payload. "Ignored on
    /// write" is a courtesy, not a design — a client that sends them has a model
    /// that believes it may set them, and that belief is the bug.
    ///
    /// Asserting it at the byte level also guards entities added later: a new
    /// server-owned field that someone forgets to exclude fails here.
    @Test("no pushed payload carries a server-owned field")
    func serverOwnedFieldsNeverPushed() async throws {
        let store = try TimelyLocalStore()

        var screenshot = Screenshot.test(uploadState: .eligible)
        screenshot.applyBlobUpload(
            .unverified(
                screenshotID: screenshot.id,
                uploadState: .uploaded,
                blobContentHash: String(repeating: "d", count: 64),
                blobByteSize: 512,
                blobURL: "https://blobs.test/signed",
                serverRevision: 7
            )
        )
        try await store.upsert(screenshot)

        let span = TimeSpan.test()
        try await store.upsert(span)

        let mutations = [
            try await store.enqueue(.update, entity: screenshot),
            try await store.enqueue(.update, entity: span)
        ]

        // `server_revision` is legitimately carried by the envelope, so it is
        // excluded here; the rest must be absent entirely.
        let forbidden = [
            "updated_at_effective", "canonical_name", "blob_available",
            "blob_content_hash", "blob_byte_size", "blob_uploaded_at",
            "blob_url", "raw_response_withheld"
        ]

        for mutation in mutations {
            let json = try TimelyJSON.encodeToString(mutation.payload)
            for key in forbidden {
                #expect(
                    !json.contains("\"\(key)\""),
                    "\(mutation.entityKind.rawValue) payload leaked \(key): \(json)"
                )
            }
        }
    }

    // MARK: - SettingsRow shape

    /// `SettingsRow` is flattened only in the sense that the server's `document`
    /// jsonb wrapper is removed. `vision` is a genuinely nested object and must
    /// stay one — reading "flattened" as "everything is top level" and hoisting
    /// its fields is a real regression, caught on Android before it shipped.
    @Test("user settings flatten the document wrapper but keep vision nested")
    func settingsFlatteningStopsAtVision() throws {
        let settings = UserSettings.minted(
            workspaceID: Fixed.workspace, userID: Fixed.user, deviceID: Fixed.deviceA
        )
        let json = try TimelyJSON.encodeToString(settings)

        // No `document` wrapper in either direction.
        #expect(!json.contains("\"document\""))

        // Body fields sit at the top level...
        #expect(json.contains("\"screenshot_interval_minutes\""))

        // ...but `vision` is still an object, not hoisted into the row.
        #expect(json.contains("\"vision\":{"))
        #expect(!json.contains("\"analysis_enabled\":") || json.contains("\"vision\":{"))

        let reparsed = try TimelyJSON.decode(JSONValue.self, from: json)
        #expect(reparsed["vision"]?.objectValue != nil, "vision must decode as an object")
        #expect(reparsed["analysis_enabled"] == nil, "vision's fields must NOT be hoisted")
    }
}
