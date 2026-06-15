import Foundation

enum DebugLog {
    private static let logFile: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/queue-populator/debug.log")

    private static let handle: FileHandle? = {
        let fm = FileManager.default
        let dir = logFile.deletingLastPathComponent()
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        if !fm.fileExists(atPath: logFile.path) {
            fm.createFile(atPath: logFile.path, contents: nil)
        }
        // Truncate on launch so the log is fresh each run
        if let h = try? FileHandle(forWritingTo: logFile) {
            h.truncateFile(atOffset: 0)
            return h
        }
        return nil
    }()

    static func log(_ message: String) {
        let ts = ISO8601DateFormatter().string(from: Date())
        let line = "[\(ts)] \(message)\n"
        fputs(line, stderr)
        if let data = line.data(using: .utf8) {
            handle?.write(data)
        }
    }
}
