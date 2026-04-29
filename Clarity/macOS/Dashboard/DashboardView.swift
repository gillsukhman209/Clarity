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
    @State private var showProjectFilter: Bool = false
    /// Persisted across launches. Default ON (grouped by section, current behavior).
    /// Toggle off to flatten the day into one chronological list.
    @AppStorage("dashboardGroupBySection") private var groupBySection: Bool = true
    /// Per-project visibility for Today. JSON-encoded `[UUID]` of projects
    /// the user has hidden. Free-floating tasks (no project) always show.
    @AppStorage(HiddenProjects.storageKey) private var hiddenProjectsRaw: String = ""

    private var hiddenProjectIDs: Set<UUID> {
        HiddenProjects.decode(hiddenProjectsRaw)
    }

    private func isHidden(_ task: PlanTask) -> Bool {
        guard let pid = task.projectID else { return false }
        return hiddenProjectIDs.contains(pid)
    }

    private var visibleGroups: [CategoryGroup] {
        let groups = store.categoryGroups(on: currentDate)
        let hidden = hiddenProjectIDs
        guard !hidden.isEmpty else { return groups }
        return groups.compactMap { group in
            let filtered = group.tasks.filter {
                guard let pid = $0.projectID else { return true }
                return !hidden.contains(pid)
            }
            guard !filtered.isEmpty else { return nil }
            return CategoryGroup(category: group.category, tasks: filtered)
        }
    }

    /// Tasks for the visible day. The store already sorts timed-first, then
    /// Anytime tasks by `manualOrder`, so we just filter out hidden projects.
    private var visibleTasks: [PlanTask] {
        store.tasks(on: currentDate).filter { !isHidden($0) }
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
                onTapTask: { selectedTaskID = $0 },
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
                        if selectedTaskID == id { selectedTaskID = nil }
                        store.delete(id)
                    }
                }
            )
            .padding(.top, AppSpacing.lg)
        }
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

                if visibleTasks.isEmpty && carryoverItems.isEmpty {
                    emptyState
                } else if groupBySection {
                    taskList
                } else {
                    flatTaskList
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
            Spacer()
            searchField
            addTaskButton
            sortToggle
            projectVisibilityToggle
            insightsToggle
        }
    }

    private var sortToggle: some View {
        HoverScaleButton(action: { groupBySection.toggle() }, hoverScale: 1.06) {
            Image(systemName: groupBySection ? "rectangle.stack" : "list.bullet")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(groupBySection ? AppColors.accent : AppColors.textSecondary)
                .frame(width: 32, height: 32)
                .background(
                    Capsule(style: .continuous)
                        .fill(groupBySection ? AppColors.accentSoft.opacity(0.45) : AppColors.surface)
                )
                .overlay(
                    Capsule(style: .continuous).stroke(AppColors.border, lineWidth: 1)
                )
        }
        .accessibilityLabel(groupBySection ? "Switch to time-sorted view" : "Switch to grouped view")
    }

    @ViewBuilder
    private var projectVisibilityToggle: some View {
        if store.projects.isEmpty {
            EmptyView()
        } else {
            let anyHidden = !hiddenProjectIDs.isEmpty
            HoverScaleButton(action: { showProjectFilter.toggle() }, hoverScale: 1.06) {
                Image(systemName: anyHidden ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(anyHidden ? AppColors.accent : AppColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(
                        Capsule(style: .continuous)
                            .fill(anyHidden ? AppColors.accentSoft.opacity(0.45) : AppColors.surface)
                    )
                    .overlay(
                        Capsule(style: .continuous).stroke(AppColors.border, lineWidth: 1)
                    )
            }
            .accessibilityLabel("Filter projects shown in Today")
            .popover(isPresented: $showProjectFilter, arrowEdge: .bottom) {
                projectFilterPopover
            }
        }
    }

    private var projectFilterPopover: some View {
        let hidden = hiddenProjectIDs
        let anyHidden = !hidden.isEmpty
        return VStack(alignment: .leading, spacing: 0) {
            Text("Show in Today")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textTertiary)
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)

            VStack(spacing: 2) {
                ForEach(store.projects) { p in
                    let on = !hidden.contains(p.id)
                    Button {
                        hiddenProjectsRaw = HiddenProjects.toggling(p.id, in: hiddenProjectsRaw)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: on ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(on ? p.accentColor : AppColors.textTertiary)
                            Image(systemName: p.iconSymbol)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(p.accentColor)
                                .frame(width: 16)
                            Text(p.name)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppColors.textPrimary)
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider().background(AppColors.divider).padding(.vertical, 6)

            Button {
                if anyHidden {
                    hiddenProjectsRaw = ""
                } else {
                    hiddenProjectsRaw = HiddenProjects.encode(Set(store.projects.map(\.id)))
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: anyHidden ? "eye" : "eye.slash")
                        .font(.system(size: 12, weight: .semibold))
                    Text(anyHidden ? "Show all projects" : "Hide all projects")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    Spacer(minLength: 0)
                }
                .foregroundStyle(AppColors.accent)
                .contentShape(Rectangle())
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 8)
        }
        .frame(minWidth: 240)
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
                ForEach(visibleGroups) { group in
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        CategoryGroupHeader(group: group)
                        VStack(spacing: AppSpacing.xs) {
                            ForEach(group.tasks) { task in
                                groupedRow(task, in: group)
                            }
                        }
                    }
                }
                carryoverHeader
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
        }
    }

    private func taskRow(_ task: PlanTask) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Text(task.timeLabel ?? "—")
                .font(AppTypography.captionMedium)
                .foregroundStyle(AppColors.textTertiary)
                .frame(width: 72, alignment: .leading)
            TaskBlock(task: task, isSelected: task.id == selectedTaskID)
        }
    }

    // MARK: - Flat task list (sorted by time, no section grouping)
    private var flatTaskList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppSpacing.xs) {
                ForEach(visibleTasks) { task in
                    flatRow(task)
                }
                carryoverHeader
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
        }
    }

    // MARK: - Anytime reorder helpers

    /// All Anytime tasks for the current day in display order.
    private var anytimeTasks: [PlanTask] {
        visibleTasks.filter { !$0.hasTime }
    }

    /// Anytime tasks within a single category bucket. Reorder is scoped to
    /// each category in grouped view to avoid implicit category changes.
    private func anytimeTasks(in group: CategoryGroup) -> [PlanTask] {
        group.tasks.filter { !$0.hasTime }
    }

    @ViewBuilder
    private func groupedRow(_ task: PlanTask, in group: CategoryGroup) -> some View {
        if task.hasTime {
            timedSwipeRow(task)
        } else {
            anytimeRow(task, pool: anytimeTasks(in: group))
        }
    }

    @ViewBuilder
    private func flatRow(_ task: PlanTask) -> some View {
        if task.hasTime {
            timedSwipeRow(task)
        } else {
            anytimeRow(task, pool: anytimeTasks)
        }
    }

    private func anytimeRow(_ task: PlanTask, pool: [PlanTask]) -> some View {
        AnytimeReorderRow(
            task: task,
            pool: pool,
            onTap: { selectedTaskID = task.id },
            onComplete: {
                withAnimation(.easeInOut(duration: 0.2)) { store.toggleComplete(task.id) }
            },
            onDelete: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if selectedTaskID == task.id { selectedTaskID = nil }
                    store.delete(task.id)
                }
            },
            onReorder: { newIDs in
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    store.reorderAnytimeTasks(newIDs)
                }
            }
        ) {
            taskRow(task).background(AppColors.background)
        }
        .contextMenu { rowMenu(task) }
    }

    private func timedSwipeRow(_ task: PlanTask) -> some View {
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
            taskRow(task).background(AppColors.background)
        }
        .contextMenu { rowMenu(task) }
    }

    @ViewBuilder
    private func rowMenu(_ task: PlanTask) -> some View {
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
#endif
