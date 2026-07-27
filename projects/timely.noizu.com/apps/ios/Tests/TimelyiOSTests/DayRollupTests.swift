import Foundation
import Testing
import TimelyKit
@testable import TimelyiOS

@Suite("Local rollup")
struct DayRollupTests {

    private let window = Fixture.day()
    private var dayStart: Date { window.start }

    @Test("Disjoint billable spans add up")
    func disjointBillable() {
        let spans = [
            Fixture.span(start: dayStart.addingTimeInterval(3600), minutes: 60, billable: true),
            Fixture.span(start: dayStart.addingTimeInterval(10800), minutes: 30, billable: true)
        ]

        let rollup = LocalRollup.compute(spans: spans, window: window, now: window.end)

        #expect(rollup.elapsed == 5400)
        #expect(rollup.billable == 5400)
        #expect(rollup.weightedBillable == 5400)
        #expect(rollup.hasContestedTime == false)
        #expect(rollup.spanCount == 2)
    }

    @Test("Overlapping billable time is counted once, not twice")
    func overlapIsDeWeighted() {
        // Two billable timers over the same hour: 09:00-10:00 and 09:30-10:30.
        let spans = [
            Fixture.span(start: dayStart.addingTimeInterval(32400), minutes: 60, billable: true),
            Fixture.span(start: dayStart.addingTimeInterval(34200), minutes: 60, billable: true)
        ]

        let rollup = LocalRollup.compute(spans: spans, window: window, now: window.end)

        #expect(rollup.billable == 7200)
        // The union is 09:00-10:30 = 90 minutes.
        #expect(rollup.weightedBillable == 5400)
        #expect(rollup.contestedBillable == 1800)
        #expect(rollup.hasContestedTime)
    }

    @Test("Weighted shares split contested time evenly and sum to the union")
    func sharesSplitEvenly() {
        let first = Fixture.span(
            start: dayStart.addingTimeInterval(32400), minutes: 60, billable: true
        )
        let second = Fixture.span(
            start: dayStart.addingTimeInterval(34200), minutes: 60, billable: true
        )

        let shares = LocalRollup.weightedShares(
            spans: [first, second], window: window, now: window.end
        )

        // 30 uncontested + half of the 30 contested = 45 minutes each.
        #expect(shares[first.id] == 2700)
        #expect(shares[second.id] == 2700)
        #expect(shares.values.reduce(0, +) == 5400)
    }

    @Test("Non-billable overlap does not affect the billable figure")
    func nonBillableIgnored() {
        let spans = [
            Fixture.span(start: dayStart.addingTimeInterval(32400), minutes: 60, billable: true),
            Fixture.span(start: dayStart.addingTimeInterval(32400), minutes: 60, billable: false)
        ]

        let rollup = LocalRollup.compute(spans: spans, window: window, now: window.end)

        #expect(rollup.billable == 3600)
        #expect(rollup.nonBillable == 3600)
        #expect(rollup.weightedBillable == 3600)
        #expect(rollup.elapsed == 7200)
    }

    @Test("A span crossing midnight is clamped to the window")
    func clampsToWindow() {
        // Starts two hours before the day and runs four hours.
        let span = Fixture.span(start: dayStart.addingTimeInterval(-7200), minutes: 240)

        let rollup = LocalRollup.compute(spans: [span], window: window, now: window.end)

        #expect(rollup.elapsed == 7200)
    }

    @Test("An open span is measured to now, not to the end of the window")
    func openSpanMeasuredToNow() {
        let span = Fixture.openSpan(start: dayStart.addingTimeInterval(3600))
        let now = dayStart.addingTimeInterval(5400)

        let rollup = LocalRollup.compute(spans: [span], window: window, now: now)

        #expect(rollup.elapsed == 1800)
        #expect(rollup.openSpanCount == 1)
    }

    @Test("Deleted spans contribute nothing")
    func deletedIgnored() {
        var span = Fixture.span(start: dayStart.addingTimeInterval(3600), minutes: 60, billable: true)
        span.sync.deletedAt = Fixture.noon

        let rollup = LocalRollup.compute(spans: [span], window: window, now: window.end)

        #expect(rollup.elapsed == 0)
        #expect(rollup.spanCount == 0)
    }

    @Test("Spans needing review are counted")
    func needsReviewCounted() {
        let flagged = Fixture.span(
            start: dayStart.addingTimeInterval(3600), minutes: 60,
            reviewState: .needsReview,
            reasons: [Fixture.reason(.suspectedDuplicate, related: UUID.v7())]
        )
        let clean = Fixture.span(start: dayStart.addingTimeInterval(10800), minutes: 60)

        let rollup = LocalRollup.compute(spans: [flagged, clean], window: window, now: window.end)

        #expect(rollup.needsReviewCount == 1)
    }

    @Test("A span fully outside the window is dropped")
    func outsideWindowDropped() {
        let span = Fixture.span(start: dayStart.addingTimeInterval(-86_400), minutes: 30)

        let rollup = LocalRollup.compute(spans: [span], window: window, now: window.end)

        #expect(rollup.spanCount == 0)
    }

    @Test("Three-way overlap still counts the wall clock once")
    func threeWayOverlap() {
        let base = dayStart.addingTimeInterval(32400)
        let spans = [
            Fixture.span(start: base, minutes: 60, billable: true),
            Fixture.span(start: base, minutes: 60, billable: true),
            Fixture.span(start: base, minutes: 60, billable: true)
        ]

        let rollup = LocalRollup.compute(spans: spans, window: window, now: window.end)
        let shares = LocalRollup.weightedShares(spans: spans, window: window, now: window.end)

        #expect(rollup.billable == 10800)
        #expect(rollup.weightedBillable == 3600)
        for span in spans {
            #expect(shares[span.id] == 1200)
        }
    }
}
