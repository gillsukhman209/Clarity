//
//  CalendarDayCell.swift
//  Clarity
//
//  A single day in the full-page calendar grid. Day number + task chips.
//  Chips are draggable, the whole cell is a drop target — so you can drag
//  any task from one day to another and it lands on the new day at the
//  same time-of-day.
//

import SwiftUI

struct CalendarDayCell: View {
    let date: Date
    let tasks: [PlanTask]
    let isInCurrentMonth: Bool
    let isSelected: Bool
    let isToday: Bool
    var maxVisibleChips: Int = 3
    var onDropTask: (UUID) -> Void = { _ in }

    @State private var isDropTarget: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            dayNumberRow
            chipsStack
            Spacer(minLength: 0)
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                .fill(cellBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .opacity(isInCurrentMonth ? 1.0 : 0.4)
        .scaleEffect(isDropTarget ? 1.03 : 1.0)
        .contentShape(Rectangle())
        .dropDestination(for: DraggedTask.self) { items, _ in
            guard let first = items.first else { return false }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                onDropTask(first.taskID)
            }
            return true
        } isTargeted: { hovering in
            withAnimation(.easeOut(duration: 0.14)) {
                isDropTarget = hovering
            }
        }
        .animation(.easeOut(duration: 0.14), value: isSelected)
    }

    // MARK: - Visual state

    private var cellBackground: Color {
        if isDropTarget { return AppColors.accentSoft.opacity(0.45) }
        if isSelected   { return AppColors.accentSoft.opacity(0.35) }
        return AppColors.surface
    }

    private var borderColor: Color {
        if isDropTarget { return AppColors.accent }
        if isSelected   { return AppColors.accent }
        return AppColors.border.opacity(0.6)
    }

    private var borderWidth: CGFloat {
        if isDropTarget { return 2 }
        if isSelected   { return 1.5 }
        return 0.5
    }

    // MARK: - Day number

    private var dayNumberRow: some View {
        HStack(spacing: 4) {
            ZStack {
                if isToday {
                    Circle()
                        .fill(AppColors.accent)
                        .frame(width: 22, height: 22)
                }
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 13, weight: isToday ? .bold : .semibold, design: .rounded))
                    .foregroundStyle(isToday ? Color.white : AppColors.textPrimary)
            }
            Spacer()
            if maxVisibleChips > 0, tasks.count > maxVisibleChips {
                Text("+\(tasks.count - maxVisibleChips)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }

    // MARK: - Chips

    @ViewBuilder
    private var chipsStack: some View {
        if maxVisibleChips > 0 {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(tasks.prefix(maxVisibleChips)) { task in
                    chip(for: task)
                        .draggable(DraggedTask(taskID: task.id)) {
                            // Lifted preview while dragging.
                            chip(for: task)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(AppColors.surface)
                                )
                                .shadow(color: Color.black.opacity(0.22), radius: 8, y: 4)
                        }
                }
            }
        }
    }

    private func chip(for task: PlanTask) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(task.category.inkColor)
                .frame(width: 3, height: 12)
            Text(task.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)
                .strikethrough(task.isCompleted, color: AppColors.textTertiary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(task.category.fillColor.opacity(0.7))
        )
        .contentShape(Rectangle())
    }
}
