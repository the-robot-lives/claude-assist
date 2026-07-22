import Foundation

enum TimelyEnvironmentResolver {
    static func resolve(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEnvironmentName(trimmed) else {
            return nil
        }

        if let value = ProcessInfo.processInfo.environment[trimmed], !value.isEmpty {
            return value
        }

        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: shell)
        process.arguments = ["-lic", "printenv \(trimmed)"]
        process.environment = ["HOME": NSHomeDirectory(), "USER": NSUserName()]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let value = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return value?.isEmpty == false ? value : nil
        } catch {
            return nil
        }
    }

    private static func isValidEnvironmentName(_ name: String) -> Bool {
        guard let first = name.first,
              first == "_" || first.isLetter else {
            return false
        }
        return name.allSatisfy { character in
            character == "_" || character.isLetter || character.isNumber
        }
    }
}

enum VisionLLMError: LocalizedError {
    case missingAPIKey
    case invalidEndpoint(String)
    case requestFailed(Int, String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "No API key configured. Set the API key field or use an env: NAME alias."
        case .invalidEndpoint(let endpoint):
            "Invalid vision endpoint: \(endpoint)"
        case .requestFailed(let code, let body):
            "Vision LLM request failed with HTTP \(code): \(String(body.prefix(240)))"
        case .emptyResponse:
            "Vision LLM returned an empty response."
        }
    }
}

struct VisionAnalysisContext {
    var knownTask: String
    var knownProject: String
    var activeAppName: String
    var previousInferredProject: String?
    var capturedAt: Date
}

private struct VisionAnalysisPayload: Decodable {
    var statusUpdate: String?
    var inferredProject: String?
    var inferredTask: String?
    var projectSwitchDetected: Bool?
    var confidence: Double?
    var evidence: String?
    var privacySensitive: Bool?
    var privacyCategory: String?
    var privacyAction: String?

    enum CodingKeys: String, CodingKey {
        case statusUpdate = "status_update"
        case inferredProject = "inferred_project"
        case inferredTask = "inferred_task"
        case projectSwitchDetected = "project_switch_detected"
        case confidence
        case evidence
        case privacySensitive = "privacy_sensitive"
        case privacyCategory = "privacy_category"
        case privacyAction = "privacy_action"
    }
}

actor VisionLLMClient {
    private let settings: VisionLLMSettings
    private let timeoutSeconds: TimeInterval = 45

    init(settings: VisionLLMSettings) {
        self.settings = settings
    }

    func analyze(screenshotID: UUID, screenshotURL: URL, context: VisionAnalysisContext) async throws -> VisionAnalysisRecord {
        let imageData = try Data(contentsOf: screenshotURL)
        let imageBase64 = imageData.base64EncodedString()
        let prompt = buildPrompt(context: context)

        let raw: String
        if settings.provider == "ollama" {
            raw = try await sendOllama(prompt: prompt, imageBase64: imageBase64)
        } else {
            raw = try await sendOpenAICompatible(prompt: prompt, imageBase64: imageBase64)
        }

        return parse(
            raw,
            screenshotID: screenshotID,
            model: settings.effectiveModel,
            knownProject: context.knownProject,
            previousInferredProject: context.previousInferredProject
        )
    }

    func parse(
        _ raw: String,
        screenshotID: UUID,
        model: String,
        knownProject: String,
        previousInferredProject: String?
    ) -> VisionAnalysisRecord {
        let cleaned = cleanJSONText(raw)
        let payload: VisionAnalysisPayload?
        if let data = cleaned.data(using: .utf8) {
            payload = try? JSONDecoder().decode(VisionAnalysisPayload.self, from: data)
        } else {
            payload = nil
        }

        guard let payload else {
            return VisionAnalysisRecord(
                id: UUID(),
                screenshotID: screenshotID,
                analyzedAt: Date(),
                model: model,
                statusUpdate: "Vision analysis completed, but the response was not valid JSON.",
                inferredProject: "",
                inferredTask: "",
                projectSwitchDetected: false,
                confidence: 0,
                evidence: "",
                privacySensitive: false,
                privacyCategory: "none",
                rawResponse: raw,
                errorMessage: "Could not parse JSON response."
            )
        }

        let inferredProject = payload.inferredProject?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let reportedSwitch = payload.projectSwitchDetected ?? false
        let confidence = min(1, max(0, payload.confidence ?? 0))
        let baseline = knownProject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? previousInferredProject?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            : knownProject.trimmingCharacters(in: .whitespacesAndNewlines)
        let inferredSwitch = !baseline.isEmpty
            && !inferredProject.isEmpty
            && baseline.localizedCaseInsensitiveCompare(inferredProject) != .orderedSame
            && confidence >= settings.confidenceThreshold
        let privacyAction = payload.privacyAction?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? "keep"
        let privacyCategory = payload.privacyCategory?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? "none"
        let privacySensitive = payload.privacySensitive == true || privacyAction == "censor"

        return VisionAnalysisRecord(
            id: UUID(),
            screenshotID: screenshotID,
            analyzedAt: Date(),
            model: model,
            statusUpdate: payload.statusUpdate?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "No status update returned.",
            inferredProject: inferredProject,
            inferredTask: payload.inferredTask?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            projectSwitchDetected: reportedSwitch || inferredSwitch,
            confidence: confidence,
            evidence: payload.evidence?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            privacySensitive: privacySensitive,
            privacyCategory: privacySensitive ? privacyCategory : "none",
            rawResponse: raw,
            errorMessage: nil
        )
    }

    private func buildPrompt(context: VisionAnalysisContext) -> String {
        """
        \(settings.prompt)

        Known current work:
        - Task: \(context.knownTask.isEmpty ? "unknown" : context.knownTask)
        - Project: \(context.knownProject.isEmpty ? "unknown" : context.knownProject)
        - Prior inferred project: \(context.previousInferredProject ?? "unknown")
        - Active app: \(context.activeAppName)
        - Screenshot captured at: \(context.capturedAt.formatted(date: .abbreviated, time: .standard))
        """
    }

    private func sendOpenAICompatible(prompt: String, imageBase64: String) async throws -> String {
        guard let endpoint = chatCompletionsURL() else {
            throw VisionLLMError.invalidEndpoint(settings.effectiveBaseURL)
        }

        guard settings.provider == "custom" || settings.provider == "ollama" || settings.effectiveAPIKey != nil else {
            throw VisionLLMError.missingAPIKey
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = timeoutSeconds
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        if let apiKey = settings.effectiveAPIKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "model": settings.effectiveModel,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt],
                        [
                            "type": "image_url",
                            "image_url": ["url": "data:image/png;base64,\(imageBase64)"]
                        ]
                    ]
                ]
            ],
            "response_format": ["type": "json_object"]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        guard (200..<300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw VisionLLMError.requestFailed(httpResponse.statusCode, body)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw VisionLLMError.emptyResponse
        }
        return content
    }

    private func sendOllama(prompt: String, imageBase64: String) async throws -> String {
        let baseURL = settings.effectiveBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let endpoint = URL(string: "\(baseURL)/api/chat") else {
            throw VisionLLMError.invalidEndpoint(settings.effectiveBaseURL)
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = timeoutSeconds
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": settings.effectiveModel,
            "stream": false,
            "format": "json",
            "messages": [
                [
                    "role": "user",
                    "content": prompt,
                    "images": [imageBase64]
                ]
            ]
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        guard (200..<300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw VisionLLMError.requestFailed(httpResponse.statusCode, body)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? [String: Any],
              let content = message["content"] as? String,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw VisionLLMError.emptyResponse
        }
        return content
    }

    private func chatCompletionsURL() -> URL? {
        let base = settings.effectiveBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if base.hasSuffix("/chat/completions") {
            return URL(string: base)
        }
        return URL(string: "\(base)/chat/completions")
    }

    private func cleanJSONText(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        }
        if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
