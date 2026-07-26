//
//  Tuning.swift
//  Carpet Grand Prix
//
//  Every gameplay constant in one place. These are the numbers that decide how
//  the game feels; nothing here should be duplicated elsewhere in the codebase.
//

import Foundation
import simd

enum Tuning {

    // MARK: - Track geometry

    /// World units between track samples.
    static let sampleSpacing: Float = 32

    /// Resting height of the track deck above the carpet, in world units.
    static let baseDeckHeight: Float = 74

    /// How strongly a difference in physical elevation maps to visual height.
    /// This is what makes gradient readable: track ahead of you is lower.
    static let gradeReadout: Float = 0.5

    static let railHeight: Float = 27
    static let deckThickness: Float = 15
    static let postSpacing: Int = 5

    // MARK: - Input

    /// Tilt angle, in degrees, that counts as full authority.
    static let fullLockDegrees: Float = 32

    /// Same, in radians. Precomputed — writing `32 * .pi / 180` inline inside a
    /// SIMD initialiser makes the Swift type-checker fall over.
    static let fullLockRadians: Float = 32 * .pi / 180

    /// Gravity-vector delta that counts as full tilt authority. sin(32°).
    static let fullLockGravity: Float = 0.5299

    /// Clamp on normalised tilt, so overshooting past full lock still helps a little.
    static let tiltClamp: Float = 1.4

    /// Low-pass factor applied to the gravity vector, per 60 Hz tick.
    static let tiltSmoothing: Float = 0.16

    /// Window used by Vehicle Mode to re-estimate the rest pose, in seconds.
    static let vehicleModeWindow: Double = 4.0

    // MARK: - Forces

    /// Acceleration from tipping the handset, at full lock, in units/s².
    static let tableGravity: Float = 560

    /// Acceleration contributed by track gradient.
    static let slopeGravity: Float = 900

    static let dragLinear: Float = 0.85
    static let dragQuadratic: Float = 0.0016

    /// Rate at which tyres bleed off lateral velocity, per second.
    static let grip: Float = 5.0
    static let gripSticky: Float = 1.4

    static let boostAcceleration: Float = 620
    static let stickyDrag: Float = 2.6
    static let offTrackDrag: Float = 5.5

    static let wallRestitution: Float = 0.34
    static let wallScrub: Float = 0.80

    // MARK: - Car

    static let carHalfWidth: Float = 17
    static let carSpriteSize: Float = 26

    static let airTime: Float = 0.72
    static let airHeight: Float = 120
    static let rampMinSpeed: Float = 110

    static let respawnPenalty: Double = 2.0
    static let fallDuration: Float = 0.55

    /// Track samples between checkpoints.
    static let checkpointStride: Int = 28

    // MARK: - Camera

    /// How far ahead of the car the camera leads, in seconds of travel.
    static let cameraLookahead: Float = 0.42
    static let cameraLag: Float = 0.0015
    static let cameraElevationLag: Float = 0.02

    /// Baseline view angle, so raised surfaces read as raised even at rest.
    static let viewBaseline: Float = 0.46
    static let viewRollGain: Float = 0.80
    static let viewPitchGain: Float = 0.52

    // MARK: - Simulation

    /// Fixed physics tick. Decoupled from render so ghosts stay comparable
    /// across 60 Hz and 120 Hz devices.
    static let physicsHz: Double = 120
    static var physicsStep: Double { 1.0 / physicsHz }

    /// Ghost recording rate.
    static let ghostHz: Double = 40

    /// World units of visible track ahead of the car, expressed in samples.
    static let visibleAhead: Int = 46
    static let visibleBehind: Int = 16

    // MARK: - Presentation

    /// World units across the narrow axis of the screen.
    static let worldUnitsAcrossScreen: Float = 430

    /// Speed readout multiplier — toy scale, tuned for a satisfying number.
    static let speedToMPH: Float = 0.42
}
