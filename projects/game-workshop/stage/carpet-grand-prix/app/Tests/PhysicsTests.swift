//
//  PhysicsTests.swift
//  Carpet Grand Prix
//
//  The simulation is pure — no Metal, no CoreMotion, no clock — so the parts
//  that decide whether a time is legitimate can be tested directly.
//

import XCTest
import simd
@testable import CarpetGrandPrix

final class TrackGenerationTests: XCTestCase {

    func testGenerationIsDeterministic() {
        let course = Course.all[0]
        let a = Track.generate(for: course)
        let b = Track.generate(for: course)

        XCTAssertEqual(a.count, b.count)
        for i in stride(from: 0, to: a.count, by: 17) {
            XCTAssertEqual(a.samples[i].position.x, b.samples[i].position.x, accuracy: 0.0001)
            XCTAssertEqual(a.samples[i].position.y, b.samples[i].position.y, accuracy: 0.0001)
            XCTAssertEqual(a.samples[i].elevation, b.samples[i].elevation, accuracy: 0.0001)
            XCTAssertEqual(a.samples[i].kind, b.samples[i].kind)
        }
    }

    /// The control scheme only reads as "tip away = go faster" because the
    /// course never turns back up the screen. This is a load-bearing invariant.
    func testCourseAlwaysAdvancesDownScreen() {
        for course in Course.all {
            let track = Track.generate(for: course)
            for sample in track.samples {
                let heading = sample.heading
                let delta = abs(heading - .pi / 2)
                XCTAssertLessThan(delta, 1.1,
                                  "\(course.name) heads more than ~63° off +Y")
            }
        }
    }

    func testCourseDescendsMonotonically() {
        for course in Course.all {
            let track = Track.generate(for: course)
            for i in 1..<track.count {
                XCTAssertLessThan(track.samples[i].elevation,
                                  track.samples[i - 1].elevation,
                                  "\(course.name) gains elevation at sample \(i)")
            }
        }
    }

    func testNearestIndexTracksTheCar() {
        let track = Track.generate(for: Course.all[0])
        var hint = 2
        for i in stride(from: 4, to: min(track.count - 4, 200), by: 3) {
            let found = track.nearestIndex(to: track.samples[i].position, hint: hint)
            XCTAssertLessThanOrEqual(abs(found - i), 1)
            hint = found
        }
    }
}

final class PhysicsTests: XCTestCase {

    private func makeState(_ track: Track) -> CarState {
        var state = CarState()
        state.position = track.samples[2].position
        state.velocity = track.tangent(at: 2) * 40
        state.sampleIndex = 2
        state.lastCheckpoint = 2
        return state
    }

    /// Tipping the handset away from the player has to accelerate the car.
    func testForwardTiltAccelerates() {
        let track = Track.generate(for: Course.all[0])
        var neutral = makeState(track)
        var tipped = makeState(track)

        for _ in 0..<120 {
            _ = Physics.step(&neutral, track: track, car: .starter,
                             tilt: SIMD2(0, 0), dt: Float(Tuning.physicsStep))
            _ = Physics.step(&tipped, track: track, car: .starter,
                             tilt: SIMD2(0, 1), dt: Float(Tuning.physicsStep))
        }

        XCTAssertGreaterThan(tipped.speed, neutral.speed,
                             "full forward tilt should be faster than resting flat")
    }

    /// And rolling it sideways has to move the car across the lane.
    func testLateralTiltSteers() {
        let track = Track.generate(for: Course.all[0])
        var left = makeState(track)
        var right = makeState(track)

        for _ in 0..<90 {
            _ = Physics.step(&left, track: track, car: .starter,
                             tilt: SIMD2(-1, 0.3), dt: Float(Tuning.physicsStep))
            _ = Physics.step(&right, track: track, car: .starter,
                             tilt: SIMD2(1, 0.3), dt: Float(Tuning.physicsStep))
        }

        XCTAssertLessThan(left.lateral, right.lateral,
                          "rolling left and right should separate the racing lines")
    }

    /// Terminal velocity has to exist, or the medal times are meaningless.
    func testSpeedConverges() {
        let track = Track.generate(for: Course.all[0])
        var state = makeState(track)

        for _ in 0..<1200 {
            _ = Physics.step(&state, track: track, car: .starter,
                             tilt: SIMD2(0, 1.4), dt: Float(Tuning.physicsStep))
            if state.falling > 0 { break }
        }

        XCTAssertLessThan(state.speed, 600, "drag should bound top speed")
        XCTAssertTrue(state.speed.isFinite)
    }

    /// A heavier car has more gravity authority than the starter.
    func testCarMassChangesGravityResponse() {
        let track = Track.generate(for: Course.all[0])
        let loaf = CarSpec.car(id: "loaf")

        var baseline = makeState(track)
        var heavy = makeState(track)

        for _ in 0..<60 {
            _ = Physics.step(&baseline, track: track, car: .starter,
                             tilt: SIMD2(0, 1), dt: Float(Tuning.physicsStep))
            _ = Physics.step(&heavy, track: track, car: loaf,
                             tilt: SIMD2(0, 1), dt: Float(Tuning.physicsStep))
        }

        XCTAssertGreaterThan(heavy.speed, baseline.speed)
    }

    /// Rails must contain the car rather than letting it wander off the deck.
    func testRailsContainTheCar() {
        let track = Track.generate(for: Course.all[0])
        var state = makeState(track)

        for _ in 0..<400 {
            _ = Physics.step(&state, track: track, car: .starter,
                             tilt: SIMD2(1.4, 0.6), dt: Float(Tuning.physicsStep))
            if state.falling > 0 { return }   // an open edge is a legitimate exit
            let width = track.samples[state.sampleIndex].halfWidth
            XCTAssertLessThanOrEqual(abs(state.lateral), width + 40,
                                     "car escaped the deck without falling")
        }
    }
}

final class MedalTests: XCTestCase {

    func testMedalThresholds() {
        let thresholds = SIMD4<Double>(70, 58, 48, 42)
        XCTAssertEqual(Medal.earned(time: 41.0, thresholds: thresholds), .sprue)
        XCTAssertEqual(Medal.earned(time: 45.0, thresholds: thresholds), .gold)
        XCTAssertEqual(Medal.earned(time: 55.0, thresholds: thresholds), .silver)
        XCTAssertEqual(Medal.earned(time: 66.0, thresholds: thresholds), .bronze)
        XCTAssertEqual(Medal.earned(time: 99.0, thresholds: thresholds), Medal.none)
    }

    func testMedalOrdering() {
        XCTAssertTrue(Medal.bronze < Medal.silver)
        XCTAssertTrue(Medal.silver < Medal.gold)
        XCTAssertTrue(Medal.gold < Medal.sprue)
    }
}

final class GhostTests: XCTestCase {

    func testGhostLookupClampsToBounds() {
        let frames = (0..<50).map { i in
            GhostFrame(x: Float(i), y: 0, elevation: 0, height: 0,
                       heading: 0, tiltX: 0, tiltY: 0)
        }
        let ghost = GhostRecording(courseID: "test", carID: "red7", time: 1.25,
                                   usedFallbackInput: false, frames: frames)

        XCTAssertEqual(ghost.frame(at: -5)?.x, 0)
        XCTAssertEqual(ghost.frame(at: 999)?.x, 49)
        XCTAssertEqual(ghost.frame(at: 10.0 / Tuning.ghostHz)?.x, 10)
    }
}
