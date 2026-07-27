import Foundation

/// The wire client for `timely-api.yaml`.
///
/// Owns exactly one policy beyond serialization: **refresh once on a 401, then
/// replay the original request once.** That is the contract's own instruction
/// for `bearerAuth`, and putting it here means no call site can forget it and
/// no call site can turn it into an unbounded loop.
public actor TimelyAPIClient {

    private let baseURL: URL
    private let transport: any HTTPTransporting
    private let auth: AuthClient

    public init(baseURL: URL, transport: any HTTPTransporting = URLSessionTransport(), auth: AuthClient) {
        self.baseURL = baseURL
        self.transport = transport
        self.auth = auth
    }

    // MARK: - Sync

    /// `GET /api/v1/sync/changes` — one page of rows above the watermark.
    public func pullChanges(
        workspaceID: UUID,
        since: Int64,
        limit: Int = 500,
        entities: [EntityKind]? = nil
    ) async throws -> ChangesResponse {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("api/v1/sync/changes"),
            resolvingAgainstBaseURL: false
        )!
        var items = [
            URLQueryItem(name: "workspace_id", value: workspaceID.canonicalString),
            URLQueryItem(name: "since", value: String(since)),
            URLQueryItem(name: "limit", value: String(min(max(limit, 1), 2000)))
        ]
        if let entities, !entities.isEmpty {
            items.append(URLQueryItem(
                name: "entities",
                value: entities.map(\.rawValue).joined(separator: ",")
            ))
        }
        components.queryItems = items

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        return try await perform(request, as: ChangesResponse.self)
    }

    /// `POST /api/v1/sync/mutations` — push a batch.
    public func pushMutations(_ batch: MutationRequest) async throws -> MutationResponse {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("api/v1/sync/mutations")
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try TimelyJSON.encode(batch)
        return try await perform(request, as: MutationResponse.self)
    }

    // MARK: - Devices

    public func registerDevice(_ registration: DeviceRegistration) async throws -> Device {
        var request = URLRequest(url: baseURL.appendingPathComponent("api/v1/devices"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try TimelyJSON.encode(registration)
        return try await perform(request, as: DeviceEnvelope.self).device
    }

    // MARK: - Screenshot blobs

    /// `POST /api/v1/screenshots/{id}/blob`.
    ///
    /// **There is deliberately no overload of this method that takes only image
    /// bytes.** The `decision` parameter is a ``BlobUploadDecision``, whose
    /// initializer is private to `BlobUpload.swift` — the only way to obtain one
    /// is `PrivacyGate.evaluate(...)` returning `.success`. A caller cannot
    /// spell "upload this image" without having passed the local gate, and the
    /// server independently re-checks its own half.
    public func uploadScreenshotBlob(
        decision: BlobUploadDecision,
        imageData: Data,
        contentType: String = "image/png"
    ) async throws -> BlobUploadResult {
        var request = URLRequest(
            url: baseURL.appendingPathComponent(
                "api/v1/screenshots/\(decision.screenshotID.canonicalString)/blob"
            )
        )
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData

        do {
            return try await perform(request, as: BlobUploadResult.self)
        } catch SyncError.http(403, let body) {
            // The server's half of the gate closed. Surface which one, so the
            // UI can say something true rather than "forbidden".
            throw Self.blobRefusal(from: body, screenshotID: decision.screenshotID)
        }
    }

    /// `GET /api/v1/screenshots/{id}/blob`. Only ever succeeds for a screenshot
    /// whose `upload_state` is `uploaded`; a metadata-only screenshot 404s, and
    /// that is the normal case rather than an error.
    public func downloadScreenshotBlob(screenshotID: UUID) async throws -> Data? {
        var request = URLRequest(
            url: baseURL.appendingPathComponent(
                "api/v1/screenshots/\(screenshotID.canonicalString)/blob"
            )
        )
        request.httpMethod = "GET"

        do {
            return try await performRaw(request)
        } catch SyncError.http(404, _) {
            return nil
        }
    }

    // MARK: - Reports

    public func reportSummary(
        workspaceID: UUID,
        from: Date,
        to: Date,
        groupBy: ReportGroupKey = .client
    ) async throws -> ReportSummary {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("api/v1/reports/summary"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "workspace_id", value: workspaceID.canonicalString),
            URLQueryItem(name: "from", value: TimelyISO8601.string(from: from)),
            URLQueryItem(name: "to", value: TimelyISO8601.string(from: to)),
            URLQueryItem(name: "group_by", value: groupBy.rawValue)
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        return try await perform(request, as: ReportSummary.self)
    }

    // MARK: - Request execution

    private func perform<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let data = try await performRaw(request)
        do {
            return try TimelyJSON.decode(T.self, from: data)
        } catch {
            throw SyncError.decoding(String(describing: error))
        }
    }

    /// Attach auth, send, and on a 401 refresh once and replay once.
    ///
    /// The replay is bounded at exactly one attempt. A server that 401s a
    /// freshly refreshed token is telling us the session is dead, and a loop
    /// would turn that into a battery-draining refresh storm.
    private func performRaw(_ request: URLRequest) async throws -> Data {
        var attempt = request
        // `authorizationHeader()` may itself refresh, and that refresh may
        // discover the session is dead. That must propagate — swallowing it
        // would send an unauthenticated request, earn a second 401, and burn a
        // redundant refresh to rediscover what we already knew.
        if let header = try await auth.authorizationHeader() {
            attempt.setValue(header, forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await transport.send(attempt)

        if response.statusCode == 401 {
            // `sessionExpired` propagates: the user must sign in again. Any
            // other refresh failure is transport-shaped and retryable later.
            let refreshed = try await auth.refresh()

            var replay = request
            replay.setValue("Bearer \(refreshed.accessToken)", forHTTPHeaderField: "Authorization")

            let (replayData, replayResponse) = try await transport.send(replay)
            guard (200..<300).contains(replayResponse.statusCode) else {
                throw SyncError.http(replayResponse.statusCode, replayData)
            }
            return replayData
        }

        guard (200..<300).contains(response.statusCode) else {
            throw SyncError.http(response.statusCode, data)
        }
        return data
    }

    private static func blobRefusal(from body: Data, screenshotID: UUID) -> SyncError {
        guard let error = try? TimelyJSON.decode(BlobForbiddenError.self, from: body) else {
            return SyncError.http(403, body)
        }
        let refusal: BlobUploadRefusal
        if error.gates.screenshotCensored == true {
            refusal = .censored
        } else if error.gates.workspaceScreenshotUploadAllowed == false {
            refusal = .workspacePolicyDisallows
        } else {
            refusal = .deviceNotOptedIn
        }
        return SyncError.blobRefused(screenshotID: screenshotID, refusal: refusal)
    }
}

// MARK: - Error responses

struct BlobForbiddenError: Decodable {
    struct Gates: Decodable {
        let workspaceScreenshotUploadAllowed: Bool?
        let deviceLocalOnlyScreenshots: Bool?
        let screenshotCensored: Bool?

        enum CodingKeys: String, CodingKey {
            case workspaceScreenshotUploadAllowed = "workspace_screenshot_upload_allowed"
            case deviceLocalOnlyScreenshots = "device_local_only_screenshots"
            case screenshotCensored = "screenshot_censored"
        }
    }

    let code: String
    let message: String
    let gates: Gates
}

/// The contract's generic error body.
public struct APIError: Decodable, Sendable, Hashable {
    public let code: String
    public let message: String
    public let details: JSONValue?
}

// MARK: - Sync errors

public enum SyncError: Error, CustomStringConvertible, Sendable {
    case transport(String)
    case http(Int, Data)
    case decoding(String)
    case immutableEntity(kind: EntityKind)
    case blobRefused(screenshotID: UUID, refusal: BlobUploadRefusal)

    /// The client's watermark fell below the server's tombstone horizon. The
    /// only correct response is a full re-bootstrap from revision 0.
    case cursorBelowTombstoneHorizon(cursor: Int64, horizon: Int64)

    public var description: String {
        switch self {
        case .transport(let message):
            return "Network error: \(message)"
        case .http(let status, let data):
            if let error = try? TimelyJSON.decode(APIError.self, from: data) {
                return "HTTP \(status): \(error.code) — \(error.message)"
            }
            return "HTTP \(status)"
        case .decoding(let message):
            return "Could not decode the server's response: \(message)"
        case .immutableEntity(let kind):
            return "\(kind.rawValue) rows are append-only and cannot be updated"
        case .blobRefused(_, let refusal):
            return refusal.explanation
        case .cursorBelowTombstoneHorizon(let cursor, let horizon):
            return "Local watermark \(cursor) is below the server's tombstone horizon "
                 + "\(horizon); a full re-sync is required"
        }
    }

    /// True when retrying the identical request later could succeed. Drives the
    /// queue's keep-or-drop decision.
    public var isRetryable: Bool {
        switch self {
        case .transport:
            return true
        case .http(let status, _):
            return status == 429 || (500..<600).contains(status)
        default:
            return false
        }
    }
}
