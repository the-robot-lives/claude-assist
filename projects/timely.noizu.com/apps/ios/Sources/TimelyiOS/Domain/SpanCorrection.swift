import Foundation
import TimelyKit

/// The workspace, device and user this app is acting as.
struct WorkspaceContext: Sendable, Hashable {
    var workspaceID: UUID
    var deviceID: UUID
    var userID: UUID?
}

/// A correction, expressed as the mutations that carry it out.
///
/// Split and merge are not distinct operations in the protocol (§7.3) — they
/// are ordinary creates, updates and deletes submitted in one `atomic: true`
/// batch, with lineage in `derived_from_span_ids`. Modelling a correction as a
/// *plan* keeps that shape in one testable value instead of spread across a
/// view model, and means a companion that goes offline mid-edit lands the whole
/// correction or none of it.
struct SpanCorrectionPlan: Sendable, Hashable {
    var creates: [TimeSpan] = []
    var updates: [TimeSpan] = []
    var deletes: [TimeSpan] = []

    /// Non-nil marks every mutation in this plan as one atomic group.
    var batchGroup: String?

    var isAtomic: Bool { batchGroup != nil }

    var isEmpty: Bool {
        creates.isEmpty && updates.isEmpty && deletes.isEmpty
    }

    var mutationCount: Int {
        creates.count + updates.count + deletes.count
    }
}

enum SpanCorrectionError: Error, Equatable, CustomStringConvertible {
    case spanIsLocked
    case splitPointOutsideSpan
    case needsTwoSpansToMerge
    case primaryNotInSelection
    case emptyTitle
    case endBeforeStart
    case reasonNotFound

    var description: String {
        switch self {
        case .spanIsLocked:
            "This interval is locked and cannot be changed."
        case .splitPointOutsideSpan:
            "Pick a time inside the interval to split it."
        case .needsTwoSpansToMerge:
            "Select at least two intervals to merge."
        case .primaryNotInSelection:
            "The interval to keep must be one of the selected intervals."
        case .emptyTitle:
            "Give the interval a title."
        case .endBeforeStart:
            "The end time must be after the start time."
        case .reasonNotFound:
            "That flag is no longer on this interval."
        }
    }
}

enum SpanCorrection {

    // MARK: - Plain updates

    /// Retitle, reassign, re-bill, or edit notes. §7.3: "a plain `update`. No
    /// atomicity needed."
    static func update(
        _ span: TimeSpan
    ) -> Result<SpanCorrectionPlan, SpanCorrectionError> {
        guard !span.isLocked else { return .failure(.spanIsLocked) }
        if let end = span.end, end < span.start { return .failure(.endBeforeStart) }
        return .success(SpanCorrectionPlan(updates: [span]))
    }

    /// Tombstone one span. Never a hard delete — the protocol's fourth
    /// commitment is that nothing is destroyed.
    static func delete(
        _ span: TimeSpan
    ) -> Result<SpanCorrectionPlan, SpanCorrectionError> {
        guard !span.isLocked else { return .failure(.spanIsLocked) }
        return .success(SpanCorrectionPlan(deletes: [span]))
    }

    // MARK: - Manual entry

    /// A hand-entered interval.
    ///
    /// `end` may be nil: the companion does not run timers, but a user
    /// correcting the record of a session they are still in the middle of is a
    /// legitimate open span, and the protocol models open spans first-class.
    static func manualEntry(
        title: String,
        start: Date,
        end: Date?,
        clientName: String = "",
        projectName: String = "",
        ticketName: String = "",
        isBillable: Bool = false,
        notes: String = "",
        context: WorkspaceContext,
        now: Date = Date()
    ) -> Result<SpanCorrectionPlan, SpanCorrectionError> {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.emptyTitle) }
        if let end, end <= start { return .failure(.endBeforeStart) }

        let span = TimeSpan(
            sync: .local(
                id: UUID.v7(at: now),
                workspaceID: context.workspaceID,
                deviceID: context.deviceID,
                at: now
            ),
            title: trimmed,
            // Ids are left nil and the names carry the reference: §6 makes a
            // name a resolution input when the id is absent, and the server
            // vivifies through the same UUIDv5 this device would compute. The
            // repository mints the taxonomy rows locally so the picker is
            // correct before the push lands.
            clientName: clientName.trimmingCharacters(in: .whitespaces),
            projectName: projectName.trimmingCharacters(in: .whitespaces),
            ticketName: ticketName.trimmingCharacters(in: .whitespaces),
            start: start,
            end: end,
            source: .manual,
            isBillable: isBillable,
            notes: notes,
            reviewState: .reviewed
        )
        return .success(SpanCorrectionPlan(creates: [span]))
    }

    /// Fill an idle gap with a hand-entered interval.
    static func fillIdleGap(
        _ gap: IdleGap,
        title: String,
        clientName: String = "",
        projectName: String = "",
        ticketName: String = "",
        isBillable: Bool = false,
        context: WorkspaceContext,
        now: Date = Date()
    ) -> Result<SpanCorrectionPlan, SpanCorrectionError> {
        manualEntry(
            title: title,
            start: gap.start,
            end: gap.end,
            clientName: clientName,
            projectName: projectName,
            ticketName: ticketName,
            isBillable: isBillable,
            notes: "",
            context: context,
            now: now
        )
    }

    // MARK: - Split

    /// Split one span in two at `splitPoint`.
    ///
    /// §7.3: N creates each citing the original in `derived_from_span_ids`,
    /// plus one delete of the original, all in one atomic batch.
    static func split(
        _ span: TimeSpan,
        at splitPoint: Date,
        context: WorkspaceContext,
        now: Date = Date()
    ) -> Result<SpanCorrectionPlan, SpanCorrectionError> {
        guard !span.isLocked else { return .failure(.spanIsLocked) }
        guard splitPoint > span.start else { return .failure(.splitPointOutsideSpan) }
        if let end = span.end, splitPoint >= end {
            return .failure(.splitPointOutsideSpan)
        }

        let first = derived(from: [span], template: span, start: span.start, end: splitPoint,
                            context: context, now: now)
        // The tail inherits the original's openness: splitting a running span
        // leaves the second half running.
        let second = derived(from: [span], template: span, start: splitPoint, end: span.end,
                             context: context, now: now)

        return .success(
            SpanCorrectionPlan(
                creates: [first, second],
                deletes: [span],
                batchGroup: UUID.v7(at: now).canonicalString
            )
        )
    }

    // MARK: - Merge

    /// Merge N spans into one.
    ///
    /// §7.3: one create citing all N in `derived_from_span_ids`, plus N
    /// deletes, in one atomic batch.
    ///
    /// `primary` decides the surviving title, taxonomy, billability and notes.
    /// It is a required argument rather than something inferred, because
    /// guessing which of two disagreeing titles the user meant is exactly the
    /// class of decision this app does not make on its own.
    static func merge(
        _ spans: [TimeSpan],
        keeping primary: TimeSpan,
        context: WorkspaceContext,
        now: Date = Date()
    ) -> Result<SpanCorrectionPlan, SpanCorrectionError> {
        guard spans.count >= 2 else { return .failure(.needsTwoSpansToMerge) }
        guard spans.contains(where: { $0.id == primary.id }) else {
            return .failure(.primaryNotInSelection)
        }
        guard !spans.contains(where: \.isLocked) else { return .failure(.spanIsLocked) }

        let start = spans.map(\.start).min() ?? primary.start
        // One open span makes the merged span open: it is still running, and
        // closing it here would assert an end nobody observed.
        let end: Date? = spans.contains(where: \.isOpen)
            ? nil
            : spans.compactMap(\.end).max()

        let merged = derived(
            from: spans, template: primary, start: start, end: end, context: context, now: now
        )

        return .success(
            SpanCorrectionPlan(
                creates: [merged],
                deletes: spans,
                batchGroup: UUID.v7(at: now).canonicalString
            )
        )
    }

    // MARK: - Review resolution

    /// Record the user's answer to a flag.
    ///
    /// A paired flag is raised on both rows, each citing the other, so a
    /// resolution writes to both. These are plain updates — independent flags,
    /// no atomicity needed — and the queue's FIFO ordering guarantees both land.
    static func resolve(
        _ item: ReviewItem,
        as resolution: ReviewResolution,
        spans: [UUID: TimeSpan],
        now: Date = Date()
    ) -> Result<SpanCorrectionPlan, SpanCorrectionError> {
        guard let code = item.code else { return .failure(.reasonNotFound) }

        var updates: [TimeSpan] = []
        for spanID in [item.spanID, item.relatedSpanID].compactMap({ $0 }) {
            guard var span = spans[spanID] else { continue }
            guard !span.isLocked else { return .failure(.spanIsLocked) }

            var changed = false
            span.reviewReasons = span.reviewReasons.map { reason in
                guard reason.isPending, reason.code == code else { return reason }
                // Only the half of the pair that names the counterpart; a span
                // may carry two duplicate flags against different rows.
                if item.isPair, let relatedID = reason.relatedID {
                    let names = [item.spanID, item.relatedSpanID].compactMap { $0 }
                    guard names.contains(relatedID) else { return reason }
                }
                changed = true
                return reason.resolving(as: resolution, at: now)
            }

            guard changed else { continue }
            // Once nothing is pending the span is no longer a question. It is
            // marked reviewed rather than approved: approval is a separate act.
            if span.pendingReviewReasons.isEmpty, span.reviewState == .needsReview {
                span.reviewState = .reviewed
            }
            updates.append(span)
        }

        guard !updates.isEmpty else { return .failure(.reasonNotFound) }
        return .success(SpanCorrectionPlan(updates: updates))
    }

    // MARK: - Helpers

    /// A new span carrying `template`'s attributes over a new interval, citing
    /// its sources as lineage.
    private static func derived(
        from sources: [TimeSpan],
        template: TimeSpan,
        start: Date,
        end: Date?,
        context: WorkspaceContext,
        now: Date
    ) -> TimeSpan {
        TimeSpan(
            sync: .local(
                id: UUID.v7(at: now),
                workspaceID: context.workspaceID,
                deviceID: context.deviceID,
                at: now
            ),
            title: template.title,
            clientID: template.clientID,
            projectID: template.projectID,
            ticketID: template.ticketID,
            clientName: template.clientName,
            projectName: template.projectName,
            ticketName: template.ticketName,
            start: start,
            end: end,
            source: template.source,
            isBillable: template.isBillable,
            notes: template.notes,
            // Flags are deliberately not copied forward. They described the
            // original rows, which this correction deletes; the server re-scans
            // on create and re-raises anything still true. Carrying them over
            // would leave the user answering a question about a row that no
            // longer exists.
            reviewState: .reviewed,
            reviewReasons: [],
            derivedFromSpanIDs: sources.map(\.id).sorted { $0.canonicalString < $1.canonicalString }
        )
    }
}
