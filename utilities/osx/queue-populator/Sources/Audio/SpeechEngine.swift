import Foundation
import AVFoundation
import AudioToolbox
import CoreAudio
import Speech

enum SpeechEngineStartResult: Sendable {
    case started(String)
    case alreadyRunning
    case failed(String)
}

protocol SpeechEngineDelegate: AnyObject, Sendable {
    @MainActor func speechEngine(_ engine: SpeechEngine, didReceivePartial text: String)
    @MainActor func speechEngine(_ engine: SpeechEngine, didFinalize text: String)
    @MainActor func speechEngine(_ engine: SpeechEngine, didReceiveRecognitionError message: String)
}

/// Continuous speech capture built around SFSpeechRecognizer's bounded task lifetime.
///
/// The audio engine and mic tap stay alive for the whole session; only the
/// recognition request/task rotates. The tap reads `activeRequest` through a lock
/// so a rotation never opens a gap in the audio feed (which also feeds the memo
/// recorder and virtual mics). Recognition tasks that end in an error — routine
/// for long recordings — flush their un-finalized partial into the transcript and
/// rotate to a fresh task instead of stopping capture.
final class SpeechEngine: @unchecked Sendable {
    private let audioEngine = AVAudioEngine()
    private let recognizer: SFSpeechRecognizer
    private let requestLock = NSLock()
    private var activeRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var tapInstalled: Bool = false
    private let onDevice: Bool
    private let inputDeviceId: String?
    private let verbose: Bool
    private var didReportFirstRecognitionCallback: Bool = false
    private(set) var isRunning: Bool = false

    // MainActor-confined recognition bookkeeping. `generation` invalidates
    // callbacks from superseded tasks; `pendingPartial` is the not-yet-final
    // text of the current task, flushed as a final on rotation/teardown.
    private var generation: Int = 0
    private var pendingPartial: String = ""
    private var taskStartedAt: Date = Date()
    private var rapidFailureCount: Int = 0

    /// Format of the live mic input, available once recognition has started.
    private(set) var currentInputFormat: AVAudioFormat?

    /// Optional sink for raw mic buffers (used to route audio to virtual devices).
    /// Invoked on the audio render thread for every captured buffer.
    var onAudioBuffer: (@Sendable (AVAudioPCMBuffer) -> Void)?

    weak var delegate: SpeechEngineDelegate?

    init(locale: String = "en-US", onDevice: Bool = true, inputDeviceId: String? = nil, verbose: Bool = false) {
        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: locale))!
        self.onDevice = onDevice
        self.inputDeviceId = inputDeviceId
        self.verbose = verbose
    }

    @discardableResult
    @MainActor
    func start() -> SpeechEngineStartResult {
        guard !isRunning else { return .alreadyRunning }
        isRunning = true
        do {
            let inputDescription = try startAudio()
            beginRecognitionTask()
            return .started(inputDescription)
        } catch {
            isRunning = false
            teardown()
            let message = error.localizedDescription
            fputs("error: failed to start audio: \(message)\n", stderr)
            return .failed(message)
        }
    }

    @MainActor
    func stop() {
        isRunning = false
        teardown()
    }

    // MARK: - Audio engine (lives for the whole session)

    private func startAudio() throws -> String {
        let inputNode = audioEngine.inputNode
        let inputDescription = try configureInputDeviceIfNeeded(on: inputNode)
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        self.currentInputFormat = recordingFormat

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self else { return }
            self.requestLock.lock()
            let request = self.activeRequest
            self.requestLock.unlock()
            request?.append(buffer)
            self.onAudioBuffer?(buffer)
        }
        tapInstalled = true

        audioEngine.prepare()
        try audioEngine.start()
        return "\(inputDescription), \(Int(recordingFormat.sampleRate)) Hz, \(Int(recordingFormat.channelCount)) channel(s)"
    }

    // MARK: - Recognition task rotation

    @MainActor
    private func beginRecognitionTask() {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = onDevice

        requestLock.lock()
        activeRequest = request
        requestLock.unlock()

        generation += 1
        let taskGeneration = generation
        taskStartedAt = Date()
        pendingPartial = ""

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if !self.didReportFirstRecognitionCallback {
                self.didReportFirstRecognitionCallback = true
                Task { @MainActor [weak self] in
                    guard let self, self.isRunning else { return }
                    self.delegate?.speechEngine(self, didReceiveRecognitionError: "Speech recognizer callback received")
                }
            }

            if let result {
                let transcript = result.bestTranscription.formattedString
                let isFinal = result.isFinal

                if self.verbose {
                    fputs("  [partial] \(transcript.lowercased())\n", stderr)
                }

                Task { @MainActor [weak self] in
                    guard let self, self.isRunning, taskGeneration == self.generation else { return }
                    if isFinal {
                        self.pendingPartial = ""
                        self.rapidFailureCount = 0
                        self.delegate?.speechEngine(self, didFinalize: transcript)
                        self.rotateRecognitionTask()
                    } else {
                        self.pendingPartial = transcript
                        self.delegate?.speechEngine(self, didReceivePartial: transcript)
                    }
                }
            }

            if let error {
                let message = error.localizedDescription
                Task { @MainActor [weak self] in
                    guard let self, self.isRunning, taskGeneration == self.generation else { return }
                    self.handleTaskError(message)
                }
            }
        }
    }

    /// Swap in a fresh request/task with no gap: the new request goes live for
    /// the tap before the old task is cancelled, and any text the old task never
    /// finalized is flushed into the transcript first.
    @MainActor
    private func rotateRecognitionTask() {
        guard isRunning else { return }
        flushPendingPartial()
        let oldTask = recognitionTask
        let oldRequest = requestLock.withLock { activeRequest }
        beginRecognitionTask()
        oldRequest?.endAudio()
        oldTask?.cancel()
    }

    /// Recognition tasks routinely die with errors on long audio (timeouts,
    /// silence detection). Keep capturing: flush what we have and rotate.
    /// Only give up after repeated immediate failures (recognizer genuinely
    /// unavailable), so the coordinator can surface the error and pause.
    @MainActor
    private func handleTaskError(_ message: String) {
        guard isRunning else { return }

        let taskUptime = Date().timeIntervalSince(taskStartedAt)
        if taskUptime < 2.0 {
            rapidFailureCount += 1
        } else {
            rapidFailureCount = 0
        }

        if rapidFailureCount >= 5 {
            delegate?.speechEngine(self, didReceiveRecognitionError: message)
            stop()
            return
        }

        if verbose {
            fputs("  [speech] recognition task ended (\(message)); rotating\n", stderr)
        }
        rotateRecognitionTask()
    }

    @MainActor
    private func flushPendingPartial() {
        let text = pendingPartial
        pendingPartial = ""
        guard !text.isEmpty else { return }
        delegate?.speechEngine(self, didFinalize: text)
    }

    @MainActor
    private func teardown() {
        generation += 1
        pendingPartial = ""
        rapidFailureCount = 0
        audioEngine.stop()
        if tapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        let request = requestLock.withLock {
            let request = activeRequest
            activeRequest = nil
            return request
        }
        request?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
    }

    private func configureInputDeviceIfNeeded(on inputNode: AVAudioInputNode) throws -> String {
        guard let inputDeviceId, !inputDeviceId.isEmpty else { return "system default input" }
        guard let audioUnit = inputNode.audioUnit else { return "system default input" }

        var deviceId = AudioDeviceID(0)
        var deviceSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var deviceUid = inputDeviceId as CFString
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDeviceForUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let lookupStatus = withUnsafePointer(to: &deviceUid) { uidPointer in
            AudioObjectGetPropertyData(
                AudioObjectID(kAudioObjectSystemObject),
                &address,
                UInt32(MemoryLayout<CFString>.size),
                uidPointer,
                &deviceSize,
                &deviceId
            )
        }
        guard lookupStatus == noErr else { return "configured input lookup failed (\(lookupStatus)); using system default input" }

        var selectedDeviceId = deviceId
        let setStatus = AudioUnitSetProperty(
            audioUnit,
            kAudioOutputUnitProperty_CurrentDevice,
            kAudioUnitScope_Global,
            0,
            &selectedDeviceId,
            UInt32(MemoryLayout<AudioDeviceID>.size)
        )
        guard setStatus == noErr else { return "configured input select failed (\(setStatus)); using system default input" }
        return "configured input \(inputDeviceId)"
    }
}
