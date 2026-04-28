//
//  PlanTask.swift
//  Clarity
//
//  Renamed from `Task` to avoid colliding with Swift Concurrency's `Task`.
//

import Foundation

struct PlanTask: Identifiable, Hashable {
    let id: UUID
    var title: String
    var category: TaskCategory
    var priority: TaskPriority
    var section: DaySectionKind
    var startTime: Date
    /// `false` means the user didn't specify a time — the task floats and
    /// renders without a time label.
    var hasTime: Bool
    var durationMinutes: Int
    var notes: String?
    var subtasks: [Subtask]
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        title: String,
        category: TaskCategory,
        priority: TaskPriority = .medium,
        section: DaySectionKind,
        startTime: Date,
        hasTime: Bool = true,
        durationMinutes: Int,
        notes: String? = nil,
        subtasks: [Subtask] = [],
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.priority = priority
        self.section = section
        self.startTime = startTime
        self.hasTime = hasTime
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.subtasks = subtasks
        self.isCompleted = isCompleted
    }

    var endTime: Date {
        startTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }

    var durationLabel: String {
        if durationMinutes < 60 {
            return "\(durationMinutes)m"
        }
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
    }

    var startTimeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter.string(from: startTime)
    }

    /// `nil` for timeless tasks; otherwise the formatted "h:mm a" label.
    var timeLabel: String? {
        hasTime ? startTimeLabel : nil
    }

    var timeRangeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startTime)) – \(formatter.string(from: endTime))"
    }
}

struct Subtask: Identifiable, Hashable {
    let id: UUID
    var title: String
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}
