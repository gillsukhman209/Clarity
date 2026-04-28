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
    @State private var showBrainDump: Bool = false
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
        #if os(iOS)
        .fullScreenCover(isPresented: $showBrainDump) {
            BrainDumpFlowView(projectID: projectID)
        }
        #else
        .sheet(isPresented: $showBrainDump) {
            BrainDumpFlowView(projectID: projectID)
                .frame(minWidth: 480, minHeight: 720)
        }
        #endif
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
            brainDumpButton
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

    private var brainDumpButton: some View {
        Button { showBrainDump = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text("Brain dump")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(AppColors.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(AppColors.accentSoft.opacity(0.45)))
            .overlay(Capsule().stroke(AppColors.accent.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
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
            onDrop: { droppedID in
                withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                    store.setBoardStatus(status, for: droppedID)
                }
            },
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
            }
        )
        .frame(width: columnWidth)
        #if os(iOS)
        .containerRelativeFrame(.horizontal)
        #endif
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
    var onDrop: (UUID) -> Void
    var onAddInline: () -> Void
    var onMoveTask: (UUID, TaskBoardStatus) -> Void
    var onDeleteTask: (UUID) -> Void

    @State private var isTargeted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    if tasks.isEmpty {
                        emptyHint
                    } else {
                        ForEach(tasks) { task in
                            KanbanCard(task: task)
                                .draggable(DraggedTask(taskID: task.id))
                                .onTapGesture { onTapTask(task.id) }
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
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.surface.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isTargeted ? status.accentColor.opacity(0.7) : AppColors.border.opacity(0.5),
                    lineWidth: isTargeted ? 2 : 1
                )
        )
        .animation(.easeInOut(duration: 0.18), value: isTargeted)
        .dropDestination(for: DraggedTask.self) { items, _ in
            for item in items { onDrop(item.taskID) }
            return !items.isEmpty
        } isTargeted: { isTargeted = $0 }
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
