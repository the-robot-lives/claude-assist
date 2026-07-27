import Foundation

/// A read-only mirror of the macOS agent's `TimelySnapshot`.
///
/// Transcribed from `apps/macos/Sources/TimelyMac/Models.swift` rather than
/// shared with it, deliberately: this package must not depend on the macOS app,
/// and the snapshot is a *legacy format* that is frozen at whatever the agent
/// wrote. When the macOS app is rewired onto TimelyKit it will stop writing
/// this shape, and these types stay behind to keep reading old files.
///
/// Every field is decoded permissively. A snapshot written by an older build of
/// the agent is missing keys a newer one has, and refusing to import someone's
/// entire work history over one absent `notes` string would be indefensible.
struct MacSnapshot: Decodable {
    var spans: [MacSpan] = []
    var screenshots: [MacScreenshot] = []
    var visionAnalyses: [MacVisionAnalysis] = []
    var censoredScreenshots: [MacCensoredScreenshot] = []
    var clients: [MacClient] = []
    var projects: [MacProject] = []
    var tickets: [MacTicket] = []

    enum CodingKeys: String, CodingKey {
        case spans, screenshots, visionAnalyses, censoredScreenshots
        case clients, projects, tickets
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        spans = try c.decodeIfPresent([MacSpan].self, forKey: .spans) ?? []
        screenshots = try c.decodeIfPresent([MacScreenshot].self, forKey: .screenshots) ?? []
        visionAnalyses = try c.decodeIfPresent([MacVisionAnalysis].self, forKey: .visionAnalyses) ?? []
        censoredScreenshots = try c.decodeIfPresent(
            [MacCensoredScreenshot].self, forKey: .censoredScreenshots
        ) ?? []
        clients = try c.decodeIfPresent([MacClient].self, forKey: .clients) ?? []
        projects = try c.decodeIfPresent([MacProject].self, forKey: .projects) ?? []
        tickets = try c.decodeIfPresent([MacTicket].self, forKey: .tickets) ?? []
    }

    // MARK: - Derived name sets
    //
    // The agent auto-creates taxonomy on first use, so a name can appear on a
    // span without ever reaching the corresponding array. The import walks the
    // union of both, otherwise spans end up referencing rows that do not exist.

    var allClientNames: [String] {
        var seen = Set<String>()
        var names: [String] = []
        for name in clients.map(\.name) + spans.map(\.client) {
            let key = Canon.canon(name)
            guard !key.isEmpty, seen.insert(key).inserted else { continue }
            names.append(name)
        }
        return names
    }

    struct ProjectPair: Hashable {
        let clientName: String
        let name: String
        var canonicalKey: String { Canon.projectKey(clientName: clientName, name: name) }
    }

    var allProjectPairs: [ProjectPair] {
        var seen = Set<String>()
        var pairs: [ProjectPair] = []

        let candidates = projects.map { ProjectPair(clientName: $0.clientName, name: $0.name) }
            + spans.map { ProjectPair(clientName: $0.client, name: $0.project) }

        for pair in candidates {
            guard !Canon.canon(pair.name).isEmpty else { continue }
            guard seen.insert(pair.canonicalKey).inserted else { continue }
            pairs.append(pair)
        }
        return pairs
    }

    struct TicketTriple: Hashable {
        let clientName: String
        let projectName: String
        let name: String
        var canonicalKey: String {
            Canon.ticketKey(clientName: clientName, projectName: projectName, name: name)
        }
    }

    var allTicketTriples: [TicketTriple] {
        var seen = Set<String>()
        var triples: [TicketTriple] = []

        let candidates = tickets.map {
            TicketTriple(clientName: $0.clientName, projectName: $0.projectName, name: $0.name)
        } + spans.map {
            TicketTriple(clientName: $0.client, projectName: $0.project, name: $0.ticket)
        }

        for triple in candidates {
            guard !Canon.canon(triple.name).isEmpty else { continue }
            guard seen.insert(triple.canonicalKey).inserted else { continue }
            triples.append(triple)
        }
        return triples
    }

    /// Notes carried on the explicit taxonomy rows, keyed canonically so the
    /// importer can attach them to the recomputed record.
    var clientNotes: [String: String] {
        Dictionary(
            clients.map { (Canon.canon($0.name), $0.notes) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    var projectNotes: [String: String] {
        Dictionary(
            projects.map {
                (Canon.projectKey(clientName: $0.clientName, name: $0.name), $0.notes)
            },
            uniquingKeysWith: { first, _ in first }
        )
    }

    var ticketNotes: [String: String] {
        Dictionary(
            tickets.map {
                (
                    Canon.ticketKey(
                        clientName: $0.clientName, projectName: $0.projectName, name: $0.name
                    ),
                    $0.notes
                )
            },
            uniquingKeysWith: { first, _ in first }
        )
    }
}

// MARK: - Legacy rows

struct MacSpan: Decodable {
    let id: UUID
    let title: String
    let client: String
    let project: String
    let ticket: String
    let start: Date
    let end: Date?
    let source: String
    let isBillable: Bool
    let notes: String

    enum CodingKeys: String, CodingKey {
        case id, title, client, project, ticket, start, end, source, isBillable, notes
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        client = try c.decodeIfPresent(String.self, forKey: .client) ?? ""
        project = try c.decodeIfPresent(String.self, forKey: .project) ?? ""
        ticket = try c.decodeIfPresent(String.self, forKey: .ticket) ?? ""
        start = try c.decode(Date.self, forKey: .start)
        end = try c.decodeIfPresent(Date.self, forKey: .end)
        source = try c.decodeIfPresent(String.self, forKey: .source) ?? "manual"
        isBillable = try c.decodeIfPresent(Bool.self, forKey: .isBillable) ?? false
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }
}

struct MacScreenshot: Decodable {
    let id: UUID
    let spanID: UUID?
    let capturedAt: Date
    let fileName: String
    let activeAppName: String

    enum CodingKeys: String, CodingKey {
        case id, spanID, capturedAt, fileName, activeAppName
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        spanID = try c.decodeIfPresent(UUID.self, forKey: .spanID)
        capturedAt = try c.decode(Date.self, forKey: .capturedAt)
        fileName = try c.decodeIfPresent(String.self, forKey: .fileName) ?? ""
        activeAppName = try c.decodeIfPresent(String.self, forKey: .activeAppName) ?? ""
    }
}

struct MacVisionAnalysis: Decodable {
    let id: UUID
    let screenshotID: UUID
    let analyzedAt: Date
    let model: String
    let statusUpdate: String
    let inferredProject: String
    let inferredTask: String
    let projectSwitchDetected: Bool
    let confidence: Double
    let evidence: String
    let privacySensitive: Bool
    let privacyCategory: String
    let rawResponse: String
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case id, screenshotID, analyzedAt, model, statusUpdate, inferredProject
        case inferredTask, projectSwitchDetected, confidence, evidence
        case privacySensitive, privacyCategory, rawResponse, errorMessage
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        screenshotID = try c.decode(UUID.self, forKey: .screenshotID)
        analyzedAt = try c.decode(Date.self, forKey: .analyzedAt)
        model = try c.decodeIfPresent(String.self, forKey: .model) ?? ""
        statusUpdate = try c.decodeIfPresent(String.self, forKey: .statusUpdate) ?? ""
        inferredProject = try c.decodeIfPresent(String.self, forKey: .inferredProject) ?? ""
        inferredTask = try c.decodeIfPresent(String.self, forKey: .inferredTask) ?? ""
        projectSwitchDetected = try c.decodeIfPresent(Bool.self, forKey: .projectSwitchDetected) ?? false
        confidence = try c.decodeIfPresent(Double.self, forKey: .confidence) ?? 0
        evidence = try c.decodeIfPresent(String.self, forKey: .evidence) ?? ""
        privacySensitive = try c.decodeIfPresent(Bool.self, forKey: .privacySensitive) ?? false
        // An absent category on a row flagged sensitive must not decode as
        // `none`; the model's own default is the private one.
        privacyCategory = try c.decodeIfPresent(String.self, forKey: .privacyCategory) ?? "none"
        rawResponse = try c.decodeIfPresent(String.self, forKey: .rawResponse) ?? ""
        errorMessage = try c.decodeIfPresent(String.self, forKey: .errorMessage)
    }
}

struct MacCensoredScreenshot: Decodable {
    let id: UUID
    let screenshotID: UUID
    let spanID: UUID?
    let fileName: String
    let activeAppName: String
    let capturedAt: Date
    let censoredAt: Date
    let model: String
    let category: String
    let reason: String
    let confidence: Double
    let deletedLocalFile: Bool

    enum CodingKeys: String, CodingKey {
        case id, screenshotID, spanID, fileName, activeAppName, capturedAt
        case censoredAt, model, category, reason, confidence, deletedLocalFile
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        screenshotID = try c.decode(UUID.self, forKey: .screenshotID)
        spanID = try c.decodeIfPresent(UUID.self, forKey: .spanID)
        fileName = try c.decodeIfPresent(String.self, forKey: .fileName) ?? ""
        activeAppName = try c.decodeIfPresent(String.self, forKey: .activeAppName) ?? ""
        capturedAt = try c.decode(Date.self, forKey: .capturedAt)
        censoredAt = try c.decode(Date.self, forKey: .censoredAt)
        model = try c.decodeIfPresent(String.self, forKey: .model) ?? ""
        category = try c.decodeIfPresent(String.self, forKey: .category) ?? "other_private"
        reason = try c.decodeIfPresent(String.self, forKey: .reason) ?? ""
        confidence = try c.decodeIfPresent(Double.self, forKey: .confidence) ?? 0
        deletedLocalFile = try c.decodeIfPresent(Bool.self, forKey: .deletedLocalFile) ?? false
    }
}

struct MacClient: Decodable {
    let name: String
    let notes: String

    enum CodingKeys: String, CodingKey { case name, notes }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }
}

struct MacProject: Decodable {
    let clientName: String
    let name: String
    let notes: String

    enum CodingKeys: String, CodingKey { case clientName, name, notes }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        clientName = try c.decodeIfPresent(String.self, forKey: .clientName) ?? ""
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }
}

struct MacTicket: Decodable {
    let clientName: String
    let projectName: String
    let name: String
    let notes: String

    enum CodingKeys: String, CodingKey { case clientName, projectName, name, notes }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        clientName = try c.decodeIfPresent(String.self, forKey: .clientName) ?? ""
        projectName = try c.decodeIfPresent(String.self, forKey: .projectName) ?? ""
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }
}
