//
//  Course.swift
//  Carpet Grand Prix
//
//  Course definitions and deterministic track generation.
//
//  A course always advances down-screen (+Y). That constraint is what makes the
//  control scheme legible: "tip the phone away from you" reliably means "go
//  faster", because the car's heading never strays more than ~54° from +Y. The
//  track weaves left and right and changes grade, but never doubles back.
//

import Foundation
import simd

// MARK: - Surface kinds

enum SurfaceKind: UInt8, Sendable {
    case plain
    case boost
    case sticky
    case ramp
    case open      // rail missing on one side — the only true hazard
}

// MARK: - Room theming

struct RoomTheme: Sendable {
    let floor: SIMD4<Float>
    let fleck: SIMD4<Float>
    let road: SIMD4<Float>
    let roadEdge: SIMD4<Float>
    let rail: SIMD4<Float>
    let ambient: SIMD4<Float>
    let vignette: Float
}

// MARK: - Course

struct Course: Identifiable, Sendable {
    let id: String
    let name: String
    let subtitle: String
    let room: String
    let seed: UInt32
    let length: Float
    let halfWidth: Float
    let theme: RoomTheme

    /// Medal thresholds in seconds: bronze, silver, gold, sprue.
    let medalTimes: SIMD4<Double>
}

extension Course {
    static let all: [Course] = [
        Course(
            id: "playroom-01",
            name: "Kitchen Cascade",
            subtitle: "Warm-up · wide lanes",
            room: "Kitchen",
            seed: 1337,
            length: 7200,
            halfWidth: 95,
            theme: RoomTheme(
                floor:    SIMD4(0.137, 0.165, 0.212, 1),
                fleck:    SIMD4(0.176, 0.212, 0.275, 1),
                road:     SIMD4(0.886, 0.400, 0.165, 1),
                roadEdge: SIMD4(0.659, 0.263, 0.102, 1),
                rail:     SIMD4(0.247, 0.725, 0.937, 1),
                ambient:  SIMD4(1.02, 0.99, 0.94, 1),
                vignette: 0.55),
            medalTimes: SIMD4(70, 58, 48, 42)),

        Course(
            id: "attic-01",
            name: "Attic Autobahn",
            subtitle: "Fast · long straights",
            room: "Attic",
            seed: 90210,
            length: 9600,
            halfWidth: 84,
            theme: RoomTheme(
                floor:    SIMD4(0.169, 0.145, 0.129, 1),
                fleck:    SIMD4(0.227, 0.196, 0.169, 1),
                road:     SIMD4(0.847, 0.627, 0.173, 1),
                roadEdge: SIMD4(0.588, 0.404, 0.078, 1),
                rail:     SIMD4(0.937, 0.435, 0.561, 1),
                ambient:  SIMD4(1.00, 0.95, 0.86, 1),
                vignette: 0.68),
            medalTimes: SIMD4(88, 74, 62, 55)),

        Course(
            id: "basement-01",
            name: "Basement Drop",
            subtitle: "Steep · narrow · gaps",
            room: "Basement",
            seed: 4242,
            length: 12000,
            halfWidth: 73,
            theme: RoomTheme(
                floor:    SIMD4(0.106, 0.129, 0.161, 1),
                fleck:    SIMD4(0.141, 0.176, 0.220, 1),
                road:     SIMD4(0.561, 0.416, 0.878, 1),
                roadEdge: SIMD4(0.361, 0.243, 0.639, 1),
                rail:     SIMD4(0.341, 0.898, 0.690, 1),
                ambient:  SIMD4(0.82, 0.86, 1.00, 1),
                vignette: 0.86),
            medalTimes: SIMD4(112, 94, 78, 68))
    ]

    static func course(id: String) -> Course? {
        all.first { $0.id == id }
    }
}

// MARK: - Deterministic RNG

/// mulberry32 — small, fast, and identical across platforms, so a seed always
/// produces the same course. Track layout is never persisted, only the seed.
struct Mulberry32 {
    private var state: UInt32

    init(seed: UInt32) { state = seed }

    mutating func next() -> Float {
        state = state &+ 0x6D2B79F5
        var t = state
        t = (t ^ (t >> 15)) &* (t | 1)
        t ^= t &+ (t ^ (t >> 7)) &* (t | 61)
        return Float((t ^ (t >> 14)) & 0xFFFFFF) / Float(0x1000000)
    }

    mutating func next(in range: ClosedRange<Float>) -> Float {
        range.lowerBound + next() * (range.upperBound - range.lowerBound)
    }

    mutating func nextInt(_ upperExclusive: Int) -> Int {
        Int(next() * Float(upperExclusive)) % max(upperExclusive, 1)
    }
}

// MARK: - Track

struct TrackSample {
    var position: SIMD2<Float>
    var elevation: Float
    var heading: Float
    var halfWidth: Float
    var distance: Float
    var kind: SurfaceKind
    /// Which side the rail is missing on: -1, 0 or +1.
    var openSide: Float
}

struct Track {
    let course: Course
    let samples: [TrackSample]

    var count: Int { samples.count }

    // MARK: Generation

    static func generate(for course: Course) -> Track {
        var rng = Mulberry32(seed: course.seed)
        var samples: [TrackSample] = []
        samples.reserveCapacity(Int(course.length / Tuning.sampleSpacing) + 2)

        let ds = Tuning.sampleSpacing
        var position = SIMD2<Float>(0, 0)
        var elevation: Float = 0
        var heading: Float = .pi / 2      // +Y, straight down the screen

        var targetHeading = heading
        var turnCountdown = 0
        var grade: Float = 0.14
        var gradeCountdown = 0
        var distance: Float = 0

        while distance < course.length {
            if turnCountdown <= 0 {
                // Stay within ±54° of "down" so tilt-forward always means faster.
                targetHeading = .pi / 2 + rng.next(in: -0.95...0.95)
                turnCountdown = 8 + rng.nextInt(17)
            }
            if gradeCountdown <= 0 {
                grade = rng.next(in: 0.06...0.30)
                gradeCountdown = 10 + rng.nextInt(22)
            }

            heading += (targetHeading - heading) * 0.11
            position += SIMD2(cos(heading), sin(heading)) * ds
            elevation -= grade * ds

            // Pinch the lane through the twistier sections.
            let twist = abs(heading - .pi / 2)
            let halfWidth = course.halfWidth * (1 - min(twist * 0.22, 0.26))

            samples.append(TrackSample(
                position: position,
                elevation: elevation,
                heading: heading,
                halfWidth: halfWidth,
                distance: distance,
                kind: .plain,
                openSide: 0))

            distance += ds
            turnCountdown -= 1
            gradeCountdown -= 1
        }

        decorate(&samples, rng: &rng)
        return Track(course: course, samples: samples)
    }

    /// Scatter surface features with a guaranteed gap between them, so the
    /// player always gets clean track to recover on.
    private static func decorate(_ samples: inout [TrackSample], rng: inout Mulberry32) {
        var i = 46
        while i < samples.count - 70 {
            let roll = rng.next()
            let kind: SurfaceKind
            let span: Int

            switch roll {
            case ..<0.34: kind = .boost;  span = 5 + rng.nextInt(5)
            case ..<0.60: kind = .sticky; span = 5 + rng.nextInt(7)
            case ..<0.80: kind = .ramp;   span = 3
            default:      kind = .open;   span = 7 + rng.nextInt(8)
            }

            let side: Float = rng.next() < 0.5 ? -1 : 1
            for k in 0..<span where i + k < samples.count {
                samples[i + k].kind = kind
                if kind == .open { samples[i + k].openSide = side }
            }

            i += span + 24 + rng.nextInt(46)
        }
    }

    // MARK: Queries

    /// Nearest sample index, searched outward from a hint. The car only moves a
    /// sample or two per tick, so this stays O(1) in practice.
    func nearestIndex(to point: SIMD2<Float>, hint: Int) -> Int {
        let lo = max(1, hint - 24)
        let hi = min(count - 2, hint + 60)
        guard lo <= hi else { return min(max(hint, 1), count - 2) }

        var best = lo
        var bestDistance = Float.greatestFiniteMagnitude
        for i in lo...hi {
            let d = simd_length_squared(samples[i].position - point)
            if d < bestDistance { bestDistance = d; best = i }
        }
        return best
    }

    func tangent(at index: Int) -> SIMD2<Float> {
        let a = samples[max(0, index - 1)].position
        let b = samples[min(count - 1, index + 1)].position
        let d = b - a
        let m = simd_length(d)
        return m > 0 ? d / m : SIMD2(0, 1)
    }

    func normal(at index: Int) -> SIMD2<Float> {
        let t = tangent(at: index)
        return SIMD2(-t.y, t.x)
    }

    /// Positive when the track is descending.
    func grade(at index: Int) -> Float {
        let a = samples[max(0, index - 1)].elevation
        let b = samples[min(count - 1, index + 1)].elevation
        return -(b - a) / (2 * Tuning.sampleSpacing)
    }

    var finishIndex: Int { count - 4 }
}
