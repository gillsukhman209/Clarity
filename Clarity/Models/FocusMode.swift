//
//  FocusMode.swift
//  Clarity
//
//  Pomodoro and Deep Work presets. Each mode supplies a set of phases with
//  durations; the FocusEngine walks through them in order.
//

import Foundation

enum FocusMode: String, CaseIterable, Identifiable, Hashable {
    case pomodoro
    case deepWork

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pomodoro: return "Pomodoro"
        case .deepWork: return "Deep Work"
        }
    }

    /// Subtitle shown in the right-hand "MODE" picker.
    var subtitle: String {
        let f = focusMinutes
        let b = shortBreakMinutes
        return "\(f) min focus • \(b) min break"
    }

    var focusMinutes: Int {
        switch self {
        case .pomodoro: return 25
        case .deepWork: return 50
        }
    }

    var shortBreakMinutes: Int {
        switch self {
        case .pomodoro: return 5
        case .deepWork: return 10
        }
    }

    var longBreakMinutes: Int {
        switch self {
        case .pomodoro: return 15
        case .deepWork: return 20
        }
    }

    /// How many focus phases before a long break.
    var cyclesBeforeLongBreak: Int { 4 }

    /// Visual symbol used in the phase timeline / right-panel mode card.
    var sfSymbol: String {
        switch self {
        case .pomodoro: return "circle.lefthalf.filled"
        case .deepWork: return "circle.fill"
        }
    }
}
