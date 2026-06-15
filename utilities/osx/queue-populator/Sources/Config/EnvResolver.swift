import Foundation

enum EnvResolver {
    nonisolated(unsafe) private static var cache: [String: String] = [:]

    static func resolve(_ name: String) -> String? {
        if let cached = cache[name] {
            DebugLog.log("[ENV] resolve(\(name)) -> cached (\(cached.isEmpty ? "empty" : "\(cached.count)chars"))")
            return cached.isEmpty ? nil : cached
        }

        if let val = ProcessInfo.processInfo.environment[name], !val.isEmpty {
            DebugLog.log("[ENV] resolve(\(name)) -> ProcessInfo (\(val.count)chars)")
            cache[name] = val
            return val
        }

        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        DebugLog.log("[ENV] resolve(\(name)) -> shelling out: \(shell) -lic")
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: shell)
        proc.arguments = ["-lic", "printf '%s' \"$\(name)\""]
        proc.environment = ["HOME": NSHomeDirectory(), "USER": NSUserName()]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = FileHandle.nullDevice
        do {
            try proc.run()
            proc.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let raw = String(data: data, encoding: .utf8) ?? ""
            DebugLog.log("[ENV] resolve(\(name)) raw=\(raw.count)chars hex=\(raw.prefix(60).unicodeScalars.map { String(format: "%02x", $0.value) }.joined(separator: " "))")
            let stripped = Self.stripEscapeSequences(raw)
            DebugLog.log("[ENV] resolve(\(name)) stripped=\(stripped.count)chars")
            let val = stripped.trimmingCharacters(in: .whitespacesAndNewlines)
            DebugLog.log("[ENV] resolve(\(name)) final=\(val.count)chars last4=...\(val.suffix(4))")
            cache[name] = val
            return val.isEmpty ? nil : val
        } catch {
            DebugLog.log("[ENV] resolve(\(name)) FAIL: \(error)")
            cache[name] = ""
            return nil
        }
    }

    private static func stripEscapeSequences(_ s: String) -> String {
        var result = s
        let patterns = [
            "\\x1b\\][^\\x07\\x1b]*(\\x07|\\x1b\\\\)",  // OSC (iTerm2 shell integration etc.)
            "\\x1b\\[[0-9;]*[A-Za-z]",                    // CSI (color codes etc.)
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                result = regex.stringByReplacingMatches(
                    in: result, range: NSRange(result.startIndex..., in: result), withTemplate: "")
            }
        }
        return result
    }

    static func clearCache() {
        cache.removeAll()
    }
}
