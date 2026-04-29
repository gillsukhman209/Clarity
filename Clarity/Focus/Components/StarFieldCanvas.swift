//
//  StarFieldCanvas.swift
//  Clarity
//
//  Stars rendered through a Canvas. Each star is a single radial-gradient
//  fill — a smooth Gaussian-style falloff from a bright pinpoint core out
//  to transparent. This avoids the concentric-ring "donut" look that
//  layered solid circles create.
//

import SwiftUI

struct StarFieldCanvas: View {
    var seed: UInt64 = 0x5EED5
    var dimCount: Int = 80
    var midCount: Int = 36
    var brightCount: Int = 16

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            Canvas { ctx, size in
                let now = context.date.timeIntervalSinceReferenceDate
                var rng = SeededRandom(seed: seed)

                // Tier 1 — pinpoint background dust. Just tiny solid dots,
                // no glow at all. They suggest depth without bringing noise.
                for _ in 0..<dimCount {
                    let x = rng.uniform() * size.width
                    let y = rng.uniform() * size.height
                    let r = 0.5 + rng.uniform() * 0.5
                    let alpha = 0.25 + rng.uniform() * 0.25
                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
                }

                // Tier 2 — small stars with a single soft glow.
                for _ in 0..<midCount {
                    let x = rng.uniform() * size.width
                    let y = rng.uniform() * size.height
                    let r = 0.9 + rng.uniform() * 0.5
                    let coreAlpha = 0.70 + rng.uniform() * 0.20
                    drawSoftStar(ctx: ctx, x: x, y: y,
                                 coreRadius: r, glowRadius: r * 4,
                                 coreColor: .white,
                                 coreAlpha: coreAlpha,
                                 glowAlpha: 0.18)
                }

                // Tier 3 — bright twinkling stars with a wider soft glow.
                // Single radial gradient does ALL the work: bright at the
                // center, smoothly fading to clear. No banded rings.
                for i in 0..<brightCount {
                    let x = rng.uniform() * size.width
                    let y = rng.uniform() * size.height
                    let r = 1.2 + rng.uniform() * 0.8
                    let phase = rng.uniform() * .pi * 2
                    let twinkle = 0.55 + 0.45 * sin(now * 1.3 + Double(i) + phase)
                    let coreAlpha = 0.80 + 0.20 * twinkle

                    let tintRoll = rng.uniform()
                    let core: Color
                    if tintRoll < 0.15 {
                        core = Color(red: 1.0, green: 0.94, blue: 0.86)   // warm
                    } else if tintRoll < 0.30 {
                        core = Color(red: 0.86, green: 0.94, blue: 1.0)   // cool
                    } else {
                        core = .white
                    }

                    drawSoftStar(ctx: ctx, x: x, y: y,
                                 coreRadius: r, glowRadius: r * 6,
                                 coreColor: core,
                                 coreAlpha: coreAlpha,
                                 glowAlpha: 0.32 * twinkle)
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// Draw a star as a single Gaussian-style radial gradient — bright at
    /// center, smoothly fading to clear. Optionally a tiny solid pinpoint
    /// is drawn on top for the very brightest stars so the core reads sharp.
    private func drawSoftStar(
        ctx: GraphicsContext,
        x: Double, y: Double,
        coreRadius: Double,
        glowRadius: Double,
        coreColor: Color,
        coreAlpha: Double,
        glowAlpha: Double
    ) {
        let center = CGPoint(x: x, y: y)
        let glowRect = CGRect(
            x: x - glowRadius, y: y - glowRadius,
            width: glowRadius * 2, height: glowRadius * 2
        )

        // Soft glow — smooth falloff via radial gradient
        let glow = Gradient(stops: [
            .init(color: coreColor.opacity(glowAlpha),       location: 0.00),
            .init(color: coreColor.opacity(glowAlpha * 0.5), location: 0.20),
            .init(color: coreColor.opacity(0.0),             location: 1.00)
        ])
        ctx.fill(
            Path(ellipseIn: glowRect),
            with: .radialGradient(glow, center: center, startRadius: 0, endRadius: glowRadius)
        )

        // Tight pinpoint core — a small solid dot at the brightest center
        let coreRect = CGRect(
            x: x - coreRadius, y: y - coreRadius,
            width: coreRadius * 2, height: coreRadius * 2
        )
        ctx.fill(Path(ellipseIn: coreRect), with: .color(coreColor.opacity(coreAlpha)))
    }
}

private struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed | 1 }
    mutating func uniform() -> Double {
        state &*= 6364136223846793005
        state &+= 1442695040888963407
        let bits = (state >> 33) & 0x7FFFFFFF
        return Double(bits) / Double(0x7FFFFFFF)
    }
}
