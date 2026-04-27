//
//  TaskRecord.swift
//  Clarity
//
//  SwiftData persistence model for a planned task.
//  The UI continues to consume the immutable `PlanTask` value type;
//  records bridge into it via `toDomain()`.
//

import Foundation
import SwiftData

@Model
final class TaskRecord {
    var id: UUID
    var title: String
    var categoryRaw: String
    var priorityRaw: String
    var sectionRaw: String
    var startTime: Date
    var durationMinutes: Int
    var notes: String?
    var isCompleted: Bool

    @Relationship(deleteRule: .cascade)
    var subtasks: [SubtaskRecord]

    init(
        id: UUID = UUID(),
        title: String,
        category: TaskCategory,
        priority: TaskPriority,
        section: DaySectionKind,
        startTime: Date,
        durationMinutes: Int,
        notes: String? = nil,
        isCompleted: Bool = false,
        subtasks: [SubtaskRecord] = []
    ) {
        self.id = id
        self.title = title
        self.categoryRaw = category.rawValue
        self.priorityRaw = priority.rawValue
        self.sectionRaw = section.rawValue
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.isCompleted = isCompleted
        self.subtasks = subtasks
    }

    var category: TaskCategory { TaskCategory(rawValue: categoryRaw) ?? .work }
    var priority: TaskPriority { TaskPriority(rawValue: priorityRaw) ?? .medium }
    var section: DaySectionKind { DaySectionKind(rawValue: sectionRaw) ?? .getThingsDone }

    func toDomain() -> PlanTask {
        let subs = subtasks
            .sorted { $0.sortIndex < $1.sortIndex }
            .map { Subtask(id: $0.id, title: $0.title, isCompleted: $0.isCompleted) }
        return PlanTask(
            id: id,
            title: title,
            category: category,
            priority: priority,
            section: section,
            startTime: startTime,
            durationMinutes: durationMinutes,
            notes: notes,
            subtasks: subs,
            isCompleted: isCompleted
        )
    }
}
