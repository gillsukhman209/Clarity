//
//  NotificationsManager.swift
//  Clarity
//
//  Phase 12 — schedules a local notification at each task's start time so the
//  user gets a ping when work begins. Reschedules whenever the day plan
//  changes; cancels when tasks complete or are deleted.
//

import Foundation
import Observation
import UserNotifications

@Observable
@MainActor
final class NotificationsManager {

    enum Authorization: Equatable {
        case unknown
        case authorized
        case denied
    }

    private(set) var authorization: Authorization = .unknown

    /// Asks the system for permission. Idempotent — safe to call repeatedly.
    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        let current = await center.notificationSettings()
        switch current.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            authorization = .authorized
            return
        case .denied:
            authorization = .denied
            return
        case .notDetermined:
            break
        @unknown default:
            break
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            authorization = granted ? .authorized : .denied
        } catch {
            authorization = .denied
        }
    }

    /// Cancels all currently scheduled task notifications and reschedules from
    /// the given plan. Cheap enough to call after every store change.
    ///
    /// Lead time depends on priority so high-stakes work gets earlier warning:
    /// - high   → fires 30 min before start
    /// - medium → fires 15 min before start
    /// - low    → fires 5 min before start
    /// Timeless tasks (`!hasTime`) get no notification — there's nothing to ping at.
    func sync(with tasks: [PlanTask]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard authorization == .authorized else { return }

        let now = Date()
        for task in tasks where !task.isCompleted && task.hasTime {
            let lead = leadMinutes(for: task.priority)
            let fireDate = task.startTime.addingTimeInterval(-Double(lead) * 60)
            guard fireDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = task.title
            content.body  = bodyText(for: task, leadMinutes: lead)
            content.sound = .default

            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: task.id.uuidString,
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    private func leadMinutes(for priority: TaskPriority) -> Int {
        switch priority {
        case .high:   return 30
        case .medium: return 15
        case .low:    return 5
        }
    }

    private func bodyText(for task: PlanTask, leadMinutes lead: Int) -> String {
        let when = lead == 0 ? "Starts now" : "Starts in \(lead) min"
        guard let duration = task.durationLabel else {
            return "\(when) · \(task.category.title)"
        }
        return "\(when) · \(duration) · \(task.category.title)"
    }
}
