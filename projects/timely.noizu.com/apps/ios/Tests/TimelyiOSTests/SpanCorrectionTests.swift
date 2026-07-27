import Foundation
import Testing
import TimelyKit
@testable import TimelyiOS

@Suite("Span corrections")
struct SpanCorrectionTests {

    private let start = Fixture.noon
    private var context: WorkspaceContext { Fixture.context }

    // MARK: - Split

    @Test("Split emits two creates plus one delete, in one atomic batch")
    func splitShape() throws {
        let span = Fixture.span(start: start, minutes: 120, billable: true, client: "Acme")
        let cut = start.addingTimeInterval(3600)

        let plan = try SpanCorrection.split(span, at: cut, context: context, now: start).get()

        #expect(plan.creates.count == 2)
        #expect(plan.deletes == [span])
        #expect(plan.updates.isEmpty)
        #expect(plan.isAtomic)
        #expect(plan.mutationCount == 3)
    }

    @Test("Split halves cover the original range exactly")
    func splitBoundaries() throws {
        let span = Fixture.span(start: start, minutes: 120)
        let cut = start.addingTimeInterval(2700)

        let plan = try SpanCorrection.split(span, at: cut, context: context, now: start).get()

        #expect(plan.creates[0].start == span.start)
        #expect(plan.creates[0].end == cut)
        #expect(plan.creates[1].start == cut)
        #expect(plan.creates[1].end == span.end)
    }

    @Test("Both halves cite the original as lineage")
    func splitLineage() throws {
        let span = Fixture.span(start: start, minutes: 120)

        let plan = try SpanCorrection
            .split(span, at: start.addingTimeInterval(3600), context: context, now: start).get()

        for created in plan.creates {
            #expect(created.derivedFromSpanIDs == [span.id])
            #expect(created.id != span.id)
        }
    }

    @Test("Splitting an open interval leaves the second half running")
    func splitOpenSpan() throws {
        let span = Fixture.openSpan(start: start)

        let plan = try SpanCorrection
            .split(span, at: start.addingTimeInterval(1800), context: context, now: start).get()

        #expect(plan.creates[0].end != nil)
        #expect(plan.creates[1].isOpen)
    }

    @Test("Split attributes carry over")
    func splitCarriesAttributes() throws {
        let span = Fixture.span(
            start: start, minutes: 120, billable: true, client: "Acme", project: "Redesign"
        )

        let plan = try SpanCorrection
            .split(span, at: start.addingTimeInterval(3600), context: context, now: start).get()

        for created in plan.creates {
            #expect(created.title == span.title)
            #expect(created.clientName == "Acme")
            #expect(created.projectName == "Redesign")
            #expect(created.isBillable)
        }
    }

    @Test("A split point outside the interval is rejected", arguments: [
        -60.0, 0.0, 7200.0, 9000.0
    ])
    func splitOutsideRejected(offset: Double) {
        let span = Fixture.span(start: start, minutes: 120)
        let result = SpanCorrection.split(
            span, at: start.addingTimeInterval(offset), context: context, now: start
        )

        #expect(throws: SpanCorrectionError.splitPointOutsideSpan) { try result.get() }
    }

    @Test("A locked interval cannot be split")
    func splitLockedRejected() {
        let span = Fixture.span(start: start, minutes: 120, locked: start)
        let result = SpanCorrection.split(
            span, at: start.addingTimeInterval(3600), context: context, now: start
        )

        #expect(throws: SpanCorrectionError.spanIsLocked) { try result.get() }
    }

    // MARK: - Merge

    @Test("Merge emits one create plus N deletes, in one atomic batch")
    func mergeShape() throws {
        let first = Fixture.span(title: "A", start: start, minutes: 60)
        let second = Fixture.span(title: "B", start: start.addingTimeInterval(3600), minutes: 60)

        let plan = try SpanCorrection
            .merge([first, second], keeping: first, context: context, now: start).get()

        #expect(plan.creates.count == 1)
        #expect(plan.deletes.count == 2)
        #expect(plan.isAtomic)
    }

    @Test("The merged interval spans the full range and keeps the primary's details")
    func mergeRangeAndAttributes() throws {
        let first = Fixture.span(
            title: "Kept", start: start, minutes: 60, billable: true, client: "Acme"
        )
        let second = Fixture.span(
            title: "Dropped", start: start.addingTimeInterval(7200), minutes: 30, client: "Other"
        )

        let plan = try SpanCorrection
            .merge([first, second], keeping: first, context: context, now: start).get()
        let merged = try #require(plan.creates.first)

        #expect(merged.start == first.start)
        #expect(merged.end == second.end)
        #expect(merged.title == "Kept")
        #expect(merged.clientName == "Acme")
        #expect(merged.isBillable)
    }

    @Test("The merged interval cites every source")
    func mergeLineage() throws {
        let first = Fixture.span(start: start, minutes: 60)
        let second = Fixture.span(start: start.addingTimeInterval(3600), minutes: 60)
        let third = Fixture.span(start: start.addingTimeInterval(7200), minutes: 60)

        let plan = try SpanCorrection
            .merge([first, second, third], keeping: second, context: context, now: start).get()
        let merged = try #require(plan.creates.first)

        #expect(Set(merged.derivedFromSpanIDs) == Set([first.id, second.id, third.id]))
    }

    @Test("Merging anything still running leaves the result running")
    func mergeWithOpenSpan() throws {
        let closed = Fixture.span(start: start, minutes: 60)
        let open = Fixture.openSpan(start: start.addingTimeInterval(3600))

        let plan = try SpanCorrection
            .merge([closed, open], keeping: closed, context: context, now: start).get()

        #expect(plan.creates.first?.isOpen == true)
    }

    @Test("Merge needs at least two intervals")
    func mergeNeedsTwo() {
        let span = Fixture.span(start: start, minutes: 60)
        let result = SpanCorrection.merge([span], keeping: span, context: context, now: start)

        #expect(throws: SpanCorrectionError.needsTwoSpansToMerge) { try result.get() }
    }

    @Test("The kept interval must be one of the selected")
    func mergePrimaryMustBeSelected() {
        let first = Fixture.span(start: start, minutes: 60)
        let second = Fixture.span(start: start.addingTimeInterval(3600), minutes: 60)
        let stranger = Fixture.span(start: start.addingTimeInterval(7200), minutes: 60)

        let result = SpanCorrection.merge(
            [first, second], keeping: stranger, context: context, now: start
        )

        #expect(throws: SpanCorrectionError.primaryNotInSelection) { try result.get() }
    }

    @Test("A locked interval blocks the merge")
    func mergeLockedRejected() {
        let first = Fixture.span(start: start, minutes: 60)
        let locked = Fixture.span(start: start.addingTimeInterval(3600), minutes: 60, locked: start)

        let result = SpanCorrection.merge(
            [first, locked], keeping: first, context: context, now: start
        )

        #expect(throws: SpanCorrectionError.spanIsLocked) { try result.get() }
    }

    // MARK: - Plain updates

    @Test("Reassign and retitle are plain updates with no batch")
    func updateIsNotAtomic() throws {
        var span = Fixture.span(start: start, minutes: 60)
        span.title = "Renamed"

        let plan = try SpanCorrection.update(span).get()

        #expect(plan.updates == [span])
        #expect(plan.isAtomic == false)
        #expect(plan.creates.isEmpty)
        #expect(plan.deletes.isEmpty)
    }

    @Test("An end before the start is rejected")
    func updateRejectsInvertedRange() {
        var span = Fixture.span(start: start, minutes: 60)
        span.end = start.addingTimeInterval(-60)

        #expect(throws: SpanCorrectionError.endBeforeStart) { try SpanCorrection.update(span).get() }
    }

    @Test("Delete is a tombstone, never a create")
    func deleteIsATombstone() throws {
        let span = Fixture.span(start: start, minutes: 60)

        let plan = try SpanCorrection.delete(span).get()

        #expect(plan.deletes == [span])
        #expect(plan.creates.isEmpty)
        #expect(plan.isAtomic == false)
    }

    // MARK: - Manual entry

    @Test("Manual entry produces one create marked manual")
    func manualEntryShape() throws {
        let plan = try SpanCorrection.manualEntry(
            title: "Client call",
            start: start,
            end: start.addingTimeInterval(1800),
            clientName: "Acme",
            isBillable: true,
            context: context,
            now: start
        ).get()

        let span = try #require(plan.creates.first)
        #expect(span.source == .manual)
        #expect(span.title == "Client call")
        #expect(span.isBillable)
        #expect(plan.isAtomic == false)
    }

    @Test("A blank title is rejected")
    func manualEntryNeedsATitle() {
        let result = SpanCorrection.manualEntry(
            title: "   ", start: start, end: start.addingTimeInterval(600),
            context: context, now: start
        )

        #expect(throws: SpanCorrectionError.emptyTitle) { try result.get() }
    }

    @Test("A zero-length interval is rejected")
    func manualEntryNeedsDuration() {
        let result = SpanCorrection.manualEntry(
            title: "Work", start: start, end: start, context: context, now: start
        )

        #expect(throws: SpanCorrectionError.endBeforeStart) { try result.get() }
    }

    @Test("Filling an idle gap covers exactly the gap")
    func fillIdleGap() throws {
        let gap = IdleGap(
            start: start, end: start.addingTimeInterval(2700),
            precedingSpanID: nil, followingSpanID: nil
        )

        let plan = try SpanCorrection.fillIdleGap(
            gap, title: "Lunch meeting", context: context, now: start
        ).get()
        let span = try #require(plan.creates.first)

        #expect(span.start == gap.start)
        #expect(span.end == gap.end)
    }

    // MARK: - Resolving flags

    @Test("Resolving a pair writes to both rows")
    func resolveWritesBothSides() throws {
        let firstID = UUID(uuidString: "0192f7a1-0000-7000-8000-00000000aaaa")!
        let secondID = UUID(uuidString: "0192f7a1-0000-7000-8000-00000000bbbb")!

        let first = Fixture.span(
            id: firstID, start: start, minutes: 60, reviewState: .needsReview,
            reasons: [Fixture.reason(.suspectedDuplicate, related: secondID)]
        )
        let second = Fixture.span(
            id: secondID, start: start, minutes: 60, reviewState: .needsReview,
            reasons: [Fixture.reason(.suspectedDuplicate, related: firstID)]
        )
        let item = try #require(ReviewItemBuilder.items(spans: [first, second]).first)

        let plan = try SpanCorrection.resolve(
            item, as: .dismissed,
            spans: [firstID: first, secondID: second],
            now: start
        ).get()

        #expect(plan.updates.count == 2)
        #expect(plan.isAtomic == false)
        for span in plan.updates {
            #expect(span.pendingReviewReasons.isEmpty)
            #expect(span.reviewReasons.allSatisfy { $0.resolution == .dismissed })
            // Cleared, not approved: approval is a separate act.
            #expect(span.reviewState == .reviewed)
        }
    }

    @Test("Only the flag naming the counterpart is resolved")
    func resolveTouchesOnlyTheNamedFlag() throws {
        let subject = UUID(uuidString: "0192f7a1-0000-7000-8000-00000000aaaa")!
        let target = UUID(uuidString: "0192f7a1-0000-7000-8000-00000000bbbb")!
        let bystander = UUID(uuidString: "0192f7a1-0000-7000-8000-00000000cccc")!

        let span = Fixture.span(
            id: subject, start: start, minutes: 60, reviewState: .needsReview,
            reasons: [
                Fixture.reason(.suspectedDuplicate, related: target),
                Fixture.reason(.suspectedDuplicate, related: bystander)
            ]
        )
        let other = Fixture.span(
            id: target, start: start, minutes: 60,
            reasons: [Fixture.reason(.suspectedDuplicate, related: subject)]
        )

        let item = try #require(
            ReviewItemBuilder.items(spans: [span, other])
                .first { $0.relatedSpanID == target || $0.spanID == target }
        )

        let plan = try SpanCorrection.resolve(
            item, as: .merged, spans: [subject: span, target: other], now: start
        ).get()

        let updatedSubject = try #require(plan.updates.first { $0.id == subject })
        #expect(updatedSubject.pendingReviewReasons.count == 1)
        #expect(updatedSubject.pendingReviewReasons.first?.relatedID == bystander)
        // Still a question outstanding, so the state must not read as reviewed.
        #expect(updatedSubject.reviewState == .needsReview)
    }

    @Test("Resolving a flag that is already answered fails rather than writing")
    func resolveMissingFlag() throws {
        let span = Fixture.span(
            start: start, minutes: 60,
            reasons: [Fixture.reason(.lowConfidence)]
        )
        // The item is built while the flag is pending; by the time it is acted
        // on, another device has already answered it.
        let item = try #require(ReviewItemBuilder.items(spans: [span]).first)

        var resolved = span
        resolved.reviewReasons = [Fixture.reason(.lowConfidence, resolution: .accepted)]

        let result = SpanCorrection.resolve(
            item, as: .accepted, spans: [resolved.id: resolved], now: start
        )

        #expect(throws: SpanCorrectionError.reasonNotFound) { try result.get() }
    }

    @Test("A locked interval cannot have its flags resolved")
    func resolveLockedRejected() throws {
        let span = Fixture.span(
            start: start, minutes: 60,
            reasons: [Fixture.reason(.lowConfidence)],
            locked: start
        )
        let item = try #require(ReviewItemBuilder.items(spans: [span]).first)

        let result = SpanCorrection.resolve(
            item, as: .accepted, spans: [span.id: span], now: start
        )

        #expect(throws: SpanCorrectionError.spanIsLocked) { try result.get() }
    }

    @Test("Corrections never copy flags onto the replacement rows")
    func correctionsDoNotCarryFlags() throws {
        let span = Fixture.span(
            start: start, minutes: 120, reviewState: .needsReview,
            reasons: [Fixture.reason(.suspectedDuplicate, related: UUID.v7())]
        )

        let plan = try SpanCorrection
            .split(span, at: start.addingTimeInterval(3600), context: context, now: start).get()

        for created in plan.creates {
            #expect(created.reviewReasons.isEmpty)
            #expect(created.needsReview == false)
        }
    }
}
