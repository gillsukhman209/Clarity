//
//  FocusSession.swift
//  Clarity
//
//  Domain types for a Pomodoro / Deep Work session. A session moves through
//  alternating Focus and Break phases; the active phase is what the cosmic
//  hero countdown reflects.
//

import SwiftUI

enum FocusPhase: String, CaseIterable, Identifiable, Hashable {
    case focus
    case shortBreak
    case longBreak
    case complete

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus:      return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak:  return "Long Break"
        case .complete:   return "Complete"
        }
    }

    /// All-caps eyebrow shown above the countdown.
    var eyebrow: String { title.uppercased() }

    /// Encouragement strapline shown under the phase label.
    var strapline: String {
        switch self {
        case .focus:      return "Stay in the zone. You've got this."
        case .shortBreak: return "Breathe. Stretch. Sip water."
        case .longBreak:  return "Take a real break. Step away."
        case .complete:   return "Session done. Nice work."
        }
    }

    var sfSymbol: String {
        switch self {
        case .focus:      return "globe"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak:  return "leaf.fill"
        case .complete:   return "flag.checkered"
        }
    }

    /// Default minute count for a given mode.
    func minutes(for mode: FocusMode) -> Int {
        switch self {
        case .focus:      return mode.focusMinutes
        case .shortBreak: return mode.shortBreakMinutes
        case .longBreak:  return mode.longBreakMinutes
        case .complete:   return 0
        }
    }

    /// The 4-step phase track shown across the bottom of the cosmic hero.
    /// Always: Focus → Short Break → Long Break → Complete.
    static var trackOrder: [FocusPhase] {
        [.focus, .shortBreak, .longBreak, .complete]
    }
}

/// A single completed (or in-progress) focus session — one focus block.
/// Breaks are not stored as separate rows; we just log focus time.
struct FocusSession: Identifiable, Hashable {
    let id: UUID
    /// Optional bound task. Focus minutes accrue on the task's record when set.
    var taskID: UUID?
    var taskTitle: String?
    var modeRaw: String
    var startedAt: Date
    var completedAt: Date?
    /// Actual focus minutes that landed (in case the user ended early).
    var focusMinutes: Int

    init(
        id: UUID = UUID(),
        taskID: UUID? = nil,
        taskTitle: String? = nil,
        mode: FocusMode,
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

    var startTimeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: startedAt)
    }

    var minutesLabel: String {
        focusMinutes > 0 ? "\(focusMinutes)m" : "—"
    }
}
