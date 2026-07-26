//
//  MetalView.swift
//  Carpet Grand Prix
//
//  SwiftUI wrapper around MTKView. Also carries the touch fallback: a tap
//  re-centres the rest pose, and a drag stands in for tilt on the Simulator or
//  on a device with no usable gyro.
//

import SwiftUI
import MetalKit
import simd

struct MetalView: UIViewRepresentable {
    @ObservedObject var session: GameSession

    func makeCoordinator() -> Coordinator {
        Coordinator(session: session)
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.framebufferOnly = true
        view.autoResizeDrawable = true
        view.isMultipleTouchEnabled = false
        view.backgroundColor = .black

        if let renderer = Renderer(view: view, session: session) {
            context.coordinator.renderer = renderer
            view.delegate = renderer
        }

        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap))
        view.addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handlePan))
        view.addGestureRecognizer(pan)

        context.coordinator.view = view
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        // The renderer pulls everything it needs from the session each frame,
        // so there is nothing to push here.
    }

    @MainActor
    final class Coordinator: NSObject {
        var renderer: Renderer?
        weak var view: MTKView?
        private let session: GameSession

        init(session: GameSession) {
            self.session = session
        }

        @objc func handleTap() {
            session.recentre()
        }

        /// Drag-to-tilt, used only when there is no gyro signal.
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard !session.motion.hasSignal, let view else { return }

            switch gesture.state {
            case .began, .changed:
                let point = gesture.location(in: view)
                let width = max(view.bounds.width, 1)
                let height = max(view.bounds.height, 1)
                let x = Float((point.x - width * 0.5) / (width * 0.36))
                let y = Float((height * 0.62 - point.y) / (height * 0.30))
                session.fallback.target = simd_clamp(SIMD2(x, -y),
                                                     SIMD2(repeating: -1),
                                                     SIMD2(repeating: 1))
            case .ended, .cancelled, .failed:
                session.fallback.target = .zero
            default:
                break
            }
        }
    }
}
