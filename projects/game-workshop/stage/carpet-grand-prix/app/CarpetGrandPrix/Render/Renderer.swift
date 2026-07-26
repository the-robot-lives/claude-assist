//
//  Renderer.swift
//  Carpet Grand Prix
//
//  One render pass, eight draws, no per-frame geometry work.
//
//  The track mesh is uploaded once when a course loads. Each frame we update a
//  single uniform struct — camera, scale, and the parallax view vector derived
//  from the handset's gravity reading — and draw a contiguous slice of each
//  layer. Everything that makes the diorama look three-dimensional happens in
//  `diorama_vertex`.
//
//  Uniforms are triple-buffered behind a semaphore so the CPU never writes a
//  buffer the GPU is still reading.
//

import Foundation
import Metal
import MetalKit
import simd

private let maxFramesInFlight = 3

@MainActor
final class Renderer: NSObject, MTKViewDelegate {

    // MARK: Metal objects

    private let device: MTLDevice
    private let queue: MTLCommandQueue

    private var dioramaPipeline: MTLRenderPipelineState!
    private var boostPipeline: MTLRenderPipelineState!
    private var carpetPipeline: MTLRenderPipelineState!
    private var spritePipeline: MTLRenderPipelineState!
    private var shadowPipeline: MTLRenderPipelineState!

    private var sampler: MTLSamplerState!

    private var uniformBuffers: [MTLBuffer] = []
    private var instanceBuffers: [MTLBuffer] = []
    private var frameIndex = 0
    private let inFlight = DispatchSemaphore(value: maxFramesInFlight)

    // MARK: Content

    private let session: GameSession
    private var mesh: TrackMesh?
    private var carpetTexture: MTLTexture?
    private var carTexture: MTLTexture?
    private var loadedCourseID: String?
    private var loadedCarID: String?

    private var viewportSize = SIMD2<Float>(1, 1)
    private var lastFrameTime: CFTimeInterval = 0

    /// Maximum sprites drawn in one frame: car, its shadow, ghost, ghost shadow.
    private let maxSprites = 4

    // MARK: - Init

    init?(view: MTKView, session: GameSession) {
        guard let device = view.device ?? MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue()
        else { return nil }

        self.device = device
        self.queue = queue
        self.session = session
        super.init()

        view.device = device
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.depthStencilPixelFormat = .invalid   // painter's algorithm, layer by layer
        view.clearColor = MTLClearColorMake(0.05, 0.06, 0.09, 1)
        view.preferredFramesPerSecond = 120       // clamped by the display

        guard buildPipelines(view: view) else { return nil }
        buildBuffers()
    }

    // MARK: - Setup

    private func buildPipelines(view: MTKView) -> Bool {
        guard let library = device.makeDefaultLibrary() else {
            assertionFailure("Shaders.metal failed to compile into the default library")
            return false
        }

        func pipeline(vertex: String,
                      fragment: String,
                      blend: Bool) -> MTLRenderPipelineState?
        {
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: vertex)
            descriptor.fragmentFunction = library.makeFunction(name: fragment)
            descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat

            if blend {
                let attachment = descriptor.colorAttachments[0]!
                attachment.isBlendingEnabled = true
                attachment.rgbBlendOperation = .add
                attachment.alphaBlendOperation = .add
                attachment.sourceRGBBlendFactor = .sourceAlpha
                attachment.sourceAlphaBlendFactor = .sourceAlpha
                attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
                attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
            }
            return try? device.makeRenderPipelineState(descriptor: descriptor)
        }

        guard let diorama = pipeline(vertex: "diorama_vertex", fragment: "diorama_fragment", blend: true),
              let boost = pipeline(vertex: "diorama_vertex", fragment: "boost_fragment", blend: true),
              let carpet = pipeline(vertex: "carpet_vertex", fragment: "carpet_fragment", blend: false),
              let sprite = pipeline(vertex: "sprite_vertex", fragment: "sprite_fragment", blend: true),
              let shadow = pipeline(vertex: "sprite_vertex", fragment: "shadow_fragment", blend: true)
        else {
            assertionFailure("Failed to build one or more render pipeline states")
            return false
        }

        dioramaPipeline = diorama
        boostPipeline = boost
        carpetPipeline = carpet
        spritePipeline = sprite
        shadowPipeline = shadow

        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        samplerDescriptor.maxAnisotropy = 4
        sampler = device.makeSamplerState(descriptor: samplerDescriptor)

        return sampler != nil
    }

    private func buildBuffers() {
        for _ in 0..<maxFramesInFlight {
            if let uniforms = device.makeBuffer(length: MemoryLayout<CGPUniforms>.stride,
                                                options: .storageModeShared) {
                uniforms.label = "Uniforms"
                uniformBuffers.append(uniforms)
            }
            if let instances = device.makeBuffer(
                length: MemoryLayout<CGPSpriteInstance>.stride * maxSprites,
                options: .storageModeShared) {
                instances.label = "Sprites"
                instanceBuffers.append(instances)
            }
        }
    }

    /// Rebuild GPU content when the course or car changes.
    private func syncContent() {
        if loadedCourseID != session.course.id, let track = session.track {
            mesh = DioramaBuilder.build(track: track, device: device)
            carpetTexture = TextureFactory.carpet(theme: session.course.theme,
                                                  seed: session.course.seed ^ 0x9E37,
                                                  device: device)
            loadedCourseID = session.course.id

            if let carpetTexture {
                TextureFactory.generateMipmaps(for: [carpetTexture], queue: queue)
            }
        }

        if loadedCarID != session.carSpec.id {
            carTexture = TextureFactory.car(spec: session.carSpec, device: device)
            loadedCarID = session.carSpec.id
            if let carTexture {
                TextureFactory.generateMipmaps(for: [carTexture], queue: queue)
            }
        }
    }

    // MARK: - MTKViewDelegate

    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        Task { @MainActor in
            self.viewportSize = SIMD2(Float(view.bounds.width), Float(view.bounds.height))
        }
    }

    nonisolated func draw(in view: MTKView) {
        Task { @MainActor in
            self.render(in: view)
        }
    }

    // MARK: - Frame

    private func render(in view: MTKView) {
        let now = CACurrentMediaTime()
        let dt = lastFrameTime > 0 ? now - lastFrameTime : 1.0 / 60.0
        lastFrameTime = now

        session.advance(dt: dt)
        syncContent()

        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = queue.makeCommandBuffer()
        else { return }

        _ = inFlight.wait(timeout: .distantFuture)
        frameIndex = (frameIndex + 1) % maxFramesInFlight

        let semaphore = inFlight
        commandBuffer.addCompletedHandler { _ in semaphore.signal() }

        if viewportSize.x <= 1 {
            viewportSize = SIMD2(Float(view.bounds.width), Float(view.bounds.height))
        }

        writeUniforms(time: now)
        let spriteCount = writeSprites()

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            commandBuffer.commit()
            return
        }

        let uniforms = uniformBuffers[frameIndex]
        encoder.setVertexBuffer(uniforms, offset: 0, index: CGPBufferUniforms.rawValue)
        encoder.setFragmentBuffer(uniforms, offset: 0, index: CGPBufferUniforms.rawValue)
        encoder.setFragmentSamplerState(sampler, index: 0)

        drawCarpet(encoder)
        drawTrack(encoder)
        drawSprites(encoder, count: spriteCount)

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    // MARK: Uniforms

    private func writeUniforms(time: CFTimeInterval) {
        let depth = Float(Persistence.shared.parallaxDepth)
        let tilt = session.tilt

        // The parallax direction. Y is pre-negated so that positive height always
        // moves a vertex toward the top of the screen. `viewBaseline` keeps a
        // little depth even when the phone is held exactly at the rest pose.
        let viewX = simd_clamp(tilt.x, -1.3, 1.3) * Tuning.viewRollGain * depth
        let viewY = simd_clamp(Tuning.viewBaseline + tilt.y * Tuning.viewPitchGain,
                               0.06, 1.15) * depth

        let scale = viewportSize.x / Tuning.worldUnitsAcrossScreen

        var shakeOffset = SIMD2<Float>.zero
        if session.shake > 0.2 {
            // Deterministic-ish jitter driven by the clock, so it does not need
            // a random source inside the render loop.
            let t = Float(time) * 47
            shakeOffset = SIMD2(sin(t * 1.7), cos(t * 2.3)) * session.shake
        }

        var uniforms = CGPUniforms(
            cameraXY: session.camera.position,
            cameraElevation: session.camera.elevation,
            scale: scale,
            viewportCentre: SIMD2(viewportSize.x * 0.5, viewportSize.y * 0.62) + shakeOffset,
            viewportSize: viewportSize,
            viewVector: SIMD2(viewX, -viewY),
            baseHeight: Tuning.baseDeckHeight,
            gradeRead: Tuning.gradeReadout,
            time: Float(time),
            carpetScroll: 0,
            ambient: session.course.theme.ambient,
            vignette: session.course.theme.vignette,
            _pad0: 0, _pad1: 0, _pad2: 0)

        memcpy(uniformBuffers[frameIndex].contents(), &uniforms, MemoryLayout<CGPUniforms>.stride)
    }

    // MARK: Sprites

    private func writeSprites() -> (shadows: Int, cars: Int) {
        guard let track = session.track else { return (0, 0) }

        var shadows: [CGPSpriteInstance] = []
        var cars: [CGPSpriteInstance] = []

        let elevation = track.samples[session.car.sampleIndex].elevation

        // Airborne cars cast a smaller, fainter shadow.
        let lift = session.car.height / Tuning.airHeight
        let shrink = 1 - simd_clamp(lift, 0, 1) * 0.42

        shadows.append(CGPSpriteInstance(
            position: session.car.position,
            elevation: elevation,
            heightOffset: 0.8,
            rotation: session.car.heading,
            size: Tuning.carSpriteSize * shrink,
            tint: SIMD4(0, 0, 0, 0.45 * shrink)))

        cars.append(CGPSpriteInstance(
            position: session.car.position,
            elevation: elevation,
            heightOffset: session.car.height + 9,
            rotation: session.car.heading,
            size: Tuning.carSpriteSize,
            tint: SIMD4(1, 1, 1, 1)))

        if let ghost = session.ghostFrame {
            shadows.append(CGPSpriteInstance(
                position: SIMD2(ghost.x, ghost.y),
                elevation: ghost.elevation,
                heightOffset: 0.8,
                rotation: ghost.heading,
                size: Tuning.carSpriteSize * 0.9,
                tint: SIMD4(0, 0, 0, 0.20)))

            cars.append(CGPSpriteInstance(
                position: SIMD2(ghost.x, ghost.y),
                elevation: ghost.elevation,
                heightOffset: ghost.height + 9,
                rotation: ghost.heading,
                size: Tuning.carSpriteSize,
                tint: SIMD4(0.55, 0.80, 1.0, 0.42)))
        }

        // Shadows first, then cars, packed into one buffer.
        let all = shadows + cars
        let buffer = instanceBuffers[frameIndex]
        all.withUnsafeBytes { raw in
            memcpy(buffer.contents(), raw.baseAddress!, raw.count)
        }
        return (shadows.count, cars.count)
    }

    // MARK: Draws

    private func drawCarpet(_ encoder: MTLRenderCommandEncoder) {
        guard let carpetTexture else { return }
        encoder.setRenderPipelineState(carpetPipeline)
        encoder.setFragmentTexture(carpetTexture, index: CGPTextureAlbedo.rawValue)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
    }

    private func drawTrack(_ encoder: MTLRenderCommandEncoder) {
        guard let mesh else { return }

        // Only the arc around the car is on screen. Everything else is skipped
        // with a vertex-range offset rather than a culling pass.
        let first = session.car.sampleIndex - Tuning.visibleBehind
        let count = Tuning.visibleBehind + Tuning.visibleAhead
        let (start, vertexCount) = mesh.range(from: first, count: count)
        guard vertexCount > 0 else { return }

        func layer(_ buffer: MTLBuffer, pipeline: MTLRenderPipelineState) {
            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(buffer, offset: 0, index: CGPBufferVertices.rawValue)
            encoder.drawPrimitives(type: .triangle,
                                   vertexStart: start,
                                   vertexCount: vertexCount)
        }

        layer(mesh.shadow, pipeline: dioramaPipeline)
        layer(mesh.posts, pipeline: dioramaPipeline)
        layer(mesh.underside, pipeline: dioramaPipeline)
        layer(mesh.deck, pipeline: dioramaPipeline)
        layer(mesh.dashes, pipeline: dioramaPipeline)
        layer(mesh.boost, pipeline: boostPipeline)
        layer(mesh.railLeft, pipeline: dioramaPipeline)
        layer(mesh.railRight, pipeline: dioramaPipeline)
    }

    private func drawSprites(_ encoder: MTLRenderCommandEncoder,
                             count: (shadows: Int, cars: Int))
    {
        guard count.cars > 0, let carTexture else { return }
        let buffer = instanceBuffers[frameIndex]
        let stride = MemoryLayout<CGPSpriteInstance>.stride

        if count.shadows > 0 {
            encoder.setRenderPipelineState(shadowPipeline)
            encoder.setVertexBuffer(buffer, offset: 0, index: CGPBufferInstances.rawValue)
            encoder.drawPrimitives(type: .triangle,
                                   vertexStart: 0,
                                   vertexCount: 6,
                                   instanceCount: count.shadows)
        }

        encoder.setRenderPipelineState(spritePipeline)
        encoder.setFragmentTexture(carTexture, index: CGPTextureAlbedo.rawValue)
        encoder.setVertexBuffer(buffer,
                                offset: stride * count.shadows,
                                index: CGPBufferInstances.rawValue)
        encoder.drawPrimitives(type: .triangle,
                               vertexStart: 0,
                               vertexCount: 6,
                               instanceCount: count.cars)
    }
}
