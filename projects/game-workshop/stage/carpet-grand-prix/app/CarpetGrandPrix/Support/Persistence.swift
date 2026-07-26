//
//  Persistence.swift
//  Carpet Grand Prix
//
//  Best times, medals and ghosts live on the device. There is no account, no
//  server and no sync — a run you set on a train with no signal counts exactly
//  the same as one set at home.
//

import Foundation
import simd

// MARK: - Medals

enum Medal: Int, Comparable, Sendable {
    case none = 0, bronze, silver, gold, sprue

    static func < (a: Medal, b: Medal) -> Bool { a.rawValue < b.rawValue }

    var label: String {
        switch self {
        case .none:   return "—"
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold:   return "Gold"
        case .sprue:  return "Sprue"
        }
    }

    var symbol: String {
        switch self {
        case .none:   return "circle.dashed"
        case .bronze: return "3.circle.fill"
        case .silver: return "2.circle.fill"
        case .gold:   return "1.circle.fill"
        case .sprue:  return "star.circle.fill"
        }
    }

    static func earned(time: Double, thresholds: SIMD4<Double>) -> Medal {
        if time <= thresholds.w { return .sprue }
        if time <= thresholds.z { return .gold }
        if time <= thresholds.y { return .silver }
        if time <= thresholds.x { return .bronze }
        return .none
    }
}

// MARK: - Ghost

/// A recorded run, sampled at a fixed rate. We store *position* rather than
/// input, so a later change to the physics constants never silently invalidates
/// a stored time — the ghost still draws the line that was actually driven.
/// Raw tilt is kept alongside it for display only.
struct GhostFrame: Codable {
    var x: Float
    var y: Float
    var elevation: Float
    var height: Float
    var heading: Float
    var tiltX: Float
    var tiltY: Float
}

struct GhostRecording: Codable {
    var courseID: String
    var carID: String
    var time: Double
    var usedFallbackInput: Bool
    var frames: [GhostFrame]

    func frame(at t: Double) -> GhostFrame? {
        guard !frames.isEmpty else { return nil }
        let index = Int(t * Tuning.ghostHz)
        guard index >= 0 else { return frames.first }
        guard index < frames.count else { return frames.last }
        return frames[index]
    }
}

final class GhostRecorder {
    private var frames: [GhostFrame] = []
    private var accumulator: Double = 0

    func reset() {
        frames.removeAll(keepingCapacity: true)
        accumulator = 0
    }

    func record(_ state: CarState, elevation: Float, tilt: SIMD2<Float>, dt: Double) {
        accumulator += dt
        let interval = 1.0 / Tuning.ghostHz
        guard accumulator >= interval else { return }
        accumulator -= interval

        frames.append(GhostFrame(
            x: state.position.x,
            y: state.position.y,
            elevation: elevation,
            height: state.height,
            heading: state.heading,
            tiltX: tilt.x,
            tiltY: tilt.y))
    }

    func finish(courseID: String, carID: String, time: Double, fallback: Bool) -> GhostRecording {
        GhostRecording(courseID: courseID,
                       carID: carID,
                       time: time,
                       usedFallbackInput: fallback,
                       frames: frames)
    }
}

// MARK: - Store

@MainActor
final class Persistence {
    static let shared = Persistence()

    private let defaults = UserDefaults.standard
    private let ghostDirectory: URL

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask)[0]
        ghostDirectory = base.appendingPathComponent("Ghosts", isDirectory: true)
        try? FileManager.default.createDirectory(at: ghostDirectory,
                                                 withIntermediateDirectories: true)
    }

    // MARK: Best times

    private func bestKey(_ courseID: String) -> String { "best.\(courseID)" }

    func bestTime(for courseID: String) -> Double? {
        let value = defaults.double(forKey: bestKey(courseID))
        return value > 0 ? value : nil
    }

    func medal(for course: Course) -> Medal {
        guard let best = bestTime(for: course.id) else { return .none }
        return Medal.earned(time: best, thresholds: course.medalTimes)
    }

    var totalMedals: Int {
        Course.all.reduce(0) { $0 + medal(for: $1).rawValue }
    }

    /// Records a run. Returns true when it beat the stored best.
    @discardableResult
    func record(time: Double, for courseID: String) -> Bool {
        let previous = bestTime(for: courseID)
        guard previous == nil || time < previous! else { return false }
        defaults.set(time, forKey: bestKey(courseID))
        return true
    }

    // MARK: Ghosts

    private func ghostURL(_ courseID: String) -> URL {
        ghostDirectory.appendingPathComponent("\(courseID).json")
    }

    func loadGhost(for courseID: String) -> GhostRecording? {
        guard let data = try? Data(contentsOf: ghostURL(courseID)) else { return nil }
        return try? JSONDecoder().decode(GhostRecording.self, from: data)
    }

    func saveGhost(_ ghost: GhostRecording) {
        guard let data = try? JSONEncoder().encode(ghost) else { return }
        try? data.write(to: ghostURL(ghost.courseID), options: .atomic)
    }

    // MARK: Settings

    var selectedCarID: String {
        get { defaults.string(forKey: "car.selected") ?? CarSpec.starter.id }
        set { defaults.set(newValue, forKey: "car.selected") }
    }

    /// Parallax depth, 0...1. Decoupled from physics so reducing it for comfort
    /// never changes handling or lap times.
    var parallaxDepth: Double {
        get { defaults.object(forKey: "a11y.parallax") as? Double ?? 1.0 }
        set { defaults.set(newValue, forKey: "a11y.parallax") }
    }

    /// Degrees of tilt that count as full lock, 12...45.
    var tiltSensitivity: Double {
        get { defaults.object(forKey: "a11y.tilt") as? Double ?? Double(Tuning.fullLockDegrees) }
        set { defaults.set(newValue, forKey: "a11y.tilt") }
    }

    var vehicleMode: Bool {
        get { defaults.bool(forKey: "input.vehicleMode") }
        set { defaults.set(newValue, forKey: "input.vehicleMode") }
    }
}
