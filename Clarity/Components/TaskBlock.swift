//
//  TaskBlock.swift
//  Clarity
//
//  A horizontal row representing a task in the day plan.
//  - Soft pastel fill in the category color
//  - Colored left accent bar
//  - Title on the left
//  - On the right: how long until the task starts, but only if it's today
//    and still in the future. Otherwise nothing.
//  - Subtle hover lift on macOS
//  - Strikethrough + dimmed when completed
//

import SwiftUI

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

            Text(task.title)
                .font(AppTypography.bodySemibold)
                .foregroundStyle(AppColors.textPrimary)
                .strikethrough(task.isCompleted, color: AppColors.textTertiary)
                .lineLimit(1)

            Spacer(minLength: AppSpacing.sm)

            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
            }

            countdown
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

    // MARK: - Countdown

    /// "in 30m" / "in 1h 15m" — only for tasks scheduled today that haven't
    /// started yet. Updates each minute via TimelineView so the value stays
    /// current while the user is looking at the screen.
    @ViewBuilder
    private var countdown: some View {
        if Calendar.current.isDateInToday(task.startTime), !task.isCompleted {
            TimelineView(.everyMinute) { context in
                if let label = countdownLabel(now: context.date) {
                    Text(label)
                        .font(AppTypography.captionMedium)
                        .foregroundStyle(AppColors.textSecondary)
                        .monospacedDigit()
                }
            }
        }
    }

    private func countdownLabel(now: Date) -> String? {
        let secondsUntil = task.startTime.timeIntervalSince(now)
        guard secondsUntil > 0 else { return nil }

        let minutes = Int((secondsUntil / 60).rounded())
        if minutes < 1 { return "now" }
        if minutes < 60 { return "in \(minutes)m" }

        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "in \(h)h" : "in \(h)h \(m)m"
    }
}
