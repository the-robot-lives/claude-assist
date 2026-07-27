import Foundation
import Observation
import TimelyKit

/// Adding an interval by hand.
///
/// The companion has no timer and never will — "intervals over timers" is the
/// second UX principle, and a phone that runs a stopwatch while a desktop agent
/// is also capturing produces exactly the double-billed hour the protocol goes
/// to such lengths to flag.
@MainActor
@Observable
final class ManualEntryViewModel {

    var title = ""
    var clientName = ""
    var projectName = ""
    var ticketName = ""
    var start: Date
    var end: Date
    var leaveOpen = false
    var isBillable = false
    var notes = ""

    private(set) var isWorking = false
    private(set) var errorMessage: String?
    private(set) var didFinish = false

    private(set) var knownClients: [String] = []
    private(set) var knownProjects: [String] = []

    init(start: Date = Date().addingTimeInterval(-3600), end: Date = Date()) {
        self.start = start
        self.end = end
    }

    /// Pre-filled from an idle gap the user chose to account for.
    convenience init(fillingGap gap: IdleGap) {
        self.init(start: gap.start, end: gap.end)
    }

    var duration: TimeInterval {
        leaveOpen ? Date().timeIntervalSince(start) : end.timeIntervalSince(start)
    }

    var canSave: Bool {
        !isWorking
            && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (leaveOpen || end > start)
    }

    func clearError() { errorMessage = nil }

    func loadSuggestions(environment: AppEnvironment) async {
        guard let repository = environment.repository else { return }
        knownClients = (try? await repository.clients().map(\.name)) ?? []
        knownProjects = (try? await repository.projects().map(\.name)) ?? []
    }

    func save(environment: AppEnvironment, now: Date = Date()) async {
        guard let repository = environment.repository else { return }

        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        let result = SpanCorrection.manualEntry(
            title: title,
            start: start,
            end: leaveOpen ? nil : end,
            clientName: clientName,
            projectName: projectName,
            ticketName: ticketName,
            isBillable: isBillable,
            notes: notes,
            context: repository.context,
            now: now
        )

        switch result {
        case .success(let plan):
            do {
                try await repository.ensureTaxonomy(
                    clientName: clientName, projectName: projectName,
                    ticketName: ticketName, at: now
                )
                try await repository.apply(plan, at: now)
                didFinish = true
                await environment.refreshQueueDepth()
                await environment.syncNow()
            } catch {
                errorMessage = String(describing: error)
            }
        case .failure(let error):
            errorMessage = error.description
        }
    }
}
