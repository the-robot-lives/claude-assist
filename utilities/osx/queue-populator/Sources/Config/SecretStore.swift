import Foundation

enum SecretStore {
    private static let dcBin = "\(NSHomeDirectory())/.local/bin/dc"

    static func encrypt(_ plaintext: String) -> String? {
        guard FileManager.default.isExecutableFile(atPath: dcBin) else {
            fputs("queue-populator: dc not found at \(dcBin)\n", stderr)
            return nil
        }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: dcBin)
        proc.arguments = ["encrypt", "--value", plaintext]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = FileHandle.nullDevice
        do {
            try proc.run()
            proc.waitUntilExit()
            guard proc.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let token = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return token.isEmpty ? nil : token
        } catch {
            fputs("queue-populator: dc encrypt failed: \(error)\n", stderr)
            return nil
        }
    }

    static func decrypt(_ token: String) -> String? {
        guard FileManager.default.isExecutableFile(atPath: dcBin) else {
            fputs("queue-populator: dc not found at \(dcBin)\n", stderr)
            return nil
        }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: dcBin)
        proc.arguments = ["decrypt", token]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = FileHandle.nullDevice
        do {
            try proc.run()
            proc.waitUntilExit()
            guard proc.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let plain = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return plain.isEmpty ? nil : plain
        } catch {
            fputs("queue-populator: dc decrypt failed: \(error)\n", stderr)
            return nil
        }
    }

    static func isEncrypted(_ value: String) -> Bool {
        value.hasPrefix("🔒:v1:")
    }

    static func generateAlias() -> String {
        let adjectives = [
            "amber", "azure", "bold", "calm", "coral", "dark", "deep",
            "fair", "fell", "gold", "gray", "hale", "high", "iron",
            "jade", "keen", "last", "lone", "mild", "moss", "nova",
            "opal", "pale", "pine", "pure", "rare", "rose", "ruby",
            "sage", "silk", "soft", "star", "teal", "true", "vast",
            "warm", "wild", "wise", "wren", "zinc",
        ]
        let nouns = [
            "arch", "bark", "bell", "bird", "bone", "cape", "cask",
            "claw", "dawn", "dell", "dove", "dusk", "edge", "fawn",
            "fern", "fish", "ford", "gate", "glen", "gull", "hawk",
            "haze", "hill", "isle", "jade", "keel", "knot", "lake",
            "leaf", "lynx", "mist", "moon", "moth", "moss", "nest",
            "owl", "palm", "peak", "pine", "pool", "rain", "reef",
            "sage", "seal", "snow", "star", "tide", "vale", "vine",
            "wren",
        ]
        func pick(_ list: [String]) -> String {
            list[Int.random(in: 0..<list.count)]
        }
        return "\(pick(adjectives))-\(pick(nouns))-\(pick(nouns))"
    }
}
