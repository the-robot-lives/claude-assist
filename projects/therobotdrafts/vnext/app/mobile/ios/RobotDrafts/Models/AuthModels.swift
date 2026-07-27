import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    let userName: String?
    let handle: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case userName = "user_name"
        case handle
        case status
    }
}

struct Organization: Codable, Identifiable, Equatable {
    let id: String
    let slug: String
    let name: String
    let role: String?
}

struct Project: Codable, Identifiable, Equatable {
    let id: String
    let name: String?
    let slug: String?
    let organizationId: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case slug
        case organizationId = "organization_id"
        case status
    }
}

struct AuthResponse: Codable, Equatable {
    let user: User
    let accessToken: String
    let refreshToken: String
    let organizations: [Organization]?

    enum CodingKeys: String, CodingKey {
        case user
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case organizations
    }
}

struct RefreshResponse: Codable, Equatable {
    let accessToken: String
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}
