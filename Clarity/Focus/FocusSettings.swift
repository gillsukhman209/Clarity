//
//  FocusSettings.swift
//  Clarity
//
//  User-editable Pomodoro / Deep Work durations, persisted via UserDefaults.
//  ContentView creates one and hands it to FocusEngine; the engine reads
//  the active mode's durations on every tick, so saved edits take effect
//  the next time a phase starts.
//

import Foundation
import Observation

@Observable
@MainActor
final class FocusSettings {
    var pomodoro: FocusDurations = .pomodoro {
        didSet { save() }
    }
    var deepWork: FocusDurations = .deepWork {
        didSet { save() }
    }

    private let pomodoroKey = "focusSettings.pomodoro.v1"
    private let deepWorkKey = "focusSettings.deepWork.v1"

    init() { load() }

    func durations(for mode: FocusMode) -> FocusDurations {
        switch mode {
        case .pomodoro: return pomodoro
        case .deepWork: return deepWork
        }
    }

    func update(_ d: FocusDurations, for mode: FocusMode) {
        switch mode {
        case .pomodoro: pomodoro = d
        case .deepWork: deepWork = d
        }
    }

    func resetToDefaults(for mode: FocusMode) {
        update(.defaults(for: mode), for: mode)
    }

    // MARK: - Persistence

    private func load() {
        let ud = UserDefaults.standard
        if let data = ud.data(forKey: pomodoroKey),
           let decoded = try? JSONDecoder().decode(FocusDurations.self, from: data) {
            pomodoro = decoded
        }
        if let data = ud.data(forKey: deepWorkKey),
           let decoded = try? JSONDecoder().decode(FocusDurations.self, from: data) {
            deepWork = decoded
        }
    }

    private func save() {
        let ud = UserDefaults.standard
        if let p = try? JSONEncoder().encode(pomodoro) { ud.set(p, forKey: pomodoroKey) }
        if let d = try? JSONEncoder().encode(deepWork) { ud.set(d, forKey: deepWorkKey) }
    }
}
