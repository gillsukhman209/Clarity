//
//  DayPlanView.swift
//  Clarity
//
//  Phase 3 — iOS Today plan with time gutter, pastel task blocks, and floating mic.
//  Phase 6 — backed by `TaskStore` instead of `MockData`.
//

import SwiftUI

struct DayPlanView: View {
    @Binding var currentDate: Date
    var onOpenBrainDump: () -> Void = {}

    @Environment(TaskStore.self) private var store
    @State private var presentedTask: SelectedTask?
    @State private var showQuickAdd: Bool = false
    /// Shared with the macOS dashboard via the same UserDefaults key.
    /// ON = grouped by section (default). OFF = flat chronological.
    @AppStorage("dashboardGroupBySection") private var groupBySection: Bool = true
    /// Shared toggle: ON hides any task that belongs to a project from the
    /// Today view (and the carryover section). Project tasks still live in
    /// the project board regardless. Default OFF — show everything.
    @AppStorage("hideProjectTasksOnToday") private var hideProjectTasks: Bool = false

    private var visibleTasks: [PlanTask] {
        let all = store.tasks(on: currentDate)
        return hideProjectTasks ? all.filter { $0.projectID == nil } : all
    }

    private var carryoverItems: [PlanTask] {
        guard Calendar.current.isDateInToday(currentDate) else { return [] }
        return store.carryoverTasks(asOf: Date())
    }

    @ViewBuilder
    private var carryoverHeader: some View {
        if !carryoverItems.isEmpty {
            CarryoverSection(
                tasks: carryoverItems,
                onTapTask: { presentedTask = SelectedTask(id: $0) },
                onMoveToToday: { id in
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                        store.move(id, to: Date())
                    }
                },
                onComplete: { id in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        store.toggleComplete(id)
                    }
                },
                onDelete: { id in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        store.delete(id)
                    }
                }
            )
            .padding(.top, AppSpacing.lg)
        }
    }

    private var visibleGroups: [CategoryGroup] {
        let groups = store.categoryGroups(on: currentDate)
        guard hideProjectTasks else { return groups }
        return groups.compactMap { group in
            let filtered = group.tasks.filter { $0.projectID == nil }
            guard !filtered.isEmpty else { return nil }
            return CategoryGroup(category: group.category, tasks: filtered)
        }
    }

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy"
        return f.string(from: currentDate)
    }

    private var navigatorLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(currentDate)     { return "Today" }
        if cal.isDateInYesterday(currentDate) { return "Yesterday" }
        if cal.isDateInTomorrow(currentDate)  { return "Tomorrow" }
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: currentDate)
    }

    private func stepDate(_ delta: Int) {
        let cal = Calendar.current
        if let next = cal.date(byAdding: .day, value: delta, to: currentDate) {
            currentDate = cal.startOfDay(for: next)
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                topBar
                Divider().background(AppColors.divider)
                if visibleTasks.isEmpty && carryoverItems.isEmpty {
                    emptyState
                } else if groupBySection {
                    sectionedTaskList
                } else {
                    taskList
                }
            }
            .background(AppColors.background)

            floatingButtons
                .padding(.trailing, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
        }
        .animation(.easeInOut(duration: 0.25), value: store.tasks.map(\.isCompleted))
        .sheet(item: $presentedTask) { selection in
            TaskDetailView(taskID: selection.id) { presentedTask = nil }
                .environment(store)
                #if os(iOS)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                #endif
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddView()
                .environment(store)
                #if os(iOS)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                #endif
        }
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            Button {
                stepDate(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(navigatorLabel)
                    .font(AppTypography.titleSmall)
                    .foregroundStyle(AppColors.textPrimary)
                Text(dateLabel)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }

            Spacer()

            Button {
                stepDate(1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            Button {
                groupBySection.toggle()
            } label: {
                Image(systemName: groupBySection ? "rectangle.stack" : "list.bullet")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(groupBySection ? AppColors.accent : AppColors.textSecondary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(groupBySection ? "Switch to time-sorted view" : "Switch to grouped view")

            Button {
                hideProjectTasks.toggle()
            } label: {
                Image(systemName: hideProjectTasks ? "square.stack.3d.up.slash" : "square.stack.3d.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(hideProjectTasks ? AppColors.textTertiary : AppColors.accent)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(hideProjectTasks ? "Show project tasks in Today" : "Hide project tasks from Today")
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - Sectioned task list (groupBySection == true)
    private var sectionedTaskList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.lg) {
                ForEach(visibleGroups) { group in
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        CategoryGroupHeader(group: group)
                            .padding(.horizontal, AppSpacing.xs)
                        VStack(spacing: AppSpacing.xs) {
                            ForEach(group.tasks) { task in
                                SwipeableRow(
                                    onTap: { presentedTask = SelectedTask(id: task.id) },
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
                                        action: { store.delete(task.id) }
                                    )
                                ) {
                                    row(for: task, previous: nil)
                                        .background(AppColors.background)
                                }
                                .contextMenu {
                                    Button {
                                        store.toggleComplete(task.id)
                                    } label: {
                                        Label(task.isCompleted ? "Mark incomplete" : "Mark complete",
                                              systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark.circle")
                                    }
                                    Button(role: .destructive) {
                                        store.delete(task.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                carryoverHeader
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, 140)
        }
    }

    // MARK: - Flat task list (groupBySection == false)
    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.xs) {
                ForEach(Array(visibleTasks.enumerated()), id: \.element.id) { index, task in
                    SwipeableRow(
                        onTap: { presentedTask = SelectedTask(id: task.id) },
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
                            action: { store.delete(task.id) }
                        )
                    ) {
                        row(for: task, previous: index > 0 ? visibleTasks[index - 1] : nil)
                            .background(AppColors.background)
                    }
                    .contextMenu {
                        Button {
                            store.toggleComplete(task.id)
                        } label: {
                            Label(task.isCompleted ? "Mark incomplete" : "Mark complete",
                                  systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark.circle")
                        }
                        Button(role: .destructive) {
                            store.delete(task.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                carryoverHeader
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, 140)
        }
    }

    @ViewBuilder
    private func row(for task: PlanTask, previous: PlanTask?) -> some View {
        let showHour: Bool = {
            guard task.hasTime else { return false }
            guard let prev = previous else { return true }
            return !prev.hasTime || hour(of: prev.startTime) != hour(of: task.startTime)
        }()
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            VStack {
                Text(showHour ? hourLabel(task.startTime) : "")
                    .font(AppTypography.captionMedium)
                    .foregroundStyle(AppColors.textTertiary)
                    .padding(.top, 10)
                Spacer(minLength: 0)
            }
            .frame(width: 48, alignment: .leading)

            TaskBlock(task: task)
        }
    }

    private func hour(of date: Date) -> Int {
        Calendar.current.component(.hour, from: date)
    }

    private func hourLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h a"
        return f.string(from: date)
    }

    // MARK: - Empty state
    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(AppColors.accent.opacity(0.5))
            Text("Your day is a blank slate")
                .font(AppTypography.title)
                .foregroundStyle(AppColors.textPrimary)
            Text("Tap the mic and tell me what's on your mind.\nI'll plan it for you.")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppSpacing.xl)
    }

    // MARK: - Floating buttons
    private var floatingButtons: some View {
        VStack(spacing: 12) {
            Button {
                showQuickAdd = true
            } label: {
                ZStack {
                    Circle()
                        .fill(AppColors.surface)
                        .frame(width: 44, height: 44)
                        .appShadow(AppShadow.card)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColors.accent)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Quick add task")

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
                        .frame(width: 56, height: 56)
                        .appShadow(AppShadow.micGlow)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Brain dump")
        }
    }
}

private struct SelectedTask: Identifiable, Hashable {
    let id: UUID
}
