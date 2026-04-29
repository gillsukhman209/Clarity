//
//  StarFieldCanvas.swift
//  Clarity
//
//  Layered starfield rendered through a Canvas.
//
//  Three tiers:
//   - Tiny dim stars (background dust): many, very small, low alpha
//   - Mid stars: medium size, medium alpha
//   - Bright twinkling stars: larger, glow halo, sin-driven flicker
//
//  Stars are seeded so positions are stable across redraws.
//

import SwiftUI

struct StarFieldCanvas: View {
    var seed: UInt64 = 0x5EED5
    var dimCount: Int = 240
    var midCount: Int = 100
    var brightCount: Int = 50

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            Canvas { ctx, size in
                let now = context.date.timeIntervalSinceReferenceDate
                var rng = SeededRandom(seed: seed)

                // Tier 1 — tiny dim background dust
                for _ in 0..<dimCount {
                    let x = rng.uniform() * size.width
                    let y = rng.uniform() * size.height
                    let r = 0.5 + rng.uniform() * 0.7
                    let alpha = 0.30 + rng.uniform() * 0.30
                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
                }

                // Tier 2 — mid stars
                for _ in 0..<midCount {
                    let x = rng.uniform() * size.width
                    let y = rng.uniform() * size.height
                    let r = 0.9 + rng.uniform() * 0.9
                    let alpha = 0.55 + rng.uniform() * 0.30
                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
                }

                // Tier 3 — bright twinkling stars with halos
                for i in 0..<brightCount {
                    let x = rng.uniform() * size.width
                    let y = rng.uniform() * size.height
                    let r = 1.4 + rng.uniform() * 1.4
                    let phase = rng.uniform() * .pi * 2
                    let twinkle = 0.55 + 0.45 * sin(now * 1.5 + Double(i) + phase)
                    let alpha = 0.65 + 0.35 * twinkle

                    // Halo
                    let glowR = r * 4
                    let glow = CGRect(x: x - glowR, y: y - glowR, width: glowR * 2, height: glowR * 2)
                    ctx.fill(Path(ellipseIn: glow),
                             with: .color(.white.opacity(0.18 * twinkle)))

                    // Core
                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
                }
            }
        }
        .allowsHitTesting(false)
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
