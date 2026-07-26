//
//  DioramaBuilder.swift
//  Carpet Grand Prix
//
//  Builds the static track mesh once per course.
//
//  The whole track is only a few hundred samples, so there is no reason to
//  rebuild geometry per frame — we upload everything up front and each frame
//  draws a contiguous slice of it. The parallax displacement is applied in the
//  vertex shader from the uniforms, so nothing here depends on the camera or on
//  how the phone is being held.
//
//  Every layer emits exactly six vertices per segment. Features that are absent
//  on a given segment (a missing rail, a segment with no support post) emit a
//  degenerate zero-area quad instead of being skipped, which keeps the stride
//  uniform and makes the per-frame draw range a single multiply.
//

import Foundation
import Metal
import simd

/// Six vertices per segment, for every layer.
private let vertsPerSegment = 6

struct TrackMesh {
    let segmentCount: Int

    let shadow: MTLBuffer
    let posts: MTLBuffer
    let underside: MTLBuffer
    let deck: MTLBuffer
    let dashes: MTLBuffer
    let boost: MTLBuffer
    let railLeft: MTLBuffer
    let railRight: MTLBuffer

    /// Byte-free draw range for a slice of segments.
    func range(from first: Int, count: Int) -> (start: Int, count: Int) {
        let start = max(0, first) * vertsPerSegment
        let clampedCount = max(0, min(count, segmentCount - max(0, first)))
        return (start, clampedCount * vertsPerSegment)
    }
}

enum DioramaBuilder {

    /// World-space displacement baked into the cast shadow.
    private static let shadowOffset = SIMD2<Float>(9, 15)

    static func build(track: Track, device: MTLDevice) -> TrackMesh? {
        let samples = track.samples
        guard samples.count > 2 else { return nil }
        let segmentCount = samples.count - 1
        let theme = track.course.theme

        var shadow: [CGPDioramaVertex] = []
        var posts: [CGPDioramaVertex] = []
        var underside: [CGPDioramaVertex] = []
        var deck: [CGPDioramaVertex] = []
        var dashes: [CGPDioramaVertex] = []
        var boost: [CGPDioramaVertex] = []
        var railL: [CGPDioramaVertex] = []
        var railR: [CGPDioramaVertex] = []

        let capacity = segmentCount * vertsPerSegment
        shadow.reserveCapacity(capacity); posts.reserveCapacity(capacity)
        underside.reserveCapacity(capacity); deck.reserveCapacity(capacity)
        dashes.reserveCapacity(capacity); boost.reserveCapacity(capacity)
        railL.reserveCapacity(capacity); railR.reserveCapacity(capacity)

        for i in 0..<segmentCount {
            let a = samples[i]
            let b = samples[i + 1]

            let na = track.normal(at: i)
            let nb = track.normal(at: i + 1)

            let aL = a.position + na * a.halfWidth
            let aR = a.position - na * a.halfWidth
            let bL = b.position + nb * b.halfWidth
            let bR = b.position - nb * b.halfWidth

            let v0 = Float(i) / 4.0          // along-track UV, one unit per 4 segments
            let v1 = Float(i + 1) / 4.0

            // --- cast shadow, pinned to the carpet -------------------------
            appendQuad(&shadow,
                       aL + shadowOffset, aR + shadowOffset,
                       bL + shadowOffset, bR + shadowOffset,
                       elevA: a.elevation, elevB: b.elevation,
                       heightOffset: 0, floorPinned: 1,
                       colour: SIMD4(0, 0, 0, 0.42), shade: 1,
                       v0: v0, v1: v1)

            // --- support posts ---------------------------------------------
            // One post per emitting segment, alternating edges, so the stride
            // stays at six vertices while both sides still get supported.
            let postColour = SIMD4<Float>(0.09, 0.10, 0.14, 1)
            let postPhase = i % Tuning.postSpacing
            if postPhase == 0 {
                appendPost(&posts, at: aL, elevation: a.elevation, colour: postColour)
            } else if postPhase == Tuning.postSpacing / 2 {
                appendPost(&posts, at: aR, elevation: a.elevation, colour: postColour)
            } else {
                appendDegenerate(&posts, at: a.position, elevation: a.elevation)
            }

            // --- underside slab ---------------------------------------------
            appendQuad(&underside, aL, aR, bL, bR,
                       elevA: a.elevation, elevB: b.elevation,
                       heightOffset: -Tuning.deckThickness, floorPinned: 0,
                       colour: theme.roadEdge, shade: 0.62,
                       v0: v0, v1: v1)

            // --- deck --------------------------------------------------------
            let deckColour: SIMD4<Float>
            var deckShade: Float = 1.0
            switch a.kind {
            case .sticky:
                deckColour = SIMD4(0.149, 0.361, 0.235, 1)
                deckShade = 0.92
            case .ramp:
                deckColour = SIMD4(1.0, 0.922, 0.706, 1)
            default:
                deckColour = theme.road
            }
            appendQuad(&deck, aL, aR, bL, bR,
                       elevA: a.elevation, elevB: b.elevation,
                       heightOffset: 0, floorPinned: 0,
                       colour: deckColour, shade: deckShade,
                       v0: v0, v1: v1)

            // --- centre dashes -------------------------------------------------
            let dashHalf: Float = 3
            let dashOn = (i % 4) < 2
            if dashOn {
                appendQuad(&dashes,
                           a.position + na * dashHalf, a.position - na * dashHalf,
                           b.position + nb * dashHalf, b.position - nb * dashHalf,
                           elevA: a.elevation, elevB: b.elevation,
                           heightOffset: 0.4, floorPinned: 0,
                           colour: SIMD4(1, 1, 1, 0.30), shade: 1,
                           v0: v0, v1: v1)
            } else {
                appendDegenerate(&dashes, at: a.position, elevation: a.elevation)
            }

            // --- boost overlay (animated in the fragment shader) ----------------
            if a.kind == .boost {
                appendQuad(&boost, aL, aR, bL, bR,
                           elevA: a.elevation, elevB: b.elevation,
                           heightOffset: 0.6, floorPinned: 0,
                           colour: SIMD4(0.306, 0.796, 1.0, 0.85), shade: 1,
                           v0: v0, v1: v1)
            } else {
                appendDegenerate(&boost, at: a.position, elevation: a.elevation)
            }

            // --- rails, extruded upward from each deck edge ---------------------
            let railOpenLeft  = a.kind == .open && a.openSide > 0
            let railOpenRight = a.kind == .open && a.openSide < 0

            if railOpenLeft {
                appendDegenerate(&railL, at: aL, elevation: a.elevation)
            } else {
                appendRail(&railL, aBase: aL, bBase: bL,
                           elevA: a.elevation, elevB: b.elevation,
                           colour: theme.rail, v0: v0, v1: v1)
            }

            if railOpenRight {
                appendDegenerate(&railR, at: aR, elevation: a.elevation)
            } else {
                appendRail(&railR, aBase: aR, bBase: bR,
                           elevA: a.elevation, elevB: b.elevation,
                           colour: theme.rail, v0: v0, v1: v1)
            }
        }

        func makeBuffer(_ array: [CGPDioramaVertex]) -> MTLBuffer? {
            array.withUnsafeBytes { raw in
                device.makeBuffer(bytes: raw.baseAddress!,
                                  length: raw.count,
                                  options: .storageModeShared)
            }
        }

        guard let bShadow = makeBuffer(shadow),
              let bPosts = makeBuffer(posts),
              let bUnder = makeBuffer(underside),
              let bDeck = makeBuffer(deck),
              let bDash = makeBuffer(dashes),
              let bBoost = makeBuffer(boost),
              let bRailL = makeBuffer(railL),
              let bRailR = makeBuffer(railR)
        else { return nil }

        return TrackMesh(segmentCount: segmentCount,
                         shadow: bShadow, posts: bPosts,
                         underside: bUnder, deck: bDeck,
                         dashes: bDash, boost: bBoost,
                         railLeft: bRailL, railRight: bRailR)
    }

    // MARK: - Primitive emitters

    private static func vertex(_ position: SIMD2<Float>,
                               elevation: Float,
                               heightOffset: Float,
                               floorPinned: Float,
                               colour: SIMD4<Float>,
                               shade: Float,
                               uv: SIMD2<Float>) -> CGPDioramaVertex
    {
        CGPDioramaVertex(position: position,
                         elevation: elevation,
                         heightOffset: heightOffset,
                         floorPinned: floorPinned,
                         shade: shade,
                         uv: uv,
                         colour: colour)
    }

    /// Emit a quad spanning two track samples as two triangles.
    private static func appendQuad(_ out: inout [CGPDioramaVertex],
                                   _ aL: SIMD2<Float>, _ aR: SIMD2<Float>,
                                   _ bL: SIMD2<Float>, _ bR: SIMD2<Float>,
                                   elevA: Float, elevB: Float,
                                   heightOffset: Float, floorPinned: Float,
                                   colour: SIMD4<Float>, shade: Float,
                                   v0: Float, v1: Float)
    {
        let p0 = vertex(aL, elevation: elevA, heightOffset: heightOffset,
                        floorPinned: floorPinned, colour: colour, shade: shade,
                        uv: SIMD2(0, v0))
        let p1 = vertex(aR, elevation: elevA, heightOffset: heightOffset,
                        floorPinned: floorPinned, colour: colour, shade: shade,
                        uv: SIMD2(1, v0))
        let p2 = vertex(bR, elevation: elevB, heightOffset: heightOffset,
                        floorPinned: floorPinned, colour: colour, shade: shade,
                        uv: SIMD2(1, v1))
        let p3 = vertex(bL, elevation: elevB, heightOffset: heightOffset,
                        floorPinned: floorPinned, colour: colour, shade: shade,
                        uv: SIMD2(0, v1))

        out.append(contentsOf: [p0, p1, p2, p0, p2, p3])
    }

    /// A rail is a vertical ribbon: the deck edge extruded up by `railHeight`,
    /// darker at the base than at the top so it reads as a solid wall.
    private static func appendRail(_ out: inout [CGPDioramaVertex],
                                   aBase: SIMD2<Float>, bBase: SIMD2<Float>,
                                   elevA: Float, elevB: Float,
                                   colour: SIMD4<Float>,
                                   v0: Float, v1: Float)
    {
        let baseShade: Float = 0.62
        let topShade: Float = 1.08

        let p0 = vertex(aBase, elevation: elevA, heightOffset: 0, floorPinned: 0,
                        colour: colour, shade: baseShade, uv: SIMD2(0, v0))
        let p1 = vertex(bBase, elevation: elevB, heightOffset: 0, floorPinned: 0,
                        colour: colour, shade: baseShade, uv: SIMD2(0, v1))
        let p2 = vertex(bBase, elevation: elevB, heightOffset: Tuning.railHeight,
                        floorPinned: 0, colour: colour, shade: topShade,
                        uv: SIMD2(1, v1))
        let p3 = vertex(aBase, elevation: elevA, heightOffset: Tuning.railHeight,
                        floorPinned: 0, colour: colour, shade: topShade,
                        uv: SIMD2(1, v0))

        out.append(contentsOf: [p0, p1, p2, p0, p2, p3])
    }

    /// A support post: a narrow ribbon from the carpet up to the deck underside.
    /// The foot is floor-pinned so it stays put while the deck slides over it.
    private static func appendPost(_ out: inout [CGPDioramaVertex],
                                   at anchor: SIMD2<Float>,
                                   elevation: Float,
                                   colour: SIMD4<Float>)
    {
        let offset = SIMD2<Float>(4, 0)

        // The foot is floor-pinned and the head is not, so as the handset tilts
        // the post visibly splays — which is exactly what a real support looks
        // like when you change your viewing angle on it.
        let f0 = vertex(anchor - offset, elevation: elevation, heightOffset: 0,
                        floorPinned: 1, colour: colour, shade: 0.5, uv: SIMD2(0, 0))
        let f1 = vertex(anchor + offset, elevation: elevation, heightOffset: 0,
                        floorPinned: 1, colour: colour, shade: 0.5, uv: SIMD2(1, 0))
        let h1 = vertex(anchor + offset, elevation: elevation,
                        heightOffset: -Tuning.deckThickness, floorPinned: 0,
                        colour: colour, shade: 0.8, uv: SIMD2(1, 1))
        let h0 = vertex(anchor - offset, elevation: elevation,
                        heightOffset: -Tuning.deckThickness, floorPinned: 0,
                        colour: colour, shade: 0.8, uv: SIMD2(0, 1))

        out.append(contentsOf: [f0, f1, h1, f0, h1, h0])
    }

    /// Zero-area quad, so absent features keep the six-vertices-per-segment stride.
    private static func appendDegenerate(_ out: inout [CGPDioramaVertex],
                                         at position: SIMD2<Float>,
                                         elevation: Float)
    {
        let v = vertex(position, elevation: elevation, heightOffset: 0,
                       floorPinned: 0, colour: SIMD4(0, 0, 0, 0), shade: 0,
                       uv: .zero)
        out.append(contentsOf: [v, v, v, v, v, v])
    }
}
