//
//  TextureFactory.swift
//  Carpet Grand Prix
//
//  All textures are generated procedurally at load time with Core Graphics.
//  The app ships no binary image assets: the carpet is seeded noise and the car
//  is drawn from primitives, so a new room theme or car livery costs a few lines
//  rather than an art round-trip.
//

import Foundation
import Metal
import CoreGraphics
import simd

enum TextureFactory {

    // MARK: - Carpet

    /// A tileable floor texture for a room. Seeded, so the same room always
    /// produces the same weave.
    static func carpet(theme: RoomTheme, seed: UInt32, device: MTLDevice) -> MTLTexture? {
        let size = 256
        return draw(width: size, height: size, device: device) { ctx in
            ctx.setFillColor(cgColour(theme.floor))
            ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

            var rng = Mulberry32(seed: seed)
            let fleck = cgColour(theme.fleck)
            let sheen = CGColor(red: 1, green: 1, blue: 1, alpha: 0.035)

            for _ in 0..<2600 {
                let x = CGFloat(rng.next()) * CGFloat(size)
                let y = CGFloat(rng.next()) * CGFloat(size)
                let w = CGFloat(rng.next(in: 0.8...3.0))
                let h = w * CGFloat(rng.next(in: 0.4...0.9))
                ctx.setFillColor(rng.next() < 0.55 ? fleck : sheen)
                ctx.fill(CGRect(x: x, y: y, width: w, height: h))
            }
        }
    }

    // MARK: - Car

    /// A top-down die-cast car. Drawn once per livery into a small texture and
    /// then rendered as a single instanced quad.
    static func car(spec: CarSpec, device: MTLDevice) -> MTLTexture? {
        let size = 128
        return draw(width: size, height: size, device: device) { ctx in
            let s = CGFloat(size)

            // The sprite points along +X, matching the physics heading.
            ctx.translateBy(x: s / 2, y: s / 2)

            let bodyLength: CGFloat = s * 0.78
            let bodyWidth: CGFloat = s * 0.46

            // wheels
            ctx.setFillColor(CGColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1))
            for dx in [-bodyLength * 0.30, bodyLength * 0.28] {
                for dy in [-bodyWidth * 0.62, bodyWidth * 0.36] {
                    ctx.fill(CGRect(x: dx, y: dy,
                                    width: bodyLength * 0.24,
                                    height: bodyWidth * 0.26))
                }
            }

            // chassis
            let body = CGRect(x: -bodyLength / 2, y: -bodyWidth / 2,
                              width: bodyLength, height: bodyWidth)
            ctx.setFillColor(cgColour(spec.accentColour))
            ctx.addPath(CGPath(roundedRect: body,
                               cornerWidth: bodyWidth * 0.24,
                               cornerHeight: bodyWidth * 0.24,
                               transform: nil))
            ctx.fillPath()

            // nose section in the body colour
            let nose = CGRect(x: -bodyLength / 2, y: -bodyWidth / 2,
                              width: bodyLength * 0.62, height: bodyWidth)
            ctx.setFillColor(cgColour(spec.bodyColour))
            ctx.addPath(CGPath(roundedRect: nose,
                               cornerWidth: bodyWidth * 0.24,
                               cornerHeight: bodyWidth * 0.24,
                               transform: nil))
            ctx.fillPath()

            // cockpit
            let cockpit = CGRect(x: -bodyLength * 0.12, y: -bodyWidth * 0.30,
                                 width: bodyLength * 0.34, height: bodyWidth * 0.60)
            ctx.setFillColor(CGColor(red: 0.11, green: 0.15, blue: 0.20, alpha: 1))
            ctx.addPath(CGPath(roundedRect: cockpit,
                               cornerWidth: bodyWidth * 0.16,
                               cornerHeight: bodyWidth * 0.16,
                               transform: nil))
            ctx.fillPath()

            // stripe over the nose
            ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.85))
            ctx.fill(CGRect(x: bodyLength * 0.24, y: -bodyWidth * 0.10,
                            width: bodyLength * 0.22, height: bodyWidth * 0.20))
        }
    }

    // MARK: - Plumbing

    private static func cgColour(_ c: SIMD4<Float>) -> CGColor {
        CGColor(red: CGFloat(c.x), green: CGFloat(c.y),
                blue: CGFloat(c.z), alpha: CGFloat(c.w))
    }

    private static func draw(width: Int,
                             height: Int,
                             device: MTLDevice,
                             _ body: (CGContext) -> Void) -> MTLTexture?
    {
        let bytesPerRow = width * 4
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(data: nil,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: bytesPerRow,
                                  space: space,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }

        ctx.clear(CGRect(x: 0, y: 0, width: width, height: height))
        ctx.saveGState()
        body(ctx)
        ctx.restoreGState()

        guard let data = ctx.data else { return nil }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm_srgb,
            width: width,
            height: height,
            mipmapped: true)
        descriptor.usage = .shaderRead
        descriptor.storageMode = .shared

        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
        texture.replace(region: MTLRegionMake2D(0, 0, width, height),
                        mipmapLevel: 0,
                        withBytes: data,
                        bytesPerRow: bytesPerRow)
        return texture
    }

    /// Generates mipmaps for textures created above. Called once at load.
    static func generateMipmaps(for textures: [MTLTexture], queue: MTLCommandQueue) {
        guard let buffer = queue.makeCommandBuffer(),
              let blit = buffer.makeBlitCommandEncoder() else { return }
        for texture in textures where texture.mipmapLevelCount > 1 {
            blit.generateMipmaps(for: texture)
        }
        blit.endEncoding()
        buffer.commit()
    }
}
