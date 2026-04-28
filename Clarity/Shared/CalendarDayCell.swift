//
//  CalendarDayCell.swift
//  Clarity
//
//  A single day in the full-page calendar grid. Shows the day number plus
//  a few task chips. The parent caps how many chips can show via
//  `maxVisibleChips`, so quiet weeks render small and busy weeks stay legible.
//

import SwiftUI

struct CalendarDayCell: View {
    let date: Date
    let tasks: [PlanTask]
    let isInCurrentMonth: Bool
    let isSelected: Bool
    let isToday: Bool
    var maxVisibleChips: Int = 3

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
                .stroke(isSelected ? AppColors.accent : AppColors.border.opacity(0.6),
                        lineWidth: isSelected ? 1.5 : 0.5)
        )
        .opacity(isInCurrentMonth ? 1.0 : 0.4)
        .contentShape(Rectangle())
    }

    // MARK: - Pieces

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

    @ViewBuilder
    private var chipsStack: some View {
        if maxVisibleChips > 0 {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(tasks.prefix(maxVisibleChips)) { task in
                    chip(for: task)
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
    }

    private var cellBackground: Color {
        if isSelected { return AppColors.accentSoft.opacity(0.35) }
        return AppColors.surface
    }
}
