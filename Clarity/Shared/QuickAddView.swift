//
//  QuickAddView.swift
//  Clarity
//
//  Quick text-based task entry. Smart parsing happens via PlanGenerator —
//  the AI understands natural language and merges the new task(s) into
//  the existing day plan.
//

import SwiftUI

struct QuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TaskStore.self) private var store

    @State private var text: String = ""
    @State private var generator = PlanGenerator()
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String?
    @FocusState private var fieldFocused: Bool

    private let placeholders = [
        "Workout at 6pm for 45 minutes",
        "Call dentist before lunch",
        "30 min focus block on the proposal at 2pm",
        "Pick up groceries on the way home"
    ]
    @State private var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            topBar
            field
            if let errorMessage {
                errorBanner(errorMessage)
            }
            Spacer(minLength: 0)
            footer
        }
        .padding(AppSpacing.lg)
        .frame(minWidth: 400, idealWidth: 480, minHeight: 260)
        .background(AppColors.background)
        .onAppear {
            placeholder = placeholders.randomElement() ?? ""
            fieldFocused = true
        }
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack {
            Text("Quick Add")
                .font(AppTypography.titleSmall)
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Button("Cancel", action: { dismiss() })
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
                .buttonStyle(.plain)
        }
    }

    // MARK: - Field
    private var field: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tell me what to add")
                .font(AppTypography.captionSemibold)
                .tracking(0.6)
                .foregroundStyle(AppColors.textTertiary)

            TextField(placeholder, text: $text, axis: .vertical)
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2...8)
                .focused($fieldFocused)
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                        .fill(AppColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                        .stroke(fieldFocused ? AppColors.accent.opacity(0.6) : AppColors.border, lineWidth: 1)
                )
                .submitLabel(.send)
                .onSubmit { Task { await submit() } }

            Text("I'll figure out the time, duration, and category for you.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.horizontal, 4)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.Priority.highInk)
            Text(message)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                .fill(AppColors.Priority.highFill.opacity(0.5))
        )
    }

    // MARK: - Footer
    private var footer: some View {
        HStack {
            Spacer()
            Button {
                Task { await submit() }
            } label: {
                HStack(spacing: 8) {
                    if isProcessing {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    Text(isProcessing ? "Adding…" : "Add")
                        .font(AppTypography.bodySemibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(canSubmit ? AppColors.accent : AppColors.accent.opacity(0.4))
                )
            }
            .buttonStyle(PressableStyle(pressedScale: 0.98))
            .disabled(!canSubmit)
        }
    }

    private var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isProcessing
    }

    // MARK: - Submit

    private func submit() async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isProcessing = true
        errorMessage = nil
        await generator.generate(from: trimmed, existing: store.tasks)

        if let err = generator.error {
            errorMessage = err
            isProcessing = false
            return
        }
        if !generator.tasks.isEmpty {
            store.replaceAll(with: generator.tasks)
        }
        dismiss()
    }
}
