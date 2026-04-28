//
//  TaskStore.swift
//  Clarity
//
//  Observable wrapper around the SwiftData `ModelContext`.
//  Exposes the day plan as immutable `PlanTask` value types and provides
//  task-level mutations. UI layers depend only on this store, not on SwiftData.
//

import Foundation
import SwiftData
import Observation
import CoreData

@Observable
final class TaskStore {
    private let context: ModelContext
    var notifications: NotificationsManager?
    @ObservationIgnored private var remoteChangeTask: Task<Void, Never>?

    private(set) var tasks: [PlanTask] = []
    private(set) var daySections: [DaySection] = []
    /// The most recently deleted task, kept around briefly so the UI can
    /// offer an Undo toast. Cleared after 5 seconds or on the next undo.
    private(set) var recentlyDeleted: PlanTask?
    @ObservationIgnored private var undoExpiryTask: Task<Void, Never>?

    init(context: ModelContext, notifications: NotificationsManager? = nil) {
        self.context = context
        self.notifications = notifications
        refresh()
        startObservingRemoteChanges()
    }

    /// Public refresh used by ContentView when the app becomes active —
    /// belt-and-suspenders so foreground always re-pulls from CloudKit.
    func reload() {
        refresh()
    }

    /// Listens for `NSPersistentStoreRemoteChange`, which the
    /// NSPersistentCloudKitContainer underneath SwiftData fires whenever
    /// CloudKit pushes records from another device.
    private func startObservingRemoteChanges() {
        remoteChangeTask = Task { [weak self] in
            let stream = NotificationCenter.default.notifications(
                named: .NSPersistentStoreRemoteChange
            )
            for await _ in stream {
                guard !Task.isCancelled else { break }
                await MainActor.run { self?.refresh() }
            }
        }
    }

    // MARK: - Reads

    func task(with id: UUID) -> PlanTask? {
        tasks.first { $0.id == id }
    }

    var firstTaskID: UUID? { tasks.first?.id }

    /// Re-runs notification scheduling against the current task list.
    /// Used after notification permission becomes known on launch.
    func kickNotifications() {
        notifications?.sync(with: tasks)
    }

    // MARK: - Date-filtered views

    /// Tasks scheduled on the same calendar day as `date`, in start-time order.
    func tasks(on date: Date) -> [PlanTask] {
        let cal = Calendar.current
        return tasks
            .filter { cal.isDate($0.startTime, inSameDayAs: date) }
            .sorted { $0.startTime < $1.startTime }
    }

    /// `daySections` filtered to the given date.
    func daySections(on date: Date) -> [DaySection] {
        let order: [DaySectionKind] = [
            .focusTime, .create, .getThingsDone, .energize, .windDown
        ]
        var grouped: [DaySectionKind: [PlanTask]] = [:]
        for task in tasks(on: date) {
            grouped[task.section, default: []].append(task)
        }
        return order.compactMap { kind in
            guard let bucket = grouped[kind], !bucket.isEmpty else { return nil }
            return DaySection(kind: kind, tasks: bucket)
        }
    }

    // MARK: - Mutations

    func toggleComplete(_ taskID: UUID) {
        guard let record = fetchRecord(taskID) else { return }
        record.isCompleted.toggle()
        save()
        refresh()
    }

    func delete(_ taskID: UUID) {
        guard let record = fetchRecord(taskID) else { return }
        let snapshot = record.toDomain()
        context.delete(record)
        save()
        refresh()
        recentlyDeleted = snapshot
        scheduleUndoExpiry(for: snapshot.id)
    }

    /// Restore the most recently deleted task. Called by the Undo toast.
    func undoLastDelete() {
        guard let task = recentlyDeleted else { return }
        undoExpiryTask?.cancel()
        recentlyDeleted = nil
        append([task])
    }

    /// Dismiss the toast manually without restoring (e.g. user tapped away).
    func clearRecentlyDeleted() {
        undoExpiryTask?.cancel()
        recentlyDeleted = nil
    }

    private func scheduleUndoExpiry(for id: UUID) {
        undoExpiryTask?.cancel()
        undoExpiryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            await MainActor.run {
                guard let self else { return }
                if self.recentlyDeleted?.id == id {
                    self.recentlyDeleted = nil
                }
            }
        }
    }

    /// Wipes every task on this device. With CloudKit on, the deletion
    /// replicates to your iCloud private database and propagates to other
    /// signed-in devices in the background.
    func deleteAll() {
        let descriptor = FetchDescriptor<TaskRecord>()
        let existing = (try? context.fetch(descriptor)) ?? []
        for record in existing {
            context.delete(record)
        }
        save()
        refresh()
    }

    func toggleSubtask(taskID: UUID, subtaskID: UUID) {
        guard let record = fetchRecord(taskID),
              let sub = (record.subtasks ?? []).first(where: { $0.id == subtaskID })
        else { return }
        sub.isCompleted.toggle()
        save()
        refresh()
    }

    // MARK: - Helpers

    private func fetchRecord(_ id: UUID) -> TaskRecord? {
        let target = id
        let descriptor = FetchDescriptor<TaskRecord>(
            predicate: #Predicate<TaskRecord> { $0.id == target }
        )
        return try? context.fetch(descriptor).first
    }

    private func save() {
        do {
            try context.save()
        } catch {
            // Mock-only project — surfacing failures is a Phase 12 concern.
            assertionFailure("TaskStore save failed: \(error)")
        }
    }

    private func refresh() {
        let descriptor = FetchDescriptor<TaskRecord>(
            sortBy: [SortDescriptor(\.startTime)]
        )
        let records = (try? context.fetch(descriptor)) ?? []
        tasks = records.map { $0.toDomain() }

        let order: [DaySectionKind] = [
            .focusTime, .create, .getThingsDone, .energize, .windDown
        ]
        var grouped: [DaySectionKind: [PlanTask]] = [:]
        for record in records {
            grouped[record.section, default: []].append(record.toDomain())
        }
        daySections = order.compactMap { kind in
            guard let bucket = grouped[kind], !bucket.isEmpty else { return nil }
            return DaySection(kind: kind, tasks: bucket)
        }

        notifications?.sync(with: tasks)
    }

    // MARK: - Bulk replace (used by AI plan generator)

    /// Wipe all current tasks and seed with the given plan.
    func replaceAll(with newTasks: [PlanTask]) {
        let descriptor = FetchDescriptor<TaskRecord>()
        let existing = (try? context.fetch(descriptor)) ?? []
        for record in existing {
            context.delete(record)
        }
        for plan in newTasks {
            context.insert(record(from: plan))
        }
        save()
        refresh()
    }

    /// Add tasks without touching anything that's already there.
    /// Used by Quick Add (text or short voice).
    func append(_ newTasks: [PlanTask]) {
        for plan in newTasks {
            context.insert(record(from: plan))
        }
        save()
        refresh()
    }

    private func record(from plan: PlanTask) -> TaskRecord {
        let subRecords = plan.subtasks.enumerated().map { index, sub in
            SubtaskRecord(id: sub.id, title: sub.title, isCompleted: sub.isCompleted, sortIndex: index)
        }
        return TaskRecord(
            id: plan.id,
            title: plan.title,
            category: plan.category,
            priority: plan.priority,
            section: plan.section,
            startTime: plan.startTime,
            durationMinutes: plan.durationMinutes,
            notes: plan.notes,
            isCompleted: plan.isCompleted,
            subtasks: subRecords
        )
    }
}
