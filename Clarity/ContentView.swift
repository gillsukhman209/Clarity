//
//  ContentView.swift
//  Clarity
//
//  Phase 1 only: a simple design-system showcase so we can verify
//  tokens, models, and reusable components render correctly on iOS and macOS.
//  Replace with real navigation in Phase 2+.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                header
                colorTokens
                typographyTokens
                componentsShowcase
                taskListShowcase
                micButtonShowcase
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(AppColors.background)
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Clarity")
                .font(AppTypography.displayLarge)
                .foregroundStyle(AppColors.textPrimary)
            Text("Phase 1 — Design System Preview")
                .font(AppTypography.bodyLarge)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    // MARK: - Colors
    private var colorTokens: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionTitle("Category palette")
            FlowingChips {
                ForEach(TaskCategory.allCases) { category in
                    CategoryTag(category: category, showsIcon: true)
                }
            }
            sectionTitle("Priorities")
            HStack(spacing: AppSpacing.sm) {
                ForEach(TaskPriority.allCases) { p in
                    PriorityBadge(priority: p)
                }
            }
        }
    }

    // MARK: - Typography
    private var typographyTokens: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Display Large").font(AppTypography.displayLarge)
                Text("Title").font(AppTypography.title)
                Text("Title Small").font(AppTypography.titleSmall)
                Text("Body Large — speak freely, I'll handle the rest.")
                    .font(AppTypography.bodyLarge)
                Text("Body — emails & communications")
                    .font(AppTypography.body)
                Text("Subheadline — 45 minutes")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                Text("CAPTION — high priority")
                    .font(AppTypography.captionSemibold)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Components
    private var componentsShowcase: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionTitle("AppCard")
            AppCard {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppColors.accent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reusable surface")
                            .font(AppTypography.bodySemibold)
                        Text("Consistent radius, padding, and shadow.")
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Task list
    private var taskListShowcase: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionTitle("TaskBlock — sample day")
            VStack(spacing: AppSpacing.xs) {
                ForEach(MockData.todayTasks.prefix(6)) { task in
                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                        Text(task.startTimeLabel)
                            .font(AppTypography.captionMedium)
                            .foregroundStyle(AppColors.textTertiary)
                            .frame(width: 64, alignment: .leading)
                        TaskBlock(task: task, isSelected: task.id == MockData.featuredTask.id)
                    }
                }
            }
        }
    }

    // MARK: - Mic
    private var micButtonShowcase: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionTitle("MicButton")
            HStack(spacing: AppSpacing.xl) {
                VStack(spacing: AppSpacing.xs) {
                    MicButton(size: .compact)
                    Text("Compact").font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                VStack(spacing: AppSpacing.xs) {
                    MicButton(size: .floating)
                    Text("Floating").font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                VStack(spacing: AppSpacing.xs) {
                    MicButton(size: .large, isActive: true)
                    Text("Large (active)").font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.lg)
        }
    }

    // MARK: - Helpers
    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(AppTypography.captionSemibold)
            .tracking(0.6)
            .foregroundStyle(AppColors.textTertiary)
    }
}

/// Lightweight wrapping HStack for chips / tags.
private struct FlowingChips<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        // SwiftUI doesn't ship a flow layout target-safe everywhere we run,
        // so we use a simple grid that wraps cleanly for the design preview.
        let columns = [GridItem(.adaptive(minimum: 110), spacing: AppSpacing.xs, alignment: .leading)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: AppSpacing.xs) {
            content
        }
    }
}

#Preview {
    ContentView()
}
