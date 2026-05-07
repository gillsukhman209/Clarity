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
    private let taskIdentifierPrefix = "clarity.task."
    private let maxPendingTaskNotifications = 60
    @ObservationIgnored private var syncGeneration: Int = 0

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
        let canSchedule = authorization == .authorized
        let snapshot = tasks
        syncGeneration += 1
        let generation = syncGeneration

        Task { @MainActor [weak self] in
            guard let self, generation == self.syncGeneration else { return }
            let center = UNUserNotificationCenter.current()
            let pending = await center.pendingNotificationRequests()
            let managedIDs = pending
                .map(\.identifier)
                .filter { identifier in
                    identifier.hasPrefix(self.taskIdentifierPrefix) || UUID(uuidString: identifier) != nil
                }
            if !managedIDs.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: managedIDs)
            }
            guard canSchedule else { return }
            for request in self.pendingRequests(for: snapshot) {
                try? await center.add(request)
            }
        }
    }

    private func pendingRequests(for tasks: [PlanTask]) -> [UNNotificationRequest] {
        let now = Date()
        return tasks.compactMap { task -> (Date, UNNotificationRequest)? in
            guard !task.isCompleted && task.hasTime else { return nil }
            let lead = leadMinutes(for: task.priority)
            let fireDate = task.startTime.addingTimeInterval(-Double(lead) * 60)
            guard fireDate > now else { return nil }

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
                identifier: taskIdentifier(for: task),
                content: content,
                trigger: trigger
            )
            return (fireDate, request)
        }
        .sorted { $0.0 < $1.0 }
        .prefix(maxPendingTaskNotifications)
        .map(\.1)
    }

    private func taskIdentifier(for task: PlanTask) -> String {
        taskIdentifierPrefix + task.id.uuidString
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
