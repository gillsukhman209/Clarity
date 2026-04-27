//
//  MicButton.swift
//  Clarity
//

import SwiftUI

/// The signature floating purple mic button. Available in three sizes:
///  - .floating  (FAB on day plan)
///  - .large     (centerpiece on the home brain-dump screen)
///  - .compact   (inline)
struct MicButton: View {
    enum Size {
        case compact
        case floating
        case large
    }

    var size: Size = .floating
    var isActive: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            ZStack {
                if size == .large {
                    // Outer glow rings for the home screen orb
                    Circle()
                        .fill(AppColors.accent.opacity(0.10))
                        .frame(width: diameter + 60, height: diameter + 60)
                    Circle()
                        .fill(AppColors.accent.opacity(0.16))
                        .frame(width: diameter + 30, height: diameter + 30)
                }

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.accent.opacity(0.95),
                                AppColors.accent
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: diameter, height: diameter)
                    .appShadow(AppShadow.micGlow)

                Image(systemName: "mic.fill")
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .scaleEffect(isActive ? 1.04 : 1.0)
            .animation(.easeInOut(duration: 0.18), value: isActive)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Microphone")
    }

    private var diameter: CGFloat {
        switch size {
        case .compact:  return 44
        case .floating: return 56
        case .large:    return 140
        }
    }

    private var iconSize: CGFloat {
        switch size {
        case .compact:  return 18
        case .floating: return 22
        case .large:    return 48
        }
    }
}
