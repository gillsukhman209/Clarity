//
//  FocusEngine.swift
//  Clarity
//
//  The runtime brain of the Pomodoro / Deep Work tab.
//
//  Tracks the active session (if any), the current phase (focus / short
//  break / long break / complete), how many focus cycles have been
//  completed, and the per-second remaining time. Pause and resume work by
//  recording a `pausedAt` timestamp so the elapsed countdown reads correctly
//  even after the app is backgrounded.
//
//  The view layer reads `remainingSeconds`, `progress`, `phase`, and
//  `cyclesCompleted` to drive the cosmic hero, the phase track, and the
//  right-hand sessions list.
//

import Foundation
import Observation

@Observable
@MainActor
final class FocusEngine {

    // MARK: - Mode + active session

    /// User's currently selected mode. Persisted via @AppStorage on the view.
    var mode: FocusMode = .pomodoro {
        didSet { if !isRunning { resetForCurrentMode() } }
    }

    /// Settings holder injected by ContentView. The engine reads the active
    /// mode's `FocusDurations` from here on every tick so saved edits take
    /// effect on the next phase.
    @ObservationIgnored var settings: FocusSettings? = nil

    /// Resolved durations for the current mode. Falls back to the built-in
    /// defaults if settings haven't been wired yet (e.g. previews).
    var currentDurations: FocusDurations {
        settings?.durations(for: mode) ?? .defaults(for: mode)
    }

    /// Optional task we're focusing on. The view sets this from a task picker.
    var boundTaskID: UUID? = nil
    var boundTaskTitle: String? = nil

    /// `nil` until the user taps Start. Set on `start(...)`.
    private(set) var sessionStartedAt: Date? = nil
    /// Set when paused; nil while actively running.
    private(set) var pausedAt: Date? = nil
    /// Cumulative seconds the current phase has been paused for.
    private var accumulatedPause: TimeInterval = 0
    /// When the current phase started — used to compute remaining time.
    private var phaseStartedAt: Date? = nil

    /// Which kanban-style track step the user is in.
    private(set) var phase: FocusPhase = .focus
    private(set) var cyclesCompleted: Int = 0   // focus phases finished this session

    /// Today's logged focus sessions. ContentView seeds this on launch from
    /// the store's persisted records, and the engine appends to it whenever
    /// a focus phase completes.
    var todaysSessions: [FocusSession] = []

    /// Hook invoked when a focus phase completes (auto or via `endSession`
    /// while in focus). The view layer wires this to TaskStore so each
    /// completed focus block lands in the SwiftData store.
    @ObservationIgnored var onSessionComplete: ((FocusSession) -> Void)? = nil

    /// Daily focus goal in minutes (used for the right-panel progress ring).
    var dailyGoalMinutes: Int = 360  // 6h default

    // MARK: - Derived state

    var isRunning: Bool { sessionStartedAt != nil && pausedAt == nil }
    var isPaused: Bool { pausedAt != nil }
    var hasActiveSession: Bool { sessionStartedAt != nil }

    /// Total seconds the current phase is supposed to last, derived from
    /// the user-customizable `FocusDurations`.
    var phaseTotalSeconds: Int {
        let d = currentDurations
        switch phase {
        case .focus:      return d.focusMinutes * 60
        case .shortBreak: return d.shortBreakMinutes * 60
        case .longBreak:  return d.longBreakMinutes * 60
        case .complete:   return 0
        }
    }

    /// How many seconds are left on the current phase, computed from now.
    /// Returns `phaseTotalSeconds` before the phase has started.
    func remainingSeconds(at now: Date = Date()) -> Int {
        guard let phaseStartedAt else { return phaseTotalSeconds }
        let elapsed = now.timeIntervalSince(phaseStartedAt) - accumulatedPause
            - (pausedAt.map { now.timeIntervalSince($0) } ?? 0)
        let remaining = Double(phaseTotalSeconds) - elapsed
        return max(0, Int(remaining.rounded(.down)))
    }

    /// 0…1 progress through the current phase.
    func progress(at now: Date = Date()) -> Double {
        let total = phaseTotalSeconds
        guard total > 0 else { return 0 }
        let remaining = remainingSeconds(at: now)
        return min(1, max(0, 1 - Double(remaining) / Double(total)))
    }

    /// Today's focused minutes (sum of all stored focus sessions).
    var todaysFocusMinutes: Int {
        todaysSessions.reduce(0) { $0 + $1.focusMinutes }
    }

    /// "M:SS" or "MM:SS" countdown label for the cosmic hero.
    func countdownLabel(at now: Date = Date()) -> String {
        let secs = remainingSeconds(at: now)
        let m = secs / 60
        let s = secs % 60
        return String(format: "%02d:%02d", m, s)
    }

    // MARK: - Lifecycle

    /// Start a brand-new session in the current mode. Begins on Focus phase.
    func start(taskID: UUID? = nil, taskTitle: String? = nil) {
        sessionStartedAt = Date()
        pausedAt = nil
        accumulatedPause = 0
        boundTaskID = taskID
        boundTaskTitle = taskTitle
        phase = .focus
        cyclesCompleted = 0
        phaseStartedAt = Date()
    }

    /// Toggle the run/pause state. No-op if no active session.
    func togglePause() {
        guard sessionStartedAt != nil else { return }
        if let pausedAt {
            accumulatedPause += Date().timeIntervalSince(pausedAt)
            self.pausedAt = nil
        } else {
            pausedAt = Date()
        }
    }

    /// Hard end — clears state and goes back to idle. If we're mid-focus,
    /// log the minutes accrued so partial work isn't lost.
    func endSession() {
        if phase == .focus, let started = phaseStartedAt {
            let now = Date()
            let elapsed = now.timeIntervalSince(started) - accumulatedPause
                - (pausedAt.map { now.timeIntervalSince($0) } ?? 0)
            let mins = Int((elapsed / 60).rounded(.down))
            if mins > 0 { logFocusSession(focusMinutes: mins, completedAt: now) }
        }
        sessionStartedAt = nil
        pausedAt = nil
        accumulatedPause = 0
        phaseStartedAt = nil
        phase = .focus
        cyclesCompleted = 0
        boundTaskID = nil
        boundTaskTitle = nil
    }

    /// Pulse called every second by the view's TimelineView. Detects when
    /// the active phase has run out and auto-advances. Logs a session when
    /// a focus phase completes.
    func tick(at now: Date = Date()) {
        guard hasActiveSession, !isPaused else { return }
        guard phase != .complete else { return }
        guard remainingSeconds(at: now) <= 0 else { return }

        if phase == .focus {
            logFocusSession(focusMinutes: currentDurations.focusMinutes, completedAt: now)
        }
        advancePhase()
    }

    private func logFocusSession(focusMinutes: Int, completedAt: Date) {
        let session = FocusSession(
            taskID: boundTaskID,
            taskTitle: boundTaskTitle,
            mode: mode,
            startedAt: phaseStartedAt ?? completedAt.addingTimeInterval(-Double(focusMinutes * 60)),
            completedAt: completedAt,
            focusMinutes: focusMinutes
        )
        todaysSessions.append(session)
        onSessionComplete?(session)
    }

    /// Advance to the next phase. Caller invokes this when the countdown
    /// hits zero. Sequence: Focus → Short Break → Focus → … every 4th focus
    /// goes to Long Break → Focus, etc. After cyclesBeforeLongBreak full
    /// cycles, lands on `.complete` and stops.
    func advancePhase() {
        switch phase {
        case .focus:
            cyclesCompleted += 1
            if cyclesCompleted >= currentDurations.cyclesBeforeLongBreak {
                phase = .complete
                phaseStartedAt = nil
            } else if cyclesCompleted % 2 == 0 {
                phase = .longBreak
                phaseStartedAt = Date()
            } else {
                phase = .shortBreak
                phaseStartedAt = Date()
            }
        case .shortBreak, .longBreak:
            phase = .focus
            phaseStartedAt = Date()
        case .complete:
            break
        }
        accumulatedPause = 0
        pausedAt = nil
    }

    /// Reset transient state when the user changes modes while idle.
    private func resetForCurrentMode() {
        phase = .focus
        cyclesCompleted = 0
        phaseStartedAt = nil
        accumulatedPause = 0
        pausedAt = nil
    }
}
