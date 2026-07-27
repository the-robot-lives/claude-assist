import Foundation
import TimelyKit

/// An unaccounted stretch between two tracked intervals.
///
/// Idle gaps have **no entity in the protocol** (`SYNC-PROTOCOL.md` §13.6):
/// they are derived from the space between spans. That has two consequences the
/// UI must respect. First, this type is computed, never synced. Second, a user
/// saying "I wasn't working then" has nowhere on the server to record that, so a
/// dismissal is device-local — see ``IdleGapDismissals``.
struct IdleGap: Identifiable, Sendable, Hashable {
    let start: Date
    let end: Date

    /// The span that ended the gap open, when there is one.
    let precedingSpanID: UUID?

    /// The span that closed it.
    let followingSpanID: UUID?

    var duration: TimeInterval { end.timeIntervalSince(start) }

    /// Stable across recomputation of the same day, which is what lets a
    /// dismissal stick. Derived from the boundaries rather than minted, because
    /// there is no row to carry an id.
    var id: String {
        "\(Int(start.timeIntervalSince1970))-\(Int(end.timeIntervalSince1970))"
    }
}

enum IdleGapDetector {

    /// Interior gaps in `window` longer than `threshold`.
    ///
    /// Only *interior* gaps are emitted. The stretch before the first span of
    /// the day is not idle time, it is time before work started, and prompting
    /// about it every morning is how a review tool teaches people to dismiss
    /// prompts without reading them.
    static func gaps(
        in spans: [TimeSpan],
        window: DateInterval,
        threshold: TimeInterval,
        now: Date = Date()
    ) -> [IdleGap] {
        let tracked: [(span: TimeSpan, interval: DateInterval)] = spans
            .filter { !$0.isDeleted }
            .compactMap { span in
                LocalRollup.clamp(span, to: window, now: now).map { (span, $0) }
            }
            .sorted { $0.1.start < $1.1.start }

        guard tracked.count > 1 else { return [] }

        var gaps: [IdleGap] = []
        var cursor = tracked[0].interval.end
        var cursorSpanID = tracked[0].span.id

        for entry in tracked.dropFirst() {
            if entry.interval.start.timeIntervalSince(cursor) >= threshold {
                gaps.append(
                    IdleGap(
                        start: cursor,
                        end: entry.interval.start,
                        precedingSpanID: cursorSpanID,
                        followingSpanID: entry.span.id
                    )
                )
            }
            if entry.interval.end > cursor {
                cursor = entry.interval.end
                cursorSpanID = entry.span.id
            }
        }
        return gaps
    }
}

/// Device-local record of idle gaps the user has said were not work.
///
/// This is genuinely local state, not a cache of something server-side: the
/// protocol has no idle-gap entity to write a resolution to. A dismissal
/// therefore does not follow the user to another device, and the settings
/// screen says so rather than implying it synced.
protocol IdleGapDismissing: Sendable {
    func isDismissed(_ gap: IdleGap, workspaceID: UUID) -> Bool
    func dismiss(_ gap: IdleGap, workspaceID: UUID)
    func restore(_ gap: IdleGap, workspaceID: UUID)
}

/// `@unchecked` because `UserDefaults` is documented as thread-safe but is not
/// annotated `Sendable`. Nothing else is stored here.
struct IdleGapDismissals: IdleGapDismissing, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "timely.idle_gap_dismissals"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private func storageKey(_ gap: IdleGap, workspaceID: UUID) -> String {
        "\(workspaceID.canonicalString):\(gap.id)"
    }

    private var stored: Set<String> {
        Set(defaults.stringArray(forKey: key) ?? [])
    }

    func isDismissed(_ gap: IdleGap, workspaceID: UUID) -> Bool {
        stored.contains(storageKey(gap, workspaceID: workspaceID))
    }

    func dismiss(_ gap: IdleGap, workspaceID: UUID) {
        var set = stored
        set.insert(storageKey(gap, workspaceID: workspaceID))
        defaults.set(Array(set), forKey: key)
    }

    func restore(_ gap: IdleGap, workspaceID: UUID) {
        var set = stored
        set.remove(storageKey(gap, workspaceID: workspaceID))
        defaults.set(Array(set), forKey: key)
    }
}

/// In-memory dismissals, for tests and previews.
final class InMemoryIdleGapDismissals: IdleGapDismissing, @unchecked Sendable {
    private let lock = NSLock()
    private var dismissed: Set<String> = []

    init() {}

    private func key(_ gap: IdleGap, _ workspaceID: UUID) -> String {
        "\(workspaceID.canonicalString):\(gap.id)"
    }

    func isDismissed(_ gap: IdleGap, workspaceID: UUID) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return dismissed.contains(key(gap, workspaceID))
    }

    func dismiss(_ gap: IdleGap, workspaceID: UUID) {
        lock.lock(); defer { lock.unlock() }
        dismissed.insert(key(gap, workspaceID))
    }

    func restore(_ gap: IdleGap, workspaceID: UUID) {
        lock.lock(); defer { lock.unlock() }
        dismissed.remove(key(gap, workspaceID))
    }
}
