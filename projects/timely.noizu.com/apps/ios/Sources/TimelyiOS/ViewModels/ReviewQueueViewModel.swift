import Foundation
import Observation
import TimelyKit

/// The queue of decisions only a person can make.
///
/// `suspected_duplicate` and `billing_overlap` arrive here and stay here until
/// the user answers. There is no "resolve all", no heuristic, and no timeout
/// that clears them — the server refuses to guess for exactly the same reason
/// this screen does, and it says so in §8.3.
@MainActor
@Observable
final class ReviewQueueViewModel {

    private(set) var items: [ReviewItem] = []
    private(set) var spansByID: [UUID: TimeSpan] = [:]
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    /// How far back the queue looks. Flags do not expire, but a companion
    /// showing a year of them is not a queue, it is a backlog.
    var lookbackDays = 90

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    var judgementItems: [ReviewItem] { items.filter(\.requiresUserJudgement) }
    var informationalItems: [ReviewItem] { items.filter { !$0.requiresUserJudgement } }

    func span(_ id: UUID?) -> TimeSpan? {
        id.flatMap { spansByID[$0] }
    }

    /// The two intervals of a flagged pair, in the order the item names them.
    func pair(for item: ReviewItem) -> (TimeSpan?, TimeSpan?) {
        (span(item.spanID), span(item.relatedSpanID))
    }

    // MARK: - Loading

    func load(environment: AppEnvironment, now: Date = Date()) async {
        guard let repository = environment.repository else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let from = calendar.date(byAdding: .day, value: -max(1, lookbackDays), to: now) ?? now
            let window = DateInterval(start: from, end: now.addingTimeInterval(86_400))
            let spans = try await repository.spans(in: window)
            let outcomes = try await repository.pendingOutcomes()

            spansByID = Dictionary(uniqueKeysWithValues: spans.map { ($0.id, $0) })
            items = ReviewItemBuilder.items(spans: spans, outcomes: outcomes, now: now)
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    // MARK: - Resolution

    /// Record the user's answer.
    ///
    /// `resolution` comes from a tap, always. A paired flag writes to both
    /// rows; the queue's FIFO ordering guarantees both land or neither does.
    func resolve(
        _ item: ReviewItem,
        as resolution: ReviewResolution,
        environment: AppEnvironment,
        now: Date = Date()
    ) async {
        guard let repository = environment.repository else { return }

        switch SpanCorrection.resolve(item, as: resolution, spans: spansByID, now: now) {
        case .success(let plan):
            do {
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

    /// Merge the two intervals of a flagged pair into one.
    ///
    /// Offered only for `suspected_duplicate`: a `billing_overlap` names two
    /// *different clients*, and merging those would silently move billable time
    /// from one client to another.
    func mergePair(
        _ item: ReviewItem,
        keeping primaryID: UUID,
        environment: AppEnvironment,
        now: Date = Date()
    ) async {
        guard let repository = environment.repository else { return }
        guard item.code == .suspectedDuplicate else {
            errorMessage = "Overlapping time for two clients cannot be merged. "
                + "Correct one of the intervals instead."
            return
        }
        guard let first = span(item.spanID), let second = span(item.relatedSpanID),
              let primary = span(primaryID) else {
            errorMessage = SpanCorrectionError.reasonNotFound.description
            return
        }

        switch SpanCorrection.merge([first, second], keeping: primary,
                                    context: repository.context, now: now) {
        case .success(let plan):
            do {
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

    /// Dismiss a push conflict or rejection the user has read.
    func acknowledge(_ item: ReviewItem, environment: AppEnvironment) async {
        guard let repository = environment.repository, let mutationID = item.mutationID else { return }
        do {
            try await repository.acknowledgeOutcome(mutationID: mutationID)
            await load(environment: environment)
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func clearError() { errorMessage = nil }
}
