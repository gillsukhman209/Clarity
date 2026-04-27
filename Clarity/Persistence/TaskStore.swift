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

@Observable
final class TaskStore {
    private let context: ModelContext

    private(set) var tasks: [PlanTask] = []
    private(set) var daySections: [DaySection] = []

    init(context: ModelContext) {
        self.context = context
        refresh()
    }

    // MARK: - Reads

    func task(with id: UUID) -> PlanTask? {
        tasks.first { $0.id == id }
    }

    var firstTaskID: UUID? { tasks.first?.id }

    // MARK: - Mutations

    func toggleComplete(_ taskID: UUID) {
        guard let record = fetchRecord(taskID) else { return }
        record.isCompleted.toggle()
        save()
        refresh()
    }

    func delete(_ taskID: UUID) {
        guard let record = fetchRecord(taskID) else { return }
        context.delete(record)
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
