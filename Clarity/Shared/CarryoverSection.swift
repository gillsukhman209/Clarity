//
//  CarryoverSection.swift
//  Clarity
//
//  "Left from yesterday" — surfaces incomplete tasks from the past 14 days
//  on Today so they don't get buried on their original date. Non-destructive:
//  rendering only. Per-row actions (move to today / mark done / delete)
//  flow through the same TaskStore mutations the rest of the app uses.
//

import SwiftUI

struct CarryoverSection: View {
    let tasks: [PlanTask]
    var onTapTask: (UUID) -> Void
    var onMoveToToday: (UUID) -> Void
    var onComplete: (UUID) -> Void
    var onDelete: (UUID) -> Void

    @State private var expanded: Bool = true

    var body: some View {
        if tasks.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 6) {
                header
                if expanded {
                    VStack(spacing: AppSpacing.xs) {
                        ForEach(tasks) { task in
                            row(for: task)
                                .transition(.asymmetric(
                                    insertion: .opacity,
                                    removal: .opacity.combined(with: .scale(scale: 0.97))
                                ))
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                    .fill(AppColors.Priority.mediumFill.opacity(0.45))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                    .stroke(AppColors.Priority.mediumInk.opacity(0.25), lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.22), value: expanded)
        }
    }

    // MARK: - Header

    private var header: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) { expanded.toggle() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColors.Priority.mediumInk)
                Text(headerTitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                Text("\(tasks.count)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.Priority.mediumInk)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(AppColors.Priority.mediumInk.opacity(0.15)))
                Spacer()
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(expanded ? "Hide carried-over tasks" : "Show carried-over tasks")
    }

    private var headerTitle: String {
        let cal = Calendar.current
        let allYesterday = tasks.allSatisfy { cal.isDateInYesterday($0.startTime) }
        return allYesterday ? "Left from yesterday" : "Carried over"
    }

    // MARK: - Row
    /// Mirrors the time-column + TaskBlock layout used by the regular Today
    /// list so heights line up. The relative-day label sits where the time
    /// would normally be.

    private func row(for task: PlanTask) -> some View {
        // Swipes mirror the regular task list (leading = Done, trailing =
        // Delete) so muscle memory works. Move-to-today lives in the context
        // menu only.
        SwipeableRow(
            onTap: { onTapTask(task.id) },
            leadingAction: SwipeAction(
                symbol: "checkmark",
                title: "Done",
                color: AppColors.Priority.lowInk,
                action: { onComplete(task.id) }
            ),
            trailingAction: SwipeAction(
                symbol: "trash",
                title: "Delete",
                color: AppColors.Priority.highInk,
                isDestructive: true,
                action: { onDelete(task.id) }
            )
        ) {
            HStack(spacing: AppSpacing.sm) {
                Text(relativeDayLabel(for: task.startTime))
                    .font(AppTypography.captionMedium)
                    .foregroundStyle(AppColors.Priority.mediumInk)
                    .lineLimit(1)
                    .frame(width: 72, alignment: .leading)
                TaskBlock(task: task)
            }
            .background(AppColors.background.opacity(0.0001))
        }
        .contextMenu { menuItems(for: task) }
    }

    @ViewBuilder
    private func menuItems(for task: PlanTask) -> some View {
        Button {
            onMoveToToday(task.id)
        } label: {
            Label("Move to today", systemImage: "arrow.turn.down.right")
        }
        Button {
            onComplete(task.id)
        } label: {
            Label("Mark complete", systemImage: "checkmark.circle")
        }
        Divider()
        Button(role: .destructive) {
            onDelete(task.id)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Relative date

    private func relativeDayLabel(for date: Date) -> String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let then = cal.startOfDay(for: date)
        let days = cal.dateComponents([.day], from: then, to: today).day ?? 0
        switch days {
        case 1:  return "yesterday"
        case 0:  return "today"
        default: return "\(days) days ago"
        }
    }
}
