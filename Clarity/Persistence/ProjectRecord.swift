//
//  ProjectRecord.swift
//  Clarity
//
//  SwiftData persistence for a Project. CloudKit-friendly: every property has
//  a default, and the to-many `tasks` relationship pairs with TaskRecord.project.
//

import Foundation
import SwiftData

@Model
final class ProjectRecord {
    var id: UUID = UUID()
    var name: String = "New Project"
    var iconSymbol: String = "folder.fill"
    var colorHex: String = "8B7CF6"
    var notes: String? = nil
    var isArchived: Bool = false
    var sortIndex: Int = 0
    var createdAt: Date = Date()

    /// Deleting a project deletes its tasks. Archive instead if you want to keep them.
    @Relationship(deleteRule: .cascade, inverse: \TaskRecord.project)
    var tasks: [TaskRecord]? = []

    init(
        id: UUID = UUID(),
        name: String = "New Project",
        iconSymbol: String = "folder.fill",
        colorHex: String = "8B7CF6",
        notes: String? = nil,
        isArchived: Bool = false,
        sortIndex: Int = 0,
        createdAt: Date = Date(),
        tasks: [TaskRecord] = []
    ) {
        self.id = id
        self.name = name
        self.iconSymbol = iconSymbol
        self.colorHex = colorHex
        self.notes = notes
        self.isArchived = isArchived
        self.sortIndex = sortIndex
        self.createdAt = createdAt
        self.tasks = tasks
    }

    func toDomain() -> Project {
        Project(
            id: id,
            name: name,
            iconSymbol: iconSymbol,
            colorHex: colorHex,
            notes: notes,
            isArchived: isArchived,
            sortIndex: sortIndex,
            createdAt: createdAt
        )
    }
}
