import Foundation

enum APIError: LocalizedError, Equatable {
    case invalidBaseURL
    case invalidResponse
    case httpStatus(Int, String)
    case missingData(String)
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Invalid backend URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpStatus(let status, let message):
            return "\(status): \(message)"
        case .missingData(let context):
            return "\(context) returned no data"
        case .notAuthenticated:
            return "Sign in required"
        }
    }
}

protocol HTTPSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPSession {}

struct APIClient {
    var baseURL: URL
    var session: HTTPSession = URLSession.shared

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }()

    init(baseURL: URL, session: HTTPSession = URLSession.shared) {
        self.baseURL = baseURL
        self.session = session
    }

    static func bundled() -> APIClient {
        let raw = Bundle.main.string(for: "RobotDraftsAPIBaseURL") ?? "http://localhost:4000"
        return APIClient(baseURL: URL(string: raw) ?? URL(string: "http://localhost:4000")!)
    }

    func url(path: String) -> URL {
        let trimmedBase = baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let trimmedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(trimmedBase)/\(trimmedPath)")!
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        try await request(
            "/api/v1/auth/login",
            method: "POST",
            body: ["email": email, "password": password],
            accessToken: nil
        )
    }

    func refresh(refreshToken: String) async throws -> RefreshResponse {
        try await request(
            "/api/v1/auth/refresh",
            method: "POST",
            body: ["refresh_token": refreshToken],
            accessToken: nil
        )
    }

    func listProjects(orgId: String, accessToken: String) async throws -> [Project] {
        struct ProjectsEnvelope: Decodable {
            let projects: [Project]?
            let data: [Project]?
        }

        let envelope: ProjectsEnvelope = try await request(
            "/api/v1/organizations/\(orgId)/projects",
            accessToken: accessToken
        )

        return envelope.projects ?? envelope.data ?? []
    }

    func listDocuments(projectId: String, accessToken: String) async throws -> [DocumentSummary] {
        let envelope: APIEnvelope<[DocumentSummary]> = try await request(
            "/api/v1/projects/\(projectId)/docs",
            accessToken: accessToken
        )
        return envelope.data ?? []
    }

    func loadDocument(id: String, accessToken: String) async throws -> GraphDocument {
        let envelope: APIEnvelope<GraphDocument> = try await request(
            "/api/v1/docs/\(id)",
            accessToken: accessToken
        )

        guard let document = envelope.data else {
            throw APIError.missingData("Document")
        }
        return document
    }

    func listFixtures() async throws -> [DocumentSummary] {
        let envelope: APIEnvelope<[DocumentSummary]> = try await request("/api/v1/holograph/docs")
        return envelope.data ?? []
    }

    func loadFixture(id: String) async throws -> GraphDocument {
        let envelope: APIEnvelope<GraphDocument> = try await request("/api/v1/holograph/docs/\(id)")

        guard let document = envelope.data else {
            throw APIError.missingData("Fixture")
        }
        return document
    }

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: [String: String]? = nil,
        accessToken: String? = nil
    ) async throws -> T {
        var request = URLRequest(url: url(path: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpStatus(http.statusCode, serverMessage(from: data))
        }

        return try decoder.decode(T.self, from: data)
    }

    private func serverMessage(from data: Data) -> String {
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return "Request failed"
        }

        if let error = object["error"] as? String {
            return error
        }

        if let error = object["error"] as? [String: Any],
           let message = error["message"] as? String {
            return message
        }

        return "Request failed"
    }
}

private extension Bundle {
    func string(for key: String) -> String? {
        object(forInfoDictionaryKey: key) as? String
    }
}
