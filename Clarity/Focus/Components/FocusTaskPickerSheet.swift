//
//  FocusTaskPickerSheet.swift
//  Clarity
//
//  Sheet for choosing the task to focus on while the Pomodoro timer runs.
//  Lists today's incomplete tasks; tap one to bind it to the engine.
//  "None" clears any current binding.
//

import SwiftUI

struct FocusTaskPickerSheet: View {
    @Environment(TaskStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// Currently bound task (used to render a checkmark).
    let currentTaskID: UUID?
    var onPick: (PlanTask?) -> Void

    private var candidates: [PlanTask] {
        store.tasks(on: Date())
            .filter { !$0.isCompleted }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            if candidates.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        clearRow
                        ForEach(candidates) { task in
                            row(task)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
        }
        .frame(minWidth: 380, idealWidth: 440, minHeight: 380)
        .background(AppColors.background)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .buttonStyle(.plain)
            Spacer()
            Text("Focus on…")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            // Right-side balance for centered title
            Text("Cancel")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.clear)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(
            Rectangle()
                .fill(AppColors.divider)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Rows

    private var clearRow: some View {
        Button {
            onPick(nil)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "circle.dashed")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(width: 24)
                Text("No task — just focus")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                if currentTaskID == nil {
                    checkmark
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(rowBg(isSelected: currentTaskID == nil))
        }
        .buttonStyle(.plain)
    }

    private func row(_ task: PlanTask) -> some View {
        let isSelected = currentTaskID == task.id
        return Button {
            onPick(task)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(task.category.fillColor.opacity(0.7))
                        .frame(width: 28, height: 28)
                    Image(systemName: task.category.sfSymbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(task.category.inkColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        if task.hasTime {
                            Text(task.startTimeLabel)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        if let durationLabel = task.durationLabel {
                            Text("·").foregroundStyle(AppColors.textTertiary).font(.caption)
                            Text(durationLabel)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
                Spacer(minLength: 0)
                if isSelected { checkmark }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(rowBg(isSelected: isSelected))
        }
        .buttonStyle(.plain)
    }

    private var checkmark: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(AppColors.accent)
    }

    private func rowBg(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(isSelected ? AppColors.accent.opacity(0.10) : AppColors.surface.opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? AppColors.accent.opacity(0.45) : AppColors.border.opacity(0.4), lineWidth: 1)
            )
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
            Text("No tasks for today")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
            Text("Add a task on the Today tab, or focus without one.")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                onPick(nil)
                dismiss()
            } label: {
                Text("Focus without a task")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Capsule(style: .continuous).fill(AppColors.accent))
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
            Spacer()
        }
        .padding(20)
    }
}
