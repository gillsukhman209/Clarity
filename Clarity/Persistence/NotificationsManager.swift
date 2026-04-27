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
    func sync(with tasks: [PlanTask]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard authorization == .authorized else { return }

        let now = Date()
        for task in tasks where !task.isCompleted && task.startTime > now {
            let content = UNMutableNotificationContent()
            content.title = task.title
            content.body  = bodyText(for: task)
            content.sound = .default

            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: task.startTime
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

    private func bodyText(for task: PlanTask) -> String {
        let mins = task.durationMinutes
        if mins < 60 {
            return "Starts now · \(mins) min · \(task.category.title)"
        }
        let h = mins / 60
        let m = mins % 60
        let duration = m == 0 ? "\(h)h" : "\(h)h \(m)m"
        return "Starts now · \(duration) · \(task.category.title)"
    }
}
