import Foundation
import Testing
@testable import TimelyKit

/// Decode the contract's own examples, re-encode, and check that nothing was
/// lost or invented.
///
/// These are the literal `examples:` blocks from `timely-api.yaml`, transcribed
/// as JSON with the wire's RFC 3339 timestamps (the YAML parser renders them as
/// native datetimes, so the text here is the on-the-wire form).
@Suite("Model round trip against contract examples")
struct ModelRoundTripTests {

    static let timeSpanExample = """
    {
      "id": "019318b4-1a2b-7c3d-8e4f-506172839400",
      "workspace_id": "0192f7a1-2b44-7000-8a10-9d3e4f5a6b7c",
      "title": "Timeline canvas keyboard pass",
      "client_id": "3a1b7d02-9e44-5c11-8f20-aabbccdd0011",
      "project_id": "5f2a9c11-4d3b-51e6-9a77-0b1c2d3e4f50",
      "ticket_id": null,
      "client_name": "Acme",
      "project_name": "Redesign",
      "ticket_name": "",
      "start": "2026-07-27T09:02:00Z",
      "end": "2026-07-27T10:47:30Z",
      "source": "timer",
      "is_billable": true,
      "notes": "",
      "review_state": "unreviewed",
      "review_reasons": [],
      "derived_from_span_ids": [],
      "locked_at": null,
      "created_at": "2026-07-27T09:02:00Z",
      "updated_at": "2026-07-27T10:47:30Z",
      "updated_at_effective": "2026-07-27T10:47:30Z",
      "server_revision": 1903,
      "deleted_at": null,
      "origin_device_id": "019318a0-7f3c-7c21-9b4e-2f6a1c3d5e70"
    }
    """

    static let screenshotExample = """
    {
      "id": "019318b9-3c4d-7000-8000-0000000000f1",
      "workspace_id": "0192f7a1-2b44-7000-8a10-9d3e4f5a6b7c",
      "span_id": "019318b4-1a2b-7c3d-8e4f-506172839400",
      "captured_at": "2026-07-27T09:20:00Z",
      "file_name": "timely-20260727-092000.png",
      "active_app_name": "Xcode",
      "upload_state": "local_only",
      "blob_available": false,
      "blob_content_hash": null,
      "blob_byte_size": null,
      "blob_uploaded_at": null,
      "blob_url": null,
      "created_at": "2026-07-27T09:20:00Z",
      "updated_at": "2026-07-27T09:20:00Z",
      "server_revision": 1910,
      "deleted_at": null,
      "origin_device_id": "019318a0-7f3c-7c21-9b4e-2f6a1c3d5e70"
    }
    """

    // MARK: - TimeSpan

    @Test("TimeSpan decodes the contract example faithfully")
    func decodeTimeSpan() throws {
        let span = try TimelyJSON.decode(TimeSpan.self, from: Self.timeSpanExample)

        #expect(span.sync.id == UUID(uuidString: "019318b4-1a2b-7c3d-8e4f-506172839400"))
        #expect(span.sync.workspaceID == UUID(uuidString: "0192f7a1-2b44-7000-8a10-9d3e4f5a6b7c"))
        #expect(span.title == "Timeline canvas keyboard pass")
        #expect(span.clientName == "Acme")
        #expect(span.projectName == "Redesign")
        #expect(span.ticketID == nil)
        #expect(span.source == .timer)
        #expect(span.isBillable)
        #expect(span.sync.serverRevision == 1903)
        #expect(span.sync.deletedAt == nil)
        #expect(!span.isOpen)
        #expect(span.duration() == 6330)   // 1h 45m 30s
    }

    /// Server-owned fields are `readOnly` **and** `required` in the contract, so
    /// they must decode non-optionally and must not be asserted on write.
    @Test("TimeSpan omits read-only fields when encoding")
    func timeSpanOmitsReadOnly() throws {
        let span = try TimelyJSON.decode(TimeSpan.self, from: Self.timeSpanExample)
        let encoded = try TimelyJSON.encodeToString(span)

        #expect(!encoded.contains("updated_at_effective"))
        // Nullable-but-required fields must be present as explicit nulls, not
        // omitted — the synthesized encoder would drop them and fail the schema.
        #expect(encoded.contains("\"deleted_at\":null"))
        #expect(encoded.contains("\"ticket_id\":null"))
        #expect(encoded.contains("\"origin_device_id\":\"019318a0-7f3c-7c21-9b4e-2f6a1c3d5e70\""))
    }

    @Test("TimeSpan survives a decode/encode/decode cycle")
    func timeSpanRoundTrip() throws {
        let first = try TimelyJSON.decode(TimeSpan.self, from: Self.timeSpanExample)
        let second = try TimelyJSON.decode(
            TimeSpan.self, from: try TimelyJSON.encode(first)
        )

        // `updatedAtEffective` is read-only and deliberately dropped on encode.
        #expect(second.sync == first.sync)
        #expect(second.title == first.title)
        #expect(second.start == first.start)
        #expect(second.end == first.end)
        #expect(second.clientID == first.clientID)
        #expect(second.source == first.source)
        #expect(second.isBillable == first.isBillable)
        #expect(second.updatedAtEffective == nil)
    }

    // MARK: - Screenshot

    @Test("Screenshot decodes the contract example faithfully")
    func decodeScreenshot() throws {
        let screenshot = try TimelyJSON.decode(Screenshot.self, from: Self.screenshotExample)

        #expect(screenshot.fileName == "timely-20260727-092000.png")
        #expect(screenshot.activeAppName == "Xcode")
        #expect(screenshot.uploadState == .localOnly)
        #expect(!screenshot.blobAvailable)
        #expect(screenshot.isMetadataOnly)
        #expect(screenshot.sync.serverRevision == 1910)
    }

    /// The blob fields are server-owned. A client that encoded them would be
    /// asserting an upload it never performed.
    @Test("Screenshot never asserts server-owned blob fields")
    func screenshotOmitsBlobFields() throws {
        let screenshot = try TimelyJSON.decode(Screenshot.self, from: Self.screenshotExample)
        let encoded = try TimelyJSON.encodeToString(screenshot)

        #expect(!encoded.contains("blob_available"))
        #expect(!encoded.contains("blob_content_hash"))
        #expect(!encoded.contains("blob_url"))
        #expect(encoded.contains("upload_state"))
    }

    // MARK: - Enum tolerance

    /// The contract's change rules make adding an enum member additive. A
    /// client that hard-failed would lose its whole sync loop to one new value.
    @Test("unknown enum members fall back rather than throwing")
    func unknownEnumFallsBack() throws {
        let json = Self.timeSpanExample
            .replacingOccurrences(of: "\"source\": \"timer\"", with: "\"source\": \"quantum\"")
            .replacingOccurrences(
                of: "\"review_state\": \"unreviewed\"",
                with: "\"review_state\": \"escalated_to_legal\""
            )

        let span = try TimelyJSON.decode(TimeSpan.self, from: json)
        #expect(span.source == .manual)          // documented fallback
        #expect(span.reviewState == .unreviewed) // documented fallback
    }

    /// An unrecognized upload state must never read as "the server has bytes".
    @Test("unknown upload state is treated as local-only")
    func unknownUploadStateIsSafe() throws {
        let json = Self.screenshotExample.replacingOccurrences(
            of: "\"upload_state\": \"local_only\"",
            with: "\"upload_state\": \"beamed_to_orbit\""
        )
        let screenshot = try TimelyJSON.decode(Screenshot.self, from: json)
        #expect(screenshot.uploadState == .localOnly)
        #expect(!screenshot.uploadState.hasServerBytes)
    }

    /// An unrecognized privacy category is private, not `none` — guessing wrong
    /// in the other direction retains evidence the model flagged as sensitive.
    @Test("unknown privacy category defaults to private")
    func unknownPrivacyCategoryIsPrivate() {
        #expect(PrivacyCategory.unknownFallback == .otherPrivate)
        #expect(PrivacyCategory.unknownFallback.isSensitive)
    }

    // MARK: - UUID rendering

    /// Foundation renders UUIDs uppercase, which fails the `Uuid` schema's
    /// pattern. Every encode path must go through `canonicalString`.
    @Test("UUIDs encode lowercase")
    func uuidsEncodeLowercase() throws {
        let span = try TimelyJSON.decode(TimeSpan.self, from: Self.timeSpanExample)
        let encoded = try TimelyJSON.encodeToString(span)

        #expect(!encoded.contains("019318B4"))
        #expect(encoded.contains("019318b4-1a2b-7c3d-8e4f-506172839400"))
    }

    @Test("UUIDv5 matches RFC 4122 vectors")
    func uuidV5IsCorrect() {
        // RFC 4122 DNS namespace, name "www.example.org" — the canonical vector.
        let dns = UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")!
        let generated = UUID.v5(namespace: dns, name: "www.example.org")
        #expect(generated.canonicalString == "74738ff5-5367-5958-9aee-98fffdcd1876")
        #expect(generated.version == 5)
    }

    @Test("UUIDv7 is time-ordered and monotonic within a millisecond")
    func uuidV7IsOrdered() {
        let instant = Date(timeIntervalSince1970: 1_800_000_000)
        let ids = (0..<200).map { _ in UUID.v7(at: instant) }

        #expect(ids.allSatisfy { $0.version == 7 })
        #expect(Set(ids).count == ids.count)

        let strings = ids.map(\.canonicalString)
        #expect(strings == strings.sorted(), "v7 ids minted in one millisecond must still sort in mint order")
    }

    // MARK: - JSONValue

    /// Unknown fields must survive a round trip. The contract requires clients
    /// to *ignore* fields they do not know; dropping them on re-encode would
    /// turn "ignore" into "delete".
    @Test("JSONValue preserves unknown fields and integral numbers")
    func jsonValuePreservesUnknowns() throws {
        let source = """
        {"a":1,"b":[1,2,3],"c":{"d":null,"e":true},"f":"x","g":1.5,"h":9007199254740991}
        """
        let value = try TimelyJSON.decode(JSONValue.self, from: source)
        let encoded = try TimelyJSON.encodeToString(value)
        let again = try TimelyJSON.decode(JSONValue.self, from: encoded)

        #expect(again == value)
        // Integral values must not acquire a ".0" tail — revisions and counts
        // travel through this type.
        #expect(encoded.contains("\"a\":1"))
        #expect(!encoded.contains("1.0"))
        #expect(encoded.contains("\"g\":1.5"))
    }

    // MARK: - Timestamps

    @Test("ISO 8601 round trips at millisecond resolution")
    func iso8601RoundTrip() throws {
        let samples = [
            "2026-07-27T09:02:00Z",
            "2026-07-27T09:02:00.123Z",
            "2026-07-27T09:02:00+02:00"
        ]
        for sample in samples {
            let date = TimelyISO8601.date(from: sample)
            #expect(date != nil, "could not parse \(sample)")
            if let date {
                let rendered = TimelyISO8601.string(from: date)
                #expect(TimelyISO8601.date(from: rendered) == date, "\(sample) did not round trip")
            }
        }
    }
}
