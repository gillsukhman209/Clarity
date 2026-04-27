//
//  Waveform.swift
//  Clarity
//

import SwiftUI

/// Static decorative waveform built from a deterministic pseudo-noise function.
/// Real audio levels arrive in a later phase.
struct Waveform: View {
    var barCount: Int = 56
    var minHeight: CGFloat = 4
    var maxHeight: CGFloat = 56
    var barWidth: CGFloat = 3
    var spacing: CGFloat = 4
    var color: Color = AppColors.accent
    var seed: Double = 0

    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            ForEach(0..<barCount, id: \.self) { i in
                Capsule(style: .continuous)
                    .fill(color)
                    .frame(width: barWidth, height: height(for: i))
            }
        }
        .frame(height: maxHeight)
    }

    private func height(for index: Int) -> CGFloat {
        let n = Double(index) / Double(max(barCount - 1, 1))
        // Layered sines give a varied, audio-ish silhouette without randomness.
        let a = sin(n * .pi * 7 + seed)
        let b = sin(n * .pi * 3.1 + seed * 0.5)
        let c = sin(n * .pi * 11.3 + seed * 1.7)
        let mix = (abs(a) * 0.55) + (abs(b) * 0.30) + (abs(c) * 0.15)
        // Taper toward the edges so it looks like a centered audio clip.
        let envelope = sin(n * .pi)
        let value = mix * envelope
        let h = CGFloat(value) * (maxHeight - minHeight) + minHeight
        return max(minHeight, min(maxHeight, h))
    }
}
