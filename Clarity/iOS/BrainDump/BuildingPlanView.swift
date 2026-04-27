//
//  BuildingPlanView.swift
//  Clarity
//
//  Phase 2 — "Building your plan" progress checklist.
//  Phase 5 — auto-advances through the checklist with a pulsing orb,
//            then enables "Show My Day".
//

import SwiftUI

struct BuildingPlanView: View {
    var onCancel: () -> Void = {}
    var onDone: () -> Void = {}

    private struct Step: Identifiable {
        let id = UUID()
        let title: String
    }

    private enum Status {
        case done, inProgress, pending
    }

    private let steps: [Step] = [
        Step(title: "Extracting tasks"),
        Step(title: "Estimating time"),
        Step(title: "Prioritizing"),
        Step(title: "Optimizing schedule"),
        Step(title: "Finalizing your plan")
    ]

    /// Steps with index < `progressIndex` are done.
    /// Step at `progressIndex` is in progress (or none if `progressIndex >= steps.count`).
    @State private var progressIndex: Int = 0

    private var allDone: Bool { progressIndex >= steps.count }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: AppSpacing.lg)
            header
                .padding(.horizontal, AppSpacing.lg)
            Spacer(minLength: AppSpacing.lg)
            GlowingOrb(size: 140, isPulsing: !allDone)
                .frame(height: 280)
            Spacer(minLength: AppSpacing.lg)
            checklist
                .padding(.horizontal, AppSpacing.xl)
            Spacer(minLength: AppSpacing.lg)
            doneButton
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
        }
        .background(AppColors.background)
        .task { await runProgress() }
    }

    private func runProgress() async {
        // Reset and step through.
        progressIndex = 0
        for i in 0..<steps.count {
            try? await Task.sleep(for: .milliseconds(900))
            withAnimation(.easeInOut(duration: 0.3)) {
                progressIndex = i + 1
            }
        }
    }

    private func status(for index: Int) -> Status {
        if index < progressIndex { return .done }
        if index == progressIndex { return .inProgress }
        return .pending
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

    private var header: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(allDone ? "Your day is ready" : "Building your plan")
                .font(AppTypography.displayMedium)
                .foregroundStyle(AppColors.textPrimary)
                .contentTransition(.opacity)
            Text(allDone ? "Tap below to see your day." : "Clarity is organizing your day…")
                .font(AppTypography.bodyLarge)
                .foregroundStyle(AppColors.textSecondary)
                .contentTransition(.opacity)
        }
        .animation(.easeInOut(duration: 0.25), value: allDone)
    }

    // MARK: - Checklist
    private var checklist: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                HStack(spacing: 12) {
                    statusIcon(for: status(for: index))
                        .frame(width: 22, height: 22)
                    Text(step.title)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(textColor(for: status(for: index)))
                    Spacer()
                }
                .animation(.easeInOut(duration: 0.25), value: progressIndex)
            }
        }
        .frame(maxWidth: 360)
    }

    @ViewBuilder
    private func statusIcon(for status: Status) -> some View {
        switch status {
        case .done:
            ZStack {
                Circle().fill(AppColors.accent)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
            .transition(.scale.combined(with: .opacity))
        case .inProgress:
            SpinnerRing()
        case .pending:
            Circle()
                .stroke(AppColors.border, lineWidth: 2)
        }
    }

    private func textColor(for status: Status) -> Color {
        switch status {
        case .done:       return AppColors.textPrimary
        case .inProgress: return AppColors.textPrimary
        case .pending:    return AppColors.textTertiary
        }
    }

    private var doneButton: some View {
        Button(action: onDone) {
            Text("Show My Day")
                .font(AppTypography.bodySemibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule(style: .continuous)
                        .fill(allDone ? AppColors.accent : AppColors.accent.opacity(0.4))
                )
        }
        .buttonStyle(PressableStyle(pressedScale: 0.98))
        .disabled(!allDone)
        .animation(.easeInOut(duration: 0.2), value: allDone)
    }
}

// MARK: - Spinner

private struct SpinnerRing: View {
    @State private var rotate: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.accent.opacity(0.18), lineWidth: 2)
            Circle()
                .trim(from: 0, to: 0.32)
                .stroke(AppColors.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(rotate ? 360 : 0))
                .animation(.linear(duration: 0.9).repeatForever(autoreverses: false), value: rotate)
        }
        .onAppear { rotate = true }
    }
}
