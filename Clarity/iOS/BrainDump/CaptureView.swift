//
//  CaptureView.swift
//  Clarity
//
//  Phase 2 — Brain-dump home / voice capture.
//

import SwiftUI

struct CaptureView: View {
    var onCancel: () -> Void = {}
    var onFinishedRecording: () -> Void = {}

    /// Mock state: `false` → idle ("tap to start"); `true` → recording (timer + waveform).
    @State private var isRecording: Bool = false
    /// Static mock timer string. We don't actually count for Phase 2.
    private let mockTimer: String = "0:23"

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

    // MARK: - Orb, waveform, timer
    private var orbAndWaveform: some View {
        VStack(spacing: AppSpacing.xl) {
            Button {
                if isRecording {
                    onFinishedRecording()
                } else {
                    isRecording = true
                }
            } label: {
                ZStack {
                    GlowingOrb(size: 180)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: AppColors.accent.opacity(0.35), radius: 6)
                }
                .frame(width: 280, height: 280)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            VStack(spacing: AppSpacing.sm) {
                if isRecording {
                    Waveform(barCount: 48, maxHeight: 36, color: AppColors.accent.opacity(0.65), seed: 0.4)
                        .frame(height: 36)
                    Text(mockTimer)
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppColors.textSecondary)
                } else {
                    Text("Tap to start")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textTertiary)
                        .frame(height: 36)
                    Text("0:00")
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
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
