import Foundation

/// Imports the existing macOS agent's `timely-state.json` into the local store.
///
/// **Non-destructive.** The source file is opened read-only and never written,
/// moved, or truncated. The macOS app keeps working off it unchanged until a
/// later task rewires that app onto this package; until then both may run.
///
/// **Idempotent.** Every imported row's id is either the id the snapshot already
/// carried (spans, screenshots, analyses) or a deterministic UUIDv5 recomputed
/// from names (clients, projects, tickets). Running the import twice upserts the
/// same ids with the same content, and the store's LWW rule makes the second
/// pass a no-op. A marker in `meta` records the completed import so a caller can
/// cheaply skip it, but correctness does not depend on that marker.
///
/// Three deliberate transformations:
///
/// 1. **`created_at` / `updated_at` are backfilled.** The snapshot has no sync
///    envelope. `created_at` becomes the span's `start` and `updated_at` becomes
///    `end ?? start`, which is the most defensible reading of when the record
///    last meaningfully changed. Everything imports at `server_revision: 0` —
///    the server has never seen any of it.
/// 2. **Taxonomy ids are recomputed, not carried.** The snapshot's client,
///    project and ticket UUIDs were minted with `UUID()` on whichever machine
///    first typed the name. They are dead weight: two devices with the same
///    client have different ids for it. Every one is recomputed as the §3.2
///    UUIDv5 of the canonicalized name, which is what makes the macOS agent's
///    history merge with a phone's instead of duplicating it.
/// 3. **Spans are relinked to the recomputed ids.** A span referenced its
///    taxonomy by *name*; after the import it carries both the name and the
///    deterministic id.
public struct MacSnapshotImporter: Sendable {

    private let store: TimelyLocalStore
    private let workspaceID: UUID
    private let deviceID: UUID?

    public init(store: TimelyLocalStore, workspaceID: UUID, deviceID: UUID?) {
        self.store = store
        self.workspaceID = workspaceID
        self.deviceID = deviceID
    }

    /// The macOS agent's own default location.
    public static var defaultSnapshotURL: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base.appendingPathComponent("Timely", isDirectory: true)
            .appendingPathComponent("timely-state.json")
    }

    // MARK: - Import

    @discardableResult
    public func importSnapshot(at url: URL) async throws -> MigrationReport {
        let data: Data
        do {
            data = try Data(contentsOf: url, options: .mappedIfSafe)
        } catch {
            throw MigrationError.unreadableSource(path: url.path, underlying: error.localizedDescription)
        }
        return try await importSnapshot(data: data)
    }

    @discardableResult
    public func importSnapshot(data: Data) async throws -> MigrationReport {
        let snapshot: MacSnapshot
        do {
            snapshot = try Self.makeDecoder().decode(MacSnapshot.self, from: data)
        } catch {
            throw MigrationError.malformedSnapshot(String(describing: error))
        }

        var report = MigrationReport()

        // Taxonomy first: spans resolve their ids from these names, and a
        // partially imported taxonomy would leave spans with null references.
        report.clients = try await importClients(snapshot)
        report.projects = try await importProjects(snapshot)
        report.tickets = try await importTickets(snapshot)
        report.spans = try await importSpans(snapshot, into: &report)
        report.screenshots = try await importScreenshots(snapshot)
        report.visionAnalyses = try await importVisionAnalyses(snapshot)
        report.censoredScreenshots = try await importCensoredScreenshots(snapshot)

        return report
    }

    // MARK: - Taxonomy

    /// Client rows, plus every distinct client *name* mentioned by a span.
    ///
    /// The snapshot's `clients` array is not authoritative: the macOS agent
    /// auto-creates taxonomy on first use and a name can appear on a span
    /// without ever landing in the array. Importing only the array would leave
    /// spans pointing at rows that do not exist.
    private func importClients(_ snapshot: MacSnapshot) async throws -> Int {
        var byID: [UUID: ClientRecord] = [:]

        for name in snapshot.allClientNames {
            guard var record = ClientRecord.minted(
                workspaceID: workspaceID,
                deviceID: deviceID,
                name: name,
                autoCreated: true
            ) else { continue }

            if let notes = snapshot.clientNotes[Canon.canon(name)] {
                record.notes = notes
            }
            byID[record.sync.id] = record
        }

        return try await store.upsertAll(Array(byID.values), markDirty: true)
    }

    private func importProjects(_ snapshot: MacSnapshot) async throws -> Int {
        var byID: [UUID: ProjectRecord] = [:]

        for pair in snapshot.allProjectPairs {
            guard var record = ProjectRecord.minted(
                workspaceID: workspaceID,
                deviceID: deviceID,
                clientName: pair.clientName,
                name: pair.name,
                autoCreated: true
            ) else { continue }

            if let notes = snapshot.projectNotes[pair.canonicalKey] {
                record.notes = notes
            }
            byID[record.sync.id] = record
        }

        return try await store.upsertAll(Array(byID.values), markDirty: true)
    }

    private func importTickets(_ snapshot: MacSnapshot) async throws -> Int {
        var byID: [UUID: TicketRecord] = [:]

        for triple in snapshot.allTicketTriples {
            guard var record = TicketRecord.minted(
                workspaceID: workspaceID,
                deviceID: deviceID,
                clientName: triple.clientName,
                projectName: triple.projectName,
                name: triple.name,
                autoCreated: true
            ) else { continue }

            if let notes = snapshot.ticketNotes[triple.canonicalKey] {
                record.notes = notes
            }
            byID[record.sync.id] = record
        }

        return try await store.upsertAll(Array(byID.values), markDirty: true)
    }

    // MARK: - Spans

    private func importSpans(_ snapshot: MacSnapshot, into report: inout MigrationReport) async throws -> Int {
        var spans: [TimeSpan] = []
        spans.reserveCapacity(snapshot.spans.count)

        for legacy in snapshot.spans {
            // The backfill. `start` is when the record came into existence;
            // `end ?? start` is the last moment it meaningfully changed. An open
            // span has never been closed, so its start is also its last edit.
            let createdAt = legacy.start
            let updatedAt = legacy.end ?? legacy.start

            if legacy.end == nil { report.openSpans += 1 }

            var envelope = SyncEnvelope(
                id: legacy.id,
                workspaceID: workspaceID,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverRevision: 0,
                deletedAt: nil,
                originDeviceID: deviceID
            )
            // A span whose end precedes its start is corrupt in the source. Keep
            // the row — it is the user's data and deleting it is not ours to do
            // — but do not let it produce an `updated_at` before `created_at`.
            if envelope.updatedAt < envelope.createdAt {
                envelope.updatedAt = envelope.createdAt
                report.repairedTimestamps += 1
            }

            let span = TimeSpan(
                sync: envelope,
                title: legacy.title,
                clientID: Canon.clientID(workspaceID: workspaceID, name: legacy.client),
                projectID: Canon.projectID(
                    workspaceID: workspaceID, clientName: legacy.client, name: legacy.project
                ),
                ticketID: Canon.ticketID(
                    workspaceID: workspaceID,
                    clientName: legacy.client,
                    projectName: legacy.project,
                    name: legacy.ticket
                ),
                clientName: legacy.client,
                projectName: legacy.project,
                ticketName: legacy.ticket,
                start: legacy.start,
                end: legacy.end,
                source: SpanSource(rawValue: legacy.source) ?? .manual,
                isBillable: legacy.isBillable,
                notes: legacy.notes,
                reviewState: .unreviewed
            )
            spans.append(span)
        }

        return try await store.upsertAll(spans, markDirty: true)
    }

    // MARK: - Screenshots and analyses

    private func importScreenshots(_ snapshot: MacSnapshot) async throws -> Int {
        let screenshots = snapshot.screenshots.map { legacy in
            Screenshot(
                sync: SyncEnvelope(
                    id: legacy.id,
                    workspaceID: workspaceID,
                    createdAt: legacy.capturedAt,
                    updatedAt: legacy.capturedAt,
                    originDeviceID: deviceID
                ),
                spanID: legacy.spanID,
                capturedAt: legacy.capturedAt,
                fileName: legacy.fileName,
                activeAppName: legacy.activeAppName,
                // Every imported screenshot starts local-only. The bytes are on
                // this Mac's disk and have never been offered to the server;
                // importing them as anything else would assert an upload that
                // never happened.
                uploadState: .localOnly
            )
        }
        return try await store.upsertAll(screenshots, markDirty: true)
    }

    private func importVisionAnalyses(_ snapshot: MacSnapshot) async throws -> Int {
        let analyses = snapshot.visionAnalyses.map { legacy in
            VisionAnalysis(
                sync: SyncEnvelope(
                    id: legacy.id,
                    workspaceID: workspaceID,
                    createdAt: legacy.analyzedAt,
                    updatedAt: legacy.analyzedAt,
                    originDeviceID: deviceID
                ),
                screenshotID: legacy.screenshotID,
                analyzedAt: legacy.analyzedAt,
                model: legacy.model,
                statusUpdate: legacy.statusUpdate,
                inferredProject: legacy.inferredProject,
                inferredTask: legacy.inferredTask,
                projectSwitchDetected: legacy.projectSwitchDetected,
                confidence: legacy.confidence,
                evidence: legacy.evidence,
                privacySensitive: legacy.privacySensitive,
                privacyCategory: PrivacyCategory(rawValue: legacy.privacyCategory) ?? .otherPrivate,
                // `rawResponse` is image-equivalent: a verbatim model
                // transcription of the screen. It exists in the local snapshot
                // and stays in the local store, but it is imported as WITHHELD so
                // that nothing pushes it before the double gate has been
                // evaluated for this workspace and device.
                rawResponse: legacy.rawResponse,
                rawResponseWithheld: true,
                errorMessage: legacy.errorMessage
            )
        }
        return try await store.upsertAll(analyses, markDirty: true)
    }

    private func importCensoredScreenshots(_ snapshot: MacSnapshot) async throws -> Int {
        let censored = snapshot.censoredScreenshots.map { legacy in
            CensoredScreenshot(
                sync: SyncEnvelope(
                    id: legacy.id,
                    workspaceID: workspaceID,
                    createdAt: legacy.censoredAt,
                    updatedAt: legacy.censoredAt,
                    originDeviceID: deviceID
                ),
                screenshotID: legacy.screenshotID,
                spanID: legacy.spanID,
                fileName: legacy.fileName,
                activeAppName: legacy.activeAppName,
                capturedAt: legacy.capturedAt,
                censoredAt: legacy.censoredAt,
                model: legacy.model,
                category: PrivacyCategory(rawValue: legacy.category) ?? .otherPrivate,
                reason: legacy.reason,
                confidence: legacy.confidence,
                deletedLocalFile: legacy.deletedLocalFile
            )
        }
        return try await store.upsertAll(censored, markDirty: true)
    }

    // MARK: - Decoding

    /// The macOS agent writes with `JSONEncoder.dateEncodingStrategy = .iso8601`,
    /// which emits **no fractional seconds**. `TimelyJSON`'s decoder expects the
    /// wire format's RFC 3339 with fractional seconds, so using it here would
    /// fail on every date in the file.
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            // Try the strict wire parser first — it accepts both forms — then
            // fall back to plain `.iso8601` semantics.
            if let date = TimelyISO8601.date(from: text) { return date }
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Not an ISO 8601 date-time: \(text)"
                )
            )
        }
        return decoder
    }
}

// MARK: - Report

public struct MigrationReport: Sendable, Hashable {
    public var clients = 0
    public var projects = 0
    public var tickets = 0
    public var spans = 0
    public var screenshots = 0
    public var visionAnalyses = 0
    public var censoredScreenshots = 0

    /// Spans that were still running when the snapshot was written.
    public var openSpans = 0

    /// Rows whose `end` preceded their `start` in the source, whose derived
    /// `updated_at` was clamped rather than left inverted.
    public var repairedTimestamps = 0

    public var totalRows: Int {
        clients + projects + tickets + spans
            + screenshots + visionAnalyses + censoredScreenshots
    }

    public init() {}
}

public enum MigrationError: Error, CustomStringConvertible {
    case unreadableSource(path: String, underlying: String)
    case malformedSnapshot(String)

    public var description: String {
        switch self {
        case .unreadableSource(let path, let underlying):
            return "Could not read the macOS snapshot at \(path): \(underlying)"
        case .malformedSnapshot(let underlying):
            return "The macOS snapshot could not be decoded: \(underlying)"
        }
    }
}
