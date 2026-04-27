//
//  ProductivityGauge.swift
//  Clarity
//

#if os(macOS)
import SwiftUI

struct ProductivityGauge: View {
    var score: Int        // 0–100
    var caption: String

    private let trackColor = AppColors.divider
    private let arcStart: Double = 0.625   // ~225°  (lower-left)
    private let arcSweep: Double = 0.75    // 270° total arc

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            ZStack {
                // Track
                Circle()
                    .trim(from: arcStart, to: arcStart + arcSweep)
                    .stroke(trackColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(0))

                // Progress
                Circle()
                    .trim(
                        from: arcStart,
                        to: arcStart + arcSweep * Double(min(max(score, 0), 100)) / 100.0
                    )
                    .stroke(
                        AngularGradient(
                            colors: [
                                AppColors.Priority.lowInk.opacity(0.85),
                                AppColors.accent
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )

                VStack(spacing: 0) {
                    Text("\(score)")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("/100")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .offset(y: -2)
            }
            .frame(width: 130, height: 130)

            Text(caption)
                .font(AppTypography.captionSemibold)
                .foregroundStyle(AppColors.Priority.lowInk)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}
#endif
