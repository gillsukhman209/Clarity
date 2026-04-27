//
//  DashboardView.swift
//  Clarity
//
//  Phase 4 — main center column: greeting, toolbar, day plan grouped into sections.
//

#if os(macOS)
import SwiftUI

struct DashboardView: View {
    @Binding var selectedTask: PlanTask?
    var onOpenBrainDump: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.xl)

            toolbar
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    ForEach(MockData.daySections) { section in
                        sectionView(section)
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xl)
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
        Button {} label: {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
    }

    private var replanButton: some View {
        Button {} label: {
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
        .buttonStyle(.plain)
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
        Button(action: onOpenBrainDump) {
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
        .buttonStyle(.plain)
    }

    // MARK: - Section
    @ViewBuilder
    private func sectionView(_ section: DaySection) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            DaySectionHeader(section: section)

            VStack(spacing: AppSpacing.xs) {
                ForEach(section.tasks) { task in
                    Button {
                        selectedTask = task
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Text(task.startTimeLabel)
                                .font(AppTypography.captionMedium)
                                .foregroundStyle(AppColors.textTertiary)
                                .frame(width: 72, alignment: .leading)
                            TaskBlock(task: task, isSelected: task.id == selectedTask?.id)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
#endif
