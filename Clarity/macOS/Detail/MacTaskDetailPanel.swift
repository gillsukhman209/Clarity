//
//  MacTaskDetailPanel.swift
//  Clarity
//
//  Phase 4 — right-side panel showing the currently selected task.
//  Phase 6 — reads from TaskStore by ID, supports complete + subtask toggles.
//

#if os(macOS)
import SwiftUI

struct MacTaskDetailPanel: View {
    let taskID: UUID
    var onComplete: () -> Void = {}

    @Environment(TaskStore.self) private var store

    var body: some View {
        Group {
            if let task = store.task(with: taskID) {
                content(for: task)
            } else {
                missing
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(AppColors.surface)
        .overlay(alignment: .topTrailing) {
            closeButton
                .padding(AppSpacing.sm)
        }
    }

    private var closeButton: some View {
        HoverScaleButton(action: onComplete, hoverScale: 1.08) {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 24, height: 24)
                .background(
                    Circle().fill(AppColors.background)
                )
                .overlay(
                    Circle().stroke(AppColors.border, lineWidth: 1)
                )
        }
        .accessibilityLabel("Close task details")
    }

    private var missing: some View {
        VStack(spacing: AppSpacing.xs) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
            Text("Task no longer exists")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func content(for task: PlanTask) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    headerCard(task)
                    timeAndPriority(task)
                    if let notes = task.notes, !notes.isEmpty {
                        whyAndNotes(notes)
                    }
                    subtasksSection(task)
                }
                .padding(AppSpacing.lg)
            }

            Divider().background(AppColors.divider)

            VStack(spacing: AppSpacing.sm) {
                completeButton(task)
                deleteButton(task)
            }
            .padding(AppSpacing.lg)
        }
    }

    // MARK: - Header
    private func headerCard(_ task: PlanTask) -> some View {
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
                    .strikethrough(task.isCompleted, color: AppColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                CategoryTag(category: task.category, showsIcon: true)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Time + Priority
    private func timeAndPriority(_ task: PlanTask) -> some View {
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
    private func subtasksSection(_ task: PlanTask) -> some View {
        if !task.subtasks.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Subtasks")
                    .font(AppTypography.captionSemibold)
                    .tracking(0.6)
                    .foregroundStyle(AppColors.textTertiary)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(task.subtasks) { sub in
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                store.toggleSubtask(taskID: task.id, subtaskID: sub.id)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: sub.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(sub.isCompleted ? AppColors.accent : AppColors.textTertiary)
                                    .symbolEffect(.bounce, value: sub.isCompleted)
                                Text(sub.title)
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColors.textPrimary)
                                    .strikethrough(sub.isCompleted, color: AppColors.textTertiary)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Complete
    private func completeButton(_ task: PlanTask) -> some View {
        HoverScaleButton(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                store.toggleComplete(task.id)
            }
        }, hoverScale: 1.02) {
            HStack(spacing: 8) {
                Image(systemName: task.isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle")
                    .font(.system(size: 14, weight: .semibold))
                Text(task.isCompleted ? "Mark as Incomplete" : "Complete Task")
                    .font(AppTypography.bodySemibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Capsule(style: .continuous).fill(AppColors.accent))
        }
    }

    // MARK: - Delete
    private func deleteButton(_ task: PlanTask) -> some View {
        HoverScaleButton(action: {
            store.delete(task.id)
            onComplete()
        }, hoverScale: 1.02) {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .semibold))
                Text("Delete Task")
                    .font(AppTypography.bodySemibold)
            }
            .foregroundStyle(AppColors.Priority.highInk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .stroke(AppColors.Priority.highInk.opacity(0.4), lineWidth: 1)
            )
        }
    }
}
#endif
