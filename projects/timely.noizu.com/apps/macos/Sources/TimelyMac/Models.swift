import Foundation

enum CaptureMode: String, Codable {
    case idle
    case running
    case paused
    case pomodoroWork
    case pomodoroBreak

    var label: String {
        switch self {
        case .idle: "Ready"
        case .running: "Tracking"
        case .paused: "Paused"
        case .pomodoroWork: "Pomodoro focus"
        case .pomodoroBreak: "Pomodoro break"
        }
    }
}

enum SpanSource: String, Codable, CaseIterable, Identifiable {
    case manual
    case timer
    case pomodoro

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

struct AppSettings: Codable {
    var screenshotIntervalMinutes: Double
    var screenshotCaptureEnabled: Bool
    var pomodoroWorkMinutes: Double
    var pomodoroBreakMinutes: Double
    var localOnlyScreenshots: Bool
    var retentionDays: Int
    var vision: VisionLLMSettings

    static let defaults = AppSettings(
        screenshotIntervalMinutes: 5,
        screenshotCaptureEnabled: true,
        pomodoroWorkMinutes: 25,
        pomodoroBreakMinutes: 5,
        localOnlyScreenshots: true,
        retentionDays: 0,
        vision: .defaults
    )

    init(
        screenshotIntervalMinutes: Double,
        screenshotCaptureEnabled: Bool,
        pomodoroWorkMinutes: Double,
        pomodoroBreakMinutes: Double,
        localOnlyScreenshots: Bool,
        retentionDays: Int,
        vision: VisionLLMSettings
    ) {
        self.screenshotIntervalMinutes = screenshotIntervalMinutes
        self.screenshotCaptureEnabled = screenshotCaptureEnabled
        self.pomodoroWorkMinutes = pomodoroWorkMinutes
        self.pomodoroBreakMinutes = pomodoroBreakMinutes
        self.localOnlyScreenshots = localOnlyScreenshots
        self.retentionDays = retentionDays
        self.vision = vision
    }

    enum CodingKeys: String, CodingKey {
        case screenshotIntervalMinutes
        case screenshotCaptureEnabled
        case pomodoroWorkMinutes
        case pomodoroBreakMinutes
        case localOnlyScreenshots
        case retentionDays
        case vision
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = Self.defaults
        screenshotIntervalMinutes = try values.decodeIfPresent(Double.self, forKey: .screenshotIntervalMinutes) ?? fallback.screenshotIntervalMinutes
        screenshotCaptureEnabled = try values.decodeIfPresent(Bool.self, forKey: .screenshotCaptureEnabled) ?? fallback.screenshotCaptureEnabled
        pomodoroWorkMinutes = try values.decodeIfPresent(Double.self, forKey: .pomodoroWorkMinutes) ?? fallback.pomodoroWorkMinutes
        pomodoroBreakMinutes = try values.decodeIfPresent(Double.self, forKey: .pomodoroBreakMinutes) ?? fallback.pomodoroBreakMinutes
        localOnlyScreenshots = try values.decodeIfPresent(Bool.self, forKey: .localOnlyScreenshots) ?? fallback.localOnlyScreenshots
        retentionDays = try values.decodeIfPresent(Int.self, forKey: .retentionDays) ?? fallback.retentionDays
        vision = try values.decodeIfPresent(VisionLLMSettings.self, forKey: .vision) ?? fallback.vision
    }
}

extension AppSettings {
    var retentionLabel: String {
        retentionDays <= 0 ? "Forever" : "\(retentionDays) days"
    }
}

struct VisionLLMSettings: Codable {
    var analysisEnabled: Bool
    var notifyOnProjectSwitch: Bool
    var privacyRedactionEnabled: Bool
    var notifyOnCensoredScreenshot: Bool
    var provider: String
    var model: String
    var apiKey: String
    var baseURL: String
    var prompt: String
    var confidenceThreshold: Double

    static let providers = ["openai", "litellm", "ollama", "custom"]

    static let defaultModels: [String: String] = [
        "openai": "gpt-4o",
        "litellm": "gpt-4o",
        "ollama": "llama3.2-vision",
        "custom": "vision-model"
    ]

    static let defaultBaseURLs: [String: String] = [
        "openai": "https://api.openai.com/v1",
        "litellm": "https://inference.noizu.com/v1",
        "ollama": "http://localhost:11434",
        "custom": "https://api.example.com/v1"
    ]

    static let defaultAPIKeys: [String: String] = [
        "openai": "env: OPENAI_API_KEY",
        "litellm": "env: LITELLM_API_KEY",
        "ollama": "",
        "custom": "env: TIMELY_VISION_API_KEY"
    ]

    static let defaultPrompt = """
    You are Timely's private work-observation assistant. Review the screenshot and the known active time span, if provided. Return only JSON with these keys: status_update, inferred_project, inferred_task, project_switch_detected, confidence, evidence.

    Rules:
    - status_update is one concise sentence describing visible progress.
    - inferred_project is the project or client visible in the screenshot, or an empty string.
    - inferred_task is the current task visible in the screenshot, or an empty string.
    - project_switch_detected is true only when the screenshot appears to show a different project from the known project or prior inferred project.
    - confidence is a number from 0.0 to 1.0.
    - evidence is a short phrase naming the visible clues.
    - Also return privacy_sensitive, privacy_category, and privacy_action.
    - privacy_sensitive is true if the screenshot visibly contains secrets, API keys, passwords, private email, personal chat, adult material, financial or identity records, medical details, or other private material that should not be retained as evidence.
    - privacy_category is one of none, secret, private_email, personal_chat, adult_material, financial, identity, medical, other_private.
    - privacy_action is keep when privacy_sensitive is false, or censor when privacy_sensitive is true.
    """

    static let defaults = VisionLLMSettings(
        analysisEnabled: false,
        notifyOnProjectSwitch: true,
        privacyRedactionEnabled: true,
        notifyOnCensoredScreenshot: true,
        provider: "openai",
        model: "gpt-4o",
        apiKey: "env: OPENAI_API_KEY",
        baseURL: "https://api.openai.com/v1",
        prompt: defaultPrompt,
        confidenceThreshold: 0.72
    )

    init(
        analysisEnabled: Bool,
        notifyOnProjectSwitch: Bool,
        privacyRedactionEnabled: Bool,
        notifyOnCensoredScreenshot: Bool,
        provider: String,
        model: String,
        apiKey: String,
        baseURL: String,
        prompt: String,
        confidenceThreshold: Double
    ) {
        self.analysisEnabled = analysisEnabled
        self.notifyOnProjectSwitch = notifyOnProjectSwitch
        self.privacyRedactionEnabled = privacyRedactionEnabled
        self.notifyOnCensoredScreenshot = notifyOnCensoredScreenshot
        self.provider = provider
        self.model = model
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.prompt = prompt
        self.confidenceThreshold = confidenceThreshold
    }

    enum CodingKeys: String, CodingKey {
        case analysisEnabled
        case notifyOnProjectSwitch
        case privacyRedactionEnabled
        case notifyOnCensoredScreenshot
        case provider
        case model
        case apiKey
        case baseURL
        case prompt
        case confidenceThreshold
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = Self.defaults
        analysisEnabled = try values.decodeIfPresent(Bool.self, forKey: .analysisEnabled) ?? fallback.analysisEnabled
        notifyOnProjectSwitch = try values.decodeIfPresent(Bool.self, forKey: .notifyOnProjectSwitch) ?? fallback.notifyOnProjectSwitch
        privacyRedactionEnabled = try values.decodeIfPresent(Bool.self, forKey: .privacyRedactionEnabled) ?? fallback.privacyRedactionEnabled
        notifyOnCensoredScreenshot = try values.decodeIfPresent(Bool.self, forKey: .notifyOnCensoredScreenshot) ?? fallback.notifyOnCensoredScreenshot
        provider = try values.decodeIfPresent(String.self, forKey: .provider) ?? fallback.provider
        model = try values.decodeIfPresent(String.self, forKey: .model) ?? fallback.model
        apiKey = try values.decodeIfPresent(String.self, forKey: .apiKey) ?? fallback.apiKey
        baseURL = try values.decodeIfPresent(String.self, forKey: .baseURL) ?? fallback.baseURL
        prompt = try values.decodeIfPresent(String.self, forKey: .prompt) ?? fallback.prompt
        confidenceThreshold = try values.decodeIfPresent(Double.self, forKey: .confidenceThreshold) ?? fallback.confidenceThreshold
    }

    var effectiveModel: String {
        model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? Self.defaultModels[provider] ?? "vision-model"
            : model.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var effectiveBaseURL: String {
        baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? Self.defaultBaseURLs[provider] ?? "https://api.example.com/v1"
            : baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var effectiveAPIKey: String? {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("env:") {
            let name = String(trimmed.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
            return TimelyEnvironmentResolver.resolve(name)
        }
        if !trimmed.isEmpty {
            return trimmed
        }
        guard let fallback = Self.defaultAPIKeys[provider], fallback.lowercased().hasPrefix("env:") else {
            return nil
        }
        let name = String(fallback.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
        return TimelyEnvironmentResolver.resolve(name)
    }
}

struct VisionAnalysisRecord: Identifiable, Codable {
    var id: UUID
    var screenshotID: UUID
    var analyzedAt: Date
    var model: String
    var statusUpdate: String
    var inferredProject: String
    var inferredTask: String
    var projectSwitchDetected: Bool
    var confidence: Double
    var evidence: String
    var privacySensitive: Bool
    var privacyCategory: String
    var rawResponse: String
    var errorMessage: String?

    init(
        id: UUID,
        screenshotID: UUID,
        analyzedAt: Date,
        model: String,
        statusUpdate: String,
        inferredProject: String,
        inferredTask: String,
        projectSwitchDetected: Bool,
        confidence: Double,
        evidence: String,
        privacySensitive: Bool = false,
        privacyCategory: String = "none",
        rawResponse: String,
        errorMessage: String?
    ) {
        self.id = id
        self.screenshotID = screenshotID
        self.analyzedAt = analyzedAt
        self.model = model
        self.statusUpdate = statusUpdate
        self.inferredProject = inferredProject
        self.inferredTask = inferredTask
        self.projectSwitchDetected = projectSwitchDetected
        self.confidence = confidence
        self.evidence = evidence
        self.privacySensitive = privacySensitive
        self.privacyCategory = privacyCategory
        self.rawResponse = rawResponse
        self.errorMessage = errorMessage
    }

    enum CodingKeys: String, CodingKey {
        case id
        case screenshotID
        case analyzedAt
        case model
        case statusUpdate
        case inferredProject
        case inferredTask
        case projectSwitchDetected
        case confidence
        case evidence
        case privacySensitive
        case privacyCategory
        case rawResponse
        case errorMessage
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        screenshotID = try values.decode(UUID.self, forKey: .screenshotID)
        analyzedAt = try values.decode(Date.self, forKey: .analyzedAt)
        model = try values.decode(String.self, forKey: .model)
        statusUpdate = try values.decode(String.self, forKey: .statusUpdate)
        inferredProject = try values.decode(String.self, forKey: .inferredProject)
        inferredTask = try values.decode(String.self, forKey: .inferredTask)
        projectSwitchDetected = try values.decode(Bool.self, forKey: .projectSwitchDetected)
        confidence = try values.decode(Double.self, forKey: .confidence)
        evidence = try values.decode(String.self, forKey: .evidence)
        privacySensitive = try values.decodeIfPresent(Bool.self, forKey: .privacySensitive) ?? false
        privacyCategory = try values.decodeIfPresent(String.self, forKey: .privacyCategory) ?? "none"
        rawResponse = try values.decode(String.self, forKey: .rawResponse)
        errorMessage = try values.decodeIfPresent(String.self, forKey: .errorMessage)
    }
}

struct CensoredScreenshotRecord: Identifiable, Codable {
    var id: UUID
    var screenshotID: UUID
    var spanID: UUID?
    var fileName: String
    var activeAppName: String
    var capturedAt: Date
    var censoredAt: Date
    var model: String
    var category: String
    var reason: String
    var confidence: Double
    var deletedLocalFile: Bool
}

struct TrackedTimeSpan: Identifiable, Codable {
    var id: UUID
    var title: String
    var client: String
    var project: String
    var ticket: String
    var start: Date
    var end: Date?
    var source: SpanSource
    var isBillable: Bool
    var notes: String

    var duration: TimeInterval {
        (end ?? Date()).timeIntervalSince(start)
    }

    var isOpen: Bool {
        end == nil
    }

    init(
        id: UUID,
        title: String,
        client: String = "",
        project: String,
        ticket: String = "",
        start: Date,
        end: Date?,
        source: SpanSource,
        isBillable: Bool,
        notes: String
    ) {
        self.id = id
        self.title = title
        self.client = client
        self.project = project
        self.ticket = ticket
        self.start = start
        self.end = end
        self.source = source
        self.isBillable = isBillable
        self.notes = notes
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case client
        case project
        case ticket
        case start
        case end
        case source
        case isBillable
        case notes
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        title = try values.decode(String.self, forKey: .title)
        client = try values.decodeIfPresent(String.self, forKey: .client) ?? ""
        project = try values.decode(String.self, forKey: .project)
        ticket = try values.decodeIfPresent(String.self, forKey: .ticket) ?? ""
        start = try values.decode(Date.self, forKey: .start)
        end = try values.decodeIfPresent(Date.self, forKey: .end)
        source = try values.decode(SpanSource.self, forKey: .source)
        isBillable = try values.decode(Bool.self, forKey: .isBillable)
        notes = try values.decode(String.self, forKey: .notes)
    }
}

struct ClientRecord: Identifiable, Codable {
    var id: UUID
    var name: String
    var notes: String
}

struct ProjectRecord: Identifiable, Codable {
    var id: UUID
    var clientName: String
    var name: String
    var notes: String
}

struct TicketRecord: Identifiable, Codable {
    var id: UUID
    var clientName: String
    var projectName: String
    var name: String
    var notes: String
}

struct ScreenshotRecord: Identifiable, Codable {
    var id: UUID
    var spanID: UUID?
    var capturedAt: Date
    var fileName: String
    var activeAppName: String
}

struct TimelySnapshot: Codable {
    var settings: AppSettings
    var spans: [TrackedTimeSpan]
    var screenshots: [ScreenshotRecord]
    var visionAnalyses: [VisionAnalysisRecord]
    var censoredScreenshots: [CensoredScreenshotRecord]
    var clients: [ClientRecord]
    var projects: [ProjectRecord]
    var tickets: [TicketRecord]
    var lastInferredProject: String?

    init(
        settings: AppSettings,
        spans: [TrackedTimeSpan],
        screenshots: [ScreenshotRecord],
        visionAnalyses: [VisionAnalysisRecord],
        censoredScreenshots: [CensoredScreenshotRecord],
        clients: [ClientRecord],
        projects: [ProjectRecord],
        tickets: [TicketRecord],
        lastInferredProject: String?
    ) {
        self.settings = settings
        self.spans = spans
        self.screenshots = screenshots
        self.visionAnalyses = visionAnalyses
        self.censoredScreenshots = censoredScreenshots
        self.clients = clients
        self.projects = projects
        self.tickets = tickets
        self.lastInferredProject = lastInferredProject
    }

    enum CodingKeys: String, CodingKey {
        case settings
        case spans
        case screenshots
        case visionAnalyses
        case censoredScreenshots
        case clients
        case projects
        case tickets
        case lastInferredProject
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        settings = try values.decodeIfPresent(AppSettings.self, forKey: .settings) ?? .defaults
        spans = try values.decodeIfPresent([TrackedTimeSpan].self, forKey: .spans) ?? []
        screenshots = try values.decodeIfPresent([ScreenshotRecord].self, forKey: .screenshots) ?? []
        visionAnalyses = try values.decodeIfPresent([VisionAnalysisRecord].self, forKey: .visionAnalyses) ?? []
        censoredScreenshots = try values.decodeIfPresent([CensoredScreenshotRecord].self, forKey: .censoredScreenshots) ?? []
        clients = try values.decodeIfPresent([ClientRecord].self, forKey: .clients) ?? []
        projects = try values.decodeIfPresent([ProjectRecord].self, forKey: .projects) ?? []
        tickets = try values.decodeIfPresent([TicketRecord].self, forKey: .tickets) ?? []
        lastInferredProject = try values.decodeIfPresent(String.self, forKey: .lastInferredProject)
    }
}

extension TimeInterval {
    var timelyClock: String {
        let total = max(0, Int(self))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
