import Foundation
import TimelyKit

/// A local, offline rollup of a set of spans over a window.
///
/// **Not** interchangeable with `ReportSummary`. The server sees every device's
/// spans; this device may not have pulled them all, so this is immediate
/// feedback for review, never the number on an invoice. Every screen that shows
/// one says which it is.
struct DayRollup: Sendable, Hashable {
    var elapsed: TimeInterval = 0
    var billable: TimeInterval = 0
    var nonBillable: TimeInterval = 0

    /// Billable time after overlap de-weighting: two billable timers running
    /// over the same hour contribute that hour once, not twice. This is the
    /// figure that answers "how much can I actually bill".
    var weightedBillable: TimeInterval = 0

    var spanCount: Int = 0
    var needsReviewCount: Int = 0
    var openSpanCount: Int = 0

    static let empty = DayRollup()

    /// How much of the billable total is contested by an overlap, in seconds.
    var contestedBillable: TimeInterval { max(0, billable - weightedBillable) }

    var hasContestedTime: Bool { contestedBillable > 1 }
}

enum LocalRollup {

    /// Compute a rollup over `window`, clamping every span to it.
    ///
    /// Open spans are measured to `now` — an open span is real time being
    /// accrued, and hiding it until it closes makes the day's total wrong all
    /// day. Clamping matters because `fetchInRange` returns anything that
    /// *overlaps* the window, including yesterday's span that ran past midnight.
    static func compute(
        spans: [TimeSpan],
        window: DateInterval,
        now: Date = Date()
    ) -> DayRollup {
        var rollup = DayRollup()
        var billableIntervals: [DateInterval] = []

        for span in spans where !span.isDeleted {
            guard let clamped = clamp(span, to: window, now: now) else { continue }

            rollup.spanCount += 1
            rollup.elapsed += clamped.duration
            if span.isOpen { rollup.openSpanCount += 1 }
            if span.needsReview { rollup.needsReviewCount += 1 }

            if span.isBillable {
                rollup.billable += clamped.duration
                billableIntervals.append(clamped)
            } else {
                rollup.nonBillable += clamped.duration
            }
        }

        rollup.weightedBillable = unionDuration(of: billableIntervals)
        return rollup
    }

    /// Each span's share of the billable clock once overlaps are split evenly,
    /// keyed by span id.
    ///
    /// The per-span figures sum to ``unionDuration(of:)`` — the same total the
    /// rollup reports — so a per-project breakdown and the day total agree.
    static func weightedShares(
        spans: [TimeSpan],
        window: DateInterval,
        now: Date = Date()
    ) -> [UUID: TimeInterval] {
        let billable: [(id: UUID, interval: DateInterval)] = spans
            .filter { !$0.isDeleted && $0.isBillable }
            .compactMap { span in
                clamp(span, to: window, now: now).map { (span.id, $0) }
            }

        guard !billable.isEmpty else { return [:] }

        var shares: [UUID: TimeInterval] = [:]
        for slice in sweep(billable.map(\.interval)) {
            let covering = billable.filter { $0.interval.intersects(slice) }
            guard !covering.isEmpty else { continue }
            let each = slice.duration / Double(covering.count)
            for entry in covering {
                shares[entry.id, default: 0] += each
            }
        }
        return shares
    }

    /// Total wall-clock time covered by at least one of `intervals`.
    static func unionDuration(of intervals: [DateInterval]) -> TimeInterval {
        guard !intervals.isEmpty else { return 0 }
        var total: TimeInterval = 0
        var cursor: Date?

        for interval in intervals.sorted(by: { $0.start < $1.start }) {
            if let end = cursor, interval.start <= end {
                if interval.end > end {
                    total += interval.end.timeIntervalSince(end)
                    cursor = interval.end
                }
            } else {
                total += interval.duration
                cursor = interval.end
            }
        }
        return total
    }

    /// A span's footprint inside the window, or nil when it does not land in it.
    static func clamp(_ span: TimeSpan, to window: DateInterval, now: Date) -> DateInterval? {
        let rawEnd = span.end ?? now
        // A span whose clock has not caught up to its start (skew, or an open
        // span queried in the past) contributes nothing rather than negative
        // time.
        let end = max(span.start, rawEnd)

        let start = max(span.start, window.start)
        let finish = min(end, window.end)
        guard finish > start else { return nil }
        return DateInterval(start: start, end: finish)
    }

    /// Cut `intervals` at every boundary, yielding non-overlapping slices that
    /// together cover the same union.
    private static func sweep(_ intervals: [DateInterval]) -> [DateInterval] {
        var boundaries = Set<Date>()
        for interval in intervals {
            boundaries.insert(interval.start)
            boundaries.insert(interval.end)
        }
        let ordered = boundaries.sorted()
        guard ordered.count > 1 else { return [] }

        var slices: [DateInterval] = []
        for index in 0..<(ordered.count - 1) {
            let slice = DateInterval(start: ordered[index], end: ordered[index + 1])
            guard slice.duration > 0 else { continue }
            // Drop slices in a hole between two disjoint intervals.
            if intervals.contains(where: { $0.intersects(slice) }) {
                slices.append(slice)
            }
        }
        return slices
    }
}

private extension DateInterval {
    /// Strict overlap: touching endpoints are not an intersection, so a slice
    /// that merely abuts an interval is not attributed to it.
    func intersects(_ other: DateInterval) -> Bool {
        start < other.end && other.start < end
    }
}
