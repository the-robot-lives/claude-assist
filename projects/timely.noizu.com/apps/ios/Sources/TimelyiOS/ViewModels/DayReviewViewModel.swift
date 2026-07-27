import Foundation
import Observation
import TimelyKit

/// One day, loaded for review.
///
/// Backs both Today and Timeline: they are the same day-shaped surface with a
/// different date and a different amount of chrome. Everything it computes —
/// the rollup, the idle gaps, the confidence labels — is derived from the local
/// store, so the screen is complete before any network call and stays complete
/// without one.
@MainActor
@Observable
final class DayReviewViewModel {

    private(set) var date: Date
    private(set) var spans: [TimeSpan] = []
    private(set) var evidence: [UUID: SpanEvidence] = [:]
    private(set) var rollup: DayRollup = .empty
    private(set) var weightedShares: [UUID: TimeInterval] = [:]
    private(set) var idleGaps: [IdleGap] = []
    private(set) var reviewItems: [ReviewItem] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    /// Model-confidence cut-off, read from the user's settings.
    private(set) var confidenceThreshold: Double = 0.72

    /// Idle threshold in force: the stricter of the workspace policy and the
    /// user's own preference.
    private(set) var idleThreshold: TimeInterval = 300

    var searchText = ""
    var showOnlyNeedsReview = false
    var selection: Set<UUID> = []

    private let calendar: Calendar

    init(date: Date = Date(), calendar: Calendar = .current) {
        self.date = calendar.startOfDay(for: date)
        self.calendar = calendar
    }

    var window: DateInterval {
        TimelyFormat.dayInterval(containing: date, calendar: calendar)
    }

    var title: String {
        TimelyFormat.dayTitle(date, calendar: calendar)
    }

    var isToday: Bool { calendar.isDateInToday(date) }

    /// The spans a filter or a search leaves visible. Ordering is chronological
    /// rather than newest-first: a day is read forwards.
    var visibleSpans: [TimeSpan] {
        var result = spans.sorted { $0.start < $1.start }

        if showOnlyNeedsReview {
            result = result.filter(\.needsReview)
        }

        let needle = Canon.canon(searchText)
        if !needle.isEmpty {
            result = result.filter { span in
                let haystack = Canon.canon(
                    [span.title, span.clientName, span.projectName, span.ticketName, span.notes]
                        .joined(separator: " ")
                )
                return haystack.contains(needle)
            }
        }
        return result
    }

    var selectedSpans: [TimeSpan] {
        spans.filter { selection.contains($0.id) }
    }

    var unresolvedIdleGaps: [IdleGap] { idleGaps }

    var pendingJudgementCount: Int {
        reviewItems.filter(\.requiresUserJudgement).count
    }

    func confidence(for span: TimeSpan) -> ConfidenceState {
        ConfidenceState.derive(
            span: span,
            evidence: evidence[span.id] ?? .none,
            confidenceThreshold: confidenceThreshold
        )
    }

    func evidence(for span: TimeSpan) -> SpanEvidence {
        evidence[span.id] ?? .none
    }

    func weighted(for span: TimeSpan) -> TimeInterval? {
        weightedShares[span.id]
    }

    // MARK: - Navigation

    func move(byDays days: Int) {
        date = calendar.date(byAdding: .day, value: days, to: date) ?? date
        selection.removeAll()
    }

    func jump(to newDate: Date) {
        date = calendar.startOfDay(for: newDate)
        selection.removeAll()
    }

    func goToToday() {
        jump(to: Date())
    }

    // MARK: - Loading

    func load(environment: AppEnvironment, now: Date = Date()) async {
        guard let repository = environment.repository else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let policy = try await repository.policy()
            let settings = try await repository.userSettingsOrDefault()
            confidenceThreshold = settings.vision.confidenceThreshold
            // A workspace floor and a user preference are both minutes; the
            // shorter one wins, because a user may be stricter than their
            // workspace but never looser.
            idleThreshold = min(settings.idleThresholdMinutes, policy.idleThresholdMinutes) * 60

            let window = self.window
            let loaded = try await repository.spans(in: window)
            spans = loaded

            var collected: [UUID: SpanEvidence] = [:]
            for span in loaded {
                collected[span.id] = try await repository.evidence(for: span.id)
            }
            evidence = collected

            rollup = LocalRollup.compute(spans: loaded, window: window, now: now)
            weightedShares = LocalRollup.weightedShares(spans: loaded, window: window, now: now)

            let workspaceID = repository.context.workspaceID
            idleGaps = IdleGapDetector
                .gaps(in: loaded, window: window, threshold: idleThreshold, now: now)
                .filter { !environment.dismissals.isDismissed($0, workspaceID: workspaceID) }

            reviewItems = ReviewItemBuilder.items(spans: loaded, now: now)

            selection = selection.intersection(Set(loaded.map(\.id)))
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }
}
