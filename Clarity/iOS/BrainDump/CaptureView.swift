//
//  CaptureView.swift
//  Clarity
//
//  Phase 2 — UI for the brain-dump home / voice capture.
//  Phase 7 — wired to a real `AudioRecorder` and gated on `TranscriptionService`.
//

import SwiftUI

struct CaptureView: View {
    var onCancel: () -> Void = {}
    /// Called once the recorder finishes; the URL points at a 16 kHz mono WAV ready for transcription.
    var onFinishedRecording: (URL) -> Void = { _ in }

    #if os(iOS)
    @State private var recorder = AudioRecorder()
    @Environment(TranscriptionService.self) private var transcription
    #endif

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: AppSpacing.lg)
            header
            Spacer(minLength: AppSpacing.lg)
            orbAndWaveform
            Spacer(minLength: AppSpacing.lg)
            tipsCard
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
        }
        .background(AppColors.background)
        #if os(iOS)
        .onChange(of: recorder.state) { _, newValue in
            if case let .finished(url) = newValue {
                onFinishedRecording(url)
            }
        }
        .onDisappear {
            recorder.reset()
        }
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
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.sm)
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: AppSpacing.xs) {
            Text("What's on your mind?")
                .font(AppTypography.displayMedium)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            Text("Speak freely. I'll handle the rest.")
                .font(AppTypography.bodyLarge)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - Orb / waveform / timer

    private var isRecording: Bool {
        #if os(iOS)
        return recorder.state == .recording
        #else
        return false
        #endif
    }

    private var canTap: Bool {
        #if os(iOS)
        return transcription.isReady && recorder.state != .denied
        #else
        return false
        #endif
    }

    private var primaryLabel: String {
        #if os(iOS)
        switch recorder.state {
        case .denied:
            return "Microphone access denied. Enable it in Settings."
        case .failed(let msg):
            return msg
        default:
            break
        }
        switch transcription.state {
        case .preparing:
            return "Preparing voice…"
        case .failed(let msg):
            return msg
        case .ready, .transcribing:
            return isRecording ? "Tap to stop" : "Tap to start"
        case .idle:
            return "Loading…"
        }
        #else
        return "iOS only"
        #endif
    }

    private var orbAndWaveform: some View {
        VStack(spacing: AppSpacing.xl) {
            Button {
                #if os(iOS)
                Task {
                    if isRecording {
                        recorder.stop()
                    } else {
                        await recorder.start()
                    }
                }
                #endif
            } label: {
                ZStack {
                    GlowingOrb(size: 180, isPulsing: isRecording)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: AppColors.accent.opacity(0.35), radius: 6)
                        .scaleEffect(isRecording ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.25), value: isRecording)
                }
                .frame(width: 280, height: 280)
                .opacity(canTap ? 1.0 : 0.7)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle(pressedScale: 0.96))
            .disabled(!canTap)

            statusBlock
                .animation(.easeInOut(duration: 0.25), value: isRecording)
                .padding(.horizontal, AppSpacing.lg)
        }
    }

    @ViewBuilder
    private var statusBlock: some View {
        VStack(spacing: AppSpacing.sm) {
            if isRecording {
                liveWaveform
                Text(timerLabel)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppColors.textSecondary)
                    .transition(.opacity)
            } else {
                Text(primaryLabel)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(minHeight: 36)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
                Text("0:00")
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppColors.textTertiary)
                    .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private var liveWaveform: some View {
        #if os(iOS)
        LiveWaveformBars(levels: recorder.levels, color: AppColors.accent.opacity(0.65))
            .frame(height: 36)
            .transition(.opacity)
        #else
        Waveform(
            barCount: 48, maxHeight: 36,
            color: AppColors.accent.opacity(0.65), seed: 0.4, animated: true
        )
        .frame(height: 36)
        .transition(.opacity)
        #endif
    }

    private var timerLabel: String {
        #if os(iOS)
        return recorder.elapsedLabel
        #else
        return "0:00"
        #endif
    }

    // MARK: - Tips card
    private var tipsCard: some View {
        AppCard(padding: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.accent)
                    Text("Tips")
                        .font(AppTypography.captionSemibold)
                        .tracking(0.6)
                        .foregroundStyle(AppColors.textTertiary)
                }
                tipRow("Mention deadlines and times")
                tipRow("Group related thoughts as you go")
                tipRow("Don't worry about order — I'll sort it")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Circle()
                .fill(AppColors.textTertiary.opacity(0.5))
                .frame(width: 4, height: 4)
                .offset(y: -3)
            Text(text)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}
