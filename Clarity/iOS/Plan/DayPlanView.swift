//
//  DayPlanView.swift
//  Clarity
//
//  Phase 3 — iOS Today plan with time gutter, pastel task blocks, and floating mic.
//  Phase 6 — backed by `TaskStore` instead of `MockData`.
//

import SwiftUI

struct DayPlanView: View {
    var onOpenBrainDump: () -> Void = {}

    @Environment(TaskStore.self) private var store
    @State private var presentedTask: SelectedTask?
    @State private var showQuickAdd: Bool = false

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy"
        return f.string(from: Date())
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                topBar
                Divider().background(AppColors.divider)
                if store.tasks.isEmpty {
                    emptyState
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
            Button {} label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    Text("Today")
                        .font(AppTypography.titleSmall)
                        .foregroundStyle(AppColors.textPrimary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColors.textTertiary)
                }
                Text(dateLabel)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }

            Spacer()

            Button {} label: {
                Image(systemName: "calendar")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - Task list
    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.xs) {
                ForEach(Array(store.tasks.enumerated()), id: \.element.id) { index, task in
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
                        row(for: task, previous: index > 0 ? store.tasks[index - 1] : nil)
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
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, 140)
        }
    }

    @ViewBuilder
    private func row(for task: PlanTask, previous: PlanTask?) -> some View {
        let showHour = previous.map { hour(of: $0.startTime) != hour(of: task.startTime) } ?? true
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
