//
//  CaptureView.swift
//  Clarity
//
//  Phase 2 — UI for the brain-dump home / voice capture.
//  Phase 7 — wired to a real `AudioRecorder` and gated on `TranscriptionService`.
//  Phase 11 — cross-platform (iOS + macOS).
//  Phase 13 — surfaces denied/failed states with actionable recovery.
//  Phase 18 — redesigned as a dedicated "Plan your whole day" view: the
//  headline lives at the top, the big glowing mic anchors the bottom.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct CaptureView: View {
    var onCancel: () -> Void = {}
    /// Called once the recorder finishes; the URL points at a 16 kHz mono WAV ready for transcription.
    var onFinishedRecording: (URL) -> Void = { _ in }

    @State private var recorder = AudioRecorder()
    @Environment(TranscriptionService.self) private var transcription

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: AppSpacing.lg)
            header
            Spacer(minLength: AppSpacing.md)
            tipsCard
                .padding(.horizontal, AppSpacing.lg)
            Spacer(minLength: AppSpacing.lg)
            statusBlock
                .padding(.horizontal, AppSpacing.lg)
            Spacer(minLength: AppSpacing.md)
            micCluster
                .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.background)
        .onChange(of: recorder.state) { _, newValue in
            if case let .finished(url) = newValue {
                onFinishedRecording(url)
            }
        }
        .onDisappear { recorder.reset() }
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
            Text("Plan your whole day")
                .font(AppTypography.displayLarge)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            Text("Speak everything that's on your mind.\nI'll turn it into a real schedule.")
                .font(AppTypography.bodyLarge)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - Mic cluster (bottom)

    private var isRecording: Bool { recorder.state == .recording }

    private var canTap: Bool {
        switch recorder.state {
        case .denied, .requestingPermission: return false
        default: break
        }
        switch transcription.state {
        case .preparing, .idle, .failed: return false
        case .ready, .transcribing: return true
        }
    }

    private var micCluster: some View {
        Button {
            Task {
                if isRecording {
                    recorder.stop()
                } else {
                    await recorder.start()
                }
            }
        } label: {
            ZStack {
                GlowingOrb(size: 200, isPulsing: isRecording)
                Image(systemName: "mic.fill")
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: AppColors.accent.opacity(0.35), radius: 6)
                    .scaleEffect(isRecording ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.25), value: isRecording)
            }
            .frame(width: 320, height: 320)
            .opacity(canTap ? 1.0 : 0.7)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle(pressedScale: 0.96))
        .disabled(!canTap)
    }

    // MARK: - Status (waveform / timer / messages)

    @ViewBuilder
    private var statusBlock: some View {
        VStack(spacing: AppSpacing.sm) {
            if isRecording {
                LiveWaveformBars(levels: recorder.levels, color: AppColors.accent.opacity(0.65))
                    .frame(height: 36)
                    .transition(.opacity)
                Text(recorder.elapsedLabel)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppColors.textSecondary)
                    .transition(.opacity)
                Text("Tap the mic again when you're done.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            } else {
                Text(primaryLabel)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(minHeight: 24)
                    .multilineTextAlignment(.center)
                if recorder.state == .denied {
                    Button {
                        openSystemSettings()
                    } label: {
                        Text("Open Settings")
                            .font(AppTypography.bodySemibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Capsule(style: .continuous).fill(AppColors.accent))
                    }
                    .buttonStyle(PressableStyle(pressedScale: 0.98))
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isRecording)
    }

    private var primaryLabel: String {
        switch recorder.state {
        case .denied:
            return "Microphone access denied."
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
            return "Tap the mic to start"
        case .idle:
            return "Loading…"
        }
    }

    private func openSystemSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #elseif canImport(AppKit)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
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
