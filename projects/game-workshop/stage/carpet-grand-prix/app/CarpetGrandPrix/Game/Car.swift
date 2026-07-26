//
//  Car.swift
//  Carpet Grand Prix
//
//  Cars are tools, not upgrades. Every spec trades one axis against another, so
//  the right car depends on the course rather than on how long you have played.
//

import Foundation
import simd

struct CarSpec: Identifiable, Sendable {
    let id: String
    let name: String
    let theme: String

    /// Multiplier on acceleration from handset tilt. Heavier cars have more
    /// gravity authority.
    let gravityAuthority: Float

    /// Multiplier on lateral grip. Lower grips slide more.
    let gripFactor: Float

    /// Multiplier on drag. Below 1 means a higher terminal speed.
    let dragFactor: Float

    /// Multiplier on boost strip effect.
    let boostFactor: Float

    /// Multiplier on how much speed a rail scrub costs. Above 1 hurts more.
    let railPenalty: Float

    /// Collision half-width. `Bit` is genuinely smaller and can take lines
    /// nothing else fits.
    let halfWidth: Float

    /// Sticky patches have no effect when true.
    let immuneToSticky: Bool

    let bodyColour: SIMD4<Float>
    let accentColour: SIMD4<Float>
}

extension CarSpec {
    static let all: [CarSpec] = [
        CarSpec(id: "red7", name: "Red 7", theme: "Loyalty",
                gravityAuthority: 1.00, gripFactor: 1.00, dragFactor: 1.00,
                boostFactor: 1.00, railPenalty: 1.00, halfWidth: Tuning.carHalfWidth,
                immuneToSticky: false,
                bodyColour: SIMD4(0.886, 0.216, 0.184, 1),
                accentColour: SIMD4(0.949, 0.961, 0.984, 1)),

        CarSpec(id: "chrome", name: "Chrome", theme: "Vanity",
                gravityAuthority: 0.86, gripFactor: 1.34, dragFactor: 1.05,
                boostFactor: 1.00, railPenalty: 1.15, halfWidth: Tuning.carHalfWidth,
                immuneToSticky: false,
                bodyColour: SIMD4(0.808, 0.847, 0.886, 1),
                accentColour: SIMD4(0.376, 0.427, 0.498, 1)),

        CarSpec(id: "loaf", name: "The Loaf", theme: "Stubbornness",
                gravityAuthority: 1.32, gripFactor: 0.58, dragFactor: 0.94,
                boostFactor: 0.90, railPenalty: 0.80, halfWidth: Tuning.carHalfWidth * 1.15,
                immuneToSticky: false,
                bodyColour: SIMD4(0.949, 0.847, 0.529, 1),
                accentColour: SIMD4(0.514, 0.404, 0.220, 1)),

        CarSpec(id: "wasp", name: "Wasp", theme: "Ambition",
                gravityAuthority: 1.06, gripFactor: 1.12, dragFactor: 0.82,
                boostFactor: 1.10, railPenalty: 1.45, halfWidth: Tuning.carHalfWidth * 0.92,
                immuneToSticky: false,
                bodyColour: SIMD4(0.965, 0.780, 0.122, 1),
                accentColour: SIMD4(0.106, 0.106, 0.125, 1)),

        CarSpec(id: "rustbucket", name: "Rustbucket", theme: "Endurance",
                gravityAuthority: 1.08, gripFactor: 0.92, dragFactor: 1.02,
                boostFactor: 0.95, railPenalty: 0.70, halfWidth: Tuning.carHalfWidth * 1.05,
                immuneToSticky: true,
                bodyColour: SIMD4(0.608, 0.353, 0.220, 1),
                accentColour: SIMD4(0.325, 0.290, 0.259, 1)),

        CarSpec(id: "sparks", name: "Sparks", theme: "Recklessness",
                gravityAuthority: 1.02, gripFactor: 0.96, dragFactor: 0.90,
                boostFactor: 1.40, railPenalty: 1.60, halfWidth: Tuning.carHalfWidth,
                immuneToSticky: false,
                bodyColour: SIMD4(0.949, 0.412, 0.129, 1),
                accentColour: SIMD4(0.145, 0.157, 0.196, 1)),

        CarSpec(id: "bit", name: "Bit", theme: "Curiosity",
                gravityAuthority: 0.90, gripFactor: 1.20, dragFactor: 1.08,
                boostFactor: 1.00, railPenalty: 1.00, halfWidth: Tuning.carHalfWidth * 0.55,
                immuneToSticky: false,
                bodyColour: SIMD4(0.400, 0.847, 0.694, 1),
                accentColour: SIMD4(0.114, 0.267, 0.239, 1)),

        CarSpec(id: "boxed", name: "The Boxed One", theme: "Loss",
                gravityAuthority: 1.14, gripFactor: 1.14, dragFactor: 0.88,
                boostFactor: 1.15, railPenalty: 0.90, halfWidth: Tuning.carHalfWidth,
                immuneToSticky: true,
                bodyColour: SIMD4(0.298, 0.322, 0.400, 1),
                accentColour: SIMD4(0.878, 0.816, 0.639, 1))
    ]

    static let starter = all[0]

    static func car(id: String) -> CarSpec {
        all.first { $0.id == id } ?? starter
    }
}
