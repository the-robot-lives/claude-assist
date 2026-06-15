import Foundation

private let configDir = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".config/queue-populator")
private let configFile = configDir.appendingPathComponent("config.json")

func loadConfig() -> QueuePopulatorConfig {
    let path = configFile.path
    DebugLog.log("[LOAD] path: \(path)")
    guard FileManager.default.fileExists(atPath: path) else {
        DebugLog.log("[LOAD] no config file, using defaults")
        return QueuePopulatorConfig()
    }
    do {
        let data = try Data(contentsOf: configFile)
        DebugLog.log("[LOAD] read \(data.count) bytes")
        let config = try JSONDecoder().decode(QueuePopulatorConfig.self, from: data)
        DebugLog.log("[LOAD] decoded OK: provider=\(config.llm.provider) model=\(config.llm.model ?? "nil") alias=\(config.llm.apiKeyAlias ?? "nil")")
        return config.sanitized()
    } catch {
        DebugLog.log("[LOAD] FAIL: \(error)")
        return QueuePopulatorConfig()
    }
}

enum ConfigSaveError: LocalizedError {
    case encodingFailed
    case directoryCreationFailed(String, Error)
    case writeFailed(String, Error)
    case permissionDenied(String)
    case encryptionFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode configuration as JSON."
        case .directoryCreationFailed(let path, let err):
            return "Cannot create config directory \(path): \(err.localizedDescription)"
        case .writeFailed(let path, let err):
            return "Cannot write config file \(path): \(err.localizedDescription)"
        case .permissionDenied(let path):
            return "Permission denied writing to \(path). Check file permissions with: ls -la \(path)"
        case .encryptionFailed:
            return "Failed to encrypt API key. Is dc installed at ~/.local/bin/dc?"
        }
    }
}

func saveConfig(_ config: QueuePopulatorConfig) throws {
    let fm = FileManager.default
    let dirPath = configDir.path
    let filePath = configFile.path

    DebugLog.log("[SAVE 1/8] target: \(filePath)")
    DebugLog.log("[SAVE 2/8] configDir exists=\(fm.fileExists(atPath: dirPath)) writable=\(fm.isWritableFile(atPath: dirPath))")

    do {
        try fm.createDirectory(at: configDir, withIntermediateDirectories: true)
        DebugLog.log("[SAVE 2/8] directory OK")
    } catch {
        DebugLog.log("[SAVE 2/8] FAIL createDirectory: \(error)")
        throw ConfigSaveError.directoryCreationFailed(dirPath, error)
    }

    let fileExists = fm.fileExists(atPath: filePath)
    let fileWritable = fm.isWritableFile(atPath: filePath)
    DebugLog.log("[SAVE 3/8] file exists=\(fileExists) writable=\(fileWritable)")
    if fileExists && !fileWritable {
        DebugLog.log("[SAVE 3/8] FAIL permission denied")
        throw ConfigSaveError.permissionDenied(filePath)
    }

    var toSave = config.sanitized()
    DebugLog.log("[SAVE 4/8] sanitized: provider=\(toSave.llm.provider) apiKey=\(toSave.llm.apiKey == nil ? "nil" : "\(toSave.llm.apiKey!.count)chars") alias=\(toSave.llm.apiKeyAlias ?? "nil")")

    if let key = toSave.llm.apiKey, !key.isEmpty,
       !key.lowercased().hasPrefix("env:"),
       !SecretStore.isEncrypted(key) {
        DebugLog.log("[SAVE 4/8] encrypting plaintext API key (\(key.count) chars)")
        guard let encrypted = SecretStore.encrypt(key) else {
            DebugLog.log("[SAVE 4/8] FAIL dc encrypt returned nil")
            throw ConfigSaveError.encryptionFailed
        }
        toSave.llm.apiKey = encrypted
        toSave.llm.apiKeyAlias = toSave.llm.apiKeyAlias ?? SecretStore.generateAlias()
        DebugLog.log("[SAVE 4/8] encrypted OK alias=\(toSave.llm.apiKeyAlias ?? "?")")
    } else {
        DebugLog.log("[SAVE 4/8] no encryption needed")
    }

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data: Data
    do {
        data = try encoder.encode(toSave)
        DebugLog.log("[SAVE 5/8] encoded JSON (\(data.count) bytes)")
    } catch {
        DebugLog.log("[SAVE 5/8] FAIL encode: \(error)")
        throw ConfigSaveError.encodingFailed
    }

    if let json = String(data: data, encoding: .utf8) {
        DebugLog.log("[SAVE 5/8] JSON:\n\(json)")
    }

    let tmpPath = filePath + ".tmp"
    let tmpURL = URL(fileURLWithPath: tmpPath)
    DebugLog.log("[SAVE 6/8] writing tmp: \(tmpPath)")
    do {
        try data.write(to: tmpURL)
        let tmpSize = (try? fm.attributesOfItem(atPath: tmpPath)[.size] as? Int) ?? -1
        DebugLog.log("[SAVE 6/8] tmp written (\(tmpSize) bytes)")
    } catch {
        DebugLog.log("[SAVE 6/8] FAIL write tmp: \(error)")
        throw ConfigSaveError.writeFailed(tmpPath, error)
    }

    DebugLog.log("[SAVE 7/8] replacing \(filePath)")
    do {
        if fm.fileExists(atPath: filePath) {
            DebugLog.log("[SAVE 7/8] file exists, using replaceItemAt")
            let result = try fm.replaceItemAt(configFile, withItemAt: tmpURL)
            DebugLog.log("[SAVE 7/8] replaceItemAt -> \(result?.path ?? "nil")")
        } else {
            DebugLog.log("[SAVE 7/8] no existing file, using moveItem")
            try fm.moveItem(at: tmpURL, to: configFile)
            DebugLog.log("[SAVE 7/8] moveItem OK")
        }
    } catch {
        DebugLog.log("[SAVE 7/8] FAIL: \(error)")
        try? fm.removeItem(at: tmpURL)
        throw ConfigSaveError.writeFailed(filePath, error)
    }

    // Clean up tmp if still around
    if fm.fileExists(atPath: tmpPath) {
        try? fm.removeItem(atPath: tmpPath)
    }

    let finalExists = fm.fileExists(atPath: filePath)
    let finalSize = (try? fm.attributesOfItem(atPath: filePath)[.size] as? Int) ?? -1
    DebugLog.log("[SAVE 8/8] verify: exists=\(finalExists) size=\(finalSize)")

    guard finalExists else {
        DebugLog.log("[SAVE 8/8] FAIL file missing after write!")
        throw ConfigSaveError.writeFailed(filePath,
            NSError(domain: "ConfigStore", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "File missing after write"
            ]))
    }

    do {
        let readBack = try Data(contentsOf: configFile)
        let _ = try JSONDecoder().decode(QueuePopulatorConfig.self, from: readBack)
        DebugLog.log("[SAVE 8/8] SUCCESS — saved and verified (\(readBack.count) bytes)")
    } catch {
        DebugLog.log("[SAVE 8/8] WARNING — written but re-read/decode failed: \(error)")
    }
}
