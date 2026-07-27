import Foundation
import Testing
@testable import TimelyKit

/// Locates the normative contract files in the repository.
///
/// The fixtures are read from `apps/shared/contracts/` in place rather than
/// copied into the test bundle as a resource. A copy is a second source of
/// truth that goes stale silently, and this file is the one artifact in the
/// project where "silently stale" is the exact failure mode being defended
/// against. `#filePath` gives a stable anchor without a build-system dependency.
enum ContractFixtures {

    /// `.../apps/shared/TimelyKit/Tests/TimelyKitTests/ContractFixtures.swift`
    /// → `.../apps/shared/contracts`
    static let contractsDirectory: URL = {
        URL(fileURLWithPath: #filePath)          // ContractFixtures.swift
            .deletingLastPathComponent()          // TimelyKitTests
            .deletingLastPathComponent()          // Tests
            .deletingLastPathComponent()          // TimelyKit
            .deletingLastPathComponent()          // shared
            .appendingPathComponent("contracts")
    }()

    static let canonFixturesURL = contractsDirectory.appendingPathComponent("canon-fixtures.json")

    static func loadCanonFixtures() throws -> CanonFixtureFile {
        let data = try Data(contentsOf: canonFixturesURL)
        return try JSONDecoder().decode(CanonFixtureFile.self, from: data)
    }
}

// MARK: - Fixture file shape

struct CanonFixtureFile: Decodable {
    let version: String
    let workspaceID: UUID
    let canonCases: [CanonCase]
    let compositeCases: [CompositeCase]

    /// The declared code point tables `canon()` MUST use. Read here (rather
    /// than hand-copied into the test) so a table-diff test compares against
    /// the fixture itself, not a second transcription of it.
    let stripCodePoints: Set<UInt32>
    let quoteCodePoints: [UInt32: Character]
    let whitespaceCodePoints: Set<UInt32>

    enum CodingKeys: String, CodingKey {
        case version
        case workspaceID = "workspace_id"
        case canonCases = "canon_cases"
        case compositeCases = "composite_cases"
        case stripCodePoints = "strip_code_points"
        case quoteCodePoints = "quote_code_points"
        case whitespaceCodePoints = "whitespace_code_points"
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decode(String.self, forKey: .version)
        let raw = try c.decode(String.self, forKey: .workspaceID)
        guard let id = UUID(uuidString: raw) else {
            throw DecodingError.dataCorruptedError(
                forKey: .workspaceID, in: c, debugDescription: "Not a UUID: \(raw)"
            )
        }
        workspaceID = id
        canonCases = try c.decode([CanonCase].self, forKey: .canonCases)
        compositeCases = try c.decode([CompositeCase].self, forKey: .compositeCases)

        let stripTokens = try c.decode([String].self, forKey: .stripCodePoints)
        stripCodePoints = Set(stripTokens.map(String.parseFixtureCodepoint))

        let whitespaceTokens = try c.decode([String].self, forKey: .whitespaceCodePoints)
        whitespaceCodePoints = Set(whitespaceTokens.map(String.parseFixtureCodepoint))

        let quoteDict = try c.decode([String: String].self, forKey: .quoteCodePoints)
        var quotes: [UInt32: Character] = [:]
        for (token, value) in quoteDict {
            guard let char = value.first, value.count == 1 else {
                throw DecodingError.dataCorruptedError(
                    forKey: .quoteCodePoints, in: c,
                    debugDescription: "quote_code_points value '\(value)' is not a single character"
                )
            }
            quotes[String.parseFixtureCodepoint(token)] = char
        }
        quoteCodePoints = quotes
    }
}

extension String {
    /// Parses the fixture's `"U+00AD"` notation into a raw code point.
    static func parseFixtureCodepoint(_ token: String) -> UInt32 {
        UInt32(token.dropFirst(2), radix: 16) ?? {
            fatalError("Not a fixture code point token: \(token)")
        }()
    }
}

struct CanonCase: Decodable {
    let id: String
    let group: String
    let input: String
    let expectedOutput: String
    let expectedOutputCodepoints: [String]
    let expectedClientKey: String?

    /// `null` means "this name is not a reference and MUST NOT mint an entity".
    let expectedClientID: UUID?

    let note: String?

    enum CodingKeys: String, CodingKey {
        case id, group, input, note
        case expectedOutput = "expected_output"
        case expectedOutputCodepoints = "expected_output_codepoints"
        case expectedClientKey = "expected_client_key"
        case expectedClientID = "expected_client_id"
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        group = try c.decode(String.self, forKey: .group)
        input = try c.decode(String.self, forKey: .input)
        expectedOutput = try c.decode(String.self, forKey: .expectedOutput)
        expectedOutputCodepoints =
            try c.decodeIfPresent([String].self, forKey: .expectedOutputCodepoints) ?? []
        expectedClientKey = try c.decodeIfPresent(String.self, forKey: .expectedClientKey)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        if let raw = try c.decodeIfPresent(String.self, forKey: .expectedClientID) {
            guard let value = UUID(uuidString: raw) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .expectedClientID, in: c, debugDescription: "Not a UUID: \(raw)"
                )
            }
            expectedClientID = value
        } else {
            expectedClientID = nil
        }
    }
}

struct CompositeCase: Decodable {
    let id: String
    let kind: String
    let input: CompositeInput
    let expectedKey: String
    let expectedID: UUID?
    let note: String?

    enum CodingKeys: String, CodingKey {
        case id, kind, input, note
        case expectedKey = "expected_key"
        case expectedID = "expected_id"
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        kind = try c.decode(String.self, forKey: .kind)
        input = try c.decode(CompositeInput.self, forKey: .input)
        expectedKey = try c.decode(String.self, forKey: .expectedKey)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        if let raw = try c.decodeIfPresent(String.self, forKey: .expectedID) {
            expectedID = UUID(uuidString: raw)
        } else {
            expectedID = nil
        }
    }
}

struct CompositeInput: Decodable {
    let clientName: String?
    let projectName: String?
    let name: String?
    let userID: String?

    enum CodingKeys: String, CodingKey {
        case name
        case clientName = "client_name"
        case projectName = "project_name"
        case userID = "user_id"
    }
}

// MARK: - Codepoint rendering

extension String {
    /// `"U+0061"`-style rendering, matching the fixture file's notation. Used to
    /// make a mismatch legible: comparing two visually identical strings that
    /// differ by an invisible is otherwise a miserable debugging session.
    var fixtureCodepoints: [String] {
        unicodeScalars.map { String(format: "U+%04X", $0.value) }
    }
}
