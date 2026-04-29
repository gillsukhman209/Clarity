//
//  FocusSessionRecord.swift
//  Clarity
//
//  SwiftData persistence for completed focus sessions. CloudKit-friendly:
//  every property has a default. We only persist FOCUS phases — breaks are
//  derived from the mode and not logged individually.
//

import Foundation
import SwiftData

@Model
final class FocusSessionRecord {
    var id: UUID = UUID()
    var taskID: UUID? = nil
    var taskTitle: String? = nil
    var modeRaw: String = "pomodoro"
    var startedAt: Date = Date()
    var completedAt: Date? = nil
    var focusMinutes: Int = 0

    init(
        id: UUID = UUID(),
        taskID: UUID? = nil,
        taskTitle: String? = nil,
        mode: FocusMode = .pomodoro,
        startedAt: Date = Date(),
        completedAt: Date? = nil,
        focusMinutes: Int = 0
    ) {
        self.id = id
        self.taskID = taskID
        self.taskTitle = taskTitle
        self.modeRaw = mode.rawValue
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.focusMinutes = focusMinutes
    }

    var mode: FocusMode { FocusMode(rawValue: modeRaw) ?? .pomodoro }

    func toDomain() -> FocusSession {
        FocusSession(
            id: id,
            taskID: taskID,
            taskTitle: taskTitle,
            mode: mode,
            startedAt: startedAt,
            completedAt: completedAt,
            focusMinutes: focusMinutes
        )
    }
}
