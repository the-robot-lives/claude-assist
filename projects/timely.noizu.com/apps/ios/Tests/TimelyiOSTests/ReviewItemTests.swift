import Foundation
import Testing
import TimelyKit
@testable import TimelyiOS

@Suite("Review queue derivation")
struct ReviewItemTests {

    private let start = Fixture.noon

    @Test("A duplicate pair collapses to one question, not two")
    func pairDeduplicated() {
        let firstID = UUID(uuidString: "0192f7a1-0000-7000-8000-00000000aaaa")!
        let secondID = UUID(uuidString: "0192f7a1-0000-7000-8000-00000000bbbb")!

        // The server raises the flag on both rows, each citing the other.
        let first = Fixture.span(
            id: firstID, title: "Report", start: start, minutes: 60,
            reviewState: .needsReview,
            reasons: [Fixture.reason(.suspectedDuplicate, related: secondID)]
        )
        let second = Fixture.span(
            id: secondID, title: "Report", start: start, minutes: 60,
            reviewState: .needsReview,
            reasons: [Fixture.reason(.suspectedDuplicate, related: firstID)]
        )

        let items = ReviewItemBuilder.items(spans: [first, second])

        #expect(items.count == 1)
        #expect(items.first?.isPair == true)
        #expect(items.first?.requiresUserJudgement == true)
        // Deterministic orientation, so the card renders the same every time.
        #expect(items.first?.spanID == firstID)
        #expect(items.first?.relatedSpanID == secondID)
    }

    @Test("Orientation does not depend on which row is seen first")
    func orientationIsStable() {
        let firstID = UUID(uuidString: "0192f7a1-0000-7000-8000-00000000aaaa")!
        let secondID = UUID(uuidString: "0192f7a1-0000-7000-8000-00000000bbbb")!

        let a = Fixture.span(
            id: firstID, start: start, minutes: 60,
            reasons: [Fixture.reason(.billingOverlap, related: secondID)]
        )
        let b = Fixture.span(
            id: secondID, start: start.addingTimeInterval(600), minutes: 60,
            reasons: [Fixture.reason(.billingOverlap, related: firstID)]
        )

        let forward = ReviewItemBuilder.items(spans: [a, b])
        let backward = ReviewItemBuilder.items(spans: [b, a])

        #expect(forward.first?.id == backward.first?.id)
        #expect(forward.first?.spanID == backward.first?.spanID)
    }

    @Test("A span flagged against two different rows yields two questions")
    func twoPairsAreTwoItems() {
        let subject = UUID(uuidString: "0192f7a1-0000-7000-8000-00000000aaaa")!
        let firstOther = UUID(uuidString: "0192f7a1-0000-7000-8000-00000000bbbb")!
        let secondOther = UUID(uuidString: "0192f7a1-0000-7000-8000-00000000cccc")!

        let span = Fixture.span(
            id: subject, start: start, minutes: 60,
            reasons: [
                Fixture.reason(.suspectedDuplicate, related: firstOther),
                Fixture.reason(.suspectedDuplicate, related: secondOther)
            ]
        )

        let items = ReviewItemBuilder.items(spans: [span])

        #expect(items.count == 2)
    }

    @Test("Unpaired flags stay per-interval")
    func unpairedFlags() {
        let span = Fixture.span(
            start: start, minutes: 60,
            reasons: [Fixture.reason(.lowConfidence), Fixture.reason(.autoCreatedEntity)]
        )

        let items = ReviewItemBuilder.items(spans: [span])

        #expect(items.count == 2)
        #expect(items.allSatisfy { $0.requiresUserJudgement == false })
    }

    @Test("Resolved flags leave the queue")
    func resolvedFlagsExcluded() {
        let span = Fixture.span(
            start: start, minutes: 60,
            reasons: [
                Fixture.reason(.suspectedDuplicate, related: UUID.v7(), resolution: .dismissed)
            ]
        )

        #expect(ReviewItemBuilder.items(spans: [span]).isEmpty)
    }

    @Test("Questions sort above notices")
    func judgementSortsFirst() {
        let subject = UUID(uuidString: "0192f7a1-0000-7000-8000-00000000aaaa")!
        let other = UUID(uuidString: "0192f7a1-0000-7000-8000-00000000bbbb")!

        let informational = Fixture.span(
            start: start.addingTimeInterval(7200), minutes: 60,
            reasons: [Fixture.reason(.lowConfidence, raisedAt: start.addingTimeInterval(7200))]
        )
        let judgement = Fixture.span(
            id: subject, start: start, minutes: 60,
            reasons: [Fixture.reason(.billingOverlap, related: other, raisedAt: start)]
        )

        let items = ReviewItemBuilder.items(spans: [informational, judgement])

        #expect(items.first?.requiresUserJudgement == true)
        #expect(items.last?.requiresUserJudgement == false)
    }

    @Test("A rejected push becomes a review item")
    func pushOutcomeSurfaces() {
        let span = Fixture.span(start: start, minutes: 60)
        let outcome = PendingOutcome(
            mutationID: UUID.v7(),
            workspaceID: Fixture.workspaceID,
            entityKind: .timeSpan,
            entityID: span.id,
            status: .rejected,
            reason: .lockedDay,
            message: "The day is locked.",
            recordedAt: start
        )

        let items = ReviewItemBuilder.items(spans: [span], outcomes: [outcome])

        #expect(items.count == 1)
        #expect(items.first?.mutationID == outcome.mutationID)
        if case .pushOutcome(let status, let reason) = items.first?.kind {
            #expect(status == .rejected)
            #expect(reason == .lockedDay)
        } else {
            Issue.record("Expected a push outcome item")
        }
    }

    @Test("Acknowledged outcomes stay out of the queue")
    func acknowledgedOutcomesHidden() {
        let span = Fixture.span(start: start, minutes: 60)
        let outcome = PendingOutcome(
            mutationID: UUID.v7(),
            workspaceID: Fixture.workspaceID,
            entityKind: .timeSpan,
            entityID: span.id,
            status: .conflict,
            reason: .staleWrite,
            message: nil,
            recordedAt: start,
            acknowledged: true
        )

        #expect(ReviewItemBuilder.items(spans: [span], outcomes: [outcome]).isEmpty)
    }

    @Test("Non-span outcomes are not span review items")
    func nonSpanOutcomesExcluded() {
        let outcome = PendingOutcome(
            mutationID: UUID.v7(),
            workspaceID: Fixture.workspaceID,
            entityKind: .userSettings,
            entityID: UUID.v7(),
            status: .rejected,
            reason: .permissionDenied,
            message: nil,
            recordedAt: start
        )

        #expect(ReviewItemBuilder.items(spans: [], outcomes: [outcome]).isEmpty)
    }

    @Test("Every item asks a question in words")
    func everyItemHasAPrompt() {
        let other = UUID.v7()
        let codes: [ReviewReasonCode] = [
            .suspectedDuplicate, .billingOverlap, .unresolvedIdleGap, .lowConfidence,
            .unresolvedReference, .autoCreatedEntity, .privacyCensored,
            .reopenedAfterApproval, .unknown
        ]

        for code in codes {
            let span = Fixture.span(
                start: start, minutes: 60,
                reasons: [Fixture.reason(code, related: other)]
            )
            let item = ReviewItemBuilder.items(spans: [span]).first
            #expect(item != nil)
            #expect(item?.prompt.isEmpty == false)
            #expect(item?.symbolName.isEmpty == false)
        }
    }
}
