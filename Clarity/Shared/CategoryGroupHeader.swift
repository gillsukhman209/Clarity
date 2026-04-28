//
//  CategoryGroupHeader.swift
//  Clarity
//
//  Header row for the grouped-by-category view. Cross-platform — used on
//  both iOS DayPlanView and macOS DashboardView.
//

import SwiftUI

struct CategoryGroupHeader: View {
    let group: CategoryGroup

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(group.fillColor.opacity(0.55))
                    .frame(width: 32, height: 32)
                Image(systemName: group.sfSymbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(group.accentColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(group.title)
                    .font(AppTypography.titleSmall)
                    .foregroundStyle(AppColors.textPrimary)
                Text(taskCountLabel)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            if let total = group.totalDurationLabel {
                Text(total)
                    .font(AppTypography.captionSemibold)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var taskCountLabel: String {
        let count = group.tasks.count
        return count == 1 ? "1 task" : "\(count) tasks"
    }
}
