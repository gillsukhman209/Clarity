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
    var startTime: Date
    /// `false` means the user didn't specify a time — the task floats and
    /// renders without a time label.
    var hasTime: Bool
    /// `0` means no duration — task is open-ended. UI hides the duration label
    /// in that case and computed `endTime` collapses to `startTime`.
    var durationMinutes: Int
    var notes: String?
    var subtasks: [Subtask]
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        title: String,
        category: TaskCategory,
        priority: TaskPriority = .medium,
        startTime: Date,
        hasTime: Bool = true,
        durationMinutes: Int = 0,
        notes: String? = nil,
        subtasks: [Subtask] = [],
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.priority = priority
        self.startTime = startTime
        self.hasTime = hasTime
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.subtasks = subtasks
        self.isCompleted = isCompleted
    }

    var hasDuration: Bool { durationMinutes > 0 }

    var endTime: Date {
        startTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }

    /// `nil` when the task has no duration set.
    var durationLabel: String? {
        guard hasDuration else { return nil }
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
        let start = formatter.string(from: startTime)
        guard hasDuration else { return start }
        return "\(start) – \(formatter.string(from: endTime))"
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
