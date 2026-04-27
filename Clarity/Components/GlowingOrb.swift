//
//  GlowingOrb.swift
//  Clarity
//

import SwiftUI

/// The signature soft purple glowing orb used on the brain-dump and
/// building-plan screens. Phase 5: pulses softly when `isPulsing == true`.
struct GlowingOrb: View {
    var size: CGFloat = 180
    var isPulsing: Bool = false

    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            // Outermost halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppColors.accent.opacity(0.18),
                            AppColors.accent.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: size * 0.25,
                        endRadius: size * 0.95
                    )
                )
                .frame(width: size * 1.9, height: size * 1.9)
                .scaleEffect(1.0 + phase * 0.08)

            // Mid halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppColors.accent.opacity(0.28),
                            AppColors.accent.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: size * 0.15,
                        endRadius: size * 0.65
                    )
                )
                .frame(width: size * 1.35, height: size * 1.35)
                .scaleEffect(1.0 + phase * 0.05)

            // Core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            AppColors.accentSoft,
                            AppColors.accent.opacity(0.75)
                        ],
                        center: UnitPoint(x: 0.32, y: 0.28),
                        startRadius: 2,
                        endRadius: size * 0.7
                    )
                )
                .frame(width: size, height: size)
                .blur(radius: 1.5)
                .scaleEffect(1.0 + phase * 0.02)

            // Inner highlight
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.7), Color.white.opacity(0.0)],
                        center: UnitPoint(x: 0.3, y: 0.25),
                        startRadius: 1,
                        endRadius: size * 0.32
                    )
                )
                .frame(width: size, height: size)
        }
        .onAppear {
            if isPulsing { startPulse() }
        }
        .onChange(of: isPulsing) { _, newValue in
            if newValue { startPulse() } else { stopPulse() }
        }
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            phase = 1
        }
    }

    private func stopPulse() {
        withAnimation(.easeOut(duration: 0.3)) {
            phase = 0
        }
    }
}
