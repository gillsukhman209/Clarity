//
//  LiveWaveformBars.swift
//  Clarity
//
//  Phase 7 — visualizes a stream of normalized RMS values from `AudioRecorder`.
//

import SwiftUI

struct LiveWaveformBars: View {
    /// 0…1 values, oldest first.
    var levels: [Float]
    var barCount: Int = 48
    var minHeight: CGFloat = 4
    var maxHeight: CGFloat = 36
    var barWidth: CGFloat = 3
    var spacing: CGFloat = 4
    var color: Color = AppColors.accent

    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            ForEach(0..<barCount, id: \.self) { i in
                Capsule(style: .continuous)
                    .fill(color)
                    .frame(width: barWidth, height: height(for: i))
                    .animation(.easeOut(duration: 0.08), value: levels.count)
            }
        }
        .frame(height: maxHeight)
    }

    /// Map bar index → recent level. Index 0 is the oldest visible bar (left edge).
    private func height(for index: Int) -> CGFloat {
        let count = levels.count
        guard count > 0 else { return minHeight }

        let stride = max(1, count / barCount)
        let sourceIndex = min(count - 1, max(0, index * stride + (count - barCount * stride)))
        let value = CGFloat(levels[max(0, sourceIndex)])
        let h = value * (maxHeight - minHeight) + minHeight
        return max(minHeight, min(maxHeight, h))
    }
}
