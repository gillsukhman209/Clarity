//
//  QuickAddView.swift
//  Clarity
//
//  Quick text-or-voice task entry.
//  - The user can type a task and tap Add
//  - Or tap the mic, talk for a moment, tap mic again, and the transcribed
//    text fills the field. They can edit, then Add.
//
//  Either way the request is routed through PlanGenerator in `.quickAdd` mode,
//  which extracts only the task(s) the user described — no full-day re-plan,
//  no invented filler tasks. Result is APPENDED to the day, not replaced.
//

import SwiftUI

struct QuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TaskStore.self) private var store
    @Environment(TranscriptionService.self) private var transcription

    @State private var text: String = ""
    @State private var generator = PlanGenerator()
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String?
    @FocusState private var fieldFocused: Bool

    @State private var recorder = AudioRecorder()
    @State private var isTranscribing: Bool = false

    private let placeholders = [
        "Workout at 6pm for 45 minutes",
        "Call dentist tomorrow",
        "30 min focus block on the proposal at 2pm",
        "Pick up groceries on the way home"
    ]
    @State private var placeholder: String = ""

    private var isRecording: Bool { recorder.state == .recording }

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
        .frame(minWidth: 420, idealWidth: 520, minHeight: 280)
        .background(AppColors.background)
        .onAppear {
            placeholder = placeholders.randomElement() ?? ""
            fieldFocused = true
        }
        .onChange(of: recorder.state) { _, newValue in
            if case let .finished(url) = newValue {
                Task { await transcribe(url) }
            }
        }
        .onDisappear {
            recorder.reset()
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
            HStack {
                Text("Tell me what to add")
                    .font(AppTypography.captionSemibold)
                    .tracking(0.6)
                    .foregroundStyle(AppColors.textTertiary)
                Spacer()
                if isRecording {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppColors.Priority.highInk)
                            .frame(width: 6, height: 6)
                        Text("Listening · \(recorder.elapsedLabel)")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .monospacedDigit()
                    }
                }
            }

            HStack(alignment: .top, spacing: AppSpacing.sm) {
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
                    .disabled(isRecording || isTranscribing)
                    .onSubmit { Task { await submit() } }

                micButton
            }

            statusLine
        }
    }

    @ViewBuilder
    private var statusLine: some View {
        if isTranscribing {
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Transcribing…")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        } else {
            Text("I'll figure out the time, duration, and category for you. Tap the mic to talk it out.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.horizontal, 4)
        }
    }

    // MARK: - Mic button
    private var micButton: some View {
        Button {
            Task { await toggleRecording() }
        } label: {
            ZStack {
                Circle()
                    .fill(isRecording ? AppColors.Priority.highInk : AppColors.accent)
                    .frame(width: 44, height: 44)
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .scaleEffect(isRecording ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isRecording)
        }
        .buttonStyle(PressableStyle(pressedScale: 0.95))
        .disabled(isTranscribing || !canRecord)
        .opacity((isTranscribing || !canRecord) ? 0.55 : 1)
    }

    private var canRecord: Bool {
        switch transcription.state {
        case .ready, .transcribing: return true
        default: return false
        }
    }

    private func toggleRecording() async {
        if isRecording {
            recorder.stop()
        } else {
            errorMessage = nil
            await recorder.start()
            if case .denied = recorder.state {
                errorMessage = "Microphone access denied. Enable it in Settings."
            } else if case .failed(let msg) = recorder.state {
                errorMessage = msg
            }
        }
    }

    private func transcribe(_ url: URL) async {
        isTranscribing = true
        defer { isTranscribing = false }
        let result = await transcription.transcribe(url)
        switch result {
        case .success(let transcript) where !transcript.isEmpty:
            text = transcript
            fieldFocused = true
        case .success:
            errorMessage = "I couldn't make out any speech."
        case .failure(let err):
            errorMessage = err.localizedDescription
        }
    }

    // MARK: - Error
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
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isProcessing
            && !isRecording
            && !isTranscribing
    }

    // MARK: - Submit

    private func submit() async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isProcessing = true
        errorMessage = nil
        await generator.generate(from: trimmed, mode: .quickAdd)

        if let err = generator.error {
            errorMessage = err
            isProcessing = false
            return
        }
        if !generator.tasks.isEmpty {
            store.append(generator.tasks)
        }
        dismiss()
    }
}
