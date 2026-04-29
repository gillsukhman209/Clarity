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
            cornerNebula
            StarFieldCanvas(seed: 0xC05A1C, dimCount: 320, midCount: 110, brightCount: 42)
            shootingStar
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Corner nebula (subtle, no central bloom)

    private var cornerNebula: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                blob(color: Color(pomHex: 0x3F4FA0),
                     size: w * 0.45, x: w * 0.10, y: h * 0.18, opacity: 0.14)
                blob(color: Color(pomHex: 0xA04F75),
                     size: w * 0.40, x: w * 0.95, y: h * 0.85, opacity: 0.12)
                blob(color: Color(pomHex: 0x5A3FA0),
                     size: w * 0.34, x: w * 0.05, y: h * 0.92, opacity: 0.10)
                blob(color: Color(pomHex: 0x4F3F95),
                     size: w * 0.36, x: w * 0.95, y: h * 0.20, opacity: 0.10)
            }
            .blendMode(.screen)
            .allowsHitTesting(false)
        }
    }

    private func blob(color: Color, size: CGFloat, x: CGFloat, y: CGFloat, opacity: Double) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: size * 0.32)
            .opacity(opacity)
            .position(x: x, y: y)
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
