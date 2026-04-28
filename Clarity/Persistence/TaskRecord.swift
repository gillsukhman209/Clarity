//
//  TaskRecord.swift
//  Clarity
//
//  SwiftData persistence model for a planned task.
//  Phase 9 — every stored property has a default value so the schema is
//  CloudKit-compatible (CloudKit needs to construct records without args).
//

import Foundation
import SwiftData

@Model
final class TaskRecord {
    var id: UUID = UUID()
    var title: String = ""
    var categoryRaw: String = "work"
    var priorityRaw: String = "medium"
    var startTime: Date = Date()
    /// Default `true` keeps every existing record meaningful after the schema migration.
    var hasTime: Bool = true
    /// `0` means no specific duration — the task is open-ended.
    var durationMinutes: Int = 0
    var notes: String? = nil
    var isCompleted: Bool = false
    /// Kanban column on a project board. Always `done` if the task is completed.
    var boardStatusRaw: String = "upcoming"

    @Relationship(deleteRule: .cascade, inverse: \SubtaskRecord.task)
    var subtasks: [SubtaskRecord]? = []

    /// Optional parent project. The inverse lives on `ProjectRecord.tasks`.
    var project: ProjectRecord? = nil

    init(
        id: UUID = UUID(),
        title: String = "",
        category: TaskCategory = .work,
        priority: TaskPriority = .medium,
        startTime: Date = Date(),
        hasTime: Bool = true,
        durationMinutes: Int = 0,
        notes: String? = nil,
        isCompleted: Bool = false,
        boardStatus: TaskBoardStatus = .upcoming,
        subtasks: [SubtaskRecord] = [],
        project: ProjectRecord? = nil
    ) {
        self.id = id
        self.title = title
        self.categoryRaw = category.rawValue
        self.priorityRaw = priority.rawValue
        self.startTime = startTime
        self.hasTime = hasTime
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.isCompleted = isCompleted
        self.boardStatusRaw = (isCompleted ? TaskBoardStatus.done : boardStatus).rawValue
        self.subtasks = subtasks
        self.project = project
    }

    var category: TaskCategory { TaskCategory(rawValue: categoryRaw) ?? .work }
    var priority: TaskPriority { TaskPriority(rawValue: priorityRaw) ?? .medium }
    var boardStatus: TaskBoardStatus { TaskBoardStatus(rawValue: boardStatusRaw) ?? .upcoming }

    func toDomain() -> PlanTask {
        let subs = (subtasks ?? [])
            .sorted { $0.sortIndex < $1.sortIndex }
            .map { Subtask(id: $0.id, title: $0.title, isCompleted: $0.isCompleted) }
        return PlanTask(
            id: id,
            title: title,
            category: category,
            priority: priority,
            startTime: startTime,
            hasTime: hasTime,
            durationMinutes: durationMinutes,
            notes: notes,
            subtasks: subs,
            isCompleted: isCompleted,
            projectID: project?.id,
            boardStatus: boardStatus
        )
    }
}
