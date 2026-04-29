//
//  PhaseTimeline.swift
//  Clarity
//
//  Four-step track shown under the cosmic hero. Custom glyphs (not SF
//  Symbols) so it matches the mockup: Saturn for Focus, alarm clock for the
//  break phases, checkered flag for Complete.
//

import SwiftUI

struct PhaseTimeline: View {
    let mode: FocusMode
    let currentPhase: FocusPhase

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(FocusPhase.trackOrder.enumerated()), id: \.element) { idx, phase in
                stepView(phase: phase, isCurrent: phase == currentPhase, isPast: idx < currentIndex)
                if idx < FocusPhase.trackOrder.count - 1 {
                    connector(active: idx < currentIndex || idx == currentIndex - 1, isLeavingCurrent: idx == currentIndex)
                        .padding(.top, 18)
                }
            }
        }
    }

    private var currentIndex: Int {
        FocusPhase.trackOrder.firstIndex(of: currentPhase) ?? 0
    }

    // MARK: - Step

    private func stepView(phase: FocusPhase, isCurrent: Bool, isPast: Bool) -> some View {
        VStack(spacing: 6) {
            badge(for: phase, isCurrent: isCurrent, isPast: isPast)
            Text(phase.title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(isCurrent ? PomodoroPalette.accent : Color.white.opacity(0.65))
            Text(durationLabel(for: phase))
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
                .monospacedDigit()
        }
        .frame(width: 80)
    }

    private func badge(for phase: FocusPhase, isCurrent: Bool, isPast: Bool) -> some View {
        let glyphColor: Color = isCurrent
            ? PomodoroPalette.accent
            : Color.white.opacity(isPast ? 0.55 : 0.40)

        return ZStack {
            Circle()
                .fill(isCurrent ? PomodoroPalette.accent.opacity(0.18) : Color.white.opacity(0.04))
            Circle()
                .strokeBorder(
                    isCurrent ? PomodoroPalette.accent.opacity(0.85) : Color.white.opacity(0.18),
                    lineWidth: isCurrent ? 1.5 : 1
                )
            glyph(for: phase, color: glyphColor)
        }
        .frame(width: 38, height: 38)
        .shadow(color: isCurrent ? PomodoroPalette.accent.opacity(0.55) : .clear, radius: 10)
    }

    @ViewBuilder
    private func glyph(for phase: FocusPhase, color: Color) -> some View {
        switch phase {
        case .focus:
            SaturnGlyph(size: 18, color: color)
        case .shortBreak, .longBreak:
            AlarmGlyph(size: 18, color: color)
        case .complete:
            Image(systemName: "flag.checkered")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    private func durationLabel(for phase: FocusPhase) -> String {
        switch phase {
        case .complete: return ""
        default:        return "\(phase.minutes(for: mode)) min"
        }
    }

    // MARK: - Connector (dotted line, leading dots colored when current phase is in progress)

    private func connector(active: Bool, isLeavingCurrent: Bool) -> some View {
        // 8 evenly-spaced dots between the two badges. If the connector
        // immediately follows the current phase, the first 2-3 dots glow
        // accent; otherwise it's uniform muted.
        HStack(spacing: 4) {
            ForEach(0..<8, id: \.self) { i in
                let isLeading = isLeavingCurrent && i < 3
                Circle()
                    .fill(isLeading
                          ? PomodoroPalette.accent
                          : (active ? PomodoroPalette.accent.opacity(0.45) : Color.white.opacity(0.18)))
                    .frame(width: 3, height: 3)
            }
        }
        .frame(width: 60)
    }
}
