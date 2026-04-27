//
//  TranscribingView.swift
//  Clarity
//
//  Phase 2 — transcript review with mock waveform + language selector.
//

import SwiftUI

struct TranscribingView: View {
    var onCancel: () -> Void = {}
    var onContinue: () -> Void = {}

    @State private var language: String = "EN"

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: AppSpacing.md)
            header
                .padding(.horizontal, AppSpacing.lg)
            Spacer(minLength: AppSpacing.lg)
            transcript
                .padding(.horizontal, AppSpacing.lg)
            Spacer(minLength: AppSpacing.lg)
            footer
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
                Capsule(style: .continuous)
                    .fill(AppColors.surface)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
        .menuStyle(.borderlessButton)
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: AppSpacing.xs) {
            Text("Transcribing…")
                .font(AppTypography.displayMedium)
                .foregroundStyle(AppColors.textPrimary)
            Text("Here's what I heard")
                .font(AppTypography.bodyLarge)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    // MARK: - Transcript
    private var transcript: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Text(MockData.sampleTranscript)
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Footer
    private var footer: some View {
        VStack(spacing: AppSpacing.md) {
            Waveform(
                barCount: 56,
                maxHeight: 44,
                color: AppColors.accent.opacity(0.55),
                seed: 1.2
            )
            .frame(height: 44)

            Button(action: onContinue) {
                HStack(spacing: 8) {
                    Text("Continue")
                        .font(AppTypography.bodySemibold)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule(style: .continuous).fill(AppColors.accent)
                )
            }
            .buttonStyle(.plain)
        }
    }
}
