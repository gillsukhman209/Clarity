//
//  CalendarMonthView.swift
//  Clarity
//
//  A full-page month-grid calendar. Each cell is one day with task chips.
//  Tapping a cell sets the shared `currentDate` and calls `onDaySelected`,
//  which the parent uses to navigate back to the day plan view.
//

import SwiftUI

struct CalendarMonthView: View {
    @Binding var currentDate: Date
    var onDaySelected: () -> Void = {}

    @Environment(TaskStore.self) private var store
    @State private var monthAnchor: Date

    private let calendar = Calendar.current

    init(currentDate: Binding<Date>, onDaySelected: @escaping () -> Void = {}) {
        self._currentDate = currentDate
        self.onDaySelected = onDaySelected
        let normalized = Calendar.current.startOfDay(for: currentDate.wrappedValue)
        self._monthAnchor = State(initialValue: normalized)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.md)

            weekdayRow
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, 4)

            grid
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
        }
        .background(AppColors.background)
        .onChange(of: currentDate) { _, newValue in
            // If the user picks a date outside the visible month, follow them.
            if !calendar.isDate(newValue, equalTo: monthAnchor, toGranularity: .month) {
                monthAnchor = calendar.startOfDay(for: newValue)
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: AppSpacing.md) {
            Text(monthLabel)
                .font(AppTypography.displayMedium)
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            chevron("chevron.left")  { stepMonth(-1) }
            chevron("chevron.right") { stepMonth(1) }
        }
    }

    private func chevron(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 32, height: 32)
                .background(
                    Circle().fill(AppColors.surface)
                )
                .overlay(
                    Circle().stroke(AppColors.border, lineWidth: 1)
                )
        }
        .buttonStyle(PressableStyle(pressedScale: 0.94))
    }

    private var monthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: monthAnchor)
    }

    private func stepMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: monthAnchor) {
            monthAnchor = calendar.startOfDay(for: next)
        }
    }

    // MARK: - Weekdays
    private var weekdayRow: some View {
        HStack(spacing: 4) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(AppTypography.captionSemibold)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var weekdaySymbols: [String] {
        // Sunday-first to match the macOS popover style we already shipped.
        let f = DateFormatter()
        return ["S", "M", "T", "W", "T", "F", "S"].enumerated().map { _, s in s }
        // (Localized weekdays would be a Phase-14 i18n task; using initials for now.)
        _ = f
    }

    // MARK: - Grid
    /// Rows have variable heights AND variable per-cell widths. A busy day
    /// gets a fatter column (and surrounding empty days get shaved) so the
    /// task titles stay legible.
    private var grid: some View {
        let rows = rowsToShow()
        return GeometryReader { geo in
            VStack(spacing: 4) {
                ForEach(rows.indices, id: \.self) { rowIndex in
                    let row = rows[rowIndex]
                    let counts = row.map { store.tasks(on: $0).count }
                    let maxTasks = counts.max() ?? 0
                    let widths = columnWidths(counts: counts, totalWidth: geo.size.width)
                    HStack(spacing: 4) {
                        ForEach(Array(row.enumerated()), id: \.element) { index, date in
                            cell(for: date, maxVisibleChips: chipBudget(for: maxTasks))
                                .frame(width: widths[index])
                        }
                    }
                    .frame(height: rowHeight(for: maxTasks))
                }
            }
        }
        .frame(minHeight: gridMinHeight())
    }

    private func gridMinHeight() -> CGFloat {
        let rows = rowsToShow()
        let total = rows.reduce(0.0) { running, row in
            let maxTasks = row.map { store.tasks(on: $0).count }.max() ?? 0
            return running + Double(rowHeight(for: maxTasks))
        }
        return total + Double(max(0, rows.count - 1)) * 4
    }

    /// Distribute row width proportionally to per-cell weight.
    private func columnWidths(counts: [Int], totalWidth: CGFloat) -> [CGFloat] {
        let spacing: CGFloat = 4
        let interGap = spacing * CGFloat(max(0, counts.count - 1))
        let available = max(0, totalWidth - interGap)

        let weights = counts.map { weight(for: $0) }
        let totalWeight = weights.reduce(0, +)
        guard totalWeight > 0 else {
            let equal = available / CGFloat(counts.count)
            return Array(repeating: equal, count: counts.count)
        }
        return weights.map { available * CGFloat($0 / totalWeight) }
    }

    /// Empty days shrink to ~60% of an "average" cell; busy days swell.
    private func weight(for count: Int) -> Double {
        switch count {
        case 0:  return 0.6
        case 1:  return 1.1
        case 2:  return 1.5
        case 3:  return 1.9
        default: return 2.3
        }
    }

    private func rowHeight(for maxTasks: Int) -> CGFloat {
        switch maxTasks {
        case 0:  return 56
        case 1:  return 88
        case 2:  return 110
        default: return 134
        }
    }

    private func chipBudget(for maxTasks: Int) -> Int {
        switch maxTasks {
        case 0:  return 0
        case 1:  return 1
        case 2:  return 2
        default: return 4
        }
    }

    private func cell(for date: Date, maxVisibleChips: Int) -> some View {
        let inMonth = calendar.isDate(date, equalTo: monthAnchor, toGranularity: .month)
        let isSelected = calendar.isDate(date, inSameDayAs: currentDate)
        let isToday = calendar.isDateInToday(date)
        return CalendarDayCell(
            date: date,
            tasks: store.tasks(on: date),
            isInCurrentMonth: inMonth,
            isSelected: isSelected,
            isToday: isToday,
            maxVisibleChips: maxVisibleChips
        )
        .onTapGesture {
            currentDate = calendar.startOfDay(for: date)
            if !inMonth {
                monthAnchor = calendar.startOfDay(for: date)
            }
            onDaySelected()
        }
    }

    private func rowsToShow() -> [[Date]] {
        var rows: [[Date]] = []
        var current: [Date] = []
        for day in daysToShow() {
            current.append(day)
            if current.count == 7 {
                rows.append(current)
                current = []
            }
        }
        if !current.isEmpty { rows.append(current) }
        return rows
    }

    private func daysToShow() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthAnchor)
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: monthInterval.start) // 1 = Sunday
        let leadingCount = firstWeekday - 1

        var days: [Date] = []
        for offset in stride(from: leadingCount, through: 1, by: -1) {
            if let d = calendar.date(byAdding: .day, value: -offset, to: monthInterval.start) {
                days.append(d)
            }
        }
        var current = monthInterval.start
        while current < monthInterval.end {
            days.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        while days.count < 42, let last = days.last,
              let next = calendar.date(byAdding: .day, value: 1, to: last) {
            days.append(next)
        }
        return days
    }
}
