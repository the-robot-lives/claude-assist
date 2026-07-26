//
//  Physics.swift
//  Carpet Grand Prix
//
//  Fixed-timestep car simulation.
//
//  The model is deliberately simple: the handset is the table the track is
//  bolted to. Tilt produces a gravity vector in world space, the track's own
//  gradient adds a component along the tangent, and the tyres bleed off lateral
//  velocity so the car carves instead of sliding like a marble.
//
//  Nothing here touches Metal, CoreMotion or SwiftUI — it is pure and testable.
//

import Foundation
import simd

// MARK: - State

struct CarState {
    var position: SIMD2<Float> = .zero
    var velocity: SIMD2<Float> = .zero
    var heading: Float = .pi / 2

    var sampleIndex: Int = 2
    var lateral: Float = 0

    /// Remaining airborne time; 0 when the wheels are down.
    var airborne: Float = 0
    /// Height above the deck, in world units.
    var height: Float = 0

    /// Remaining fall animation before respawn.
    var falling: Float = 0
    var lastCheckpoint: Int = 2

    var speed: Float { simd_length(velocity) }
}

/// Things the presentation layer wants to know about, emitted per tick.
enum RunEvent: Equatable {
    case enteredBoost
    case railStruck(intensity: Float)
    case launched
    case landed(hard: Bool)
    case fell
    case respawned
    case finished
}

// MARK: - Simulation

enum Physics {

    /// Advance the simulation by one fixed step.
    ///
    /// - Parameters:
    ///   - tilt: normalised handset tilt, +X right, +Y toward the bottom of the
    ///           screen. Magnitude 1 is full lock.
    static func step(_ state: inout CarState,
                     track: Track,
                     car: CarSpec,
                     tilt: SIMD2<Float>,
                     dt: Float) -> [RunEvent]
    {
        var events: [RunEvent] = []

        // ---- falling / respawn ------------------------------------------
        if state.falling > 0 {
            state.falling -= dt
            state.height -= 900 * dt
            if state.falling <= 0 {
                let sample = track.samples[state.lastCheckpoint]
                let tangent = track.tangent(at: state.lastCheckpoint)
                state.position = sample.position
                state.velocity = tangent * 70
                state.height = 0
                state.airborne = 0
                state.sampleIndex = state.lastCheckpoint
                events.append(.respawned)
            }
            return events
        }

        state.sampleIndex = track.nearestIndex(to: state.position, hint: state.sampleIndex)
        let index = state.sampleIndex
        let sample = track.samples[index]
        let tangent = track.tangent(at: index)
        let normal = SIMD2<Float>(-tangent.y, tangent.x)

        let lateral = simd_dot(state.position - sample.position, normal)
        state.lateral = lateral

        let grounded = state.airborne <= 0
        let onTrack = abs(lateral) < sample.halfWidth + 6
        let sticky = grounded && onTrack && sample.kind == .sticky && !car.immuneToSticky

        // ---- forces ------------------------------------------------------
        // 1. the handset as a tilting table
        let clamped = simd_clamp(tilt,
                                 SIMD2(repeating: -Tuning.tiltClamp),
                                 SIMD2(repeating: Tuning.tiltClamp))
        let tiltAngle = clamped * Tuning.fullLockRadians
        var acceleration = SIMD2<Float>(sin(tiltAngle.x), sin(tiltAngle.y))
        acceleration *= Tuning.tableGravity * car.gravityAuthority

        // 2. the gradient of the track, only while the wheels are down
        if grounded && onTrack {
            acceleration += tangent * (track.grade(at: index) * Tuning.slopeGravity)

            if sample.kind == .boost {
                acceleration += tangent * (Tuning.boostAcceleration * car.boostFactor)
                events.append(.enteredBoost)
            }
        }

        state.velocity += acceleration * dt

        // ---- drag ---------------------------------------------------------
        var linear = Tuning.dragLinear * car.dragFactor
        var quadratic = Tuning.dragQuadratic * car.dragFactor
        if sticky { linear += Tuning.stickyDrag }
        if !onTrack && grounded {
            linear += Tuning.offTrackDrag
            quadratic += 0.006
        }

        let speed = simd_length(state.velocity)
        if speed > 0.001 {
            let factor = max(0, 1 - (linear + quadratic * speed) * dt)
            state.velocity *= factor
        }

        // ---- tyre grip ----------------------------------------------------
        if grounded {
            let along = simd_dot(state.velocity, tangent)
            var cross = simd_dot(state.velocity, normal)
            let grip = (sticky ? Tuning.gripSticky : Tuning.grip) * car.gripFactor
            cross *= exp(-grip * dt)
            state.velocity = tangent * along + normal * cross
        }

        state.position += state.velocity * dt

        // ---- ramps --------------------------------------------------------
        if grounded && onTrack && sample.kind == .ramp && speed > Tuning.rampMinSpeed {
            state.airborne = Tuning.airTime
            events.append(.launched)
        }

        if state.airborne > 0 {
            state.airborne -= dt
            let t = 1 - simd_clamp(state.airborne / Tuning.airTime, 0, 1)
            state.height = sin(t * .pi) * Tuning.airHeight
            if state.airborne <= 0 {
                state.height = 0
                // A landing that is not pointing down the track scrubs speed.
                let alignment = abs(simd_dot(simd_normalize(state.velocity), tangent))
                let hard = alignment < 0.82
                if hard { state.velocity *= 0.78 }
                events.append(.landed(hard: hard))
            }
        } else {
            state.height = 0
        }

        // ---- rails and open edges ------------------------------------------
        if state.airborne <= 0 {
            let limit = sample.halfWidth - car.halfWidth
            if abs(lateral) > limit {
                let side: Float = lateral < 0 ? -1 : 1
                let openHere = sample.kind == .open && sample.openSide == side

                if openHere && abs(lateral) > sample.halfWidth + 30 {
                    state.falling = Tuning.fallDuration
                    events.append(.fell)
                    return events
                }

                if !openHere {
                    let over = abs(lateral) - limit
                    state.position -= normal * (over * side)

                    let along = simd_dot(state.velocity, tangent)
                    let cross = -simd_dot(state.velocity, normal) * Tuning.wallRestitution
                    let scrub = 1 - (1 - Tuning.wallScrub) * car.railPenalty
                    state.velocity = tangent * (along * max(scrub, 0.3)) + normal * cross
                    events.append(.railStruck(intensity: min(over / 40, 1)))
                }
            }
        }

        // ---- bookkeeping -----------------------------------------------------
        if state.speed > 6 {
            let target = atan2(state.velocity.y, state.velocity.x)
            state.heading = lerpAngle(state.heading, target, 1 - pow(0.0008, dt))
        }

        if index > state.lastCheckpoint + Tuning.checkpointStride,
           abs(lateral) < sample.halfWidth {
            state.lastCheckpoint = index - 4
        }

        if index >= track.finishIndex {
            events.append(.finished)
        }

        return events
    }

    static func lerpAngle(_ a: Float, _ b: Float, _ t: Float) -> Float {
        var delta = (b - a).truncatingRemainder(dividingBy: .pi * 2)
        if delta > .pi { delta -= .pi * 2 }
        if delta < -.pi { delta += .pi * 2 }
        return a + delta * t
    }
}
