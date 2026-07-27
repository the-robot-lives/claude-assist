import Foundation
import Testing
import TimelyKit
@testable import TimelyiOS

@Suite("Confidence labelling")
struct ConfidenceStateTests {

    private let start = Fixture.noon

    @Test("Strong analysis reads as verified")
    func verified() {
        let span = Fixture.span(start: start, minutes: 60)
        let evidence = SpanEvidence(
            screenshots: [Fixture.screenshot(spanID: span.id)],
            analyses: [Fixture.analysis(confidence: 0.91)]
        )

        #expect(ConfidenceState.derive(span: span, evidence: evidence) == .verified)
    }

    @Test("Weak analysis reads as inferred")
    func inferred() {
        let span = Fixture.span(start: start, minutes: 60)
        let evidence = SpanEvidence(analyses: [Fixture.analysis(confidence: 0.4)])

        #expect(ConfidenceState.derive(span: span, evidence: evidence) == .inferred)
    }

    @Test("A hand-entered interval with no evidence reads as manual")
    func manual() {
        let span = Fixture.span(start: start, minutes: 60, source: .manual)

        #expect(ConfidenceState.derive(span: span) == .manual)
    }

    @Test("A timer interval with no evidence reads as inferred, not manual")
    func timerWithoutEvidence() {
        let span = Fixture.span(start: start, minutes: 60, source: .timer)

        #expect(ConfidenceState.derive(span: span) == .inferred)
    }

    @Test("Privacy-sensitive evidence outranks a confident analysis")
    func privateOutranksVerified() {
        let span = Fixture.span(start: start, minutes: 60)
        let evidence = SpanEvidence(
            analyses: [
                Fixture.analysis(confidence: 0.99, privacySensitive: true, category: .financial)
            ]
        )

        #expect(ConfidenceState.derive(span: span, evidence: evidence) == .private)
    }

    @Test("A censorship row alone makes an interval private")
    func censoredIsPrivate() {
        let span = Fixture.span(start: start, minutes: 60)
        let censored = CensoredScreenshot(
            sync: .local(id: UUID.v7(), workspaceID: Fixture.workspaceID,
                         deviceID: Fixture.deviceID, at: start),
            screenshotID: UUID.v7(),
            capturedAt: start,
            censoredAt: start,
            category: .personalChat,
            confidence: 0.8
        )
        let evidence = SpanEvidence(censored: [censored])

        #expect(ConfidenceState.derive(span: span, evidence: evidence) == .private)
    }

    @Test("Approval outranks privacy and evidence")
    func approvedOutranksPrivate() {
        let span = Fixture.span(start: start, minutes: 60, reviewState: .approved)
        let evidence = SpanEvidence(analyses: [Fixture.analysis(confidence: 0.99, privacySensitive: true)])

        #expect(ConfidenceState.derive(span: span, evidence: evidence) == .approved)
    }

    @Test("A locked interval reads as approved")
    func lockedIsApproved() {
        let span = Fixture.span(start: start, minutes: 60, locked: start)

        #expect(ConfidenceState.derive(span: span) == .approved)
    }

    @Test("An unanswered flag outranks everything, including approval")
    func disputedWins() {
        let span = Fixture.span(
            start: start, minutes: 60,
            reviewState: .approved,
            reasons: [Fixture.reason(.suspectedDuplicate, related: UUID.v7())]
        )

        #expect(ConfidenceState.derive(span: span) == .disputed)
    }

    @Test("A resolved flag no longer disputes the interval")
    func resolvedFlagClears() {
        let span = Fixture.span(
            start: start, minutes: 60,
            source: .manual,
            reasons: [
                Fixture.reason(.suspectedDuplicate, related: UUID.v7(), resolution: .dismissed)
            ]
        )

        #expect(ConfidenceState.derive(span: span) == .manual)
    }

    @Test("The threshold is respected", arguments: [
        (0.72, ConfidenceState.verified),
        (0.71, ConfidenceState.inferred)
    ])
    func thresholdBoundary(confidence: Double, expected: ConfidenceState) {
        let span = Fixture.span(start: start, minutes: 60)
        let evidence = SpanEvidence(analyses: [Fixture.analysis(confidence: confidence)])

        #expect(
            ConfidenceState.derive(span: span, evidence: evidence, confidenceThreshold: 0.72)
                == expected
        )
    }

    @Test("Every state names itself with a symbol as well as a colour")
    func everyStateHasASymbol() {
        for state in ConfidenceState.allCases {
            #expect(!state.label.isEmpty)
            #expect(!state.symbolName.isEmpty)
            #expect(!state.explanation.isEmpty)
        }
    }
}
