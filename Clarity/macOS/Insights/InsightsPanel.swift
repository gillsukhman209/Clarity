//
//  InsightsPanel.swift
//  Clarity
//
//  Phase 4 — far-right column with day-at-a-glance tiles and a real progress
//  gauge driven by the user's actual tasks. No mock numbers.
//

#if os(macOS)
import SwiftUI

struct InsightsPanel: View {
    var currentDate: Date = Date()
    var onClose: () -> Void = {}

    @Environment(TaskStore.self) private var store

    private var visibleTasks: [PlanTask] {
        store.tasks(on: currentDate)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    HStack {
                        Text("Insights")
                            .font(AppTypography.title)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        HoverScaleButton(action: onClose, hoverScale: 1.08) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.textSecondary)
                                .frame(width: 24, height: 24)
                                .background(
                                    Circle().fill(AppColors.surface)
                                )
                                .overlay(
                                    Circle().stroke(AppColors.border, lineWidth: 1)
                                )
                        }
                        .accessibilityLabel("Hide Insights")
                    }

                    Text("Day at a glance")
                        .font(AppTypography.captionSemibold)
                        .tracking(0.6)
                        .foregroundStyle(AppColors.textTertiary)

                    let stats = computeStats(visibleTasks)

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
                            value: durationLabel(stats.focusMinutes),
                            subtitle: tasksLabel(stats.focusCount),
                            accent: AppColors.Category.focusInk
                        )
                        InsightTile(
                            symbol: "person.2.fill",
                            title: "Get Things Done",
                            value: durationLabel(stats.gtdMinutes),
                            subtitle: tasksLabel(stats.gtdCount),
                            accent: AppColors.Category.workInk
                        )
                        InsightTile(
                            symbol: "cup.and.saucer.fill",
                            title: "Energize",
                            value: durationLabel(stats.energizeMinutes),
                            subtitle: tasksLabel(stats.energizeCount),
                            accent: AppColors.Category.energizeInk
                        )
                        InsightTile(
                            symbol: "checkmark.circle.fill",
                            title: "Tasks",
                            value: "\(stats.totalTasks)",
                            subtitle: stats.completedCount > 0 ? "\(stats.completedCount) done" : "Today",
                            accent: AppColors.Category.personalInk
                        )
                    }

                    progressCard(stats)
                }
                .padding(AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(AppColors.background)
    }

    // MARK: - Stats

    private struct DayStats {
        let totalTasks: Int
        let completedCount: Int
        let focusMinutes: Int
        let focusCount: Int
        let gtdMinutes: Int
        let gtdCount: Int
        let energizeMinutes: Int
        let energizeCount: Int
        var completionPercent: Int {
            guard totalTasks > 0 else { return 0 }
            return Int((Double(completedCount) / Double(totalTasks) * 100).rounded())
        }
    }

    private func computeStats(_ tasks: [PlanTask]) -> DayStats {
        let focus    = tasks.filter { $0.section == .focusTime || $0.section == .create }
        let gtd      = tasks.filter { $0.section == .getThingsDone }
        let energize = tasks.filter { $0.section == .energize }
        return DayStats(
            totalTasks: tasks.count,
            completedCount: tasks.filter(\.isCompleted).count,
            focusMinutes: focus.reduce(0) { $0 + $1.durationMinutes },
            focusCount: focus.count,
            gtdMinutes: gtd.reduce(0) { $0 + $1.durationMinutes },
            gtdCount: gtd.count,
            energizeMinutes: energize.reduce(0) { $0 + $1.durationMinutes },
            energizeCount: energize.count
        )
    }

    private func durationLabel(_ minutes: Int) -> String {
        if minutes == 0 { return "—" }
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    private func tasksLabel(_ count: Int) -> String {
        switch count {
        case 0: return "No tasks"
        case 1: return "1 task"
        default: return "\(count) tasks"
        }
    }

    private func progressCaption(percent: Int, total: Int) -> String {
        guard total > 0 else { return "No tasks yet" }
        switch percent {
        case 100: return "Done for the day"
        case 80...: return "Almost there"
        case 50...: return "Halfway there"
        case 1...:  return "Building momentum"
        default:    return "Let's get started"
        }
    }

    // MARK: - Progress card

    private func progressCard(_ stats: DayStats) -> some View {
        AppCard(padding: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Today's Progress")
                    .font(AppTypography.captionSemibold)
                    .tracking(0.6)
                    .foregroundStyle(AppColors.textTertiary)
                ProductivityGauge(
                    score: stats.completionPercent,
                    caption: progressCaption(percent: stats.completionPercent, total: stats.totalTasks)
                )
                .frame(maxWidth: .infinity)
            }
        }
    }

}
#endif
