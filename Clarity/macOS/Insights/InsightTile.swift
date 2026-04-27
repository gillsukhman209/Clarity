//
//  InsightTile.swift
//  Clarity
//

#if os(macOS)
import SwiftUI

struct InsightTile: View {
    let symbol: String
    let title: String
    let value: String
    let subtitle: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accent)
                Text(title)
                    .font(AppTypography.captionSemibold)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Text(value)
                .font(AppTypography.title)
                .foregroundStyle(AppColors.textPrimary)
            Text(subtitle)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .fill(accent.opacity(0.10))
        )
    }
}
#endif
