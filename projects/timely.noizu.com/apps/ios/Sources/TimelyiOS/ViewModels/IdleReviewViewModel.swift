import Foundation
import Observation
import TimelyKit

/// Resolving unaccounted time.
///
/// Idle gaps are derived, not stored: the protocol has no entity for them
/// (§13.6). That shapes the two answers this screen offers. "Account for it"
/// writes a real span, which syncs. "It wasn't work" records a dismissal in
/// device-local storage, which does not — and the screen says so rather than
/// implying the decision travelled.
@MainActor
@Observable
final class IdleReviewViewModel {

    struct DayGaps: Identifiable, Sendable {
        let date: Date
        let gaps: [IdleGap]
        var id: Date { date }
    }

    private(set) var days: [DayGaps] = []
    private(set) var spansByID: [UUID: TimeSpan] = [:]
    private(set) var idleThreshold: TimeInterval = 300
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    /// How far back to look. A companion is for reviewing the recent past; a
    /// month-old gap is not a prompt, it is archaeology.
    var lookbackDays = 7

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    var totalGaps: Int { days.reduce(0) { $0 + $1.gaps.count } }

    var totalUnaccounted: TimeInterval {
        days.flatMap(\.gaps).reduce(0) { $0 + $1.duration }
    }

    func context(for gap: IdleGap) -> (before: TimeSpan?, after: TimeSpan?) {
        (gap.precedingSpanID.flatMap { spansByID[$0] },
         gap.followingSpanID.flatMap { spansByID[$0] })
    }

    // MARK: - Loading

    func load(environment: AppEnvironment, now: Date = Date()) async {
        guard let repository = environment.repository else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let policy = try await repository.policy()
            let settings = try await repository.userSettingsOrDefault()
            idleThreshold = min(settings.idleThresholdMinutes, policy.idleThresholdMinutes) * 60

            let workspaceID = repository.context.workspaceID
            var collected: [DayGaps] = []
            var spans: [UUID: TimeSpan] = [:]

            for offset in 0..<max(1, lookbackDays) {
                guard let day = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
                let window = TimelyFormat.dayInterval(containing: day, calendar: calendar)
                let daySpans = try await repository.spans(in: window)
                for span in daySpans { spans[span.id] = span }

                let gaps = IdleGapDetector
                    .gaps(in: daySpans, window: window, threshold: idleThreshold, now: now)
                    .filter { !environment.dismissals.isDismissed($0, workspaceID: workspaceID) }

                if !gaps.isEmpty {
                    collected.append(DayGaps(date: window.start, gaps: gaps))
                }
            }

            days = collected
            spansByID = spans
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    // MARK: - Resolution

    /// Account for a gap with a real interval.
    func account(
        for gap: IdleGap,
        title: String,
        clientName: String = "",
        projectName: String = "",
        ticketName: String = "",
        isBillable: Bool = false,
        environment: AppEnvironment,
        now: Date = Date()
    ) async {
        guard let repository = environment.repository else { return }

        let result = SpanCorrection.fillIdleGap(
            gap,
            title: title,
            clientName: clientName,
            projectName: projectName,
            ticketName: ticketName,
            isBillable: isBillable,
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
                await environment.syncNow()
                await load(environment: environment, now: now)
            } catch {
                errorMessage = String(describing: error)
            }
        case .failure(let error):
            errorMessage = error.description
        }
    }

    /// Mark a gap as not-work. Device-local; see the type doc.
    func dismiss(_ gap: IdleGap, environment: AppEnvironment) async {
        guard let repository = environment.repository else { return }
        environment.dismissals.dismiss(gap, workspaceID: repository.context.workspaceID)
        await load(environment: environment)
    }

    func restore(_ gap: IdleGap, environment: AppEnvironment) async {
        guard let repository = environment.repository else { return }
        environment.dismissals.restore(gap, workspaceID: repository.context.workspaceID)
        await load(environment: environment)
    }
}
