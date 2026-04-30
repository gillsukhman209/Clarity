//
//  ProjectListView.swift
//  Clarity
//
//  Cross-platform list of the user's projects. Tap to open the kanban board;
//  context menu / edit button to rename / change icon-color / archive / delete.
//

import SwiftUI

struct ProjectListView: View {
    @Environment(TaskStore.self) private var store

    /// Single sheet target for both create + edit. Two separate `.sheet`
    /// modifiers on the same view fight for presentation, which is why
    /// "+" did nothing once at least one project existed.
    enum EditorPresentation: Identifiable {
        case create
        case edit(Project)
        var id: String {
            switch self {
            case .create:        return "create"
            case .edit(let p):   return p.id.uuidString
            }
        }
    }

    @State private var editorPresentation: EditorPresentation?
    @State private var showArchived: Bool = false
    @State private var pendingDelete: Project?

    var body: some View {
        NavigationStack {
            Group {
                if store.projects.isEmpty && store.archivedProjects.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Projects")
            .background(AppColors.background)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editorPresentation = .create
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .accessibilityLabel("New project")
                }
            }
            .sheet(item: $editorPresentation) { presentation in
                switch presentation {
                case .create:
                    ProjectEditorSheet(editing: nil)
                        .environment(store)
                case .edit(let project):
                    ProjectEditorSheet(editing: project)
                        .environment(store)
                }
            }
            .confirmationDialog(
                "Delete project?",
                isPresented: Binding(
                    get: { pendingDelete != nil },
                    set: { if !$0 { pendingDelete = nil } }
                ),
                presenting: pendingDelete
            ) { project in
                Button("Delete \(project.name) and its tasks", role: .destructive) {
                    store.deleteProject(project.id)
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: { _ in
                Text("This permanently removes the project and every task in it.")
            }
        }
    }

    private var list: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: AppSpacing.sm) {
                if !store.projects.isEmpty {
                    ForEach(store.projects) { project in
                        projectRow(project, archived: false)
                    }
                }

                if !store.archivedProjects.isEmpty {
                    archivedHeader
                    if showArchived {
                        ForEach(store.archivedProjects) { project in
                            projectRow(project, archived: true)
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xl)
        }
        .navigationDestination(for: UUID.self) { id in
            ProjectDetailView(projectID: id)
                .environment(store)
        }
    }

    @ViewBuilder
    private func projectRow(_ project: Project, archived: Bool) -> some View {
        if archived {
            ProjectListRow(project: project, taskCount: store.tasks(in: project.id).count, dimmed: true)
                .contextMenu { menu(for: project, archived: true) }
        } else {
            NavigationLink(value: project.id) {
                ProjectListRow(project: project, taskCount: store.tasks(in: project.id).count, dimmed: false)
            }
            .buttonStyle(.plain)
            .contextMenu { menu(for: project, archived: false) }
        }
    }

    @ViewBuilder
    private func menu(for project: Project, archived: Bool) -> some View {
        Button {
            editorPresentation = .edit(project)
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        if archived {
            Button {
                store.setArchived(project.id, archived: false)
            } label: {
                Label("Restore", systemImage: "tray.and.arrow.up")
            }
        } else {
            Button {
                store.setArchived(project.id, archived: true)
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
        }
        Divider()
        Button(role: .destructive) {
            pendingDelete = project
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private var archivedHeader: some View {
        Button { withAnimation(.easeInOut(duration: 0.2)) { showArchived.toggle() } } label: {
            HStack(spacing: 8) {
                Image(systemName: showArchived ? "chevron.down" : "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                Text("Archived")
                    .font(AppTypography.captionSemibold)
                Text("\(store.archivedProjects.count)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
                Spacer()
            }
            .foregroundStyle(AppColors.textSecondary)
            .padding(.horizontal, 4)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(AppColors.accent.opacity(0.55))
            Text("No projects yet")
                .font(AppTypography.title)
                .foregroundStyle(AppColors.textPrimary)
            Text("Projects collect related tasks into a kanban\nboard you can drag around.")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                editorPresentation = .create
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("New Project")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule(style: .continuous).fill(AppColors.accent))
            }
            .buttonStyle(.plain)
            .padding(.top, AppSpacing.sm)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppSpacing.xl)
    }
}

private struct ProjectListRow: View {
    let project: Project
    let taskCount: Int
    let dimmed: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(project.accentColor.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: project.iconSymbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(project.accentColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(AppTypography.bodySemibold)
                    .foregroundStyle(AppColors.textPrimary)
                Text(taskCount == 1 ? "1 task" : "\(taskCount) tasks")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            if !dimmed {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .fill(AppColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .stroke(AppColors.border.opacity(0.6), lineWidth: 1)
        )
        .opacity(dimmed ? 0.55 : 1)
    }
}
