import AppKit
import CoreGraphics
import Foundation
import SwiftUI
import TimelyKit
import UserNotifications

/// The app's view model, and the boundary between SwiftUI and TimelyKit.
///
/// **What changed in the retrofit.** This type used to own the domain: it
/// declared its own `TrackedTimeSpan`, `ScreenshotRecord` and friends, and
/// persisted the lot as one `timely-state.json` blob rewritten on every edit.
/// It now holds TimelyKit's models and delegates persistence to
/// `TimelyLocalStore` (SQLite). The published property names are unchanged, so
/// the SwiftUI layer above did not have to be redesigned.
///
/// **Two hard deletes are gone.** `deleteSpan` and `censorScreenshot` used to
/// call `removeAll`. In a protocol where nothing is ever hard-deleted, a local
/// hard delete is not a tidy-up — it is a row the next pull faithfully restores.
/// For a censored screenshot that means the app re-downloads the thing the user
/// asked it to forget. Both now write tombstones. See ``censorScreenshot(_:analysis:)``.
///
/// **The in-memory arrays are a cache, not the truth.** SQLite is the truth.
/// They exist because SwiftUI wants synchronous `@Published` reads and the store
/// is an actor. Every mutation updates the array for immediate UI feedback and
/// chains a persistence task; ``reload()`` re-reads from disk.
@MainActor
final class TimelyStore: ObservableObject {

    // MARK: - Published domain state

    @Published var settings: AppSettings = .defaults
    @Published var spans: [TimeSpan] = []
    @Published var screenshots: [Screenshot] = []
    @Published var visionAnalyses: [VisionAnalysis] = []
    @Published var censoredScreenshots: [CensoredScreenshot] = []
    @Published var clients: [ClientRecord] = []
    @Published var projects: [ProjectRecord] = []
    @Published var tickets: [TicketRecord] = []

    // MARK: - Published UI state (unchanged)

    @Published var isAnalyzingVisionScreenshot: Bool = false
    @Published var lastInferredProject: String?
    @Published var mode: CaptureMode = .idle
    @Published var activeSpanID: UUID?
    @Published var currentTask: String = ""
    @Published var currentClient: String = ""
    @Published var currentProject: String = ""
    @Published var currentTicket: String = ""
    @Published var manualTitle: String = ""
    @Published var manualClient: String = ""
    @Published var manualProject: String = ""
    @Published var manualTicket: String = ""
    @Published var manualStart: Date = Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
    @Published var manualEnd: Date = Date()
    @Published var manualNotes: String = ""
    @Published var manualBillable: Bool = true
    @Published var draftClientName: String = ""
    @Published var draftProjectClient: String = ""
    @Published var draftProjectName: String = ""
    @Published var draftTicketClient: String = ""
    @Published var draftTicketProject: String = ""
    @Published var draftTicketName: String = ""
    @Published var now: Date = Date()
    @Published var pomodoroRemaining: TimeInterval = 0
    @Published var lastError: String?
    @Published var lastScreenshotAt: Date?

    // MARK: - Published sync state

    @Published private(set) var syncState: SyncStatus = .offline
    @Published private(set) var pendingUploadCount: Int = 0
    @Published private(set) var needsAttentionCount: Int = 0
    @Published private(set) var signedInEmail: String?

    enum SyncStatus: Equatable {
        /// No account. The normal state for a fresh install, and not an error.
        case offline
        case idle(lastSync: Date?)
        case syncing
        /// The refresh token was rejected. Local work continues; the user must
        /// sign in again for it to leave the device.
        case signInRequired
        case failed(String)
    }

    // MARK: - Collaborators

    private let identity = DeviceIdentity()

    /// Internal rather than private so `TimelyStore+Sync` can reach them. They
    /// are still not part of the surface SwiftUI binds to.
    var local: TimelyLocalStore?
    var auth: AuthClient?
    var engine: SyncEngine?
    var apiClient: TimelyAPIClient?

    /// The workspace's own upload policy, learned at device registration. The
    /// closed default matters: an unknown policy must never read as permission.
    var workspacePolicyAllowsBlobUpload: Bool = false

    private var tickTimer: Timer?
    private var screenshotTimer: Timer?
    private var pomodoroWorkSpanID: UUID?

    /// Serializes persistence so the push queue's FIFO order matches the order
    /// the user actually did things. Independent `Task`s would interleave.
    private var persistenceChain: Task<Void, Never> = Task {}

    private var workspaceID: UUID { identity.workspaceID }
    private var deviceID: UUID { identity.deviceID }

    // Narrow, named accessors for the sync extension, so identity stays private
    // and every mutation of it goes through one reviewable place.

    var workspaceIdentifier: UUID { identity.workspaceID }
    var deviceIdentifier: UUID { identity.deviceID }

    func adoptRealWorkspaceIdentifier(_ id: UUID) -> UUID? {
        identity.adoptRealWorkspace(id)
    }

    func setSyncCollaborators(auth: AuthClient, engine: SyncEngine) {
        self.auth = auth
        self.engine = engine
        self.apiClient = TimelyAPIClient(baseURL: Self.defaultBaseURL, auth: auth)
    }

    func setSyncState(_ state: SyncStatus) { syncState = state }
    func setSignedInEmail(_ email: String?) { signedInEmail = email }
    func setLastError(_ message: String?) { lastError = message }
    func refreshCounters() async { await refreshQueueCounters() }

    init() {
        startClock()
        requestNotificationPermissionIfNeeded()
        Task { await bootstrap() }
    }

    // MARK: - Paths

    var appSupportURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        return base.appendingPathComponent("Timely", isDirectory: true)
    }

    var screenshotsURL: URL {
        appSupportURL.appendingPathComponent("Screenshots", isDirectory: true)
    }

    private var databaseURL: URL {
        appSupportURL.appendingPathComponent("timely.sqlite3")
    }

    /// The legacy blob. Read once, never written again, never deleted.
    private var legacySnapshotURL: URL {
        appSupportURL.appendingPathComponent("timely-state.json")
    }

    private var settingsURL: URL {
        appSupportURL.appendingPathComponent("device-settings.json")
    }

    // MARK: - Derived

    var activeSpan: TimeSpan? {
        guard let activeSpanID else { return nil }
        return spans.first { $0.id == activeSpanID }
    }

    var reviewedDuration: TimeInterval {
        spans.reduce(0) { $0 + $1.duration(now: now) }
    }

    var billableDuration: TimeInterval {
        spans.filter(\.isBillable).reduce(0) { $0 + $1.duration(now: now) }
    }

    // MARK: - Bootstrap

    private func bootstrap() async {
        do {
            ensureDirectories()
            let store = try TimelyLocalStore(url: databaseURL)
            local = store

            loadDeviceSettings()
            try await importLegacySnapshotIfNeeded(into: store)
            await reload()
            await configureSync()
            configureScreenshotTimer()
        } catch {
            lastError = "Could not open the Timely database: \(error.localizedDescription)"
        }
    }

    /// One-time import of the pre-TimelyKit `timely-state.json`.
    ///
    /// Non-destructive and idempotent — the source file is opened read-only and
    /// the importer recomputes deterministic ids, so a second run upserts the
    /// same rows. The flag is a cost optimization, not the correctness guard.
    private func importLegacySnapshotIfNeeded(into store: TimelyLocalStore) async throws {
        guard !identity.didImportLegacySnapshot else { return }
        guard FileManager.default.fileExists(atPath: legacySnapshotURL.path) else {
            identity.didImportLegacySnapshot = true
            return
        }

        let importer = MacSnapshotImporter(
            store: store, workspaceID: workspaceID, deviceID: deviceID
        )
        do {
            let report = try await importer.importSnapshot(at: legacySnapshotURL)
            identity.didImportLegacySnapshot = true
            if report.totalRows > 0 {
                lastError = nil
            }
        } catch {
            // A failed import must not brick the app — the user still has their
            // JSON file, untouched, and can retry on the next launch.
            lastError = "Could not import your previous Timely data: \(error.localizedDescription)"
        }
    }

    /// Re-read every published array from SQLite.
    func reload() async {
        guard let local else { return }
        do {
            spans = try await local.fetchAll(TimeSpan.self, workspaceID: workspaceID)
            screenshots = try await local.fetchAll(Screenshot.self, workspaceID: workspaceID, limit: 200)
            visionAnalyses = try await local.fetchAll(VisionAnalysis.self, workspaceID: workspaceID, limit: 200)
            censoredScreenshots = try await local.fetchAll(
                CensoredScreenshot.self, workspaceID: workspaceID, limit: 200
            )
            clients = try await local.fetchAll(ClientRecord.self, workspaceID: workspaceID)
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            projects = try await local.fetchAll(ProjectRecord.self, workspaceID: workspaceID)
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            tickets = try await local.fetchAll(TicketRecord.self, workspaceID: workspaceID)
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            activeSpanID = spans.first(where: { $0.isOpen })?.id
            lastScreenshotAt = screenshots.first?.capturedAt
            pendingUploadCount = try await local.queueDepth(workspaceID: workspaceID)
            needsAttentionCount = try await local.pendingOutcomes(workspaceID: workspaceID).count
        } catch {
            lastError = "Could not read local Timely data: \(error.localizedDescription)"
        }
    }

    // MARK: - Persistence

    /// Queue a store write. Ordered, off the main actor, never blocking the UI.
    private func persist(
        _ work: @escaping @Sendable (TimelyLocalStore) async throws -> Void
    ) {
        guard let local else { return }
        let previous = persistenceChain
        persistenceChain = Task { [weak self] in
            await previous.value
            do {
                try await work(local)
                await self?.refreshQueueCounters()
            } catch {
                await MainActor.run {
                    self?.lastError = "Could not save: \(error.localizedDescription)"
                }
            }
        }
    }

    private func refreshQueueCounters() async {
        guard let local else { return }
        pendingUploadCount = (try? await local.queueDepth(workspaceID: workspaceID)) ?? pendingUploadCount
        needsAttentionCount = (try? await local.pendingOutcomes(workspaceID: workspaceID).count)
            ?? needsAttentionCount
    }

    /// Apply a local edit: update the cache, and queue it for sync.
    private func record<E: SyncEntity>(_ operation: MutationOperation, _ entity: E) {
        let deviceID = self.deviceID
        persist { store in
            _ = try await store.recordLocalChange(operation, entity: entity, deviceID: deviceID)
        }
    }

    // MARK: - Spans

    func startSpan() {
        let trimmedTask = currentTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTask.isEmpty else {
            lastError = "Enter a task before starting a span."
            return
        }

        closeActiveSpan()

        let span = makeSpan(
            title: trimmedTask,
            client: currentClient,
            project: currentProject,
            ticket: currentTicket,
            start: Date(),
            end: nil,
            source: .timer,
            isBillable: true,
            notes: ""
        )

        spans.insert(span, at: 0)
        record(.create, span)
        upsertAssignment(client: span.clientName, project: span.projectName, ticket: span.ticketName)
        activeSpanID = span.id
        mode = .running
        lastError = nil
        configureScreenshotTimer()
    }

    func pause() {
        guard mode == .running || mode == .pomodoroWork else { return }
        mode = .paused
        stopScreenshotTimer()
    }

    func resume() {
        guard activeSpanID != nil else {
            startSpan()
            return
        }
        mode = pomodoroWorkSpanID == activeSpanID ? .pomodoroWork : .running
        configureScreenshotTimer()
    }

    func stopActiveSpan() {
        closeActiveSpan()
        activeSpanID = nil
        pomodoroWorkSpanID = nil
        mode = .idle
        pomodoroRemaining = 0
        stopScreenshotTimer()
    }

    func addManualSpan() {
        let trimmedTask = manualTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTask.isEmpty else {
            lastError = "Enter a title before adding a manual span."
            return
        }
        guard manualEnd > manualStart else {
            lastError = "Manual span end must be after start."
            return
        }

        let span = makeSpan(
            title: trimmedTask,
            client: manualClient,
            project: manualProject,
            ticket: manualTicket,
            start: manualStart,
            end: manualEnd,
            source: .manual,
            isBillable: manualBillable,
            notes: manualNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        spans.insert(span, at: 0)
        record(.create, span)
        upsertAssignment(client: span.clientName, project: span.projectName, ticket: span.ticketName)

        manualTitle = ""
        manualClient = ""
        manualProject = ""
        manualTicket = ""
        manualNotes = ""
        manualEnd = Date()
        manualStart = Calendar.current.date(byAdding: .hour, value: -1, to: manualEnd) ?? manualEnd
        lastError = nil
    }

    /// Soft-delete.
    ///
    /// This used to `removeAll` the span. Under a protocol that never hard
    /// -deletes, that row comes straight back on the next pull — the user
    /// deletes a span, it reappears, and nothing in the app explains why.
    func deleteSpan(_ span: TimeSpan) {
        if activeSpanID == span.id {
            activeSpanID = nil
            mode = .idle
        }
        spans.removeAll { $0.id == span.id }
        record(.delete, span)
    }

    private func makeSpan(
        title: String,
        client: String,
        project: String,
        ticket: String,
        start: Date,
        end: Date?,
        source: SpanSource,
        isBillable: Bool,
        notes: String
    ) -> TimeSpan {
        let clientName = client.trimmingCharacters(in: .whitespacesAndNewlines)
        let projectName = project.trimmingCharacters(in: .whitespacesAndNewlines)
        let ticketName = ticket.trimmingCharacters(in: .whitespacesAndNewlines)

        return TimeSpan(
            sync: .local(id: UUID.v7(), workspaceID: workspaceID, deviceID: deviceID),
            title: title,
            // Resolved from the names, so two devices that type the same client
            // independently arrive at the same row instead of duplicating it.
            clientID: Canon.clientID(workspaceID: workspaceID, name: clientName),
            projectID: Canon.projectID(
                workspaceID: workspaceID, clientName: clientName, name: projectName
            ),
            ticketID: Canon.ticketID(
                workspaceID: workspaceID,
                clientName: clientName,
                projectName: projectName,
                name: ticketName
            ),
            clientName: clientName,
            projectName: projectName,
            ticketName: ticketName,
            start: start,
            end: end,
            source: source,
            isBillable: isBillable,
            notes: notes
        )
    }

    private func closeActiveSpan() {
        guard let activeSpanID,
              let index = spans.firstIndex(where: { $0.id == activeSpanID }),
              spans[index].end == nil else { return }
        spans[index].end = Date()
        record(.update, spans[index])
    }

    // MARK: - Pomodoro

    func startPomodoro() {
        let trimmedTask = currentTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTask.isEmpty else {
            lastError = "Enter a Pomodoro task first."
            return
        }

        closeActiveSpan()

        let span = makeSpan(
            title: trimmedTask,
            client: currentClient,
            project: currentProject,
            ticket: currentTicket,
            start: Date(),
            end: nil,
            source: .pomodoro,
            isBillable: true,
            notes: "Pomodoro focus span"
        )

        spans.insert(span, at: 0)
        record(.create, span)
        upsertAssignment(client: span.clientName, project: span.projectName, ticket: span.ticketName)
        activeSpanID = span.id
        pomodoroWorkSpanID = span.id
        pomodoroRemaining = settings.pomodoroWorkMinutes * 60
        mode = .pomodoroWork
        lastError = nil
        configureScreenshotTimer()
    }

    func completePomodoroNow() {
        closeActiveSpan()
        activeSpanID = nil
        pomodoroWorkSpanID = nil
        pomodoroRemaining = settings.pomodoroBreakMinutes * 60
        mode = .pomodoroBreak
        stopScreenshotTimer()
    }

    func finishBreak() {
        pomodoroRemaining = 0
        mode = .idle
    }

    // MARK: - Taxonomy

    func addClient() {
        let name = draftClientName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            lastError = "Enter a client name."
            return
        }
        upsertClient(name)
        draftClientName = ""
        lastError = nil
    }

    func addProject() {
        let client = draftProjectClient.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = draftProjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            lastError = "Enter a project name."
            return
        }
        upsertAssignment(client: client, project: name, ticket: "")
        draftProjectClient = ""
        draftProjectName = ""
        lastError = nil
    }

    func addTicket() {
        let client = draftTicketClient.trimmingCharacters(in: .whitespacesAndNewlines)
        let project = draftTicketProject.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = draftTicketName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            lastError = "Enter a ticket name."
            return
        }
        upsertAssignment(client: client, project: project, ticket: name)
        draftTicketClient = ""
        draftTicketProject = ""
        draftTicketName = ""
        lastError = nil
    }

    private func upsertAssignment(client: String, project: String, ticket: String) {
        upsertClient(client)
        upsertProject(name: project, client: client)
        upsertTicket(name: ticket, project: project, client: client)
    }

    /// Deduplication is by deterministic id rather than by case-insensitive name
    /// compare. `Canon.canon` is the rule the server and every other client use,
    /// so "Bob's Diner" typed on a phone and "Bob's Diner" typed here collapse to
    /// one row instead of two that merely look alike.
    private func upsertClient(_ name: String) {
        guard let record = ClientRecord.minted(
            workspaceID: workspaceID, deviceID: deviceID, name: name, autoCreated: true
        ) else { return }
        guard !clients.contains(where: { $0.id == record.id }) else { return }

        clients.append(record)
        clients.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        self.record(.create, record)
    }

    private func upsertProject(name: String, client: String) {
        guard let record = ProjectRecord.minted(
            workspaceID: workspaceID, deviceID: deviceID,
            clientName: client, name: name, autoCreated: true
        ) else { return }
        guard !projects.contains(where: { $0.id == record.id }) else { return }

        projects.append(record)
        projects.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        self.record(.create, record)
    }

    private func upsertTicket(name: String, project: String, client: String) {
        guard let record = TicketRecord.minted(
            workspaceID: workspaceID, deviceID: deviceID,
            clientName: client, projectName: project, name: name, autoCreated: true
        ) else { return }
        guard !tickets.contains(where: { $0.id == record.id }) else { return }

        tickets.append(record)
        tickets.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        self.record(.create, record)
    }

    // MARK: - Screenshots

    func captureScreenshotNow() {
        do {
            let record = try captureScreenshot()
            screenshots.insert(record, at: 0)
            lastScreenshotAt = record.capturedAt
            self.record(.create, record)
            analyzeScreenshotIfConfigured(record)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func analyzeLatestScreenshot() async {
        guard let screenshot = screenshots.first else {
            lastError = "Capture a screenshot before running vision analysis."
            return
        }
        await analyzeScreenshot(screenshot, force: true)
    }

    func openScreenshotsFolder() {
        ensureDirectories()
        NSWorkspace.shared.open(screenshotsURL)
    }

    private func captureScreenshot() throws -> Screenshot {
        ensureDirectories()
        guard let image = CGDisplayCreateImage(CGMainDisplayID()) else {
            throw TimelyError.screenshotUnavailable
        }

        let bitmap = NSBitmapImageRep(cgImage: image)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw TimelyError.screenshotEncodingFailed
        }

        let capturedAt = Date()
        let fileName = "timely-\(Self.fileStampFormatter.string(from: capturedAt)).png"
        let url = screenshotsURL.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)

        return Screenshot(
            sync: .local(id: UUID.v7(), workspaceID: workspaceID, deviceID: deviceID),
            spanID: activeSpanID,
            capturedAt: capturedAt,
            fileName: fileName,
            activeAppName: NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown app",
            // The bytes are on this disk and have not been offered to anyone.
            // Only the server may move this past `localOnly`, and only through
            // the double gate.
            uploadState: .localOnly
        )
    }

    private func analyzeScreenshotIfConfigured(_ screenshot: Screenshot) {
        guard settings.vision.analysisEnabled else { return }
        Task { @MainActor in
            await analyzeScreenshot(screenshot, force: false)
        }
    }

    private func analyzeScreenshot(_ screenshot: Screenshot, force: Bool) async {
        if !force && visionAnalyses.contains(where: { $0.screenshotID == screenshot.id }) {
            return
        }

        isAnalyzingVisionScreenshot = true
        defer { isAnalyzingVisionScreenshot = false }

        let client = VisionLLMClient(settings: settings.vision)
        let screenshotURL = screenshotsURL.appendingPathComponent(screenshot.fileName)
        let context = VisionAnalysisContext(
            knownTask: activeSpan?.title ?? currentTask,
            knownProject: activeSpan?.projectName ?? currentProject,
            activeAppName: screenshot.activeAppName,
            previousInferredProject: lastInferredProject,
            capturedAt: screenshot.capturedAt
        )

        do {
            var analysis = try await client.analyze(
                screenshotID: screenshot.id,
                workspaceID: workspaceID,
                deviceID: deviceID,
                screenshotURL: screenshotURL,
                context: context
            )
            if analysis.projectSwitchDetected && analysis.confidence < settings.vision.confidenceThreshold {
                analysis.projectSwitchDetected = false
            }
            if settings.vision.privacyRedactionEnabled && analysis.privacySensitive {
                censorScreenshot(screenshot, analysis: analysis)
                return
            }
            recordVisionAnalysis(analysis)
        } catch {
            let failed = VisionAnalysis(
                sync: .local(id: UUID.v7(), workspaceID: workspaceID, deviceID: deviceID),
                screenshotID: screenshot.id,
                analyzedAt: Date(),
                model: settings.vision.effectiveModel,
                statusUpdate: "Vision analysis failed.",
                confidence: 0,
                errorMessage: error.localizedDescription
            )
            recordVisionAnalysis(failed)
            lastError = error.localizedDescription
        }
    }

    /// Vision analyses are **append-only** (§8 rows 14, 15): re-analysis creates
    /// a new row rather than editing the old one, and the server rejects an
    /// update with `immutable_entity`. The previous row is tombstoned rather
    /// than dropped from the array, so the supersede is expressible on the wire.
    private func recordVisionAnalysis(_ analysis: VisionAnalysis) {
        let superseded = visionAnalyses.filter { $0.screenshotID == analysis.screenshotID }
        visionAnalyses.removeAll { $0.screenshotID == analysis.screenshotID }
        for old in superseded {
            record(.delete, old)
        }

        visionAnalyses.insert(analysis, at: 0)
        visionAnalyses = Array(visionAnalyses.prefix(200))
        record(.create, analysis)

        if !analysis.inferredProject.isEmpty {
            lastInferredProject = analysis.inferredProject
        }

        if settings.vision.notifyOnProjectSwitch && analysis.projectSwitchDetected {
            sendProjectSwitchNotification(analysis)
        }
    }

    /// The censorship path — the one that used to leak.
    ///
    /// Previously this deleted the PNG **and** `removeAll`'d the `ScreenshotRecord`
    /// and its analyses from local state. Deleting the bytes is right. Deleting
    /// the *rows* is not expressible in this protocol: the server has no idea
    /// they are gone, so the next pull hands them straight back and the app
    /// re-materializes the record of a screenshot the user asked it to forget.
    /// That is a privacy failure, not untidiness.
    ///
    /// What the contract actually says: creating a `censored_screenshot` row is
    /// an *assertion of censorship*. The server applies the cascade — tombstone
    /// the screenshot, tombstone its analyses, purge any stored blob — and
    /// returns it as `side_effects`. So the client's job is:
    ///
    /// 1. delete the local bytes (unchanged — they must go),
    /// 2. **tombstone** the screenshot and its analyses locally,
    /// 3. create the censorship assertion and let it sync.
    private func censorScreenshot(_ screenshot: Screenshot, analysis: VisionAnalysis) {
        // 1. The bytes. This part was always correct.
        let screenshotURL = screenshotsURL.appendingPathComponent(screenshot.fileName)
        var deletedLocalFile = false
        if FileManager.default.fileExists(atPath: screenshotURL.path) {
            do {
                try FileManager.default.removeItem(at: screenshotURL)
                deletedLocalFile = true
            } catch {
                lastError = "Sensitive screenshot was detached, but the local file "
                    + "could not be deleted: \(error.localizedDescription)"
            }
        } else {
            deletedLocalFile = true
        }

        // 2. Tombstones, not deletions. The rows leave the UI either way, but
        // now they leave it in a way the server can be told about.
        let doomedAnalyses = visionAnalyses.filter { $0.screenshotID == screenshot.id }
        screenshots.removeAll { $0.id == screenshot.id }
        visionAnalyses.removeAll { $0.screenshotID == screenshot.id }

        record(.delete, screenshot)
        for old in doomedAnalyses {
            record(.delete, old)
        }

        // 3. The assertion. Append-only, so this is always a create.
        let record = CensoredScreenshot(
            sync: .local(id: UUID.v7(), workspaceID: workspaceID, deviceID: deviceID),
            screenshotID: screenshot.id,
            spanID: screenshot.spanID,
            fileName: screenshot.fileName,
            activeAppName: screenshot.activeAppName,
            capturedAt: screenshot.capturedAt,
            censoredAt: Date(),
            model: analysis.model,
            category: analysis.privacyCategory.isSensitive ? analysis.privacyCategory : .otherPrivate,
            reason: analysis.evidence.isEmpty
                ? "Vision LLM identified private screenshot content."
                : analysis.evidence,
            confidence: analysis.confidence,
            // This device's report about its own disk. It says nothing about any
            // other device and must not be rendered as a workspace-wide claim.
            deletedLocalFile: deletedLocalFile
        )
        censoredScreenshots.insert(record, at: 0)
        censoredScreenshots = Array(censoredScreenshots.prefix(200))
        self.record(.create, record)

        if settings.vision.notifyOnCensoredScreenshot {
            sendCensoredScreenshotNotification(record)
        }
    }

    // MARK: - Notifications

    private func requestNotificationPermissionIfNeeded() {
        guard settings.vision.notifyOnProjectSwitch || settings.vision.notifyOnCensoredScreenshot else { return }
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                _ = try? await center.requestAuthorization(options: [.alert, .sound])
            }
        }
    }

    func requestNotificationPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    private func sendProjectSwitchNotification(_ analysis: VisionAnalysis) {
        let content = UNMutableNotificationContent()
        content.title = "Timely detected a project switch"
        let project = analysis.inferredProject.isEmpty ? "another project" : analysis.inferredProject
        content.body = "It looks like you switched to \(project). \(analysis.statusUpdate)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "timely-project-switch-\(analysis.id.uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func sendCensoredScreenshotNotification(_ record: CensoredScreenshot) {
        let content = UNMutableNotificationContent()
        content.title = "Timely censored a screenshot"
        let category = record.category.rawValue.replacingOccurrences(of: "_", with: " ")
        content.body = "A \(category) screenshot was removed from evidence history."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "timely-censored-\(record.id.uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Timers

    private func startClock() {
        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        now = Date()
        guard mode == .pomodoroWork || mode == .pomodoroBreak else { return }

        pomodoroRemaining = max(0, pomodoroRemaining - 1)
        if pomodoroRemaining == 0 {
            if mode == .pomodoroWork {
                completePomodoroNow()
            } else {
                finishBreak()
            }
        }
    }

    private func configureScreenshotTimer() {
        stopScreenshotTimer()
        guard settings.screenshotCaptureEnabled,
              mode == .running || mode == .pomodoroWork,
              settings.screenshotIntervalMinutes > 0 else { return }

        screenshotTimer = Timer.scheduledTimer(
            withTimeInterval: settings.screenshotIntervalMinutes * 60, repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.captureScreenshotNow()
            }
        }
    }

    private func stopScreenshotTimer() {
        screenshotTimer?.invalidate()
        screenshotTimer = nil
    }

    private func ensureDirectories() {
        try? FileManager.default.createDirectory(at: screenshotsURL, withIntermediateDirectories: true)
    }

    private static let fileStampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()

    // MARK: - Device settings
    //
    // These stay a small local JSON file rather than moving into SQLite. They
    // are device configuration, not workspace data — the vision API key in
    // particular is a device secret the contract deliberately has no field for
    // — and they must be readable before the database is open.

    private func loadDeviceSettings() {
        guard let data = try? Data(contentsOf: settingsURL) else {
            migrateSettingsFromLegacySnapshot()
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let loaded = try? decoder.decode(AppSettings.self, from: data) {
            settings = loaded
        }
    }

    /// The old blob carried settings too. Lift them across on first launch so a
    /// returning user does not find their configuration reset.
    private func migrateSettingsFromLegacySnapshot() {
        guard let data = try? Data(contentsOf: legacySnapshotURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        struct SettingsOnly: Decodable { let settings: AppSettings }
        if let wrapper = try? decoder.decode(SettingsOnly.self, from: data) {
            settings = wrapper.settings
            saveDeviceSettings()
        }
    }

    private func saveDeviceSettings() {
        ensureDirectories()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(settings) {
            try? data.write(to: settingsURL, options: .atomic)
        }
    }

    func settingsChanged() {
        saveDeviceSettings()
        configureScreenshotTimer()
    }
}

enum TimelyError: LocalizedError {
    case screenshotUnavailable
    case screenshotEncodingFailed

    var errorDescription: String? {
        switch self {
        case .screenshotUnavailable:
            "Screenshot capture failed. Grant Screen Recording permission to Timely in System Settings and try again."
        case .screenshotEncodingFailed:
            "Screenshot capture succeeded, but PNG encoding failed."
        }
    }
}
