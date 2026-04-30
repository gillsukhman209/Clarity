//
//  FocusPhaseNotifier.swift
//  Clarity
//
//  Schedules a single local notification for the current phase's end. When
//  the engine starts, advances, pauses, resumes, or ends, the notifier is
//  re-synced so the user reliably gets a banner + sound at the right moment
//  whether the app is in the foreground or background.
//

import Foundation
import UserNotifications

@MainActor
final class FocusPhaseNotifier {

    /// Single identifier — there's only ever one pending phase-end
    /// notification. Re-scheduling cancels the previous request.
    private let identifier = "clarity.focusPhaseEnd"

    /// Schedule a notification to fire `seconds` from now. The body
    /// describes which phase ends and what comes next.
    func schedule(in seconds: Int, endingPhase: FocusPhase, nextPhase: FocusPhase, taskTitle: String?) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard seconds > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = title(for: endingPhase)
        content.body = body(for: nextPhase, taskTitle: taskTitle)
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(seconds),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        center.add(request) { error in
            if let error {
                print("⚠️ Pomodoro phase notification failed: \(error.localizedDescription)")
            }
        }
    }

    /// Cancel any pending phase-end notification (e.g. user paused or ended
    /// the session).
    func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Strings

    private func title(for phase: FocusPhase) -> String {
        switch phase {
        case .focus:      return "Focus complete"
        case .shortBreak: return "Break's over"
        case .longBreak:  return "Long break's over"
        case .complete:   return "Session complete"
        }
    }

    private func body(for nextPhase: FocusPhase, taskTitle: String?) -> String {
        switch nextPhase {
        case .focus:
            if let taskTitle, !taskTitle.isEmpty {
                return "Time to focus on \(taskTitle)."
            }
            return "Time to focus."
        case .shortBreak:
            return "Take 5. Stretch, breathe, sip water."
        case .longBreak:
            return "Take a real break — step away."
        case .complete:
            return "Nice work — you've earned it."
        }
    }
}
