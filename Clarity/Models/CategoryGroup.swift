//
//  CategoryGroup.swift
//  Clarity
//
//  A bucket of tasks grouped by category. Replaces the old DaySection
//  abstraction so the grouped view in DayPlanView / DashboardView shows
//  Work / Health / Personal / etc. instead of Focus Time / Get Things Done.
//

import SwiftUI

struct CategoryGroup: Identifiable, Hashable {
    let id: UUID
    var category: TaskCategory
    var tasks: [PlanTask]

    init(id: UUID = UUID(), category: TaskCategory, tasks: [PlanTask]) {
        self.id = id
        self.category = category
        self.tasks = tasks
    }

    var title: String { category.title }
    var sfSymbol: String { category.sfSymbol }
    var accentColor: Color { category.inkColor }
    var fillColor: Color { category.fillColor }

    /// `nil` when none of the tasks in this group have a duration set.
    var totalDurationLabel: String? {
        let total = tasks.reduce(0) { $0 + $1.durationMinutes }
        guard total > 0 else { return nil }
        if total < 60 { return "\(total)m" }
        let h = total / 60
        let m = total % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}
