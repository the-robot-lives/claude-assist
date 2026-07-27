import Foundation
import TimelyKit
@testable import TimelyiOS

/// Fixtures for the app's own logic.
///
/// Deliberately thin. TimelyKit's models, canon, store, sync and auth are
/// covered by that package's 109 tests; nothing here re-tests them.
enum Fixture {

    static let workspaceID = UUID(uuidString: "0192f7a1-0000-7000-8000-00000000c0de")!
    static let deviceID = UUID(uuidString: "0192f7a1-0000-7000-8000-000000000001")!
    static let userID = UUID(uuidString: "0192f7a1-0000-7000-8000-000000000002")!

    static let context = WorkspaceContext(
        workspaceID: workspaceID, deviceID: deviceID, userID: userID
    )

    /// A fixed clock. Tests that involve "now" must not depend on when they run.
    ///
    /// Deliberately in the **past** relative to any plausible wall clock. A
    /// fixture dated in the future is a trap: a first write stamped ahead of
    /// `Date()` makes every later write that falls back on the real clock lose
    /// the LWW comparison and vanish, leaving a green suite that measures
    /// nothing.
    static let noon = Date(timeIntervalSince1970: 1_750_000_000)

    /// A monotonically advancing timestamp, one minute per tick.
    ///
    /// Use this for any sequence of writes to the **same row**. Two writes
    /// carrying an identical `updated_at` from the same device lose the tie-break
    /// to each other, so the second is dropped from local state while still
    /// being queued — a failure that hides behind a passing queue-depth
    /// assertion. Ticking makes the ordering explicit instead of incidental.
    static func tick(_ step: Int) -> Date {
        noon.addingTimeInterval(Double(step) * 60)
    }

    static func day(containing date: Date = noon) -> DateInterval {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        return TimelyFormat.dayInterval(containing: date, calendar: utc)
    }

    static func span(
        id: UUID = UUID.v7(),
        title: String = "Work",
        start: Date,
        minutes: Double,
        billable: Bool = false,
        client: String = "",
        project: String = "",
        source: SpanSource = .timer,
        reviewState: ReviewState = .unreviewed,
        reasons: [ReviewReason] = [],
        locked: Date? = nil,
        serverRevision: Int64 = 1
    ) -> TimeSpan {
        TimeSpan(
            sync: SyncEnvelope(
                id: id,
                workspaceID: workspaceID,
                createdAt: start,
                updatedAt: start,
                serverRevision: serverRevision,
                originDeviceID: deviceID
            ),
            title: title,
            clientName: client,
            projectName: project,
            start: start,
            end: start.addingTimeInterval(minutes * 60),
            source: source,
            isBillable: billable,
            reviewState: reviewState,
            reviewReasons: reasons,
            lockedAt: locked
        )
    }

    static func openSpan(
        id: UUID = UUID.v7(),
        title: String = "Running",
        start: Date,
        billable: Bool = false
    ) -> TimeSpan {
        var span = self.span(id: id, title: title, start: start, minutes: 1, billable: billable)
        span.end = nil
        return span
    }

    static func reason(
        _ code: ReviewReasonCode,
        related: UUID? = nil,
        raisedAt: Date = noon,
        resolution: ReviewResolution = .pending
    ) -> ReviewReason {
        ReviewReason(
            code: code,
            detail: nil,
            relatedID: related,
            raisedAt: raisedAt,
            raisedBy: .server,
            resolution: resolution
        )
    }

    static func analysis(
        screenshotID: UUID = UUID.v7(),
        confidence: Double,
        privacySensitive: Bool = false,
        category: PrivacyCategory = .none
    ) -> VisionAnalysis {
        VisionAnalysis(
            sync: .local(id: UUID.v7(), workspaceID: workspaceID, deviceID: deviceID, at: noon),
            screenshotID: screenshotID,
            analyzedAt: noon,
            model: "test",
            statusUpdate: "Editing the report",
            confidence: confidence,
            evidence: "editor visible",
            privacySensitive: privacySensitive,
            privacyCategory: category
        )
    }

    static func screenshot(spanID: UUID, at: Date = noon) -> Screenshot {
        Screenshot(
            sync: .local(id: UUID.v7(), workspaceID: workspaceID, deviceID: deviceID, at: at),
            spanID: spanID,
            capturedAt: at,
            fileName: "shot.png",
            activeAppName: "Xcode"
        )
    }
}
