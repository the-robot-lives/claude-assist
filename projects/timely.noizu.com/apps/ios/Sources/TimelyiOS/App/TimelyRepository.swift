import Foundation
import TimelyKit

/// The app's one door to persistence.
///
/// Every read and every write goes through `TimelyLocalStore`, which never
/// consults the network or the auth state. That is what makes the offline
/// promise structural rather than aspirational: there is no code path in this
/// target that can gate an edit on connectivity, because the write API this
/// type wraps does not take a session.
struct TimelyRepository: Sendable {
    let store: TimelyLocalStore
    let context: WorkspaceContext

    private var workspaceID: UUID { context.workspaceID }
    private var deviceID: UUID { context.deviceID }

    // MARK: - Spans

    func spans(in window: DateInterval) async throws -> [TimeSpan] {
        try await store.fetchInRange(
            TimeSpan.self,
            workspaceID: workspaceID,
            from: window.start,
            to: window.end
        )
    }

    func span(id: UUID) async throws -> TimeSpan? {
        try await store.fetch(TimeSpan.self, id: id)
    }

    func spans(ids: [UUID]) async throws -> [UUID: TimeSpan] {
        var found: [UUID: TimeSpan] = [:]
        for id in ids {
            if let span = try await store.fetch(TimeSpan.self, id: id) {
                found[id] = span
            }
        }
        return found
    }

    func searchSpans(_ text: String, limit: Int = 100) async throws -> [TimeSpan] {
        try await store.search(TimeSpan.self, workspaceID: workspaceID, matching: text, limit: limit)
    }

    func openSpans() async throws -> [TimeSpan] {
        try await store.openSpans(workspaceID: workspaceID)
    }

    // MARK: - Evidence

    /// Screenshots for a span, plus their analyses and any censorship rows.
    ///
    /// The image bytes are not fetched and there is no code here that would.
    /// A companion's recall surface is metadata plus `recallSummary`.
    func evidence(for spanID: UUID) async throws -> SpanEvidence {
        let screenshots = try await store.fetchChildren(Screenshot.self, parentID: spanID)
        var analyses: [VisionAnalysis] = []
        var censored: [CensoredScreenshot] = []

        for screenshot in screenshots {
            analyses += try await store.fetchChildren(VisionAnalysis.self, parentID: screenshot.id)
            censored += try await store.fetchChildren(CensoredScreenshot.self, parentID: screenshot.id)
        }

        return SpanEvidence(screenshots: screenshots, analyses: analyses, censored: censored)
    }

    // MARK: - Taxonomy

    func clients() async throws -> [ClientRecord] {
        try await store.fetchAll(ClientRecord.self, workspaceID: workspaceID)
            .filter { !$0.isMergedAway }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func projects() async throws -> [ProjectRecord] {
        try await store.fetchAll(ProjectRecord.self, workspaceID: workspaceID)
            .filter { !$0.isMergedAway }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func tickets() async throws -> [TicketRecord] {
        try await store.fetchAll(TicketRecord.self, workspaceID: workspaceID)
            .filter { !$0.isMergedAway }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Vivify the taxonomy rows a span's names refer to.
    ///
    /// Ids are derived (UUIDv5 over the canonical name), so this is idempotent
    /// and converges with any other device that names the same thing. Rows are
    /// created only when absent, and marked `autoCreated` so they arrive
    /// flagged for review rather than silently joining the picker as if a human
    /// had curated them.
    func ensureTaxonomy(
        clientName: String,
        projectName: String,
        ticketName: String,
        at now: Date = Date()
    ) async throws {
        if let client = ClientRecord.minted(
            workspaceID: workspaceID, deviceID: deviceID,
            name: clientName, autoCreated: true, at: now
        ), try await store.fetch(ClientRecord.self, id: client.id) == nil {
            try await store.recordLocalChange(.create, entity: client, deviceID: deviceID, at: now)
        }

        if let project = ProjectRecord.minted(
            workspaceID: workspaceID, deviceID: deviceID,
            clientName: clientName, name: projectName, autoCreated: true, at: now
        ), try await store.fetch(ProjectRecord.self, id: project.id) == nil {
            try await store.recordLocalChange(.create, entity: project, deviceID: deviceID, at: now)
        }

        if let ticket = TicketRecord.minted(
            workspaceID: workspaceID, deviceID: deviceID,
            clientName: clientName, projectName: projectName,
            name: ticketName, autoCreated: true, at: now
        ), try await store.fetch(TicketRecord.self, id: ticket.id) == nil {
            try await store.recordLocalChange(.create, entity: ticket, deviceID: deviceID, at: now)
        }
    }

    // MARK: - Applying corrections

    /// Carry out a plan.
    ///
    /// Creates run before deletes so a split's replacements exist before the
    /// original is tombstoned, which is the order §7.3 describes. Every
    /// mutation in an atomic plan carries the same `batchGroup`, and the push
    /// queue refuses to split a group across batches.
    func apply(_ plan: SpanCorrectionPlan, at now: Date = Date()) async throws {
        for span in plan.creates {
            try await store.recordLocalChange(
                .create, entity: span, deviceID: deviceID, batchGroup: plan.batchGroup, at: now
            )
        }
        for span in plan.updates {
            try await store.recordLocalChange(
                .update, entity: span, deviceID: deviceID, batchGroup: plan.batchGroup, at: now
            )
        }
        for span in plan.deletes {
            try await store.recordLocalChange(
                .delete, entity: span, deviceID: deviceID, batchGroup: plan.batchGroup, at: now
            )
        }
    }

    // MARK: - Settings, policy, device

    func policy() async throws -> WorkspacePolicy {
        // An unknown policy is a *closed* gate. Defaulting the other way would
        // let a device that has not pulled yet believe upload is permitted.
        try await store.fetch(WorkspacePolicy.self, id: workspaceID)
            ?? .closed(workspaceID: workspaceID)
    }

    func userSettings() async throws -> UserSettings? {
        guard let userID = context.userID else { return nil }
        let id = Canon.userSettingsID(workspaceID: workspaceID, userID: userID)
        return try await store.fetch(UserSettings.self, id: id)
    }

    func userSettingsOrDefault() async throws -> UserSettings {
        if let existing = try await userSettings() { return existing }
        guard let userID = context.userID else {
            // No signed-in user yet: hand back an unsaved default rather than
            // inventing a row keyed on a user id we do not have.
            return UserSettings.minted(
                workspaceID: workspaceID, userID: workspaceID, deviceID: deviceID
            )
        }
        return UserSettings.minted(workspaceID: workspaceID, userID: userID, deviceID: deviceID)
    }

    func saveUserSettings(_ settings: UserSettings, at now: Date = Date()) async throws {
        let existing = try await store.fetch(UserSettings.self, id: settings.id)
        try await store.recordLocalChange(
            existing == nil ? .create : .update,
            entity: settings, deviceID: deviceID, at: now
        )
    }

    func device() async throws -> Device? {
        try await store.fetch(Device.self, id: deviceID)
    }

    /// This device's row, minted if it has never been registered.
    ///
    /// `isCaptureAgent` is false and stays false. The iOS app is a companion:
    /// the server rejects a capture claim from a non-macOS platform, and
    /// `Device.init` refuses to compose one anyway.
    func deviceOrDefault(appVersion: String, osVersion: String?, name: String) async throws -> Device {
        if let existing = try await device() { return existing }
        return Device(
            sync: .local(id: deviceID, workspaceID: workspaceID, deviceID: deviceID),
            userID: context.userID,
            platform: .ios,
            name: name,
            appVersion: appVersion,
            osVersion: osVersion,
            localOnlyScreenshots: true,
            isCaptureAgent: false
        )
    }

    func saveDevice(_ device: Device, at now: Date = Date()) async throws {
        let existing = try await store.fetch(Device.self, id: device.id)
        try await store.recordLocalChange(
            existing == nil ? .create : .update,
            entity: device, deviceID: deviceID, at: now
        )
    }

    func devices() async throws -> [Device] {
        try await store.fetchAll(Device.self, workspaceID: workspaceID)
    }

    // MARK: - Sync surface

    func pendingOutcomes() async throws -> [PendingOutcome] {
        try await store.pendingOutcomes(workspaceID: workspaceID)
    }

    func acknowledgeOutcome(mutationID: UUID) async throws {
        try await store.acknowledgeOutcome(mutationID: mutationID)
    }

    func queueDepth() async throws -> Int {
        try await store.queueDepth(workspaceID: workspaceID)
    }

    func syncState() async throws -> SyncCursorState {
        try await store.syncState(workspaceID: workspaceID)
    }
}
