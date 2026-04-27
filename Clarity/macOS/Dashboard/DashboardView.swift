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
    @State private var showQuickAdd: Bool = false

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
                taskList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.background)
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
        return f.string(from: Date())
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
        List {
            ForEach(store.daySections) { section in
                Section {
                    ForEach(section.tasks) { task in
                        taskRow(task)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 2, leading: AppSpacing.xl, bottom: 2, trailing: AppSpacing.xl))
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    store.toggleComplete(task.id)
                                } label: {
                                    Label(task.isCompleted ? "Undo" : "Complete",
                                          systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                                }
                                .tint(AppColors.Priority.lowInk)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if selectedTaskID == task.id { selectedTaskID = nil }
                                    store.delete(task.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
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
                } header: {
                    DaySectionHeader(section: section)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.top, AppSpacing.md)
                        .padding(.bottom, 4)
                        .listRowInsets(EdgeInsets())
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.bottom, AppSpacing.xl)
    }

    private func taskRow(_ task: PlanTask) -> some View {
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
#endif
