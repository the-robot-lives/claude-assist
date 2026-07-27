import Foundation
import Observation
import TimelyKit

/// Correcting one interval: retitle, reassign, re-bill, adjust boundaries,
/// split, delete.
///
/// Every write goes out through `SpanCorrection`, which returns a plan, and
/// then through the repository, which queues it. Nothing here asks whether the
/// device is online, because nothing here could act on the answer.
@MainActor
@Observable
final class SpanEditorViewModel {

    private(set) var original: TimeSpan
    private(set) var evidence: SpanEvidence

    var title: String
    var clientName: String
    var projectName: String
    var ticketName: String
    var start: Date
    var end: Date?
    var isBillable: Bool
    var notes: String

    /// Where a split would cut. Defaults to the midpoint, which is the least
    /// surprising starting position for a slider.
    var splitPoint: Date

    private(set) var isWorking = false
    private(set) var errorMessage: String?
    private(set) var didFinish = false

    init(span: TimeSpan, evidence: SpanEvidence = .none, now: Date = Date()) {
        self.original = span
        self.evidence = evidence
        self.title = span.title
        self.clientName = span.clientName
        self.projectName = span.projectName
        self.ticketName = span.ticketName
        self.start = span.start
        self.end = span.end
        self.isBillable = span.isBillable
        self.notes = span.notes

        let finish = span.end ?? now
        self.splitPoint = span.start.addingTimeInterval(
            max(60, finish.timeIntervalSince(span.start) / 2)
        )
    }

    // MARK: - Derived state

    var isLocked: Bool { original.isLocked }

    var confidence: ConfidenceState {
        ConfidenceState.derive(span: original, evidence: evidence)
    }

    var isOpen: Bool { end == nil }

    var duration: TimeInterval { (end ?? Date()).timeIntervalSince(start) }

    var canSplit: Bool {
        !isLocked && splitPoint > start && (end.map { splitPoint < $0 } ?? true)
    }

    var hasChanges: Bool {
        title != original.title
            || clientName != original.clientName
            || projectName != original.projectName
            || ticketName != original.ticketName
            || start != original.start
            || end != original.end
            || isBillable != original.isBillable
            || notes != original.notes
    }

    /// Flags on this span that still need an answer. Shown inline so a
    /// correction and its reason live on the same screen.
    var pendingReasons: [ReviewReason] { original.pendingReviewReasons }

    var lineage: [UUID] { original.derivedFromSpanIDs }

    func clearError() { errorMessage = nil }

    // MARK: - Actions

    func save(environment: AppEnvironment, now: Date = Date()) async {
        guard let repository = environment.repository else { return }
        guard hasChanges else { didFinish = true; return }

        var edited = original
        edited.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        edited.clientName = clientName.trimmingCharacters(in: .whitespaces)
        edited.projectName = projectName.trimmingCharacters(in: .whitespaces)
        edited.ticketName = ticketName.trimmingCharacters(in: .whitespaces)
        edited.start = start
        edited.end = end
        edited.isBillable = isBillable
        edited.notes = notes

        // Reassignment changes which taxonomy row this points at. Clearing the
        // ids lets the name resolve again — §6 makes a name the resolution
        // input when the id is absent — rather than keeping a stale id that
        // contradicts the name shown on screen.
        if edited.clientName != original.clientName { edited.clientID = nil }
        if edited.projectName != original.projectName { edited.projectID = nil }
        if edited.ticketName != original.ticketName { edited.ticketID = nil }

        await run(environment: environment) {
            try await repository.ensureTaxonomy(
                clientName: edited.clientName,
                projectName: edited.projectName,
                ticketName: edited.ticketName,
                at: now
            )
            switch SpanCorrection.update(edited) {
            case .success(let plan):
                try await repository.apply(plan, at: now)
                self.original = edited
                self.didFinish = true
            case .failure(let error):
                self.errorMessage = error.description
            }
        }
    }

    func split(environment: AppEnvironment, now: Date = Date()) async {
        guard let repository = environment.repository else { return }

        await run(environment: environment) {
            switch SpanCorrection.split(
                self.original, at: self.splitPoint,
                context: repository.context, now: now
            ) {
            case .success(let plan):
                try await repository.apply(plan, at: now)
                self.didFinish = true
            case .failure(let error):
                self.errorMessage = error.description
            }
        }
    }

    func delete(environment: AppEnvironment, now: Date = Date()) async {
        guard let repository = environment.repository else { return }

        await run(environment: environment) {
            switch SpanCorrection.delete(self.original) {
            case .success(let plan):
                try await repository.apply(plan, at: now)
                self.didFinish = true
            case .failure(let error):
                self.errorMessage = error.description
            }
        }
    }

    /// Close an interval that is still running.
    func close(environment: AppEnvironment, at closeTime: Date = Date()) async {
        guard original.isOpen, closeTime > start else { return }
        end = closeTime
        await save(environment: environment, now: closeTime)
    }

    private func run(
        environment: AppEnvironment,
        _ body: () async throws -> Void
    ) async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            try await body()
            await environment.refreshQueueDepth()
            // Best effort. The mutation is already durable in the queue, so a
            // failure here changes nothing about whether the edit survived.
            await environment.syncNow()
        } catch {
            errorMessage = String(describing: error)
        }
    }
}
