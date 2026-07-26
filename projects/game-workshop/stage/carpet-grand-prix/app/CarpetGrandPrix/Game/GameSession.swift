//
//  GameSession.swift
//  Carpet Grand Prix
//
//  Owns a run: the loaded course, the car, the clock, the camera and the input
//  source. The renderer drives it (`advance(dt:)` once per displayed frame) and
//  SwiftUI observes it for the HUD.
//
//  Physics runs on a fixed 120 Hz accumulator regardless of display rate, so a
//  time set on a 60 Hz iPhone is directly comparable to one set on a ProMotion
//  device.
//

import Foundation
import Combine
import simd

struct Camera {
    var position: SIMD2<Float> = .zero
    var elevation: Float = 0
}

struct RunResult: Equatable {
    let courseID: String
    let time: Double
    let penalty: Double
    let topSpeed: Float
    let falls: Int
    let boosts: Int
    let medal: Medal
    let previousBest: Double?
    let isNewBest: Bool

    var total: Double { time + penalty }
}

@MainActor
final class GameSession: ObservableObject {

    enum Phase: Equatable {
        case menu
        case countdown(remaining: Double)
        case racing
        case finished
    }

    // MARK: Published, for the HUD

    @Published private(set) var phase: Phase = .menu
    @Published private(set) var displayTime: Double = 0
    @Published private(set) var speedMPH: Int = 0
    @Published private(set) var progress: Double = 0
    @Published private(set) var banner: String?
    @Published private(set) var result: RunResult?
    @Published var course: Course = Course.all[0]
    @Published var carSpec: CarSpec = CarSpec.starter

    // MARK: Simulation

    private(set) var track: Track?
    private(set) var car = CarState()
    private(set) var camera = Camera()
    private(set) var ghostFrame: GhostFrame?

    let motion = MotionController()
    let fallback = FallbackController()

    private var ghost: GhostRecording?
    private let recorder = GhostRecorder()

    private var accumulator: Double = 0
    private var raceTime: Double = 0
    private var penalty: Double = 0
    private var topSpeed: Float = 0
    private var falls = 0
    private var boostCount = 0
    private var bannerExpiry: Double = 0
    private var elapsed: Double = 0

    /// Screen shake magnitude in points, decayed each frame.
    private(set) var shake: Float = 0

    /// Tilt actually being applied this frame.
    private(set) var tilt: SIMD2<Float> = .zero

    var usingFallbackInput: Bool { !motion.hasSignal }

    // MARK: - Setup

    func load(course: Course) {
        self.course = course
        track = Track.generate(for: course)
        ghost = Persistence.shared.loadGhost(for: course.id)
        carSpec = CarSpec.car(id: Persistence.shared.selectedCarID)
        resetToStart()
        phase = .menu
    }

    private func resetToStart() {
        guard let track, track.count > 4 else { return }
        let start = track.samples[2]

        car = CarState()
        car.position = start.position
        car.velocity = track.tangent(at: 2) * 40
        car.heading = start.heading
        car.sampleIndex = 2
        car.lastCheckpoint = 2

        camera = Camera(position: start.position, elevation: start.elevation)

        raceTime = 0
        penalty = 0
        topSpeed = 0
        falls = 0
        boostCount = 0
        accumulator = 0
        elapsed = 0
        displayTime = 0
        speedMPH = 0
        progress = 0
        banner = nil
        result = nil
        shake = 0
        recorder.reset()
        fallback.reset()
    }

    func startRun() {
        resetToStart()
        motion.start()
        motion.vehicleMode = Persistence.shared.vehicleMode
        motion.fullLockDegrees = Float(Persistence.shared.tiltSensitivity)
        motion.calibrate()
        phase = .countdown(remaining: 3.2)
    }

    func returnToMenu() {
        motion.stop()
        phase = .menu
        result = nil
    }

    func recentre() {
        guard case .racing = phase else { return }
        motion.calibrate()
        show(banner: "RE-CENTRED")
    }

    // MARK: - Per-frame

    func advance(dt displayDelta: Double) {
        let dt = min(displayDelta, 0.25)
        elapsed += dt

        switch phase {
        case .menu, .finished:
            decayShake(dt)
            return

        case .countdown(let remaining):
            updateInput(dt: dt)
            let next = remaining - dt
            if next <= 0 {
                phase = .racing
                show(banner: "GO!")
            } else {
                phase = .countdown(remaining: next)
                let whole = Int(ceil(next))
                if whole <= 3 { show(banner: "\(whole)", duration: 0.4) }
            }
            followCamera(dt: dt)
            decayShake(dt)
            return

        case .racing:
            break
        }

        guard let track else { return }

        // Fixed-step physics.
        accumulator += dt
        let step = Tuning.physicsStep
        var guardCounter = 0
        while accumulator >= step && guardCounter < 8 {
            accumulator -= step
            guardCounter += 1

            updateInput(dt: step)
            raceTime += step

            let events = Physics.step(&car,
                                      track: track,
                                      car: carSpec,
                                      tilt: tilt,
                                      dt: Float(step))
            handle(events)

            let elevation = track.samples[car.sampleIndex].elevation
            recorder.record(car, elevation: elevation, tilt: tilt, dt: step)

            topSpeed = max(topSpeed, car.speed)
            if case .finished = phase { break }
        }

        followCamera(dt: dt)
        decayShake(dt)
        updateHUD(track: track)
        updateGhost()
    }

    // MARK: - Input

    private func updateInput(dt: Double) {
        motion.update(dt: dt)
        if motion.hasSignal {
            tilt = motion.tilt
        } else {
            fallback.update(dt: dt)
            tilt = fallback.tilt
        }
    }

    // MARK: - Events

    private func handle(_ events: [RunEvent]) {
        for event in events {
            switch event {
            case .enteredBoost:
                boostCount += 1

            case .railStruck(let intensity):
                shake = max(shake, 2 + intensity * 4)

            case .launched:
                show(banner: "AIR!")

            case .landed(let hard):
                shake = max(shake, hard ? 8 : 4)

            case .fell:
                falls += 1
                penalty += Tuning.respawnPenalty
                show(banner: "OFF TRACK  +2.0s")
                shake = max(shake, 6)

            case .respawned:
                break

            case .finished:
                finish()
            }
        }
    }

    private func finish() {
        guard case .racing = phase else { return }
        phase = .finished
        motion.stop()

        let total = raceTime + penalty
        let previous = Persistence.shared.bestTime(for: course.id)
        let isNewBest = Persistence.shared.record(time: total, for: course.id)

        if isNewBest {
            let recording = recorder.finish(courseID: course.id,
                                            carID: carSpec.id,
                                            time: total,
                                            fallback: usingFallbackInput)
            Persistence.shared.saveGhost(recording)
            ghost = recording
        }

        result = RunResult(courseID: course.id,
                           time: raceTime,
                           penalty: penalty,
                           topSpeed: topSpeed,
                           falls: falls,
                           boosts: boostCount,
                           medal: Medal.earned(time: total, thresholds: course.medalTimes),
                           previousBest: previous,
                           isNewBest: isNewBest)
    }

    // MARK: - Camera, HUD, ghost

    private func followCamera(dt: Double) {
        guard let track else { return }
        let lead = car.position + car.velocity * Tuning.cameraLookahead
        let k = Float(1 - pow(Double(Tuning.cameraLag), dt))
        camera.position += (lead - camera.position) * k

        let targetElevation = track.samples[car.sampleIndex].elevation
        let ke = Float(1 - pow(Double(Tuning.cameraElevationLag), dt))
        camera.elevation += (targetElevation - camera.elevation) * ke
    }

    private func updateHUD(track: Track) {
        displayTime = raceTime + penalty
        speedMPH = Int((car.speed * Tuning.speedToMPH).rounded())
        progress = min(max(Double(car.sampleIndex) / Double(track.finishIndex), 0), 1)
        if elapsed > bannerExpiry { banner = nil }
    }

    private func updateGhost() {
        guard let ghost, case .racing = phase else { ghostFrame = nil; return }
        ghostFrame = ghost.frame(at: raceTime)
    }

    private func decayShake(_ dt: Double) {
        shake = max(0, shake - Float(dt) * 22)
    }

    private func show(banner text: String, duration: Double = 0.85) {
        banner = text
        bannerExpiry = elapsed + duration
    }
}
