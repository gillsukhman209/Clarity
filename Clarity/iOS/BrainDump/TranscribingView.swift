//
//  TranscribingView.swift
//  Clarity
//
//  Phase 2/7 — runs the recording through TranscriptionService and shows the result.
//

import SwiftUI

struct TranscribingView: View {
    var recordingURL: URL?
    var onCancel: () -> Void = {}
    var onContinue: (String) -> Void = { _ in }

    @State private var language: String = "EN"
    @State private var transcript: String = ""
    @State private var phase: Phase = .transcribing
    @State private var errorMessage: String?

    #if os(iOS)
    @Environment(TranscriptionService.self) private var transcription
    #endif

    private enum Phase: Equatable {
        case transcribing
        case ready
        case failed
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: AppSpacing.md)
            header
                .padding(.horizontal, AppSpacing.lg)
            Spacer(minLength: AppSpacing.lg)
            transcriptArea
                .padding(.horizontal, AppSpacing.lg)
            Spacer(minLength: AppSpacing.lg)
            footer
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
        }
        .background(AppColors.background)
        .task { await runTranscription() }
    }

    // MARK: - Lifecycle

    private func runTranscription() async {
        #if os(iOS)
        guard let url = recordingURL else {
            phase = .failed
            errorMessage = "No recording was captured."
            return
        }

        phase = .transcribing
        errorMessage = nil

        let result = await transcription.transcribe(url)
        switch result {
        case .success(let text) where !text.isEmpty:
            transcript = text
            phase = .ready
        case .success:
            phase = .failed
            errorMessage = TranscriptionError.empty.errorDescription
        case .failure(let error):
            phase = .failed
            errorMessage = error.localizedDescription
        }
        #else
        // macOS path will arrive in a later phase; show a placeholder for now.
        transcript = MockData.sampleTranscript
        phase = .ready
        #endif
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack {
            Button(action: onCancel) {
                Text("Cancel")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            languagePill
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.sm)
    }

    private var languagePill: some View {
        Menu {
            Button("English") { language = "EN" }
            Button("Español") { language = "ES" }
            Button("Français") { language = "FR" }
            Button("Deutsch")  { language = "DE" }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "globe")
                    .font(.system(size: 12, weight: .semibold))
                Text(language)
                    .font(AppTypography.captionSemibold)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(AppColors.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous).fill(AppColors.surface)
            )
            .overlay(
                Capsule(style: .continuous).stroke(AppColors.border, lineWidth: 1)
            )
        }
        .menuStyle(.borderlessButton)
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(headerTitle)
                .font(AppTypography.displayMedium)
                .foregroundStyle(AppColors.textPrimary)
                .contentTransition(.opacity)
            Text(headerSubtitle)
                .font(AppTypography.bodyLarge)
                .foregroundStyle(AppColors.textSecondary)
                .contentTransition(.opacity)
                .multilineTextAlignment(.center)
        }
        .animation(.easeInOut(duration: 0.25), value: phase)
    }

    private var headerTitle: String {
        switch phase {
        case .transcribing: return "Transcribing…"
        case .ready:        return "Here's what I heard"
        case .failed:       return "Couldn't transcribe"
        }
    }

    private var headerSubtitle: String {
        switch phase {
        case .transcribing: return "On-device, no audio leaves your phone."
        case .ready:        return "Tap continue to build your day."
        case .failed:       return errorMessage ?? "Something went wrong."
        }
    }

    // MARK: - Transcript
    @ViewBuilder
    private var transcriptArea: some View {
        switch phase {
        case .transcribing:
            VStack(spacing: AppSpacing.sm) {
                ProgressView()
                    .controlSize(.large)
                    .tint(AppColors.accent)
                Text("Working on it…")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        case .ready:
            ScrollView(.vertical, showsIndicators: false) {
                Text(transcript)
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .failed:
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColors.Priority.highInk)
                if let errorMessage {
                    Text(errorMessage)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Footer
    private var footer: some View {
        VStack(spacing: AppSpacing.md) {
            Waveform(
                barCount: 56,
                maxHeight: 44,
                color: AppColors.accent.opacity(phase == .transcribing ? 0.55 : 0.3),
                seed: 1.2,
                animated: phase == .transcribing
            )
            .frame(height: 44)

            primaryButton
        }
    }

    @ViewBuilder
    private var primaryButton: some View {
        switch phase {
        case .transcribing:
            disabledButton(label: "Transcribing…")
        case .ready:
            Button {
                onContinue(transcript)
            } label: {
                HStack(spacing: 8) {
                    Text("Continue")
                        .font(AppTypography.bodySemibold)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Capsule(style: .continuous).fill(AppColors.accent))
            }
            .buttonStyle(PressableStyle(pressedScale: 0.98))
        case .failed:
            Button {
                Task { await runTranscription() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Try again")
                        .font(AppTypography.bodySemibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Capsule(style: .continuous).fill(AppColors.accent))
            }
            .buttonStyle(PressableStyle(pressedScale: 0.98))
        }
    }

    private func disabledButton(label: String) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(AppTypography.bodySemibold)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Capsule(style: .continuous).fill(AppColors.accent.opacity(0.4)))
    }
}
