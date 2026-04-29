//
//  PlanetView.swift
//  Clarity
//
//  3D-feeling planet for the Pomodoro hero. Layers, back → front:
//   - Atmospheric halo (violet aura wrapping the body)
//   - Sphere body (radial gradient with off-center light source)
//   - Limb darkening (radial inset for the curvature illusion)
//   - Specular highlight on the lit side
//   - Saturn ring, with the back half visually masked behind the body
//

import SwiftUI

struct PlanetView: View {
    /// Diameter of the planet body, in points.
    let size: CGFloat
    /// Accent color for halo, ring, specular highlight (drifts during the
    /// session — passed in by the hero).
    let accent: Color

    var body: some View {
        ZStack {
            // 1. Atmospheric halo — wraps the planet, brightest on lit side
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .clear,
                            accent.opacity(0.55),
                            accent.opacity(0.30),
                            .clear
                        ],
                        center: UnitPoint(x: 0.62, y: 0.38),
                        startRadius: size * 0.42,
                        endRadius: size * 0.95
                    )
                )
                .frame(width: size * 1.8, height: size * 1.8)
                .blur(radius: 14)
                .blendMode(.screen)

            // 2. Saturn ring — BACK half, drawn before the planet body so the
            //    body covers it for the occlusion illusion.
            saturnRingBack
                .opacity(0.95)

            // 3. Sphere body
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(pomHex: 0x4A2F90),     // bright lit side
                            Color(pomHex: 0x261647),
                            Color(pomHex: 0x0A0518)      // deep shadow
                        ],
                        center: UnitPoint(x: 0.72, y: 0.28),
                        startRadius: 0,
                        endRadius: size * 0.85
                    )
                )
                .frame(width: size, height: size)

            // 4. Limb darkening — a radial gradient from clear at center to
            //    black on the rim, blended in to deepen the silhouette.
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

            // 5. Specular highlight crescent on the upper-right
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

            // 6. Saturn ring — FRONT half, drawn ABOVE the body so it appears
            //    to wrap around. The back half (drawn earlier) is occluded.
            saturnRingFront
        }
    }

    // MARK: - Saturn ring (split into back / front halves for occlusion)

    /// The full ring as a single ellipse stroke, used by both halves.
    private var ringEllipse: some Shape {
        Ellipse()
    }

    private var ringDimensions: (w: CGFloat, h: CGFloat, tilt: Double) {
        (w: size * 1.62, h: size * 0.30, tilt: -12)
    }

    /// Back half: the part of the ring that should appear behind the planet.
    /// Rendered before the body so the body's circle covers it. Plus a tiny
    /// peek of the very edges (left + right tips) that should still be
    /// visible since they sit outside the body's silhouette.
    private var saturnRingBack: some View {
        let dim = ringDimensions
        return Ellipse()
            .stroke(accent.opacity(0.90), lineWidth: 1.4)
            .frame(width: dim.w, height: dim.h)
            .rotationEffect(.degrees(dim.tilt))
            .shadow(color: accent.opacity(0.55), radius: 8)
    }

    /// Front half: only the lower portion of the ring (which would pass
    /// IN FRONT of the body in a 3D view). We mask the upper half away.
    private var saturnRingFront: some View {
        let dim = ringDimensions
        return Ellipse()
            .stroke(accent.opacity(0.90), lineWidth: 1.4)
            .frame(width: dim.w, height: dim.h)
            .rotationEffect(.degrees(dim.tilt))
            .mask(
                // Only the bottom half of the ring is in front of the planet.
                // We tilt the mask to match the ring tilt so the seam looks clean.
                Rectangle()
                    .frame(width: dim.w * 1.2, height: dim.h)
                    .offset(y: dim.h * 0.5)
                    .rotationEffect(.degrees(dim.tilt))
            )
            .shadow(color: accent.opacity(0.6), radius: 8)
            .blendMode(.screen)
    }
}
