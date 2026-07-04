import Foundation
import AVFoundation

final class MemoAudioRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var file: AVAudioFile?
    private var tempURL: URL?
    private var outputURL: URL?
    private var wroteAudio = false

    var isRecording: Bool {
        lock.withLock { file != nil }
    }

    func start(format: AVAudioFormat?, outputDirectory: URL) throws -> URL {
        guard let format else {
            throw MemoAudioRecorderError.missingFormat
        }

        let timestamp = Self.timestamp()
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("queue-populator-\(timestamp).caf")
        let output = outputDirectory
            .appendingPathComponent("memo-\(timestamp).mp3")

        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )
        try? FileManager.default.removeItem(at: temp)
        try? FileManager.default.removeItem(at: output)

        let audioFile = try AVAudioFile(forWriting: temp, settings: format.settings)

        lock.withLock {
            file = audioFile
            tempURL = temp
            outputURL = output
            wroteAudio = false
        }

        return output
    }

    func append(_ buffer: AVAudioPCMBuffer) {
        lock.withLock {
            guard let file else { return }
            do {
                try file.write(from: buffer)
                wroteAudio = true
            } catch {
                fputs("memo-audio: failed to write buffer: \(error.localizedDescription)\n", stderr)
            }
        }
    }

    func stopAndExport() throws -> URL? {
        // The AVAudioFile must deinit inside this block so its tail buffers are
        // flushed to disk before the encoders below read the temp file.
        let state: (hadFile: Bool, temp: URL?, output: URL?, wrote: Bool) = lock.withLock {
            let result = (file != nil, tempURL, outputURL, wroteAudio)
            file = nil
            tempURL = nil
            outputURL = nil
            wroteAudio = false
            return result
        }

        guard state.hadFile, let temp = state.temp, let output = state.output else {
            return nil
        }

        guard state.wrote else {
            try? FileManager.default.removeItem(at: temp)
            return nil
        }

        defer { try? FileManager.default.removeItem(at: temp) }

        // CoreAudio cannot encode MP3, so real .mp3 output needs lame.
        if let lame = Self.lamePath() {
            do {
                try Self.encodeMP3(input: temp, output: output, lame: lame)
                return output
            } catch {
                try? FileManager.default.removeItem(at: output)
                fputs("memo-audio: lame encode failed (\(error.localizedDescription)); falling back to AAC\n", stderr)
            }
        } else {
            fputs("memo-audio: lame not found; saving AAC .m4a instead of .mp3\n", stderr)
        }

        let m4a = output.deletingPathExtension().appendingPathExtension("m4a")
        do {
            try? FileManager.default.removeItem(at: m4a)
            try Self.run("/usr/bin/afconvert", ["-f", "m4af", "-d", "aac", temp.path, m4a.path])
            return m4a
        } catch {
            fputs("memo-audio: AAC fallback failed (\(error.localizedDescription)); salvaging raw audio\n", stderr)
        }

        // Last resort: keep the raw capture so the recording is never lost.
        let caf = output.deletingPathExtension().appendingPathExtension("caf")
        try? FileManager.default.removeItem(at: caf)
        try FileManager.default.copyItem(at: temp, to: caf)
        return caf
    }

    func cancel() {
        let temp = lock.withLock {
            let temp = tempURL
            file = nil
            tempURL = nil
            outputURL = nil
            wroteAudio = false
            return temp
        }
        if let temp {
            try? FileManager.default.removeItem(at: temp)
        }
    }

    private static func lamePath() -> String? {
        let candidates = ["/opt/homebrew/bin/lame", "/usr/local/bin/lame", "/usr/bin/lame"]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    // lame cannot read CAF, so hop through a 16-bit WAV.
    private static func encodeMP3(input: URL, output: URL, lame: String) throws {
        let wav = input.deletingPathExtension().appendingPathExtension("wav")
        defer { try? FileManager.default.removeItem(at: wav) }
        try run("/usr/bin/afconvert", ["-f", "WAVE", "-d", "LEI16", input.path, wav.path])
        try? FileManager.default.removeItem(at: output)
        try run(lame, ["--quiet", "-b", "128", wav.path, output.path])
    }

    private static func run(_ tool: String, _ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool)
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw MemoAudioRecorderError.exportFailed(Int(process.terminationStatus))
        }
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }
}

enum MemoAudioRecorderError: LocalizedError {
    case missingFormat
    case exportFailed(Int)

    var errorDescription: String? {
        switch self {
        case .missingFormat:
            "Live microphone format is not available yet."
        case .exportFailed(let status):
            "MP3 export failed with status \(status)."
        }
    }
}
