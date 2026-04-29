//
//  CosmicBackdrop.swift
//  Clarity
//
//  Window-wide cosmic atmosphere: pure cosmic black + subtle corner nebula
//  + starfield + occasional shooting star. Painted as the background of the
//  entire app when on the Pomodoro tab — sidebar, main column, and right
//  column all share the same continuous canvas.
//
//  Brightness budget here is intentionally low. The bright focal elements
//  (planet, progress arc, comet) live in CosmicHero and sit on top of this.
//

import SwiftUI

struct CosmicBackdrop: View {
    var body: some View {
        ZStack {
            PomodoroPalette.space
            galaxyClusters
            StarFieldCanvas(seed: 0xC05A1C, dimCount: 90, midCount: 36, brightCount: 18)
            shootingStar
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Wispy galaxy clusters
    //
    // Instead of one solid colored disc per nebula, each "galaxy" is a stack
    // of 3 overlapping soft circles with slight offsets and dual-color tint.
    // This makes the shape irregular so it reads as cosmic dust, not a UFO.

    private var galaxyClusters: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                galaxyCluster(
                    center: CGPoint(x: w * 0.95, y: h * 0.20),
                    primary:   Color(pomHex: 0x4F5FB0),
                    secondary: Color(pomHex: 0x8F4F95),
                    size: w * 0.36
                )
                galaxyCluster(
                    center: CGPoint(x: w * 0.97, y: h * 0.72),
                    primary:   Color(pomHex: 0xA04F75),
                    secondary: Color(pomHex: 0x6F4F90),
                    size: w * 0.32
                )
                galaxyCluster(
                    center: CGPoint(x: w * 0.04, y: h * 0.92),
                    primary:   Color(pomHex: 0x5A3FA0),
                    secondary: Color(pomHex: 0x4F4F95),
                    size: w * 0.26
                )
                galaxyCluster(
                    center: CGPoint(x: w * 0.08, y: h * 0.18),
                    primary:   Color(pomHex: 0x3F4FA0),
                    secondary: Color(pomHex: 0x6F4FA0),
                    size: w * 0.24
                )
            }
            .blendMode(.screen)
            .allowsHitTesting(false)
        }
    }

    private func galaxyCluster(center: CGPoint, primary: Color, secondary: Color, size: CGFloat) -> some View {
        ZStack {
            // Largest, dimmest base — sets the overall glow envelope
            Circle()
                .fill(primary)
                .frame(width: size, height: size)
                .blur(radius: size * 0.40)
                .opacity(0.16)
                .offset(x: -size * 0.05, y: size * 0.04)

            // Mid lobe — secondary color, slightly offset for irregularity
            Circle()
                .fill(secondary)
                .frame(width: size * 0.72, height: size * 0.72)
                .blur(radius: size * 0.32)
                .opacity(0.13)
                .offset(x: size * 0.18, y: -size * 0.08)

            // Tight bright core — small and slightly off-center, suggests
            // a dense star cluster at the heart of the galaxy
            Circle()
                .fill(primary)
                .frame(width: size * 0.45, height: size * 0.45)
                .blur(radius: size * 0.22)
                .opacity(0.18)
                .offset(x: size * 0.06, y: -size * 0.02)
        }
        .position(x: center.x, y: center.y)
    }

    // MARK: - Shooting star (occasional)

    private var shootingStar: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let cycle = t.truncatingRemainder(dividingBy: 11) / 11
            let visible = cycle < 0.18
            let p = cycle / 0.18

            GeometryReader { proxy in
                ZStack(alignment: .topLeading) {
                    if visible {
                        let startX = proxy.size.width * 0.20
                        let startY = proxy.size.height * 0.55
                        let dx     = proxy.size.width  * 0.30
                        let dy     = -proxy.size.height * 0.40
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white, .white.opacity(0.95), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 110, height: 1.6)
                            .rotationEffect(.degrees(-22))
                            .position(x: startX + p * dx, y: startY + p * dy)
                            .opacity(sin(p * .pi))
                            .shadow(color: .white.opacity(0.85), radius: 8)
                            .shadow(color: PomodoroPalette.accent.opacity(0.55), radius: 14)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}
