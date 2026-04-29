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
    private(set) var categoryGroups: [CategoryGroup] = []
    /// All non-archived projects, sorted by `sortIndex` then `createdAt`.
    private(set) var projects: [Project] = []
    private(set) var archivedProjects: [Project] = []
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

    /// Tasks scheduled on the same calendar day as `date`.
    /// Order: timed tasks first by `startTime`; Anytime tasks last by
    /// `manualOrder` (set by drag-reorder), with `id` as a stable tiebreaker.
    func tasks(on date: Date) -> [PlanTask] {
        let cal = Calendar.current
        return tasks
            .filter { cal.isDate($0.startTime, inSameDayAs: date) }
            .sorted { a, b in
                if a.hasTime != b.hasTime { return a.hasTime }   // timed before timeless
                if a.hasTime { return a.startTime < b.startTime }
                if a.manualOrder != b.manualOrder { return a.manualOrder < b.manualOrder }
                return a.id.uuidString < b.id.uuidString
            }
    }

    /// Incomplete free-floating tasks dated in the past, capped at 14 days back.
    /// Used by the "Left from yesterday" carryover section on Today. Project
    /// tasks are excluded — those stay on the project board's Upcoming column.
    /// Sort: most recent slip first; within a day, by start time ascending.
    func carryoverTasks(asOf date: Date) -> [PlanTask] {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: date)
        guard let windowStart = cal.date(byAdding: .day, value: -14, to: todayStart) else {
            return []
        }
        return tasks
            .filter { task in
                !task.isCompleted
                    && task.projectID == nil
                    && task.startTime < todayStart
                    && task.startTime >= windowStart
            }
            .sorted { a, b in
                let aDay = cal.startOfDay(for: a.startTime)
                let bDay = cal.startOfDay(for: b.startTime)
                if aDay != bDay { return aDay > bDay }   // newer day first
                return a.startTime < b.startTime          // earliest time within the day
            }
    }

    /// Groups the day's tasks by category in `TaskCategory.allCases` order.
    /// Empty buckets are dropped so the UI only renders categories with work.
    func categoryGroups(on date: Date) -> [CategoryGroup] {
        var grouped: [TaskCategory: [PlanTask]] = [:]
        for task in tasks(on: date) {
            grouped[task.category, default: []].append(task)
        }
        return TaskCategory.allCases.compactMap { cat in
            guard let bucket = grouped[cat], !bucket.isEmpty else { return nil }
            return CategoryGroup(category: cat, tasks: bucket)
        }
    }

    // MARK: - Mutations

    func toggleComplete(_ taskID: UUID) {
        guard let record = fetchRecord(taskID) else { return }
        record.isCompleted.toggle()
        // Keep the kanban column in sync. When a user un-completes a task
        // we drop it back into Upcoming rather than try to recall its prior
        // column — simpler and predictable.
        record.boardStatusRaw = (record.isCompleted ? TaskBoardStatus.done : .upcoming).rawValue
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

    /// Move a task to a different day, preserving its time-of-day.
    /// Used by the calendar's drag-and-drop. No-op if the task ends up
    /// on the same day it's already on.
    func move(_ taskID: UUID, to newDate: Date) {
        guard let record = fetchRecord(taskID) else { return }
        let cal = Calendar.current
        let timeComps = cal.dateComponents([.hour, .minute, .second], from: record.startTime)
        var components = cal.dateComponents([.year, .month, .day], from: newDate)
        components.hour   = timeComps.hour
        components.minute = timeComps.minute
        components.second = timeComps.second
        guard let updated = cal.date(from: components),
              !cal.isDate(updated, inSameDayAs: record.startTime)
        else { return }
        record.startTime = updated
        save()
        refresh()
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

    /// Persists the edited task. Title, time, priority, category, etc. all
    /// flow through here — the row keeps its `id`, so the SwiftData record is
    /// updated in place and notifications get rescheduled by `refresh()`.
    func update(_ task: PlanTask) {
        guard let record = fetchRecord(task.id) else { return }
        record.title = task.title
        record.categoryRaw = task.category.rawValue
        record.priorityRaw = task.priority.rawValue
        record.startTime = task.startTime
        record.hasTime = task.hasTime
        record.durationMinutes = task.durationMinutes
        record.notes = task.notes
        record.isCompleted = task.isCompleted
        record.boardStatusRaw = (task.isCompleted ? .done : task.boardStatus).rawValue
        record.manualOrder = task.manualOrder
        record.project = task.projectID.flatMap(fetchProjectRecord(_:))
        save()
        refresh()
    }

    /// Renumber the manualOrder of all Anytime tasks (in the given scope) to
    /// match the supplied id order. Pass exactly the tasks you want
    /// reordered — usually all Anytime tasks for one day, or all Anytime
    /// tasks within one category for grouped view.
    func reorderAnytimeTasks(_ orderedIDs: [UUID]) {
        for (index, id) in orderedIDs.enumerated() {
            guard let record = fetchRecord(id) else { continue }
            record.manualOrder = index
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

        var grouped: [TaskCategory: [PlanTask]] = [:]
        for record in records {
            grouped[record.category, default: []].append(record.toDomain())
        }
        categoryGroups = TaskCategory.allCases.compactMap { cat in
            guard let bucket = grouped[cat], !bucket.isEmpty else { return nil }
            return CategoryGroup(category: cat, tasks: bucket)
        }

        let projectDescriptor = FetchDescriptor<ProjectRecord>(
            sortBy: [SortDescriptor(\.sortIndex), SortDescriptor(\.createdAt)]
        )
        let projectRecords = (try? context.fetch(projectDescriptor)) ?? []
        projects = projectRecords.filter { !$0.isArchived }.map { $0.toDomain() }
        archivedProjects = projectRecords.filter { $0.isArchived }.map { $0.toDomain() }

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
        let parent: ProjectRecord? = plan.projectID.flatMap(fetchProjectRecord(_:))
        return TaskRecord(
            id: plan.id,
            title: plan.title,
            category: plan.category,
            priority: plan.priority,
            startTime: plan.startTime,
            hasTime: plan.hasTime,
            durationMinutes: plan.durationMinutes,
            notes: plan.notes,
            isCompleted: plan.isCompleted,
            boardStatus: plan.boardStatus,
            manualOrder: plan.manualOrder,
            subtasks: subRecords,
            project: parent
        )
    }

    // MARK: - Project queries

    func project(with id: UUID) -> Project? {
        projects.first { $0.id == id } ?? archivedProjects.first { $0.id == id }
    }

    /// All tasks belonging to a project, regardless of date or completion.
    func tasks(in projectID: UUID) -> [PlanTask] {
        tasks.filter { $0.projectID == projectID }
    }

    /// Tasks for a project bucketed by board status. Order within each bucket:
    /// scheduled-today first, then by start time.
    func tasksByBoardStatus(in projectID: UUID) -> [TaskBoardStatus: [PlanTask]] {
        var buckets: [TaskBoardStatus: [PlanTask]] = [:]
        for task in tasks(in: projectID) {
            buckets[task.boardStatus, default: []].append(task)
        }
        for (status, list) in buckets {
            buckets[status] = list.sorted { a, b in
                if a.hasTime != b.hasTime { return a.hasTime }
                return a.startTime < b.startTime
            }
        }
        return buckets
    }

    // MARK: - Project mutations

    @discardableResult
    func createProject(
        name: String,
        iconSymbol: String = "folder.fill",
        colorHex: String = "8B7CF6",
        notes: String? = nil
    ) -> Project {
        let nextIndex = (projects.map(\.sortIndex).max() ?? -1) + 1
        let record = ProjectRecord(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            iconSymbol: iconSymbol,
            colorHex: colorHex,
            notes: notes,
            sortIndex: nextIndex
        )
        context.insert(record)
        save()
        refresh()
        return record.toDomain()
    }

    func renameProject(_ id: UUID, to newName: String) {
        guard let record = fetchProjectRecord(id) else { return }
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        record.name = trimmed
        save()
        refresh()
    }

    func updateProject(
        _ id: UUID,
        name: String? = nil,
        iconSymbol: String? = nil,
        colorHex: String? = nil,
        notes: String?? = nil
    ) {
        guard let record = fetchProjectRecord(id) else { return }
        if let name {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { record.name = trimmed }
        }
        if let iconSymbol { record.iconSymbol = iconSymbol }
        if let colorHex   { record.colorHex   = colorHex   }
        if let notes      { record.notes      = notes      }
        save()
        refresh()
    }

    func setArchived(_ id: UUID, archived: Bool) {
        guard let record = fetchProjectRecord(id) else { return }
        record.isArchived = archived
        save()
        refresh()
    }

    /// Permanently deletes a project. Cascade-deletes its tasks.
    func deleteProject(_ id: UUID) {
        guard let record = fetchProjectRecord(id) else { return }
        context.delete(record)
        save()
        refresh()
    }

    // MARK: - Board status

    /// Move a task to a different kanban column. `.done` also flips
    /// `isCompleted` to true; moving away from `.done` clears it.
    func setBoardStatus(_ status: TaskBoardStatus, for taskID: UUID) {
        guard let record = fetchRecord(taskID) else { return }
        record.boardStatusRaw = status.rawValue
        record.isCompleted = (status == .done)
        save()
        refresh()
    }

    /// Reassign or clear a task's parent project.
    func setProject(_ projectID: UUID?, for taskID: UUID) {
        guard let record = fetchRecord(taskID) else { return }
        record.project = projectID.flatMap(fetchProjectRecord(_:))
        save()
        refresh()
    }

    private func fetchProjectRecord(_ id: UUID) -> ProjectRecord? {
        let target = id
        let descriptor = FetchDescriptor<ProjectRecord>(
            predicate: #Predicate<ProjectRecord> { $0.id == target }
        )
        return try? context.fetch(descriptor).first
    }
}
