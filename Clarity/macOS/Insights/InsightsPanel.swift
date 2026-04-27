//
//  InsightsPanel.swift
//  Clarity
//
//  Phase 4 — far-right column with day-at-a-glance tiles, productivity score,
//  open-blocks notice, and floating mic.
//

#if os(macOS)
import SwiftUI

struct InsightsPanel: View {
    var onOpenBrainDump: () -> Void = {}

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    Text("Insights")
                        .font(AppTypography.title)
                        .foregroundStyle(AppColors.textPrimary)

                    Text("Day at a glance")
                        .font(AppTypography.captionSemibold)
                        .tracking(0.6)
                        .foregroundStyle(AppColors.textTertiary)

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: AppSpacing.sm),
                            GridItem(.flexible(), spacing: AppSpacing.sm)
                        ],
                        spacing: AppSpacing.sm
                    ) {
                        InsightTile(
                            symbol: "brain.head.profile",
                            title: "Focus Time",
                            value: "3h 45m",
                            subtitle: "7 tasks",
                            accent: AppColors.Category.focusInk
                        )
                        InsightTile(
                            symbol: "person.2.fill",
                            title: "Meetings",
                            value: "1h 00m",
                            subtitle: "1 task",
                            accent: AppColors.Category.workInk
                        )
                        InsightTile(
                            symbol: "cup.and.saucer.fill",
                            title: "Breaks",
                            value: "1h 15m",
                            subtitle: "2 breaks",
                            accent: AppColors.Category.energizeInk
                        )
                        InsightTile(
                            symbol: "checkmark.circle.fill",
                            title: "Tasks",
                            value: "13",
                            subtitle: "Today",
                            accent: AppColors.Category.personalInk
                        )
                    }

                    productivityCard
                    openBlocksCard
                }
                .padding(AppSpacing.lg)
                .padding(.bottom, 80)
            }

            floatingMic
                .padding(AppSpacing.lg)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(AppColors.background)
    }

    // MARK: - Productivity card
    private var productivityCard: some View {
        AppCard(padding: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Productivity Forecast")
                    .font(AppTypography.captionSemibold)
                    .tracking(0.6)
                    .foregroundStyle(AppColors.textTertiary)
                ProductivityGauge(score: 87, caption: "Great day ahead!")
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Open blocks
    private var openBlocksCard: some View {
        AppCard(padding: AppSpacing.md) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "square.dashed")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("2 open blocks")
                        .font(AppTypography.bodySemibold)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("You have 1h 30m of unscheduled time. Tap to fill it.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Floating mic
    private var floatingMic: some View {
        Button(action: onOpenBrainDump) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.accent.opacity(0.95), AppColors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .appShadow(AppShadow.micGlow)
                Image(systemName: "mic.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Brain dump")
    }
}
#endif
