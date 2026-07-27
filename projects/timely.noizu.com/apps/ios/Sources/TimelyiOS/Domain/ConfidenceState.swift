import Foundation
import TimelyKit

/// How much a span's time is *believed*, as one visible label.
///
/// UX principle 4 — "confidence is visible" — is the whole reason this type is
/// a first-class domain value rather than an ad-hoc string in a row view. Every
/// surface that shows a span shows one of these, with an SF Symbol as well as a
/// colour, because the style guide forbids relying on colour alone.
enum ConfidenceState: String, CaseIterable, Sendable, Hashable {
    /// The model saw the work and was sure enough to say so.
    case verified

    /// There is evidence, but not strong enough to assert.
    case inferred

    /// A person typed it. No evidence, and none expected.
    case manual

    /// Backed by material that stays on the capture device.
    case `private`

    /// Two records disagree, or the server raised a flag nobody has answered.
    case disputed

    /// Reviewed and signed off; edits are closed or closing.
    case approved

    var label: String {
        switch self {
        case .verified: "Verified"
        case .inferred: "Inferred"
        case .manual: "Manual"
        case .private: "Private"
        case .disputed: "Disputed"
        case .approved: "Approved"
        }
    }

    var symbolName: String {
        switch self {
        case .verified: "checkmark.seal"
        case .inferred: "wand.and.stars"
        case .manual: "hand.point.up.left"
        case .private: "lock"
        case .disputed: "exclamationmark.triangle"
        case .approved: "lock.doc"
        }
    }

    /// One line explaining the label, for the detail screen. Written to be true
    /// rather than reassuring.
    var explanation: String {
        switch self {
        case .verified:
            "A vision analysis of captured evidence supports this interval."
        case .inferred:
            "There is evidence for this interval, but the analysis was not confident."
        case .manual:
            "Entered by hand. There is no captured evidence for this interval."
        case .private:
            "Evidence for this interval was marked private and stays on the capture device."
        case .disputed:
            "Something about this interval needs your decision before it can be billed."
        case .approved:
            "This interval has been reviewed and approved."
        }
    }

    /// Derive the label for one span.
    ///
    /// Precedence is deliberate and top-down: an unanswered question outranks
    /// an approval, an approval outranks a privacy note, and a privacy note
    /// outranks any claim about evidence — because in each pair the first is
    /// the thing the user must not miss.
    static func derive(
        span: TimeSpan,
        evidence: SpanEvidence = .none,
        confidenceThreshold: Double = 0.72
    ) -> ConfidenceState {
        if span.reviewState == .disputed || !span.pendingReviewReasons.isEmpty {
            return .disputed
        }
        if span.isLocked || span.reviewState == .approved || span.reviewState == .locked {
            return .approved
        }
        if evidence.containsPrivateMaterial {
            return .private
        }
        if evidence.peakConfidence >= confidenceThreshold {
            return .verified
        }
        if !evidence.isEmpty {
            return .inferred
        }
        // No evidence at all. A hand-entered span is honestly "manual"; a timer
        // or pomodoro span the user never annotated is a machine's guess about
        // what they were doing, which is "inferred".
        return span.source == .manual ? .manual : .inferred
    }
}
