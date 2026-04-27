//
//  Waveform.swift
//  Clarity
//

import SwiftUI

/// Decorative waveform built from a deterministic pseudo-noise function.
/// When `animated == true`, bars breathe over time via `TimelineView`.
struct Waveform: View {
    var barCount: Int = 56
    var minHeight: CGFloat = 4
    var maxHeight: CGFloat = 56
    var barWidth: CGFloat = 3
    var spacing: CGFloat = 4
    var color: Color = AppColors.accent
    var seed: Double = 0
    var animated: Bool = false

    var body: some View {
        if animated {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
                bars(phase: context.date.timeIntervalSinceReferenceDate)
            }
        } else {
            bars(phase: seed)
        }
    }

    private func bars(phase: Double) -> some View {
        HStack(alignment: .center, spacing: spacing) {
            ForEach(0..<barCount, id: \.self) { i in
                Capsule(style: .continuous)
                    .fill(color)
                    .frame(width: barWidth, height: height(for: i, phase: phase))
            }
        }
        .frame(height: maxHeight)
    }

    private func height(for index: Int, phase: Double) -> CGFloat {
        let n = Double(index) / Double(max(barCount - 1, 1))
        // Layered sines, modulated by `phase` so each frame shifts subtly.
        let p = phase * 1.6 + seed
        let a = sin(n * .pi * 7 + p)
        let b = sin(n * .pi * 3.1 + p * 0.5)
        let c = sin(n * .pi * 11.3 + p * 1.7)
        let mix = (abs(a) * 0.55) + (abs(b) * 0.30) + (abs(c) * 0.15)
        // Taper toward edges so the silhouette looks centered.
        let envelope = sin(n * .pi)
        let value = mix * envelope
        let h = CGFloat(value) * (maxHeight - minHeight) + minHeight
        return max(minHeight, min(maxHeight, h))
    }
}
