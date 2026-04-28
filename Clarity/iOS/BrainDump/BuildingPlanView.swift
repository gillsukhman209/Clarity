//
//  BuildingPlanView.swift
//  Clarity
//
//  Phase 2/8 — runs the transcript through PlanGenerator and animates the
//  five-step checklist while the OpenAI call resolves in parallel.
//

import SwiftUI

struct BuildingPlanView: View {
    var transcript: String = ""
    /// When non-nil, the brain dump runs in append-only mode and stamps every
    /// generated task with this project. Used by the per-project brain dump.
    var projectID: UUID? = nil
    var onCancel: () -> Void = {}
    var onDone: () -> Void = {}

    @Environment(TaskStore.self) private var store
    @State private var generator = PlanGenerator()
    @State private var didStart = false

    private var allDone: Bool { generator.isComplete && generator.error == nil }
    private var hasError: Bool { generator.error != nil }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: AppSpacing.lg)
            header
                .padding(.horizontal, AppSpacing.lg)
            Spacer(minLength: AppSpacing.lg)
            GlowingOrb(size: 140, isPulsing: !generator.isComplete)
                .frame(height: 280)
            Spacer(minLength: AppSpacing.lg)
            checklist
                .padding(.horizontal, AppSpacing.xl)
            if let err = generator.error {
                errorCard(err)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.md)
            }
            Spacer(minLength: AppSpacing.lg)
            primaryButton
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
        }
        .background(AppColors.background)
        .task {
            guard !didStart else { return }
            didStart = true
            await runGeneration()
        }
    }

    private func runGeneration() async {
        if let projectID {
            // Project-scoped brain dump: never replan the whole day, just
            // append the generated tasks tagged with this project.
            await generator.generate(from: transcript, mode: .quickAdd)
            if generator.error == nil, !generator.tasks.isEmpty {
                let stamped = generator.tasks.map { t -> PlanTask in
                    var copy = t
                    copy.projectID = projectID
                    copy.boardStatus = .upcoming
                    return copy
                }
                store.append(stamped)
            }
        } else {
            await generator.generate(from: transcript, existing: store.tasks)
            if generator.error == nil, !generator.tasks.isEmpty {
                store.replaceAll(with: generator.tasks)
            }
        }
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
            Text(headerTitle)
                .font(AppTypography.displayMedium)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
            Text(headerSubtitle)
                .font(AppTypography.bodyLarge)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
        }
        .animation(.easeInOut(duration: 0.25), value: allDone)
        .animation(.easeInOut(duration: 0.25), value: hasError)
    }

    private var headerTitle: String {
        if hasError { return "Hmm, something went wrong" }
        if allDone  { return "Your day is ready" }
        return "Building your plan"
    }

    private var headerSubtitle: String {
        if hasError { return "Tap retry to try again." }
        if allDone  { return "Tap below to see your day." }
        return "Clarity is organizing your day…"
    }

    // MARK: - Checklist
    private var checklist: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(PlanGenerator.Stage.allCases, id: \.rawValue) { step in
                HStack(spacing: 12) {
                    statusIcon(for: status(for: step))
                        .frame(width: 22, height: 22)
                    Text(step.title)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(textColor(for: status(for: step)))
                    Spacer()
                }
                .animation(.easeInOut(duration: 0.25), value: generator.stage)
                .animation(.easeInOut(duration: 0.25), value: generator.isComplete)
            }
        }
        .frame(maxWidth: 360)
    }

    private enum Status { case done, inProgress, pending }

    private func status(for step: PlanGenerator.Stage) -> Status {
        if hasError { return step.rawValue <= generator.stage.rawValue ? .pending : .pending }
        if generator.isComplete { return .done }
        if step.rawValue <  generator.stage.rawValue { return .done }
        if step.rawValue == generator.stage.rawValue { return .inProgress }
        return .pending
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
        case .done, .inProgress: return AppColors.textPrimary
        case .pending:           return AppColors.textTertiary
        }
    }

    // MARK: - Error
    private func errorCard(_ message: String) -> some View {
        AppCard(padding: AppSpacing.md, background: AppColors.Priority.highFill.opacity(0.5)) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.Priority.highInk)
                Text(message)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Primary button
    @ViewBuilder
    private var primaryButton: some View {
        if hasError {
            Button {
                Task { await runGeneration() }
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
        } else {
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
