//
//  FocusDurations.swift
//  Clarity
//
//  The actual minute counts that drive a Pomodoro / Deep Work cycle. Lives
//  outside `FocusMode` so the user can override them per-mode and persist
//  the changes (see FocusSettings).
//

import Foundation

struct FocusDurations: Equatable, Hashable, Codable {
    var focusMinutes: Int
    var shortBreakMinutes: Int
    var longBreakMinutes: Int
    var cyclesBeforeLongBreak: Int

    static let pomodoro = FocusDurations(
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        cyclesBeforeLongBreak: 4
    )

    static let deepWork = FocusDurations(
        focusMinutes: 50,
        shortBreakMinutes: 10,
        longBreakMinutes: 20,
        cyclesBeforeLongBreak: 4
    )

    static func defaults(for mode: FocusMode) -> FocusDurations {
        switch mode {
        case .pomodoro: return .pomodoro
        case .deepWork: return .deepWork
        }
    }

    /// "25 min focus • 5 min break" for the Mode card subtitle.
    var subtitle: String {
        "\(focusMinutes) min focus • \(shortBreakMinutes) min break"
    }
}
