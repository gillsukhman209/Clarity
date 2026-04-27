//
//  TaskBlock.swift
//  Clarity
//

import SwiftUI

/// A horizontal row representing a task in the day plan, matching the reference image.
/// - Soft pastel fill in the category color
/// - Colored left accent bar
/// - Title on the left, duration on the right
/// - Subtle hover lift on macOS
/// - Strikethrough + dimmed when completed
struct TaskBlock: View {
    let task: PlanTask
    var isSelected: Bool = false

    @State private var isHovered: Bool = false

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
                    .strikethrough(task.isCompleted, color: AppColors.textTertiary)
                    .lineLimit(1)
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: AppSpacing.sm)

            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
            }

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
        .opacity(task.isCompleted ? 0.55 : 1.0)
        .scaleEffect(isHovered && !isSelected ? 1.005 : 1.0)
        .shadow(
            color: Color.black.opacity(isHovered ? 0.06 : 0),
            radius: isHovered ? 6 : 0,
            x: 0,
            y: isHovered ? 2 : 0
        )
        .animation(.easeOut(duration: 0.14), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onHover { isHovered = $0 }
    }
}
