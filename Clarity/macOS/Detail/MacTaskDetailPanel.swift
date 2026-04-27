//
//  MacTaskDetailPanel.swift
//  Clarity
//
//  Phase 4 — right-side panel showing the currently selected task.
//

#if os(macOS)
import SwiftUI

struct MacTaskDetailPanel: View {
    let task: PlanTask
    var onComplete: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    headerCard
                    timeAndPriority
                    if let notes = task.notes, !notes.isEmpty {
                        whyAndNotes(notes)
                    }
                    subtasks
                }
                .padding(AppSpacing.lg)
            }

            Divider().background(AppColors.divider)

            completeButton
                .padding(AppSpacing.lg)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(AppColors.surface)
    }

    // MARK: - Header
    private var headerCard: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(task.category.fillColor)
                    .frame(width: 44, height: 44)
                Image(systemName: task.category.sfSymbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(task.category.inkColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(AppTypography.title)
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                CategoryTag(category: task.category, showsIcon: true)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Time + Priority
    private var timeAndPriority: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: 6) {
                Text(task.timeRangeLabel)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                Text("(\(task.durationMinutes) minutes)")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
            }
            PriorityBadge(priority: task.priority)
        }
    }

    // MARK: - Why this first / notes
    private func whyAndNotes(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Why this first?")
                .font(AppTypography.captionSemibold)
                .tracking(0.6)
                .foregroundStyle(AppColors.textTertiary)
            Text(notes)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Subtasks
    @ViewBuilder
    private var subtasks: some View {
        if !task.subtasks.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Subtasks")
                    .font(AppTypography.captionSemibold)
                    .tracking(0.6)
                    .foregroundStyle(AppColors.textTertiary)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(task.subtasks) { sub in
                        HStack(spacing: 10) {
                            Image(systemName: sub.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(sub.isCompleted ? AppColors.accent : AppColors.textTertiary)
                            Text(sub.title)
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.textPrimary)
                                .strikethrough(sub.isCompleted, color: AppColors.textTertiary)
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Complete
    private var completeButton: some View {
        Button(action: onComplete) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 14, weight: .semibold))
                Text("Complete Task")
                    .font(AppTypography.bodySemibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Capsule(style: .continuous).fill(AppColors.accent))
        }
        .buttonStyle(.plain)
    }
}
#endif
