import Foundation
import Testing
@testable import TimelyKit

@Suite("macOS snapshot migration")
struct MigrationTests {

    /// A snapshot in exactly the shape the macOS agent writes: `.iso8601` dates
    /// with **no fractional seconds**, and taxonomy ids that were minted with
    /// `UUID()` on whichever Mac first typed the name.
    static let snapshot = """
    {
      "spans": [
        {
          "id": "019318b4-1a2b-7c3d-8e4f-506172839400",
          "title": "Timeline canvas keyboard pass",
          "client": "Acme",
          "project": "Redesign",
          "ticket": "TL-14",
          "start": "2026-07-27T09:02:00Z",
          "end": "2026-07-27T10:47:30Z",
          "source": "timer",
          "isBillable": true,
          "notes": "keyboard nav"
        },
        {
          "id": "019318b4-1a2b-7c3d-8e4f-506172839401",
          "title": "Still running",
          "client": "Acme",
          "project": "Redesign",
          "ticket": "",
          "start": "2026-07-27T11:00:00Z",
          "end": null,
          "source": "manual",
          "isBillable": false,
          "notes": ""
        },
        {
          "id": "019318b4-1a2b-7c3d-8e4f-506172839402",
          "title": "Never in the taxonomy arrays",
          "client": "Bob\\u2019s Diner",
          "project": "Menu site",
          "ticket": "",
          "start": "2026-07-26T09:00:00Z",
          "end": "2026-07-26T09:30:00Z",
          "source": "timer",
          "isBillable": true,
          "notes": ""
        }
      ],
      "screenshots": [
        {
          "id": "019318b9-3c4d-7000-8000-0000000000f1",
          "spanID": "019318b4-1a2b-7c3d-8e4f-506172839400",
          "capturedAt": "2026-07-27T09:20:00Z",
          "fileName": "timely-20260727-092000.png",
          "activeAppName": "Xcode"
        }
      ],
      "visionAnalyses": [
        {
          "id": "019318b9-3c4d-7000-8000-0000000000a1",
          "screenshotID": "019318b9-3c4d-7000-8000-0000000000f1",
          "analyzedAt": "2026-07-27T09:20:05Z",
          "model": "gpt-4o",
          "statusUpdate": "Editing the timeline canvas",
          "inferredProject": "Redesign",
          "inferredTask": "keyboard nav",
          "projectSwitchDetected": false,
          "confidence": 0.91,
          "evidence": "Xcode, TimelineView.swift",
          "privacySensitive": false,
          "privacyCategory": "none",
          "rawResponse": "VERBATIM TRANSCRIPTION of everything on the screen",
          "errorMessage": null
        }
      ],
      "censoredScreenshots": [
        {
          "id": "019318b9-3c4d-7000-8000-0000000000c1",
          "screenshotID": "019318b9-3c4d-7000-8000-0000000000f2",
          "spanID": null,
          "fileName": "timely-20260727-100000.png",
          "activeAppName": "1Password",
          "capturedAt": "2026-07-27T10:00:00Z",
          "censoredAt": "2026-07-27T10:00:02Z",
          "model": "gpt-4o",
          "category": "secret",
          "reason": "password manager visible",
          "confidence": 0.99,
          "deletedLocalFile": true
        }
      ],
      "clients":  [{"id":"11111111-1111-1111-1111-111111111111","name":"Acme","notes":"good payer"}],
      "projects": [{"id":"22222222-2222-2222-2222-222222222222","clientName":"Acme","name":"Redesign","notes":"Q3"}],
      "tickets":  [{"id":"33333333-3333-3333-3333-333333333333","clientName":"Acme","projectName":"Redesign","name":"TL-14","notes":""}],
      "lastInferredProject": "Redesign"
    }
    """

    private func makeImporter(_ store: TimelyLocalStore) -> MacSnapshotImporter {
        MacSnapshotImporter(store: store, workspaceID: Fixed.workspace, deviceID: Fixed.deviceA)
    }

    // MARK: - Import

    @Test("a snapshot imports every row")
    func importsEverything() async throws {
        let store = try TimelyLocalStore()
        let report = try await makeImporter(store)
            .importSnapshot(data: Data(Self.snapshot.utf8))

        #expect(report.spans == 3)
        #expect(report.screenshots == 1)
        #expect(report.visionAnalyses == 1)
        #expect(report.censoredScreenshots == 1)
        #expect(report.openSpans == 1)

        // Two clients: "Acme" from the array, "Bob's Diner" only ever on a span.
        #expect(report.clients == 2)
        #expect(report.projects == 2)
        #expect(report.tickets == 1)
    }

    /// The macOS agent auto-creates taxonomy on first use, so a name can appear
    /// on a span without ever reaching the `clients` array. Importing only the
    /// array would leave spans pointing at rows that do not exist.
    @Test("taxonomy mentioned only by a span is still created")
    func spanOnlyTaxonomyIsCreated() async throws {
        let store = try TimelyLocalStore()
        try await makeImporter(store).importSnapshot(data: Data(Self.snapshot.utf8))

        let bobsID = Canon.clientID(workspaceID: Fixed.workspace, name: "Bob\u{2019}s Diner")
        #expect(bobsID != nil)
        let bobs = try await store.fetch(ClientRecord.self, id: bobsID!)
        #expect(bobs != nil, "a client named only on a span must still be created")
        #expect(bobs?.autoCreated == true)
    }

    /// The snapshot's taxonomy UUIDs are dead weight — minted with `UUID()` on
    /// one machine. Recomputing them as §3.2 UUIDv5 is what makes the Mac's
    /// history merge with a phone's instead of duplicating it.
    @Test("taxonomy ids are recomputed, not carried over")
    func taxonomyIDsAreRecomputed() async throws {
        let store = try TimelyLocalStore()
        try await makeImporter(store).importSnapshot(data: Data(Self.snapshot.utf8))

        let legacyID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        #expect(try await store.fetch(ClientRecord.self, id: legacyID) == nil,
                "the snapshot's random client id must not survive")

        let expected = Canon.clientID(workspaceID: Fixed.workspace, name: "Acme")!
        let acme = try await store.fetch(ClientRecord.self, id: expected)
        #expect(acme?.name == "Acme")
        #expect(acme?.notes == "good payer", "notes from the explicit row must carry over")
        #expect(expected.version == 5)
    }

    @Test("spans are relinked to the recomputed taxonomy ids")
    func spansRelinked() async throws {
        let store = try TimelyLocalStore()
        try await makeImporter(store).importSnapshot(data: Data(Self.snapshot.utf8))

        let spanID = UUID(uuidString: "019318b4-1a2b-7c3d-8e4f-506172839400")!
        let span = try await store.fetch(TimeSpan.self, id: spanID)

        #expect(span?.clientID == Canon.clientID(workspaceID: Fixed.workspace, name: "Acme"))
        #expect(span?.projectID == Canon.projectID(
            workspaceID: Fixed.workspace, clientName: "Acme", name: "Redesign"
        ))
        #expect(span?.ticketID == Canon.ticketID(
            workspaceID: Fixed.workspace, clientName: "Acme", projectName: "Redesign", name: "TL-14"
        ))
        // The names survive alongside the ids.
        #expect(span?.clientName == "Acme")
    }

    /// The backfill rule: `created_at = start`, `updated_at = end ?? start`.
    @Test("timestamps are backfilled from the span's own interval")
    func timestampsBackfilled() async throws {
        let store = try TimelyLocalStore()
        try await makeImporter(store).importSnapshot(data: Data(Self.snapshot.utf8))

        let closed = try await store.fetch(
            TimeSpan.self, id: UUID(uuidString: "019318b4-1a2b-7c3d-8e4f-506172839400")!
        )
        #expect(closed?.sync.createdAt == closed?.start)
        #expect(closed?.sync.updatedAt == closed?.end)

        // An open span has never been closed, so its start is also its last edit.
        let open = try await store.fetch(
            TimeSpan.self, id: UUID(uuidString: "019318b4-1a2b-7c3d-8e4f-506172839401")!
        )
        #expect(open?.end == nil)
        #expect(open?.sync.createdAt == open?.start)
        #expect(open?.sync.updatedAt == open?.start)
    }

    @Test("everything imports unacknowledged by the server")
    func importsAtRevisionZero() async throws {
        let store = try TimelyLocalStore()
        try await makeImporter(store).importSnapshot(data: Data(Self.snapshot.utf8))

        let spans = try await store.fetchAll(TimeSpan.self, workspaceID: Fixed.workspace)
        #expect(spans.allSatisfy { $0.sync.serverRevision == 0 })
        #expect(spans.allSatisfy { $0.sync.isLocalOnly })
    }

    // MARK: - Idempotence

    @Test("importing twice produces the same rows, not duplicates")
    func idempotent() async throws {
        let store = try TimelyLocalStore()
        let importer = makeImporter(store)

        let first = try await importer.importSnapshot(data: Data(Self.snapshot.utf8))
        let countAfterFirst = try await store.count(.timeSpan, workspaceID: Fixed.workspace)
        let clientsAfterFirst = try await store.count(.client, workspaceID: Fixed.workspace)

        try await importer.importSnapshot(data: Data(Self.snapshot.utf8))

        #expect(try await store.count(.timeSpan, workspaceID: Fixed.workspace) == countAfterFirst)
        #expect(try await store.count(.client, workspaceID: Fixed.workspace) == clientsAfterFirst)
        #expect(first.spans == 3)
    }

    /// The source file is opened read-only. The macOS app keeps running off it.
    @Test("the source file is not modified")
    func nonDestructive() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let url = directory.appendingPathComponent("timely-state.json")
        let original = Data(Self.snapshot.utf8)
        try original.write(to: url)

        let store = try TimelyLocalStore()
        try await makeImporter(store).importSnapshot(at: url)

        #expect(try Data(contentsOf: url) == original, "the macOS snapshot must be untouched")
    }

    // MARK: - Privacy

    /// `rawResponse` is a verbatim transcription of the screen — image
    /// -equivalent. It is imported but marked withheld, so nothing pushes it
    /// before the double gate has been evaluated.
    @Test("imported vision raw responses are withheld")
    func rawResponseWithheld() async throws {
        let store = try TimelyLocalStore()
        try await makeImporter(store).importSnapshot(data: Data(Self.snapshot.utf8))

        let analysis = try await store.fetch(
            VisionAnalysis.self, id: UUID(uuidString: "019318b9-3c4d-7000-8000-0000000000a1")!
        )
        #expect(analysis?.rawResponseWithheld == true)
        #expect(analysis?.rawResponse?.isEmpty == false, "the text is kept locally")
        #expect(analysis?.recallSummary.contains("Editing the timeline canvas") == true)
    }

    /// The bytes are on this Mac's disk and have never been offered to the
    /// server. Importing as anything but `localOnly` would assert an upload that
    /// never happened.
    @Test("imported screenshots start local-only")
    func screenshotsStartLocalOnly() async throws {
        let store = try TimelyLocalStore()
        try await makeImporter(store).importSnapshot(data: Data(Self.snapshot.utf8))

        let shot = try await store.fetch(
            Screenshot.self, id: UUID(uuidString: "019318b9-3c4d-7000-8000-0000000000f1")!
        )
        #expect(shot?.uploadState == .localOnly)
        #expect(shot?.blobAvailable == false)
        #expect(shot?.isMetadataOnly == true)
    }

    @Test("censored screenshots keep their category")
    func censoredImported() async throws {
        let store = try TimelyLocalStore()
        try await makeImporter(store).importSnapshot(data: Data(Self.snapshot.utf8))

        let censored = try await store.fetch(
            CensoredScreenshot.self, id: UUID(uuidString: "019318b9-3c4d-7000-8000-0000000000c1")!
        )
        #expect(censored?.category == .secret)
        #expect(censored?.deletedLocalFile == true)
    }

    // MARK: - Robustness

    /// An older build of the agent wrote fewer keys. Refusing to import a whole
    /// work history over one absent `notes` string would be indefensible.
    @Test("a sparse snapshot from an older build still imports")
    func sparseSnapshot() async throws {
        let sparse = """
        {"spans":[{"id":"019318b4-1a2b-7c3d-8e4f-5061728394ff",
                   "title":"Minimal","project":"Thing",
                   "start":"2026-07-27T09:00:00Z","end":null,
                   "source":"manual","isBillable":false,"notes":""}]}
        """
        let store = try TimelyLocalStore()
        let report = try await makeImporter(store).importSnapshot(data: Data(sparse.utf8))

        #expect(report.spans == 1)
        let span = try await store.fetch(
            TimeSpan.self, id: UUID(uuidString: "019318b4-1a2b-7c3d-8e4f-5061728394ff")!
        )
        #expect(span?.title == "Minimal")
        #expect(span?.clientName == "")
        // No client name means no client reference — not a client named "".
        #expect(span?.clientID == nil)
        #expect(span?.projectID != nil, "a project with no client is its own scope")
    }

    @Test("a corrupt snapshot reports rather than crashing")
    func corruptSnapshot() async throws {
        let store = try TimelyLocalStore()
        await #expect(throws: MigrationError.self) {
            try await makeImporter(store).importSnapshot(data: Data("{not json".utf8))
        }
    }

    @Test("a missing snapshot file reports rather than crashing")
    func missingFile() async throws {
        let store = try TimelyLocalStore()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("definitely-not-here-\(UUID().uuidString).json")

        await #expect(throws: MigrationError.self) {
            try await makeImporter(store).importSnapshot(at: url)
        }
    }

    /// A span whose end precedes its start is corrupt in the source. Keep the
    /// row — it is the user's data — but do not derive an inverted envelope.
    @Test("an inverted interval is clamped rather than dropped")
    func invertedIntervalClamped() async throws {
        let inverted = """
        {"spans":[{"id":"019318b4-1a2b-7c3d-8e4f-5061728394ee",
                   "title":"Backwards","client":"Acme","project":"P","ticket":"",
                   "start":"2026-07-27T10:00:00Z","end":"2026-07-27T09:00:00Z",
                   "source":"manual","isBillable":false,"notes":""}]}
        """
        let store = try TimelyLocalStore()
        let report = try await makeImporter(store).importSnapshot(data: Data(inverted.utf8))

        #expect(report.spans == 1)
        #expect(report.repairedTimestamps == 1)

        let span = try await store.fetch(
            TimeSpan.self, id: UUID(uuidString: "019318b4-1a2b-7c3d-8e4f-5061728394ee")!
        )
        #expect(span != nil, "corrupt input is still the user's data")
        #expect(span!.sync.updatedAt >= span!.sync.createdAt)
    }

    /// The imported rows are queued for push exactly as local edits would be.
    @Test("imported rows are marked for upload")
    func importedRowsAreDirty() async throws {
        let store = try TimelyLocalStore()
        try await makeImporter(store).importSnapshot(data: Data(Self.snapshot.utf8))

        // The importer does not enqueue mutations itself — a caller decides when
        // to push a migration — but every row lands unacknowledged so a
        // bootstrap push can find them.
        let spans = try await store.fetchAll(TimeSpan.self, workspaceID: Fixed.workspace)
        #expect(spans.count == 3)
        #expect(spans.allSatisfy { $0.sync.isLocalOnly })
    }
}
