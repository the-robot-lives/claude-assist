import Foundation
@testable import TimelyKit

/// Fixed ids so a failure message names a recognizable row rather than a fresh
/// random UUID nobody can correlate.
enum Fixed {
    static let workspace = UUID(uuidString: "0192f7a1-2b44-7000-8a10-9d3e4f5a6b7c")!
    static let deviceA = UUID(uuidString: "019318a0-7f3c-7c21-9b4e-2f6a1c3d5e70")!
    static let deviceB = UUID(uuidString: "019318a0-7f3c-7c21-9b4e-2f6a1c3d5e71")!
    static let user = UUID(uuidString: "019318a0-0000-7000-8000-000000000001")!

    /// `deviceB` sorts above `deviceA`, which the LWW tie-break depends on.
    static var deviceBWinsTies: Bool {
        deviceB.canonicalString > deviceA.canonicalString
    }

    static func date(_ offsetSeconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: 1_800_000_000 + offsetSeconds)
    }
}

extension TimeSpan {
    /// A span with a controllable envelope, for LWW and store tests.
    static func test(
        id: UUID = UUID(),
        title: String = "Test span",
        clientName: String = "Acme",
        projectName: String = "Redesign",
        start: Date = Fixed.date(0),
        end: Date? = Fixed.date(3600),
        serverRevision: Int64 = 0,
        createdAt: Date = Fixed.date(0),
        updatedAt: Date = Fixed.date(0),
        deletedAt: Date? = nil,
        deviceID: UUID? = Fixed.deviceA,
        isBillable: Bool = true,
        workspaceID: UUID = Fixed.workspace
    ) -> TimeSpan {
        TimeSpan(
            sync: SyncEnvelope(
                id: id,
                workspaceID: workspaceID,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverRevision: serverRevision,
                deletedAt: deletedAt,
                originDeviceID: deviceID
            ),
            title: title,
            clientID: Canon.clientID(workspaceID: workspaceID, name: clientName),
            projectID: Canon.projectID(
                workspaceID: workspaceID, clientName: clientName, name: projectName
            ),
            clientName: clientName,
            projectName: projectName,
            start: start,
            end: end,
            source: .timer,
            isBillable: isBillable
        )
    }
}

extension Screenshot {
    static func test(
        id: UUID = UUID(),
        spanID: UUID? = nil,
        capturedAt: Date = Fixed.date(60),
        uploadState: ScreenshotUploadState = .localOnly,
        workspaceID: UUID = Fixed.workspace
    ) -> Screenshot {
        Screenshot(
            sync: SyncEnvelope(
                id: id,
                workspaceID: workspaceID,
                createdAt: capturedAt,
                updatedAt: capturedAt,
                originDeviceID: Fixed.deviceA
            ),
            spanID: spanID,
            capturedAt: capturedAt,
            fileName: "shot.png",
            activeAppName: "Xcode",
            uploadState: uploadState
        )
    }
}

extension VisionAnalysis {
    static func test(
        id: UUID = UUID(),
        screenshotID: UUID,
        privacySensitive: Bool = false,
        privacyCategory: PrivacyCategory = .none,
        workspaceID: UUID = Fixed.workspace
    ) -> VisionAnalysis {
        VisionAnalysis(
            sync: SyncEnvelope(
                id: id,
                workspaceID: workspaceID,
                createdAt: Fixed.date(90),
                updatedAt: Fixed.date(90),
                originDeviceID: Fixed.deviceA
            ),
            screenshotID: screenshotID,
            analyzedAt: Fixed.date(90),
            model: "test-vision",
            statusUpdate: "Editing the timeline canvas",
            confidence: 0.9,
            evidence: "Xcode, TimelineView.swift",
            privacySensitive: privacySensitive,
            privacyCategory: privacyCategory
        )
    }
}

extension AuthTokens {
    static func fresh(expiresIn: TimeInterval = 3600) -> AuthTokens {
        AuthTokens(
            accessToken: "fresh-access",
            refreshToken: "refresh-1",
            expiresAt: Date().addingTimeInterval(expiresIn),
            userID: Fixed.user,
            workspaceID: Fixed.workspace
        )
    }

    /// A token that expired an hour ago. The refresh token is still good.
    static func expired() -> AuthTokens {
        AuthTokens(
            accessToken: "stale-access",
            refreshToken: "refresh-1",
            expiresAt: Date().addingTimeInterval(-3600),
            userID: Fixed.user,
            workspaceID: Fixed.workspace
        )
    }
}

// MARK: - Response builders

enum Wire {

    static func emptyChangeSet() -> String {
        """
        "clients":[],"projects":[],"tickets":[],"time_spans":[],"screenshots":[],
        "vision_analyses":[],"censored_screenshots":[],"devices":[],"settings":[]
        """
    }

    static func changesResponse(
        timeSpans: [String] = [],
        nextCursor: Int64,
        hasMore: Bool = false,
        tombstoneHorizon: Int64 = 0
    ) -> String {
        """
        {
          "changes": {
            "clients":[],"projects":[],"tickets":[],
            "time_spans":[\(timeSpans.joined(separator: ","))],
            "screenshots":[],"vision_analyses":[],"censored_screenshots":[],
            "devices":[],"settings":[]
          },
          "next_cursor": \(nextCursor),
          "has_more": \(hasMore),
          "tombstone_horizon_revision": \(tombstoneHorizon),
          "server_time": "2026-07-27T12:00:00Z"
        }
        """
    }

    static func mutationResponse(
        results: [String],
        nextCursor: Int64 = 0
    ) -> String {
        """
        {
          "results": [\(results.joined(separator: ","))],
          "next_cursor": \(nextCursor),
          "server_time": "2026-07-27T12:00:00Z"
        }
        """
    }

    static func result(
        mutationID: UUID,
        status: String,
        reason: String? = nil,
        entity: String? = nil,
        sideEffects: [String] = [],
        replayed: Bool = false,
        staleBase: Bool = false
    ) -> String {
        var parts = [
            "\"mutation_id\":\"\(mutationID.canonicalString)\"",
            "\"status\":\"\(status)\"",
            "\"replayed\":\(replayed)",
            "\"stale_base\":\(staleBase)",
            "\"unresolved_refs\":[]",
            "\"side_effects\":[\(sideEffects.joined(separator: ","))]"
        ]
        if let reason { parts.append("\"reason\":\"\(reason)\"") }
        if let entity { parts.append("\"entity\":\(entity)") }
        return "{" + parts.joined(separator: ",") + "}"
    }

    /// A span rendered as the server would send it back.
    static func span(_ span: TimeSpan, serverRevision: Int64) -> String {
        var copy = span
        copy.sync.serverRevision = serverRevision
        // The server-authored form carries the read-only fields the client omits.
        let encoded = (try? TimelyJSON.encodeToString(copy)) ?? "{}"
        return encoded.replacingOccurrences(
            of: "\"server_revision\":\(serverRevision)",
            with: "\"server_revision\":\(serverRevision)"
        )
    }
}
