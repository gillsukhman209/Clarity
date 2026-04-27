//
//  BuildingPlanView.swift
//  Clarity
//
//  Phase 2 — "Building your plan" progress checklist.
//

import SwiftUI

struct BuildingPlanView: View {
    var onCancel: () -> Void = {}
    var onDone: () -> Void = {}

    private struct Step: Identifiable {
        let id = UUID()
        let title: String
        let status: Status
    }

    private enum Status {
        case done, inProgress, pending
    }

    private let steps: [Step] = [
        Step(title: "Extracting tasks",   status: .done),
        Step(title: "Estimating time",    status: .done),
        Step(title: "Prioritizing",       status: .done),
        Step(title: "Optimizing schedule", status: .inProgress),
        Step(title: "Finalizing your plan", status: .pending)
    ]

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: AppSpacing.lg)
            header
                .padding(.horizontal, AppSpacing.lg)
            Spacer(minLength: AppSpacing.lg)
            GlowingOrb(size: 140)
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
    }

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
            Text("Building your plan")
                .font(AppTypography.displayMedium)
                .foregroundStyle(AppColors.textPrimary)
            Text("Clarity is organizing your day…")
                .font(AppTypography.bodyLarge)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var checklist: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(steps) { step in
                HStack(spacing: 12) {
                    statusIcon(for: step.status)
                        .frame(width: 22, height: 22)
                    Text(step.title)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(textColor(for: step.status))
                    Spacer()
                }
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
        case .inProgress:
            ZStack {
                Circle()
                    .stroke(AppColors.accent.opacity(0.25), lineWidth: 2)
                Circle()
                    .trim(from: 0, to: 0.35)
                    .stroke(AppColors.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
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
                .background(Capsule(style: .continuous).fill(AppColors.accent))
        }
        .buttonStyle(.plain)
    }
}
