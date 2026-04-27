//
//  TaskBlock.swift
//  Clarity
//

import SwiftUI

/// A horizontal row representing a task in the day plan, matching the reference image.
/// - Soft pastel fill in the category color
/// - Colored left accent bar
/// - Title on the left, duration on the right
struct TaskBlock: View {
    let task: PlanTask
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(task.category.inkColor)
                .frame(width: 4)
                .padding(.vertical, 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(AppTypography.bodySemibold)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: AppSpacing.sm)

            Text(task.durationLabel)
                .font(AppTypography.captionMedium)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                .fill(task.category.fillColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                .stroke(isSelected ? AppColors.accent : .clear, lineWidth: isSelected ? 1.5 : 0)
        )
    }
}
