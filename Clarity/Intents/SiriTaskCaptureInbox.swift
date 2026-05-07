//
//  SiriTaskCaptureInbox.swift
//  Clarity
//

import Foundation

enum SiriTaskCaptureInbox {
    private static let suiteName = "group.com.gill.Clarity"
    private static let pendingKey = "pendingSiriTaskCaptures"

    static func drainPendingTasks() -> [PlanTask] {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: pendingKey)
        else { return [] }

        let records = (try? JSONDecoder().decode([PendingTask].self, from: data)) ?? []
        defaults.removeObject(forKey: pendingKey)
        defaults.synchronize()

        return records.map { record in
            PlanTask(
                id: record.id,
                title: record.title,
                category: TaskCategory(rawValue: record.categoryRaw) ?? .personal,
                priority: TaskPriority(rawValue: record.priorityRaw) ?? .medium,
                startTime: record.startTime,
                hasTime: record.hasTime,
                durationMinutes: record.durationMinutes,
                notes: record.notes,
                isCompleted: record.isCompleted,
                boardStatus: TaskBoardStatus(rawValue: record.boardStatusRaw) ?? .upcoming,
                manualOrder: record.manualOrder
            )
        }
    }

    private struct PendingTask: Codable {
        var id: UUID
        var title: String
        var categoryRaw: String
        var priorityRaw: String
        var startTime: Date
        var hasTime: Bool
        var durationMinutes: Int
        var notes: String?
        var isCompleted: Bool
        var boardStatusRaw: String
        var manualOrder: Int
    }
}
