//
//  CosmicHero.swift
//  Clarity
//
//  Cinematic Pomodoro centerpiece. 9 layers, back → front:
//   1. Pure cosmic black (PomodoroPalette.space) — same as the rest of the app
//   2. Corner-only nebula (3 tiny soft radials, NOT central)
//   3. Three-tier starfield (Canvas)
//   4. Concentric ghost orbital rings
//   5. Outer progress arc + glowing comet head
//   6. Slow-traveling moon dots
//   7. Planet (delegated to PlanetView)
//   8. Occasional shooting star
//   9. Countdown overlay (eyebrow + numerals + glass pause pill)
//
//  Brightness budget is reserved for the planet rim, the progress arc, and
//  the comet. No central bloom. No bright nebula bloom.
//

import SwiftUI

struct CosmicHero: View {
    let phase: FocusPhase
    let progress: Double
    let countdown: String
    let isPaused: Bool
    let isIdle: Bool
    var onTogglePause: () -> Void
    var onStart: () -> Void = {}

    var body: some View {
        // The window-wide CosmicBackdrop owns the black, nebula, stars, and
        // shooting star — they run across sidebar/main/right as one canvas.
        // Here we only paint the focal cosmic system + countdown overlay.
        ZStack {
            GeometryReader { proxy in
                let side = min(proxy.size.width, proxy.size.height) * 0.92
                CosmicSystem(
                    side: side,
                    progress: progress,
                    accent: phaseAccent
                )
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            countdownOverlay
        }
    }

    // MARK: - Countdown overlay

    private var countdownOverlay: some View {
        VStack(spacing: 14) {
            Text(phase.eyebrow)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(2.5)
                .foregroundStyle(.white.opacity(0.92))

            Text(countdown)
                .font(.system(size: 78, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .shadow(color: phaseAccent.opacity(0.65), radius: 26, x: 0, y: 0)

            actionButton.padding(.top, 4)
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var actionButton: some View {
        if isIdle {
            actionPill(symbol: "play.fill", title: "Start", action: onStart)
        } else {
            actionPill(symbol: isPaused ? "play.fill" : "pause.fill",
                       title: isPaused ? "Resume" : "Pause",
                       action: onTogglePause)
        }
    }

    private func actionPill(symbol: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 11)
            .background(Capsule(style: .continuous).fill(.white.opacity(0.10)))
            .overlay(Capsule(style: .continuous).stroke(.white.opacity(0.30), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Phase accent

    private var phaseAccent: Color {
        switch phase {
        case .focus:
            // Drifts cool → warm as the focus session progresses.
            let cool = Color(pomHex: 0x9F84FF)
            let warm = Color(pomHex: 0xE38AB6)
            return blend(cool, warm, t: progress)
        case .shortBreak: return Color(pomHex: 0x73D8C2)
        case .longBreak:  return Color(pomHex: 0x8CC8F2)
        case .complete:   return Color(pomHex: 0xF2C173)
        }
    }

    private func blend(_ a: Color, _ b: Color, t: Double) -> Color {
        let p = max(0, min(1, t))
        let aC = a.resolved()
        let bC = b.resolved()
        return Color(
            red:   aC.r + (bC.r - aC.r) * p,
            green: aC.g + (bC.g - aC.g) * p,
            blue:  aC.b + (bC.b - aC.b) * p
        )
    }
}

// MARK: - Cosmic system (rings + arc + comet + moons + planet)

private struct CosmicSystem: View {
    let side: CGFloat
    let progress: Double
    let accent: Color

    var body: some View {
        ZStack {
            // Three concentric ghost orbital rings
            Circle().stroke(.white.opacity(0.08), lineWidth: 0.9)
                .frame(width: side * 0.66, height: side * 0.66)
            Circle().stroke(.white.opacity(0.10), lineWidth: 0.9)
                .frame(width: side * 0.82, height: side * 0.82)
            Circle().stroke(.white.opacity(0.14), lineWidth: 0.9)
                .frame(width: side, height: side)

            outerProgressArc
            moons
            PlanetView(size: side * 0.42, accent: accent)
        }
        .frame(width: side, height: side)
    }

    // MARK: - Progress arc + comet

    private var outerProgressArc: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(
                    AngularGradient(
                        colors: [accent.opacity(0.0), accent.opacity(0.7), accent, accent],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 1.8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: side, height: side)
                .shadow(color: accent.opacity(0.85), radius: 16)
                .animation(.linear(duration: 0.3), value: progress)

            // White dot at the start (12 o'clock)
            Circle()
                .fill(.white)
                .frame(width: 4, height: 4)
                .offset(y: -side / 2)
                .shadow(color: .white.opacity(0.7), radius: 4)

            cometHead
        }
    }

    private var cometHead: some View {
        let radius = side / 2
        let angleDeg = -90.0 + progress * 360.0
        let angleRad = angleDeg * .pi / 180
        let x = cos(angleRad) * radius
        let y = sin(angleRad) * radius
        return ZStack {
            Circle()
                .fill(accent.opacity(0.55))
                .frame(width: 32, height: 32)
                .blur(radius: 12)
            Circle()
                .fill(.white)
                .frame(width: 8, height: 8)
                .shadow(color: accent, radius: 12)
                .shadow(color: .white, radius: 4)
        }
        .offset(x: x, y: y)
        .animation(.linear(duration: 0.3), value: progress)
    }

    // MARK: - Moons on inner rings

    private var moons: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                moon(period: 24, ringScale: 0.88, baseAngle: 20,   size: 4.5, t: t)
                moon(period: 36, ringScale: 0.66, baseAngle: 130,  size: 3.5, t: t)
                moon(period: 18, ringScale: 0.78, baseAngle: 240,  size: 3,   t: t)
            }
        }
    }

    private func moon(period: Double, ringScale: Double, baseAngle: Double, size: CGFloat, t: TimeInterval) -> some View {
        let radius = (side * ringScale) / 2
        let angle = baseAngle + (t.truncatingRemainder(dividingBy: period) / period) * 360
        let r = angle * .pi / 180
        let x = cos(r) * radius
        let y = sin(r) * radius
        return Circle()
            .fill(.white)
            .frame(width: size, height: size)
            .shadow(color: .white.opacity(0.7), radius: 5)
            .offset(x: x, y: y)
    }
}

// MARK: - Color resolution helper

private extension Color {
    struct Components { let r: Double; let g: Double; let b: Double }
    func resolved() -> Components {
        #if canImport(UIKit)
        let c = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return Components(r: Double(r), g: Double(g), b: Double(b))
        #elseif canImport(AppKit)
        let c = NSColor(self).usingColorSpace(.sRGB) ?? .gray
        return Components(r: Double(c.redComponent), g: Double(c.greenComponent), b: Double(c.blueComponent))
        #else
        return Components(r: 0.5, g: 0.5, b: 0.5)
        #endif
    }
}
