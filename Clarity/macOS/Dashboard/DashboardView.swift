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
    @Binding var currentDate: Date
    @Binding var showInsights: Bool
    var onOpenBrainDump: () -> Void = {}

    @Environment(TaskStore.self) private var store
    @State private var showQuickAdd: Bool = false

    private var visibleSections: [DaySection] {
        store.daySections(on: currentDate)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, AppSpacing.xl)

                toolbar
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.lg)

                if visibleSections.isEmpty {
                    emptyState
                } else {
                    taskList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            floatingMic
                .padding(AppSpacing.xl)
        }
        .background(AppColors.background)
    }

    // MARK: - Floating mic — opens the "Plan your whole day" view
    private var floatingMic: some View {
        HoverScaleButton(action: onOpenBrainDump, hoverScale: 1.06) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.accent.opacity(0.95), AppColors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .appShadow(AppShadow.micGlow)
                Image(systemName: "mic.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .accessibilityLabel("Plan your whole day")
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(AppTypography.displayLarge)
                .foregroundStyle(AppColors.textPrimary)
            Text(dateLine)
                .font(AppTypography.bodyLarge)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var greeting: String {
        if !Calendar.current.isDateInToday(currentDate) {
            return relativeDayLabel
        }
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:  return "Good morning."
        case 12..<17: return "Good afternoon."
        default:      return "Good evening."
        }
    }

    private var dateLine: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: currentDate)
    }

    private var relativeDayLabel: String {
        let cal = Calendar.current
        if cal.isDateInYesterday(currentDate) { return "Yesterday." }
        if cal.isDateInTomorrow(currentDate)  { return "Tomorrow." }
        let f = DateFormatter()
        f.dateFormat = "EEEE."
        return f.string(from: currentDate)
    }

    // MARK: - Toolbar
    private var toolbar: some View {
        HStack(spacing: AppSpacing.sm) {
            todayNavigator
            replanButton
            Spacer()
            searchField
            addTaskButton
            insightsToggle
        }
    }

    private var todayNavigator: some View {
        HStack(spacing: 6) {
            chevronButton(symbol: "chevron.left", action: { stepDate(-1) })
            Text(navigatorLabel)
                .font(AppTypography.bodySemibold)
                .foregroundStyle(AppColors.textPrimary)
                .frame(minWidth: 80)
            chevronButton(symbol: "chevron.right", action: { stepDate(1) })
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

    private var navigatorLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(currentDate)     { return "Today" }
        if cal.isDateInYesterday(currentDate) { return "Yesterday" }
        if cal.isDateInTomorrow(currentDate)  { return "Tomorrow" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: currentDate)
    }

    private func stepDate(_ delta: Int) {
        let cal = Calendar.current
        if let next = cal.date(byAdding: .day, value: delta, to: currentDate) {
            currentDate = cal.startOfDay(for: next)
        }
    }

    private var insightsToggle: some View {
        HoverScaleButton(action: { showInsights.toggle() }, hoverScale: 1.06) {
            Image(systemName: showInsights ? "sidebar.right" : "sidebar.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(showInsights ? AppColors.accent : AppColors.textSecondary)
                .frame(width: 32, height: 32)
                .background(
                    Capsule(style: .continuous)
                        .fill(showInsights ? AppColors.accentSoft.opacity(0.45) : AppColors.surface)
                )
                .overlay(
                    Capsule(style: .continuous).stroke(AppColors.border, lineWidth: 1)
                )
        }
        .accessibilityLabel(showInsights ? "Hide Insights" : "Show Insights")
    }

    private func chevronButton(symbol: String, action: @escaping () -> Void) -> some View {
        HoverScaleButton(action: action) {
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
        HoverScaleButton(action: { showQuickAdd = true }, hoverScale: 1.06) {
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
        .sheet(isPresented: $showQuickAdd) {
            QuickAddView()
                .environment(store)
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

    // MARK: - Task list
    private var taskList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                ForEach(visibleSections) { section in
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        DaySectionHeader(section: section)

                        VStack(spacing: AppSpacing.xs) {
                            ForEach(section.tasks) { task in
                                SwipeableRow(
                                    onTap: { selectedTaskID = task.id },
                                    leadingAction: SwipeAction(
                                        symbol: task.isCompleted ? "arrow.uturn.backward" : "checkmark",
                                        title: task.isCompleted ? "Undo" : "Done",
                                        color: AppColors.Priority.lowInk,
                                        action: { store.toggleComplete(task.id) }
                                    ),
                                    trailingAction: SwipeAction(
                                        symbol: "trash",
                                        title: "Delete",
                                        color: AppColors.Priority.highInk,
                                        isDestructive: true,
                                        action: {
                                            if selectedTaskID == task.id { selectedTaskID = nil }
                                            store.delete(task.id)
                                        }
                                    )
                                ) {
                                    taskRow(task)
                                        .background(AppColors.background)
                                }
                                .contextMenu {
                                    Button {
                                        store.toggleComplete(task.id)
                                    } label: {
                                        Label(task.isCompleted ? "Mark incomplete" : "Mark complete",
                                              systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark.circle")
                                    }
                                    Divider()
                                    Button(role: .destructive) {
                                        if selectedTaskID == task.id { selectedTaskID = nil }
                                        store.delete(task.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
        }
    }

    private func taskRow(_ task: PlanTask) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Text(task.startTimeLabel)
                .font(AppTypography.captionMedium)
                .foregroundStyle(AppColors.textTertiary)
                .frame(width: 72, alignment: .leading)
            TaskBlock(task: task, isSelected: task.id == selectedTaskID)
        }
    }
}
#endif
