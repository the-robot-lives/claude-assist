//
//  ContentView.swift
//  Carpet Grand Prix
//
//  The SwiftUI shell: course select, in-run HUD, and the results card. The
//  Metal view sits underneath all of it and never stops rendering.
//
//  Every control lives in the bottom third of the screen so the whole game is
//  reachable one-handed while the other hand is holding onto something.
//

import SwiftUI
import simd

struct ContentView: View {
    @StateObject private var session = GameSession()
    @State private var showSettings = false

    var body: some View {
        ZStack {
            MetalView(session: session)
                .ignoresSafeArea()

            switch session.phase {
            case .menu:
                CourseSelectView(session: session, showSettings: $showSettings)
                    .transition(.opacity)
            case .countdown, .racing:
                RunHUD(session: session)
            case .finished:
                if let result = session.result {
                    ResultCard(session: session, result: result)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
        }
        .animation(.easeOut(duration: 0.22), value: session.phase)
        .sheet(isPresented: $showSettings) {
            SettingsView(session: session)
        }
        .onAppear { session.load(course: Course.all[0]) }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }
}

// MARK: - Course select

struct CourseSelectView: View {
    @ObservedObject var session: GameSession
    @Binding var showSettings: Bool

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black.opacity(0.35), .black.opacity(0.88)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    Text("CARPET")
                        .kerning(8)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.orange)
                    Text("GRAND PRIX")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("The floor is the racetrack.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .padding(.top, 54)

                Spacer(minLength: 12)

                VStack(spacing: 9) {
                    ForEach(Course.all) { course in
                        CourseRow(course: course, selected: course.id == session.course.id)
                            .onTapGesture { session.load(course: course) }
                    }
                }
                .padding(.horizontal, 20)

                CarPicker(session: session)
                    .padding(.top, 14)

                Button {
                    session.startRun()
                } label: {
                    Text("RACE")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [Color(red: 1, green: 0.71, blue: 0.33),
                                                    Color(red: 1, green: 0.48, blue: 0.16)],
                                           startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 15))
                        .foregroundStyle(.black.opacity(0.85))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Button("Settings & Accessibility") { showSettings = true }
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.top, 12)
                    .padding(.bottom, 26)
            }
        }
    }
}

struct CourseRow: View {
    let course: Course
    let selected: Bool

    private var best: Double? { Persistence.shared.bestTime(for: course.id) }
    private var medal: Medal { Persistence.shared.medal(for: course) }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: medal.symbol)
                .font(.system(size: 20))
                .foregroundStyle(medal == .none ? .white.opacity(0.25) : .yellow)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(course.name)
                    .font(.system(size: 15.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(course.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            Text(best.map { String(format: "%.2fs", $0) } ?? "—")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(best == nil ? .white.opacity(0.3) : .green)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(selected ? Color.orange.opacity(0.16) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(selected ? Color.orange : Color.white.opacity(0.10),
                                lineWidth: 1)))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(course.name), \(course.subtitle), \(medal.label) medal")
        .accessibilityValue(best.map { String(format: "best %.2f seconds", $0) } ?? "no time set")
    }
}

struct CarPicker: View {
    @ObservedObject var session: GameSession

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CarSpec.all) { car in
                    let selected = car.id == session.carSpec.id
                    VStack(spacing: 3) {
                        Text(car.name)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                        Text(car.theme)
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(selected ? Color.orange.opacity(0.22)
                                                : Color.white.opacity(0.05))
                            .overlay(Capsule().stroke(selected ? Color.orange
                                                               : Color.white.opacity(0.10),
                                                      lineWidth: 1)))
                    .foregroundStyle(.white)
                    .onTapGesture {
                        session.carSpec = car
                        Persistence.shared.selectedCarID = car.id
                    }
                    .accessibilityLabel("\(car.name), \(car.theme)")
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - In-run HUD

struct RunHUD: View {
    @ObservedObject var session: GameSession

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                chip(label: "TIME", value: String(format: "%.2f", session.displayTime))
                Spacer()
                chip(label: "SPEED", value: "\(session.speedMPH)", unit: "MPH", tint: .orange)
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)

            Spacer()

            if let banner = session.banner {
                Text(banner)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.8), radius: 12, y: 3)
                    .transition(.opacity)
                    .padding(.bottom, 40)
                    .accessibilityLabel(banner)
            }

            Spacer()

            TiltBubble(tilt: session.tilt, live: session.motion.hasSignal)
                .padding(.bottom, 18)
        }
        .overlay(alignment: .trailing) {
            ProgressRail(progress: session.progress)
                .padding(.trailing, 8)
        }
        .allowsHitTesting(false)
    }

    private func chip(label: String, value: String,
                      unit: String? = nil, tint: Color = .white) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .kerning(1.6)
                .foregroundStyle(.white.opacity(0.5))
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(tint)
                if let unit {
                    Text(unit)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 11))
    }
}

struct ProgressRail: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Capsule().fill(.white.opacity(0.12))
                Capsule()
                    .fill(LinearGradient(colors: [.orange, .yellow],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(height: geo.size.height * progress)
                Circle()
                    .fill(.white)
                    .frame(width: 11, height: 11)
                    .offset(x: 0, y: geo.size.height * progress - 5.5)
                    .shadow(color: .orange.opacity(0.9), radius: 6)
            }
        }
        .frame(width: 5)
        .frame(maxHeight: .infinity)
        .padding(.vertical, 130)
    }
}

struct TiltBubble: View {
    let tilt: SIMD2<Float>
    let live: Bool

    var body: some View {
        ZStack {
            Circle().fill(.ultraThinMaterial)
            Circle().stroke(.white.opacity(0.10), lineWidth: 1)
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .foregroundStyle(.white.opacity(0.16))
                .frame(width: 46, height: 46)
            Circle()
                .fill(Color(red: 0.31, green: 0.80, blue: 1.0))
                .frame(width: 21, height: 21)
                .shadow(color: Color(red: 0.31, green: 0.80, blue: 1.0).opacity(0.7), radius: 9)
                .offset(x: CGFloat(min(max(tilt.x, -1.15), 1.15)) * 38,
                        y: CGFloat(min(max(tilt.y, -1.15), 1.15)) * 38)
        }
        .frame(width: 112, height: 112)
        .overlay(alignment: .bottom) {
            Text(live ? "GYRO LIVE · TAP TO RE-CENTRE" : "DRAG TO STEER")
                .font(.system(size: 8.5, weight: .semibold))
                .kerning(1.1)
                .foregroundStyle(.white.opacity(0.42))
                .offset(y: 15)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Results

struct ResultCard: View {
    @ObservedObject var session: GameSession
    let result: RunResult

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()

            VStack(spacing: 14) {
                Text(result.medal == .none ? "FINISH" : result.medal.label.uppercased())
                    .font(.system(size: 12, weight: .heavy))
                    .kerning(3)
                    .foregroundStyle(result.medal == .none ? .white.opacity(0.5) : .yellow)

                Text(String(format: "%.2fs", result.total))
                    .font(.system(size: 46, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)

                deltaLine

                Text("Top speed \(Int(result.topSpeed * Tuning.speedToMPH)) mph · "
                     + "boosts \(result.boosts) · falls \(result.falls)")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)

                VStack(spacing: 9) {
                    Button { session.startRun() } label: {
                        Text("RUN IT AGAIN")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(colors: [Color(red: 1, green: 0.71, blue: 0.33),
                                                        Color(red: 1, green: 0.48, blue: 0.16)],
                                               startPoint: .leading, endPoint: .trailing),
                                in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.black.opacity(0.85))
                    }
                    Button { session.returnToMenu() } label: {
                        Text("Change Course")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.17), lineWidth: 1))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.top, 8)
            }
            .padding(26)
            .frame(maxWidth: 340)
        }
    }

    @ViewBuilder
    private var deltaLine: some View {
        if let previous = result.previousBest {
            let delta = result.total - previous
            Text(String(format: "%@%.2fs vs best", delta < 0 ? "−" : "+", abs(delta)))
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(delta < 0 ? .green : .red.opacity(0.85))
        } else {
            Text("First run on \(session.course.name)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.green)
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @ObservedObject var session: GameSession
    @Environment(\.dismiss) private var dismiss

    @State private var parallax = Persistence.shared.parallaxDepth
    @State private var sensitivity = Persistence.shared.tiltSensitivity
    @State private var vehicleMode = Persistence.shared.vehicleMode

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading) {
                        Text("Parallax depth  \(Int(parallax * 100))%")
                        Slider(value: $parallax, in: 0...1)
                            .onChange(of: parallax) { new in
                                Persistence.shared.parallaxDepth = new
                            }
                    }
                } header: {
                    Text("Comfort")
                } footer: {
                    Text("Reduces how far the diorama shifts as you tilt. "
                         + "Handling and lap times are unaffected at any setting.")
                }

                Section {
                    VStack(alignment: .leading) {
                        Text("Full lock at \(Int(sensitivity))°")
                        Slider(value: $sensitivity, in: 12...45, step: 1)
                            .onChange(of: sensitivity) { new in
                                Persistence.shared.tiltSensitivity = new
                            }
                    }
                    Toggle("Vehicle mode", isOn: $vehicleMode)
                        .onChange(of: vehicleMode) { new in
                            Persistence.shared.vehicleMode = new
                            session.motion.vehicleMode = new
                        }
                } header: {
                    Text("Tilt")
                } footer: {
                    Text("A lower angle means a smaller wrist movement reaches full steering. "
                         + "Vehicle mode filters out the motion of a train or car.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
