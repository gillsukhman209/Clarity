//
//  TaskDetailView.swift
//  Clarity
//
//  Phase 3 — task details sheet.
//  Phase 6 — reads from `TaskStore` and wires Mark Complete + Delete.
//

import SwiftUI

struct TaskDetailView: View {
    let taskID: UUID
    var onClose: () -> Void = {}

    @Environment(TaskStore.self) private var store

    var body: some View {
        if let task = store.task(with: taskID) {
            content(for: task)
        } else {
            // Task was deleted while open — fall back to a tidy empty state.
            missing
        }
    }

    private func content(for task: PlanTask) -> some View {
        VStack(spacing: 0) {
            topBar
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSpacing.lg) {
                    iconAndTitle(task)
                    detailsCard(task)
                    if let notes = task.notes, !notes.isEmpty {
                        notesSection(notes)
                    }
                    actions(task)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .background(AppColors.background)
    }

    private var missing: some View {
        VStack(spacing: AppSpacing.sm) {
            topBar
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
            Text("Task no longer exists")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
        }
        .background(AppColors.background)
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack {
            Button("Close", action: onClose)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text("Task Details")
                .font(AppTypography.titleSmall)
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Button("Edit") {}
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.accent)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - Icon + title
    private func iconAndTitle(_ task: PlanTask) -> some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(task.category.fillColor)
                    .frame(width: 86, height: 86)
                Image(systemName: task.category.sfSymbol)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(task.category.inkColor)
            }
            Text(task.title)
                .font(AppTypography.displayMedium)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.md)
            Text(task.category.title)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(task.category.inkColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.md)
    }

    // MARK: - Details card
    private func detailsCard(_ task: PlanTask) -> some View {
        AppCard(padding: 0, cornerRadius: AppRadius.large) {
            VStack(spacing: 0) {
                detailRow(label: "Duration", value: AnyView(
                    Text("\(task.durationMinutes) minutes")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                ))
                Divider().background(AppColors.divider)
                detailRow(label: "Start Time", value: AnyView(
                    Text(task.startTimeLabel)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                ))
                Divider().background(AppColors.divider)
                detailRow(label: "Priority", value: AnyView(
                    PriorityBadge(priority: task.priority, compact: true)
                ))
                Divider().background(AppColors.divider)
                detailRow(label: "Category", value: AnyView(
                    CategoryTag(category: task.category, showsIcon: true)
                ))
            }
        }
    }

    private func detailRow(label: String, value: AnyView) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            value
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 14)
    }

    // MARK: - Notes
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Notes")
                .font(AppTypography.captionSemibold)
                .tracking(0.6)
                .foregroundStyle(AppColors.textTertiary)
            AppCard {
                Text(notes)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Actions
    private func actions(_ task: PlanTask) -> some View {
        VStack(spacing: AppSpacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.toggleComplete(task.id)
                }
                onClose()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: task.isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle")
                        .font(.system(size: 16, weight: .semibold))
                    Text(task.isCompleted ? "Mark as Incomplete" : "Mark as Complete")
                        .font(AppTypography.bodySemibold)
                }
                .foregroundStyle(AppColors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule(style: .continuous).fill(AppColors.accentSoft.opacity(0.4))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(AppColors.accent.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button {
                store.delete(task.id)
                onClose()
            } label: {
                Text("Delete Task")
                    .font(AppTypography.bodySemibold)
                    .foregroundStyle(AppColors.Priority.highInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
    }
}
