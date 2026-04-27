//
//  MockData.swift
//  Clarity
//
//  Static sample data matching the reference design. No persistence.
//

import Foundation

enum MockData {
    static let userFirstName = "Alex"

    static var today: Date {
        let cal = Calendar.current
        return cal.startOfDay(for: Date())
    }

    private static func at(_ hour: Int, _ minute: Int = 0) -> Date {
        let cal = Calendar.current
        return cal.date(bySettingHour: hour, minute: minute, second: 0, of: today) ?? today
    }

    // MARK: - iOS Today plan (matches the iOS reference screen)
    static let todayTasks: [PlanTask] = [
        PlanTask(
            title: "Deep Work: Marketing Strategy",
            category: .focus,
            priority: .high,
            startTime: at(8, 0),
            durationMinutes: 90,
            notes: "Focus on positioning, market analysis, and next steps. Prepare for leadership review tomorrow.",
            subtasks: [
                Subtask(title: "Outline key sections"),
                Subtask(title: "Market analysis"),
                Subtask(title: "Competitive landscape"),
                Subtask(title: "Strategic recommendations")
            ]
        ),
        PlanTask(
            title: "Emails & Communications",
            category: .work,
            priority: .medium,
            startTime: at(9, 30),
            durationMinutes: 45
        ),
        PlanTask(
            title: "Content Planning: Next Week",
            category: .create,
            priority: .medium,
            startTime: at(10, 15),
            durationMinutes: 60
        ),
        PlanTask(
            title: "Break",
            category: .energize,
            priority: .low,
            startTime: at(11, 15),
            durationMinutes: 15
        ),
        PlanTask(
            title: "Team Standup",
            category: .work,
            priority: .medium,
            startTime: at(11, 30),
            durationMinutes: 30
        ),
        PlanTask(
            title: "Lunch",
            category: .energize,
            priority: .low,
            startTime: at(12, 0),
            durationMinutes: 60
        ),
        PlanTask(
            title: "Admin Tasks",
            category: .admin,
            priority: .medium,
            startTime: at(13, 0),
            durationMinutes: 45
        ),
        PlanTask(
            title: "Call Mom",
            category: .personal,
            priority: .medium,
            startTime: at(13, 45),
            durationMinutes: 30
        ),
        PlanTask(
            title: "Workout",
            category: .health,
            priority: .high,
            startTime: at(14, 15),
            durationMinutes: 60
        ),
        PlanTask(
            title: "Grocery Shopping",
            category: .personal,
            priority: .low,
            startTime: at(15, 15),
            durationMinutes: 45
        ),
        PlanTask(
            title: "Read",
            category: .windDown,
            priority: .low,
            startTime: at(16, 0),
            durationMinutes: 45
        ),
        PlanTask(
            title: "Plan Tomorrow",
            category: .focus,
            priority: .medium,
            startTime: at(16, 45),
            durationMinutes: 30
        ),
        PlanTask(
            title: "Dentist Appointment",
            category: .health,
            priority: .high,
            startTime: at(17, 15),
            durationMinutes: 30
        )
    ]

    // MARK: - macOS day grouped by energy section
    static let daySections: [DaySection] = [
        DaySection(kind: .focusTime, tasks: [
            todayTasks[0],   // Deep Work
            todayTasks[11]   // Plan Tomorrow
        ]),
        DaySection(kind: .create, tasks: [
            todayTasks[2]    // Content Planning
        ]),
        DaySection(kind: .getThingsDone, tasks: [
            todayTasks[1],   // Emails
            todayTasks[4],   // Standup
            todayTasks[6],   // Admin Tasks
            todayTasks[9]    // Grocery
        ]),
        DaySection(kind: .energize, tasks: [
            todayTasks[3],   // Break
            todayTasks[5],   // Lunch
            todayTasks[8]    // Workout
        ]),
        DaySection(kind: .windDown, tasks: [
            todayTasks[7],   // Call Mom
            todayTasks[10],  // Read
            todayTasks[12]   // Dentist
        ])
    ]

    static let featuredTask: PlanTask = todayTasks[0]
}
