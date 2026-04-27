//
//  DashboardView.swift
//  Clarity
//
//  Phase 4 — main center column: greeting, toolbar, day plan grouped into sections.
//  Phase 6 — backed by TaskStore.
//

#if os(macOS)
import SwiftUI

struct DashboardView: View {
    @Binding var selectedTaskID: UUID?
    var onOpenBrainDump: () -> Void = {}

    @Environment(TaskStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.xl)

            toolbar
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)

            if store.daySections.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppSpacing.xl) {
                        ForEach(store.daySections) { section in
                            sectionView(section)
                        }
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.background)
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Good morning, \(MockData.userFirstName).")
                .font(AppTypography.displayLarge)
                .foregroundStyle(AppColors.textPrimary)
            Text("Let's make today count.")
                .font(AppTypography.bodyLarge)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    // MARK: - Toolbar
    private var toolbar: some View {
        HStack(spacing: AppSpacing.sm) {
            todayNavigator
            replanButton
            Spacer()
            searchField
            addTaskButton
        }
    }

    private var todayNavigator: some View {
        HStack(spacing: 6) {
            chevronButton(symbol: "chevron.left")
            Text("Today")
                .font(AppTypography.bodySemibold)
                .foregroundStyle(AppColors.textPrimary)
                .frame(minWidth: 60)
            chevronButton(symbol: "chevron.right")
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous).fill(AppColors.surface)
        )
        .overlay(
            Capsule(style: .continuous).stroke(AppColors.border, lineWidth: 1)
        )
    }

    private func chevronButton(symbol: String) -> some View {
        HoverScaleButton(action: {}) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 24, height: 24)
        }
    }

    private var replanButton: some View {
        HoverScaleButton(action: {}) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                Text("Re-plan")
                    .font(AppTypography.bodyMedium)
            }
            .foregroundStyle(AppColors.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule(style: .continuous).fill(AppColors.accentSoft.opacity(0.45)))
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
            Text("Search")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textTertiary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: 220)
        .background(
            Capsule(style: .continuous).fill(AppColors.surface)
        )
        .overlay(
            Capsule(style: .continuous).stroke(AppColors.border, lineWidth: 1)
        )
    }

    private var addTaskButton: some View {
        HoverScaleButton(action: onOpenBrainDump, hoverScale: 1.06) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.accent.opacity(0.95), AppColors.accent],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            .appShadow(AppShadow.card)
        }
    }

    // MARK: - Empty state
    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(AppColors.accent.opacity(0.5))
            Text("Nothing planned yet")
                .font(AppTypography.title)
                .foregroundStyle(AppColors.textPrimary)
            Text("Tap the mic on the right to do a brain dump.\nI'll turn it into a structured day.")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Section
    @ViewBuilder
    private func sectionView(_ section: DaySection) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            DaySectionHeader(section: section)

            VStack(spacing: AppSpacing.xs) {
                ForEach(section.tasks) { task in
                    HoverScaleButton(
                        action: { selectedTaskID = task.id },
                        hoverScale: 1.005
                    ) {
                        HStack(spacing: AppSpacing.sm) {
                            Text(task.startTimeLabel)
                                .font(AppTypography.captionMedium)
                                .foregroundStyle(AppColors.textTertiary)
                                .frame(width: 72, alignment: .leading)
                            TaskBlock(task: task, isSelected: task.id == selectedTaskID)
                        }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: section.tasks.map(\.isCompleted))
    }
}
#endif
