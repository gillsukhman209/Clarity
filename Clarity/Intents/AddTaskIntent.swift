//
//  AddTaskIntent.swift
//  Clarity
//

import AppIntents
import SwiftData

struct AddTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Task"
    static let description = IntentDescription("Add a task to Clarity without opening the app.")
    static let openAppWhenRun = false

    @Parameter(
        title: "Task",
        requestValueDialog: IntentDialog("What task should I add?")
    )
    var taskText: String

    init() {
        taskText = ""
    }

    init(taskText: String) {
        self.taskText = taskText
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmed = taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .result(dialog: "I need a task to add.")
        }

        do {
            let count = try await ClarityIntentTaskWriter.addTask(from: trimmed)
            let taskWord = count == 1 ? "task" : "tasks"
            return .result(dialog: "Added \(count) \(taskWord) to Clarity.")
        } catch {
            return .result(dialog: "I couldn't add that task to Clarity.")
        }
    }
}

struct ClarityAppShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .blue

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: [
                "Add a task in \(.applicationName)",
                "Quick add in \(.applicationName)",
                "Capture task in \(.applicationName)"
            ],
            shortTitle: "Add Task",
            systemImageName: "plus.circle.fill"
        )
    }
}

@MainActor
private enum ClarityIntentTaskWriter {
    static func addTask(from input: String) async throws -> Int {
        let tasks = SmartTaskParser.makeTasks(from: input)
        guard !tasks.isEmpty else { return 0 }

        let container = try ClarityPersistence.makeContainer()
        let context = ModelContext(container)
        let notifications = NotificationsManager()
        await notifications.refreshAuthorizationStatus()

        let store = TaskStore(context: context, notifications: notifications)
        store.append(tasks)
        return tasks.count
    }
}
