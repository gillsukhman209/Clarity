//
//  ProjectDetailView.swift
//  Clarity
//
//  Trello-style kanban board for a single project.
//  Three columns — Upcoming / Working on / Done — with drag-and-drop between
//  them. The whole view lives on top of TaskStore so completing a card from
//  the board flows back into Today / Calendar in one shot.
//

import SwiftUI

struct ProjectDetailView: View {
    let projectID: UUID
    @Environment(TaskStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var quickText: String = ""
    @State private var addTargetStatus: TaskBoardStatus = .upcoming
    @State private var presentedTaskID: UUID?
    @State private var showEditProject: Bool = false
    /// Frames of each kanban column in the `"kanbanBoard"` coordinate space.
    /// Cards report their drop location and we hit-test against this map.
    @State private var columnFrames: [TaskBoardStatus: CGRect] = [:]
    /// The status (column) that currently has a lifted/dragging card. We
    /// raise that column's zIndex so the floating card draws on top of its
    /// siblings instead of being hidden by the next HStack child.
    @State private var draggingFromStatus: TaskBoardStatus? = nil
    @FocusState private var quickFocused: Bool

    private var project: Project? { store.project(with: projectID) }

    private var buckets: [TaskBoardStatus: [PlanTask]] {
        store.tasksByBoardStatus(in: projectID)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()

            if let project {
                VStack(spacing: 0) {
                    header(project)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.md)
                        .padding(.bottom, AppSpacing.sm)

                    quickAddBar(project)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.md)

                    board
                        .padding(.bottom, AppSpacing.lg)
                }
            } else {
                Text("Project not found")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .sheet(isPresented: $showEditProject) {
            if let project {
                ProjectEditorSheet(editing: project) {
                    // If user deleted the project, bounce back to the list.
                    if store.project(with: projectID) == nil { dismiss() }
                }
                .environment(store)
            }
        }
        .sheet(item: Binding(
            get: { presentedTaskID.map(SelectedTask.init) },
            set: { presentedTaskID = $0?.id }
        )) { sel in
            TaskEditView(taskID: sel.id) { presentedTaskID = nil }
                .environment(store)
                #if os(iOS)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                #endif
        }
    }

    // MARK: - Header
    private func header(_ project: Project) -> some View {
        HStack(spacing: 14) {
            backButton
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(project.accentColor.opacity(0.18))
                    .frame(width: 40, height: 40)
                Image(systemName: project.iconSymbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(project.accentColor)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(project.name)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                let total = store.tasks(in: projectID).count
                Text(total == 1 ? "1 task" : "\(total) tasks")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            menuButton(project)
        }
    }

    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 32, height: 32)
                .background(Circle().fill(AppColors.surface))
                .overlay(Circle().stroke(AppColors.border.opacity(0.6), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back to projects")
    }

    private func menuButton(_ project: Project) -> some View {
        Menu {
            Button {
                showEditProject = true
            } label: {
                Label("Edit project", systemImage: "pencil")
            }
            Button {
                store.setArchived(project.id, archived: true)
                dismiss()
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 32, height: 32)
                .background(Circle().fill(AppColors.surface))
                .overlay(Circle().stroke(AppColors.border.opacity(0.6), lineWidth: 1))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    // MARK: - Quick add
    private func quickAddBar(_ project: Project) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(project.accentColor)
                TextField("Add a task to this project", text: $quickText)
                    .textFieldStyle(.plain)
                    .focused($quickFocused)
                    .submitLabel(.done)
                    .font(.system(size: 14, design: .rounded))
                    .onSubmit { submitQuick() }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous).fill(AppColors.surface)
            )
            .overlay(
                Capsule(style: .continuous).stroke(AppColors.border.opacity(0.6), lineWidth: 1)
            )

            if !quickText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button { submitQuick() } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(AppColors.accent))
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: quickText.isEmpty)
    }

    // MARK: - Board
    private var board: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 14) {
                column(.upcoming)
                column(.workingOn)
                column(.done)
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        // Don't clip the outer scroll either — the dragging-column zIndex
        // raise plus this ensures a lifted card draws on top of everything,
        // including the columns rendered later in the HStack.
        .scrollClipDisabled()
        // Coordinate space the columns publish their frames into and the
        // card gesture reads its drop location from. Same name on both ends
        // means a simple `frame.contains(location)` check works.
        .coordinateSpace(name: "kanbanBoard")
        .onPreferenceChange(KanbanColumnFramesKey.self) { newFrames in
            columnFrames = newFrames
        }
        #if os(iOS)
        .scrollTargetBehavior(.viewAligned)
        #endif
    }

    private func column(_ status: TaskBoardStatus) -> some View {
        let tasks = buckets[status] ?? []
        return KanbanColumn(
            status: status,
            tasks: tasks,
            onTapTask: { presentedTaskID = $0 },
            onCardDrop: { taskID, location in handleDrop(taskID: taskID, at: location) },
            onAddInline: {
                addTargetStatus = status
                quickFocused = true
            },
            onMoveTask: { taskID, newStatus in
                withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                    store.setBoardStatus(newStatus, for: taskID)
                }
            },
            onDeleteTask: { taskID in
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.delete(taskID)
                }
            },
            onCardLiftedChange: { lifted in
                draggingFromStatus = lifted ? status : nil
            }
        )
        .frame(width: columnWidth)
        // Raise the dragging column above its siblings so the floating card
        // is drawn over later HStack children (Working on, Done, etc.)
        // rather than disappearing behind them.
        .zIndex(draggingFromStatus == status ? 100 : 0)
        #if os(iOS)
        .containerRelativeFrame(.horizontal)
        #endif
    }

    /// Hit-test the drop location against captured column frames. If the
    /// finger ended up inside a column other than the task's current one,
    /// move the task there.
    private func handleDrop(taskID: UUID, at location: CGPoint) {
        for (status, frame) in columnFrames {
            if frame.contains(location) {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                    store.setBoardStatus(status, for: taskID)
                }
                return
            }
        }
        // Dropped outside any column — no-op (card snaps back visually).
    }

    /// On macOS we want all three columns visible side-by-side; on iOS we
    /// page through them one at a time. SwiftUI handles the iOS sizing via
    /// `containerRelativeFrame` so we only need a hint here for macOS.
    private var columnWidth: CGFloat {
        #if os(macOS)
        return 320
        #else
        return UIScreen.main.bounds.width - 48
        #endif
    }

    // MARK: - Quick add submit
    private func submitQuick() {
        let trimmed = quickText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let parsed = SmartTaskParser.parse(trimmed)
        let hasTime = SmartTaskParser.hasExplicitTime(in: trimmed)
        let anchor = parsed.startTime ?? Calendar.current.startOfDay(for: Date())
        let task = PlanTask(
            title: parsed.title,
            category: parsed.category,
            priority: .medium,
            startTime: anchor,
            hasTime: hasTime,
            durationMinutes: parsed.durationMinutes,
            projectID: projectID,
            boardStatus: addTargetStatus
        )
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            store.append([task])
        }
        quickText = ""
        addTargetStatus = .upcoming
    }
}

// MARK: - Selected task wrapper

private struct SelectedTask: Identifiable, Hashable {
    let id: UUID
}

// MARK: - Kanban column

private struct KanbanColumn: View {
    let status: TaskBoardStatus
    let tasks: [PlanTask]
    var onTapTask: (UUID) -> Void
    /// Called on every card drop. Args: dragged task id + finger location
    /// in the board's coordinate space.
    var onCardDrop: (UUID, CGPoint) -> Void
    var onAddInline: () -> Void
    var onMoveTask: (UUID, TaskBoardStatus) -> Void
    var onDeleteTask: (UUID) -> Void
    /// Forwarded to the parent so it can raise this column's zIndex while a
    /// card here is in drag mode.
    var onCardLiftedChange: (Bool) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    // (clip disabled below — see `.scrollClipDisabled()`)
                    if tasks.isEmpty {
                        emptyHint
                    } else {
                        ForEach(tasks) { task in
                            KanbanCardGesture(
                                onTap: { onTapTask(task.id) },
                                onComplete: { onMoveTask(task.id, status == .done ? .upcoming : .done) },
                                onDelete: { onDeleteTask(task.id) },
                                onDropAt: { location in onCardDrop(task.id, location) },
                                onDragLiftedChange: { lifted in onCardLiftedChange(lifted) }
                            ) {
                                KanbanCard(task: task)
                            }
                            .contextMenu {
                                Button {
                                    onTapTask(task.id)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                Divider()
                                ForEach(TaskBoardStatus.allCases) { other in
                                    if other != status {
                                        Button {
                                            onMoveTask(task.id, other)
                                        } label: {
                                            Label("Move to \(other.title)", systemImage: other.sfSymbol)
                                        }
                                    }
                                }
                                Divider()
                                Button(role: .destructive) {
                                    onDeleteTask(task.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.96).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            // Lets a card that's been lifted (drag mode) extend beyond the
            // column's bounds — without this the floating card is clipped
            // to the ScrollView and disappears the moment the user drags it
            // sideways toward another column.
            .scrollClipDisabled()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.surface.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColors.border.opacity(0.5), lineWidth: 1)
        )
        // Publish this column's frame in board coordinates so the parent
        // can hit-test card drops.
        .background(
            GeometryReader { proxy in
                Color.clear
                    .preference(
                        key: KanbanColumnFramesKey.self,
                        value: [status: proxy.frame(in: .named("kanbanBoard"))]
                    )
            }
        )
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: status.sfSymbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(status.accentColor)
            Text(status.title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
            Text("\(tasks.count)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textTertiary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(AppColors.background))
            Spacer()
            Button(action: onAddInline) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add to \(status.title)")
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
    }

    private var emptyHint: some View {
        VStack(spacing: 4) {
            Text("Drop a card here")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.border.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        )
    }
}

// MARK: - Kanban card

private struct KanbanCard: View {
    let task: PlanTask

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(task.category.fillColor.opacity(0.7))
                        .frame(width: 24, height: 24)
                    Image(systemName: task.category.sfSymbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(task.category.inkColor)
                }
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .strikethrough(task.isCompleted, color: AppColors.textTertiary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 6) {
                if task.hasTime {
                    metaPill(
                        icon: "clock",
                        text: task.startTimeLabel,
                        tint: AppColors.textSecondary
                    )
                }
                if let durationLabel = task.durationLabel {
                    metaPill(
                        icon: "hourglass",
                        text: durationLabel,
                        tint: AppColors.textSecondary
                    )
                }
                Spacer(minLength: 0)
                Circle()
                    .fill(task.priority.inkColor)
                    .frame(width: 7, height: 7)
                    .accessibilityLabel("\(task.priority.title) priority")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.border.opacity(0.55), lineWidth: 1)
        )
        .appShadow(AppShadow.card)
    }

    private func metaPill(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(AppColors.surface.opacity(0.6)))
    }
}
