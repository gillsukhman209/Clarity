//
//  PlanetView.swift
//  Clarity
//
//  3D-feeling planet for the Pomodoro hero. Layers, back → front:
//   1. Wide soft atmospheric scatter (very dim, all directions — sets the
//      overall halo envelope so the planet doesn't sit in flat black)
//   2. Directional limb glow — bright crescent ONLY on the lit side via an
//      AngularGradient. Replaces the harsh full-ring halo.
//   3. Saturn ring back half (drawn before the body for occlusion)
//   4. Sphere body — radial gradient with off-center light source
//   5. Limb darkening — multiplied black gradient deepening the rim
//   6. Specular highlight crescent on the lit side
//   7. Saturn ring front half — masked to the lower portion so it appears
//      to wrap around the planet
//

import SwiftUI

struct PlanetView: View {
    let size: CGFloat
    let accent: Color

    var body: some View {
        ZStack {
            // 1. Wide soft ambient scattering
            Circle()
                .fill(accent)
                .frame(width: size * 1.55, height: size * 1.55)
                .blur(radius: size * 0.28)
                .opacity(0.14)

            // 2. Directional limb glow — bright crescent on the lit side.
            //    AngularGradient sweeps from -90° (top), brightest just past
            //    1-3 o'clock, fading back to clear by 5 o'clock and staying
            //    clear around the dark side.
            Circle()
                .fill(
                    AngularGradient(
                        stops: [
                            .init(color: .clear,                    location: 0.00),
                            .init(color: .clear,                    location: 0.05),
                            .init(color: accent.opacity(0.55),      location: 0.16),
                            .init(color: accent.opacity(0.95),      location: 0.26),
                            .init(color: accent,                    location: 0.30),
                            .init(color: accent.opacity(0.85),      location: 0.36),
                            .init(color: accent.opacity(0.40),      location: 0.46),
                            .init(color: .clear,                    location: 0.58),
                            .init(color: .clear,                    location: 1.00)
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    )
                )
                .frame(width: size * 1.14, height: size * 1.14)
                .blur(radius: size * 0.07)
                .blendMode(.screen)

            // 3. Saturn ring — back half (will be partially covered by body)
            saturnRingBack

            // 4. Sphere body
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(pomHex: 0x4A2F90),
                            Color(pomHex: 0x261647),
                            Color(pomHex: 0x0A0518)
                        ],
                        center: UnitPoint(x: 0.72, y: 0.28),
                        startRadius: 0,
                        endRadius: size * 0.85
                    )
                )
                .frame(width: size, height: size)

            // 5. Limb darkening — deepens the rim for sphere illusion
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.clear, .clear, .black.opacity(0.55)],
                        center: .center,
                        startRadius: size * 0.20,
                        endRadius: size * 0.50
                    )
                )
                .frame(width: size, height: size)
                .blendMode(.multiply)

            // 6. Specular highlight crescent on the upper-right
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accent.opacity(0.55), .clear],
                        center: UnitPoint(x: 0.78, y: 0.28),
                        startRadius: 0,
                        endRadius: size * 0.30
                    )
                )
                .frame(width: size, height: size)
                .blendMode(.screen)

            // 7. Saturn ring — front half (only lower portion visible)
            saturnRingFront
        }
    }

    // MARK: - Saturn ring (split for occlusion illusion)

    private var ringDimensions: (w: CGFloat, h: CGFloat, tilt: Double) {
        (w: size * 1.62, h: size * 0.30, tilt: -12)
    }

    private var saturnRingBack: some View {
        let dim = ringDimensions
        return Ellipse()
            .stroke(accent.opacity(0.85), lineWidth: 1.2)
            .frame(width: dim.w, height: dim.h)
            .rotationEffect(.degrees(dim.tilt))
            .shadow(color: accent.opacity(0.55), radius: 8)
    }

    private var saturnRingFront: some View {
        let dim = ringDimensions
        return Ellipse()
            .stroke(accent.opacity(0.90), lineWidth: 1.2)
            .frame(width: dim.w, height: dim.h)
            .rotationEffect(.degrees(dim.tilt))
            .mask(
                Rectangle()
                    .frame(width: dim.w * 1.2, height: dim.h)
                    .offset(y: dim.h * 0.5)
                    .rotationEffect(.degrees(dim.tilt))
            )
            .shadow(color: accent.opacity(0.6), radius: 8)
            .blendMode(.screen)
    }
}
