import Foundation
import Testing
import TimelyKit
@testable import TimelyiOS

@Suite("Idle gap detection")
struct IdleGapTests {

    private let window = Fixture.day()
    private var dayStart: Date { window.start }

    @Test("A gap longer than the threshold is reported")
    func interiorGap() {
        let spans = [
            Fixture.span(start: dayStart.addingTimeInterval(3600), minutes: 60),
            Fixture.span(start: dayStart.addingTimeInterval(10800), minutes: 60)
        ]

        let gaps = IdleGapDetector.gaps(
            in: spans, window: window, threshold: 300, now: window.end
        )

        #expect(gaps.count == 1)
        #expect(gaps.first?.duration == 3600)
        #expect(gaps.first?.precedingSpanID == spans[0].id)
        #expect(gaps.first?.followingSpanID == spans[1].id)
    }

    @Test("A gap shorter than the threshold is not a prompt")
    func shortGapIgnored() {
        let spans = [
            Fixture.span(start: dayStart.addingTimeInterval(3600), minutes: 60),
            Fixture.span(start: dayStart.addingTimeInterval(7380), minutes: 60)
        ]

        let gaps = IdleGapDetector.gaps(
            in: spans, window: window, threshold: 300, now: window.end
        )

        #expect(gaps.isEmpty)
    }

    @Test("Time before the first interval is not an idle gap")
    func noLeadingGap() {
        let spans = [Fixture.span(start: dayStart.addingTimeInterval(32400), minutes: 60)]

        let gaps = IdleGapDetector.gaps(
            in: spans, window: window, threshold: 300, now: window.end
        )

        #expect(gaps.isEmpty)
    }

    @Test("Time after the last interval is not an idle gap")
    func noTrailingGap() {
        let spans = [
            Fixture.span(start: dayStart.addingTimeInterval(3600), minutes: 60),
            Fixture.span(start: dayStart.addingTimeInterval(7200), minutes: 60)
        ]

        let gaps = IdleGapDetector.gaps(
            in: spans, window: window, threshold: 300, now: window.end
        )

        #expect(gaps.isEmpty)
    }

    @Test("Overlapping intervals leave no gap between them")
    func overlapLeavesNoGap() {
        let spans = [
            Fixture.span(start: dayStart.addingTimeInterval(3600), minutes: 120),
            Fixture.span(start: dayStart.addingTimeInterval(5400), minutes: 120)
        ]

        let gaps = IdleGapDetector.gaps(
            in: spans, window: window, threshold: 300, now: window.end
        )

        #expect(gaps.isEmpty)
    }

    @Test("A long interval covering a shorter one does not create a false gap")
    func containedSpanDoesNotSplitCoverage() {
        let spans = [
            Fixture.span(start: dayStart.addingTimeInterval(3600), minutes: 240),
            Fixture.span(start: dayStart.addingTimeInterval(7200), minutes: 30),
            Fixture.span(start: dayStart.addingTimeInterval(21600), minutes: 60)
        ]

        let gaps = IdleGapDetector.gaps(
            in: spans, window: window, threshold: 300, now: window.end
        )

        // Only the real gap, between the end of the 4-hour span and 06:00.
        #expect(gaps.count == 1)
        #expect(gaps.first?.start == dayStart.addingTimeInterval(18000))
    }

    @Test("An open interval extends coverage to now")
    func openSpanExtendsCoverage() {
        let spans = [
            Fixture.openSpan(start: dayStart.addingTimeInterval(3600)),
            Fixture.span(start: dayStart.addingTimeInterval(10800), minutes: 60)
        ]

        let gaps = IdleGapDetector.gaps(
            in: spans, window: window, threshold: 300, now: dayStart.addingTimeInterval(10800)
        )

        #expect(gaps.isEmpty)
    }

    @Test("Deleted intervals do not open gaps")
    func deletedSpansIgnored() {
        var deleted = Fixture.span(start: dayStart.addingTimeInterval(7200), minutes: 60)
        deleted.sync.deletedAt = Fixture.noon

        let spans = [
            Fixture.span(start: dayStart.addingTimeInterval(3600), minutes: 60),
            deleted,
            Fixture.span(start: dayStart.addingTimeInterval(14400), minutes: 60)
        ]

        let gaps = IdleGapDetector.gaps(
            in: spans, window: window, threshold: 300, now: window.end
        )

        #expect(gaps.count == 1)
        #expect(gaps.first?.duration == 7200)
    }

    @Test("A gap id is stable across recomputation, so a dismissal sticks")
    func gapIDIsStable() {
        let spans = [
            Fixture.span(start: dayStart.addingTimeInterval(3600), minutes: 60),
            Fixture.span(start: dayStart.addingTimeInterval(10800), minutes: 60)
        ]

        let first = IdleGapDetector.gaps(in: spans, window: window, threshold: 300, now: window.end)
        let second = IdleGapDetector.gaps(in: spans, window: window, threshold: 300, now: window.end)

        #expect(first.first?.id == second.first?.id)
    }

    @Test("Dismissals are per workspace")
    func dismissalsAreScoped() {
        let store = InMemoryIdleGapDismissals()
        let gap = IdleGap(
            start: dayStart, end: dayStart.addingTimeInterval(600),
            precedingSpanID: nil, followingSpanID: nil
        )
        let other = UUID.v7()

        store.dismiss(gap, workspaceID: Fixture.workspaceID)

        #expect(store.isDismissed(gap, workspaceID: Fixture.workspaceID))
        #expect(store.isDismissed(gap, workspaceID: other) == false)

        store.restore(gap, workspaceID: Fixture.workspaceID)
        #expect(store.isDismissed(gap, workspaceID: Fixture.workspaceID) == false)
    }
}
