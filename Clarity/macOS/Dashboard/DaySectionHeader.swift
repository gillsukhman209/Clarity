//
//  DaySectionHeader.swift
//  Clarity
//

#if os(macOS)
import SwiftUI

struct DaySectionHeader: View {
    let section: DaySection

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(section.accentColor.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: section.sfSymbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(section.accentColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(section.title)
                    .font(AppTypography.titleSmall)
                    .foregroundStyle(AppColors.textPrimary)
                Text(section.subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            Text(section.totalDurationLabel)
                .font(AppTypography.captionSemibold)
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(.vertical, 4)
    }
}
#endif
