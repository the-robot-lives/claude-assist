import Foundation
import TimelyKit

/// Something the app is asking a person to decide.
///
/// The server raises flags and never resolves them; neither does this app.
/// `suspected_duplicate` and `billing_overlap` both mean "two records claim the
/// same hours", and picking a winner automatically either invents or destroys
/// billable time. Every one of these reaches a screen with the choice spelled
/// out — there is no code path anywhere in this target that resolves one
/// without a tap.
struct ReviewItem: Identifiable, Sendable, Hashable {

    enum Kind: Sendable, Hashable {
        /// A `ReviewReason` the server or a device attached to a span.
        case reviewReason(ReviewReasonCode)

        /// A mutation this device pushed that the server would not apply.
        case pushOutcome(MutationStatus, MutationReason?)
    }

    let id: String
    let kind: Kind

    /// The span the user is being asked about.
    let spanID: UUID

    /// The other row of a flagged pair, when the flag names one.
    let relatedSpanID: UUID?

    /// The mutation this came from, for a push outcome.
    let mutationID: UUID?

    let title: String
    let subtitle: String?
    let detail: String?
    let raisedAt: Date
    let raisedBy: ReviewRaisedBy

    /// True when the app must not act without an explicit choice.
    let requiresUserJudgement: Bool

    var code: ReviewReasonCode? {
        if case .reviewReason(let code) = kind { return code }
        return nil
    }

    var isPair: Bool { relatedSpanID != nil }

    /// The headline, written as the question being asked.
    var prompt: String {
        switch kind {
        case .reviewReason(let code):
            switch code {
            case .suspectedDuplicate:
                return "Are these the same work?"
            case .billingOverlap:
                return "Two clients are billed for the same time"
            case .unresolvedIdleGap:
                return "There is unaccounted time here"
            case .lowConfidence:
                return "This interval is a guess"
            case .unresolvedReference:
                return "A client or project could not be matched"
            case .autoCreatedEntity:
                return "A client or project was created automatically"
            case .privacyCensored:
                return "Evidence for this interval was removed"
            case .reopenedAfterApproval:
                return "Approved time was changed"
            case .unknown:
                return "This interval was flagged"
            }
        case .pushOutcome(let status, let reason):
            switch status {
            case .conflict: return "Your change conflicted with the server"
            case .rejected: return "The server rejected your change"
            case .applied: return reason.map { "Applied with \($0.rawValue)" } ?? "Applied"
            }
        }
    }

    var symbolName: String {
        switch kind {
        case .reviewReason(let code):
            switch code {
            case .suspectedDuplicate: return "doc.on.doc"
            case .billingOverlap: return "dollarsign.circle"
            case .unresolvedIdleGap: return "moon.zzz"
            case .lowConfidence: return "questionmark.circle"
            case .unresolvedReference: return "link.badge.plus"
            case .autoCreatedEntity: return "sparkles"
            case .privacyCensored: return "eye.slash"
            case .reopenedAfterApproval: return "lock.open"
            case .unknown: return "flag"
            }
        case .pushOutcome:
            return "arrow.triangle.2.circlepath.circle"
        }
    }
}

enum ReviewItemBuilder {

    /// Build the review queue from local state.
    ///
    /// Paired flags — `suspected_duplicate` and `billing_overlap` — are raised
    /// on **both** rows, each citing the other. Showing both would ask the same
    /// question twice and invite the user to answer it two different ways, so
    /// they collapse to one item per unordered pair. Resolving that one item
    /// still writes a resolution to both rows; see ``SpanCorrection/resolve``.
    static func items(
        spans: [TimeSpan],
        outcomes: [PendingOutcome] = [],
        now: Date = Date()
    ) -> [ReviewItem] {
        let byID = Dictionary(uniqueKeysWithValues: spans.map { ($0.id, $0) })
        var seenPairs = Set<String>()
        var items: [ReviewItem] = []

        for span in spans.sorted(by: { $0.start > $1.start }) {
            for reason in span.pendingReviewReasons {
                if reason.requiresUserJudgement, let relatedID = reason.relatedID {
                    let key = pairKey(span.id, relatedID, code: reason.code)
                    guard seenPairs.insert(key).inserted else { continue }

                    // Deterministic orientation, so the same pair renders the
                    // same way no matter which row was iterated first.
                    let (primary, secondary) = orient(span.id, relatedID)
                    let primarySpan = byID[primary] ?? span

                    items.append(
                        ReviewItem(
                            id: key,
                            kind: .reviewReason(reason.code),
                            spanID: primary,
                            relatedSpanID: secondary,
                            mutationID: nil,
                            title: displayTitle(primarySpan),
                            subtitle: byID[secondary].map(displayTitle),
                            detail: reason.detail,
                            raisedAt: reason.raisedAt,
                            raisedBy: reason.raisedBy,
                            requiresUserJudgement: true
                        )
                    )
                } else {
                    items.append(
                        ReviewItem(
                            id: "\(span.id.canonicalString):\(reason.code.rawValue):"
                                + "\(Int(reason.raisedAt.timeIntervalSince1970))",
                            kind: .reviewReason(reason.code),
                            spanID: span.id,
                            relatedSpanID: reason.relatedID,
                            mutationID: nil,
                            title: displayTitle(span),
                            subtitle: nil,
                            detail: reason.detail,
                            raisedAt: reason.raisedAt,
                            raisedBy: reason.raisedBy,
                            requiresUserJudgement: reason.requiresUserJudgement
                        )
                    )
                }
            }
        }

        for outcome in outcomes where !outcome.acknowledged {
            // Only span outcomes belong in this queue; a rejected settings write
            // is a settings problem and is surfaced there.
            guard outcome.entityKind == .timeSpan else { continue }
            items.append(
                ReviewItem(
                    id: "outcome:\(outcome.mutationID.canonicalString)",
                    kind: .pushOutcome(outcome.status, outcome.reason),
                    spanID: outcome.entityID,
                    relatedSpanID: nil,
                    mutationID: outcome.mutationID,
                    title: byID[outcome.entityID].map(displayTitle) ?? "Interval",
                    subtitle: outcome.reason?.rawValue.replacingOccurrences(of: "_", with: " "),
                    detail: outcome.message,
                    raisedAt: outcome.recordedAt,
                    raisedBy: .server,
                    requiresUserJudgement: outcome.requiresHumanJudgement
                )
            )
        }

        // Questions the user must answer first, then newest.
        return items.sorted { lhs, rhs in
            if lhs.requiresUserJudgement != rhs.requiresUserJudgement {
                return lhs.requiresUserJudgement
            }
            return lhs.raisedAt > rhs.raisedAt
        }
    }

    static func pairKey(_ a: UUID, _ b: UUID, code: ReviewReasonCode) -> String {
        let (first, second) = orient(a, b)
        return "\(code.rawValue):\(first.canonicalString):\(second.canonicalString)"
    }

    private static func orient(_ a: UUID, _ b: UUID) -> (UUID, UUID) {
        a.canonicalString <= b.canonicalString ? (a, b) : (b, a)
    }

    private static func displayTitle(_ span: TimeSpan) -> String {
        span.title.isEmpty ? "Untitled interval" : span.title
    }
}
