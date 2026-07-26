//
//  MotionController.swift
//  Carpet Grand Prix
//
//  Reads the handset's orientation and turns it into a single normalised tilt
//  vector that drives both the physics and the parallax.
//
//  We use CoreMotion's fused `gravity` vector rather than Euler angles. Gravity
//  is exactly the quantity the fiction needs — "which way is down, relative to
//  the phone" — and it has no gimbal degeneracy, no wrap-around at ±180°, and no
//  axis-remapping headache. Euler pitch/roll would give us all three problems for
//  no benefit.
//
//  Device frame in portrait:
//      +X -> right edge of the screen
//      +Y -> top edge of the screen
//      +Z -> out of the screen toward the user
//
//  Screen space has +Y pointing *down*, so the Y channel is negated.
//

import Foundation
import CoreMotion
import simd

@MainActor
final class MotionController: ObservableObject {

    enum Availability {
        case active
        case unavailable          // no gyro in this device
        case notStarted
    }

    @Published private(set) var availability: Availability = .notStarted

    /// Normalised tilt relative to the captured rest pose.
    /// (+X = rolled right, +Y = tipped away from the player.)
    private(set) var tilt: SIMD2<Float> = .zero

    /// Set when the player is riding in a vehicle; re-estimates the rest pose
    /// from a rolling average so a train's motion does not read as steering.
    var vehicleMode: Bool = false {
        didSet { restAverage = nil }
    }

    private let manager = CMMotionManager()
    private var restPose: SIMD2<Float>?
    private var smoothed: SIMD2<Float> = .zero
    private var restAverage: SIMD2<Float>?

    /// True once at least one sample has arrived.
    private(set) var hasSignal = false

    // MARK: - Lifecycle

    func start() {
        guard manager.isDeviceMotionAvailable else {
            availability = .unavailable
            return
        }
        guard !manager.isDeviceMotionActive else { return }

        manager.deviceMotionUpdateInterval = 1.0 / Tuning.physicsHz
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical)
        availability = .active
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        availability = .notStarted
    }

    /// Capture the current pose as neutral. Called at the start of every run and
    /// whenever the player taps to re-centre.
    func calibrate() {
        guard let raw = rawGravity() else { return }
        restPose = raw
        restAverage = raw
        smoothed = .zero
        tilt = .zero
    }

    // MARK: - Per-tick update

    /// Pull the latest sample and fold it into the smoothed tilt. Called once
    /// per physics tick so the filter runs at a fixed rate.
    func update(dt: Double) {
        guard let raw = rawGravity() else { return }
        hasSignal = true

        if restPose == nil { restPose = raw; restAverage = raw }
        guard var rest = restPose else { return }

        if vehicleMode {
            // Track the slow-moving component of gravity and treat it as level.
            let alpha = Float(min(dt / Tuning.vehicleModeWindow, 1))
            let previous = restAverage ?? raw
            let updated = previous + (raw - previous) * alpha
            restAverage = updated
            rest = updated
        }

        // Screen-space gravity delta. Y is negated: device +Y points up the
        // screen, world +Y points down it.
        let delta = SIMD2<Float>(raw.x - rest.x, -(raw.y - rest.y))
        let normalised = delta / Tuning.fullLockGravity

        smoothed += (normalised - smoothed) * Tuning.tiltSmoothing
        tilt = simd_clamp(smoothed,
                          SIMD2(repeating: -Tuning.tiltClamp),
                          SIMD2(repeating: Tuning.tiltClamp))
    }

    // MARK: - Private

    private func rawGravity() -> SIMD2<Float>? {
        guard let motion = manager.deviceMotion else { return nil }
        return SIMD2(Float(motion.gravity.x), Float(motion.gravity.y))
    }
}

// MARK: - Keyboard / touch fallback

/// Used on the Simulator and on devices without a usable gyro, so the game is
/// always driveable. Runs are still timed but are flagged in the ghost record.
final class FallbackController {
    private(set) var tilt: SIMD2<Float> = .zero
    var target: SIMD2<Float> = .zero

    func update(dt: Double) {
        let k = Float(1 - pow(0.001, dt))
        tilt += (target - tilt) * k
    }

    func reset() {
        tilt = .zero
        target = .zero
    }
}
