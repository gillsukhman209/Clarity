//
//  PlanGenerator.swift
//  Clarity
//
//  Phase 8 — turns a transcript into a structured day plan via OpenAI.
//  Uses gpt-4o-mini with strict JSON Schema response_format so the
//  decoded shape is reliable.
//

import Foundation
import Observation

@Observable
@MainActor
final class PlanGenerator {

    enum Stage: Int, CaseIterable, Equatable {
        case extracting, estimating, prioritizing, optimizing, finalizing

        var title: String {
            switch self {
            case .extracting:   return "Extracting tasks"
            case .estimating:   return "Estimating time"
            case .prioritizing: return "Prioritizing"
            case .optimizing:   return "Optimizing schedule"
            case .finalizing:   return "Finalizing your plan"
            }
        }
    }

    private(set) var stage: Stage = .extracting
    private(set) var isComplete: Bool = false
    private(set) var error: String?
    private(set) var tasks: [PlanTask] = []

    /// Drives the BuildingPlanView. Animates the stage list while the API call
    /// runs in parallel; the final result lands once both finish.
    /// - Parameters:
    ///   - quick: when true, skips the 5-stage animation and resolves as soon
    ///     as OpenAI responds. Used by Quick Add where the user just wants
    ///     their task added with no theatrics.
    func generate(from transcript: String, existing: [PlanTask] = [], quick: Bool = false) async {
        // Reset
        stage = .extracting
        isComplete = false
        error = nil
        tasks = []

        let apiKey = Secrets.openAIAPIKey
        guard !apiKey.isEmpty else {
            error = "OpenAI key missing in Secrets.swift."
            isComplete = true
            return
        }

        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            error = "I didn't catch anything to plan."
            isComplete = true
            return
        }

        let userMessage = buildUserMessage(transcript: trimmed, existing: existing)

        if quick {
            applyResult(await callOpenAI(userMessage: userMessage, apiKey: apiKey))
            return
        }

        // Run stage animation + API in parallel.
        async let apiResult = callOpenAI(userMessage: userMessage, apiKey: apiKey)
        for next in Stage.allCases {
            stage = next
            try? await Task.sleep(for: .milliseconds(700))
        }
        applyResult(await apiResult)
    }

    private func applyResult(_ result: Result<[PlanTask], Error>) {
        switch result {
        case .success(let generated):
            tasks = generated
        case .failure(let err):
            error = err.localizedDescription
        }
        isComplete = true
    }

    private func buildUserMessage(transcript: String, existing: [PlanTask]) -> String {
        let dateHeader = "Today's date: \(Self.todayDateString())"

        guard !existing.isEmpty else {
            return """
            \(dateHeader)

            \(transcript)
            """
        }

        let lines = existing.map { task -> String in
            let subs = task.subtasks.isEmpty
                ? ""
                : " — subtasks: \(task.subtasks.map(\.title).joined(separator: "; "))"
            let day = Self.dayLabel(for: task.startTime)
            return "- [\(day)] \(task.startTimeLabel) \(task.title) (\(task.durationMinutes)m, category=\(task.category.rawValue), priority=\(task.priority.rawValue), section=\(task.section.rawValue))\(subs)"
        }
        let summary = lines.joined(separator: "\n")

        return """
        \(dateHeader)

        My current plan (across days):
        \(summary)

        New thoughts from me:
        \(transcript)

        Update my plan to incorporate the new thoughts. Keep tasks that aren't affected. Set dayOffset on each task — match each existing task's [day label] above, and use the user's day references for new tasks. Output the FULL updated plan, not just deltas.
        """
    }

    private static func todayDateString() -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d, yyyy"
        return f.string(from: Date())
    }

    private static func dayLabel(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInTomorrow(date)  { return "Tomorrow" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let today = cal.startOfDay(for: Date())
        let target = cal.startOfDay(for: date)
        let days = cal.dateComponents([.day], from: today, to: target).day ?? 0
        if days > 0 {
            let f = DateFormatter()
            f.dateFormat = "EEE MMM d"
            return "\(f.string(from: date)) (+\(days)d)"
        }
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d"
        return f.string(from: date)
    }

    // MARK: - OpenAI call

    private func callOpenAI(userMessage: String, apiKey: String) async -> Result<[PlanTask], Error> {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ChatRequest(
            model: "gpt-4o-mini",
            messages: [
                ChatMessage(role: "system", content: PlanGenerator.systemPrompt),
                ChatMessage(role: "user", content: userMessage)
            ],
            response_format: .schema
        )

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return .failure(error)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .failure(PlanGeneratorError.network("Couldn't reach OpenAI."))
            }
            guard (200..<300).contains(http.statusCode) else {
                return .failure(PlanGeneratorError.openAI(status: http.statusCode, body: data))
            }
            let chat = try JSONDecoder().decode(ChatResponse.self, from: data)
            guard let content = chat.choices.first?.message.content,
                  let contentData = content.data(using: .utf8) else {
                return .failure(PlanGeneratorError.empty)
            }
            let plan = try JSONDecoder().decode(DayPlanJSON.self, from: contentData)
            return .success(plan.toDomain())
        } catch let urlError as URLError {
            return .failure(PlanGeneratorError.fromURLError(urlError))
        } catch {
            return .failure(error)
        }
    }

    // MARK: - System prompt

    private static let systemPrompt: String = """
    You are Clarity, a personal day planning assistant. The user describes things they want to do today; you turn it into a structured schedule.

    CRITICAL — DO NOT INVENT TASKS:
    - Output ONLY tasks the user explicitly mentioned.
    - Do NOT auto-add lunch, breakfast, breaks, exercise, prep time, or anything else they did not name.
    - Each thing the user says becomes exactly one task unless they explicitly describe multiple.
    - If the user mentions a time relative to a meal ("before lunch", "after my workout") and the meal/workout itself is NOT in the plan, do not add it — just respect the timing context.

    MERGE BEHAVIOR:
    If the user message starts with "My current day plan", you are UPDATING that plan.
    - Keep every existing task as-is unless the user explicitly removes or renames it.
    - Add ONLY the new tasks the user just mentioned.
    - Adjust an existing task's time only if a new task has an explicit time that conflicts.
    - Output the FULL updated day, not just deltas.

    SCHEDULING:
    - Default window is 8:00 AM to 7:00 PM. Respect explicit times the user gives.
    - For tasks without explicit times, place them in a sensible order based on what they said.
    - Don't pack tasks back-to-back; a few minutes gap is fine. Don't add filler tasks to fill gaps.

    DAY ASSIGNMENT (dayOffset):
    - dayOffset is an INTEGER number of days from today. 0 = today (default), 1 = tomorrow, 2 = day after, 7 = a week from today, etc.
    - The user message starts with "Today's date: ...". Use that as your anchor for "today".
    - If the user says "tomorrow", "next Friday", "in 3 days", "Monday", "on the 15th", etc., compute the dayOffset and set it on THAT specific task.
    - Different tasks in the same brain dump CAN have different dayOffsets — set each one based on what the user said about it.
    - If the user does not mention a day for a task, dayOffset must be 0 (today).
    - If the user merges new thoughts into an existing plan, only change dayOffset on tasks they explicitly want to move.

    PER-TASK FIELDS:
    - title: short, action-oriented, faithful to what the user said
    - category, priority, section: see allowed values
    - dayOffset: integer, see above
    - startHour, startMinute, durationMinutes: realistic numbers (estimate duration if not given)
    - notes: 1–2 sentences on how to approach it
    - subtasks: 1–4 short actionable steps ONLY for tasks that benefit from breakdown (deep focus / creative work). Empty array for everything else.

    ALLOWED VALUES:
    - category: "work" | "personal" | "health" | "admin" | "focus" | "create" | "energize" | "windDown"
    - priority: "low" | "medium" | "high"
    - section: "focusTime" | "create" | "getThingsDone" | "energize" | "windDown"

    SECTION GUIDANCE:
    - focusTime: deep, uninterrupted thinking work
    - create: making something new (writing, design, content)
    - getThingsDone: admin, errands, meetings, quick wins
    - energize: meals, breaks, exercise (only if the user mentioned them)
    - windDown: low-effort, evening tasks, calls, reading
    """
}

// MARK: - Models

private struct ChatRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let response_format: ResponseFormat
}

private struct ChatMessage: Encodable {
    let role: String
    let content: String
}

private struct ResponseFormat: Encodable {
    let type: String
    let json_schema: JSONSchemaWrapper

    static let schema = ResponseFormat(
        type: "json_schema",
        json_schema: JSONSchemaWrapper(
            name: "DayPlan",
            strict: true,
            schema: .dayPlan
        )
    )
}

private struct JSONSchemaWrapper: Encodable {
    let name: String
    let strict: Bool
    let schema: JSONSchema
}

/// Minimal JSON-Schema encoder tailored to the shape we need.
private struct JSONSchema: Encodable {
    enum SchemaType: String, Encodable {
        case object, array, string, integer
    }

    let type: SchemaType
    var description: String? = nil
    var properties: [String: JSONSchema]? = nil
    var required: [String]? = nil
    var additionalProperties: Bool? = nil
    var items: SchemaBox? = nil
    var `enum`: [String]? = nil
    var minimum: Int? = nil
    var maximum: Int? = nil

    enum CodingKeys: String, CodingKey {
        case type, description, properties, required, additionalProperties, items, `enum`, minimum, maximum
    }

    /// Recursive boxing so JSONSchema can contain itself in `items`.
    final class SchemaBox: Encodable {
        let value: JSONSchema
        init(_ value: JSONSchema) { self.value = value }
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(value)
        }
    }

    static let dayPlan: JSONSchema = {
        let categoryEnum = ["work", "personal", "health", "admin", "focus", "create", "energize", "windDown"]
        let priorityEnum = ["low", "medium", "high"]
        let sectionEnum  = ["focusTime", "create", "getThingsDone", "energize", "windDown"]

        let task = JSONSchema(
            type: .object,
            properties: [
                "title":           JSONSchema(type: .string),
                "category":        JSONSchema(type: .string, enum: categoryEnum),
                "priority":        JSONSchema(type: .string, enum: priorityEnum),
                "section":         JSONSchema(type: .string, enum: sectionEnum),
                "dayOffset":       JSONSchema(type: .integer, minimum: 0, maximum: 90),
                "startHour":       JSONSchema(type: .integer, minimum: 0, maximum: 23),
                "startMinute":     JSONSchema(type: .integer, minimum: 0, maximum: 59),
                "durationMinutes": JSONSchema(type: .integer, minimum: 5, maximum: 480),
                "notes":           JSONSchema(type: .string),
                "subtasks":        JSONSchema(type: .array, items: SchemaBox(JSONSchema(type: .string)))
            ],
            required: ["title", "category", "priority", "section", "dayOffset", "startHour", "startMinute", "durationMinutes", "notes", "subtasks"],
            additionalProperties: false
        )

        return JSONSchema(
            type: .object,
            properties: [
                "tasks": JSONSchema(type: .array, items: SchemaBox(task))
            ],
            required: ["tasks"],
            additionalProperties: false
        )
    }()
}

private struct ChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable { let content: String }
        let message: Message
    }
    let choices: [Choice]
}

private struct DayPlanJSON: Decodable {
    struct TaskJSON: Decodable {
        let title: String
        let category: String
        let priority: String
        let section: String
        let dayOffset: Int
        let startHour: Int
        let startMinute: Int
        let durationMinutes: Int
        let notes: String
        let subtasks: [String]
    }
    let tasks: [TaskJSON]

    func toDomain() -> [PlanTask] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return tasks.map { t in
            let category = TaskCategory(rawValue: t.category) ?? .work
            let priority = TaskPriority(rawValue: t.priority) ?? .medium
            let section  = DaySectionKind(rawValue: t.section) ?? .getThingsDone
            let day = cal.date(
                byAdding: .day,
                value: max(0, min(90, t.dayOffset)),
                to: today
            ) ?? today
            let startTime = cal.date(
                bySettingHour: max(0, min(23, t.startHour)),
                minute: max(0, min(59, t.startMinute)),
                second: 0,
                of: day
            ) ?? day
            return PlanTask(
                title: t.title,
                category: category,
                priority: priority,
                section: section,
                startTime: startTime,
                durationMinutes: max(5, t.durationMinutes),
                notes: t.notes.isEmpty ? nil : t.notes,
                subtasks: t.subtasks.map { Subtask(title: $0) }
            )
        }
        .sorted { $0.startTime < $1.startTime }
    }
}

enum PlanGeneratorError: LocalizedError {
    case network(String)
    case openAI(status: Int, body: Data)
    case empty

    var errorDescription: String? {
        switch self {
        case .network(let detail):
            return detail
        case .empty:
            return "OpenAI returned an empty response."
        case .openAI(let status, let body):
            switch status {
            case 401:
                return "OpenAI rejected the API key. Check Secrets.swift."
            case 402, 429:
                return "OpenAI rate limit or quota hit. Try again in a minute."
            case 500...599:
                return "OpenAI is having trouble (\(status)). Try again shortly."
            default:
                let snippet = String(data: body, encoding: .utf8)?.prefix(200) ?? ""
                return "OpenAI error \(status). \(snippet)"
            }
        }
    }

    static func fromURLError(_ error: URLError) -> PlanGeneratorError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .network("You're offline. Reconnect and try again.")
        case .timedOut:
            return .network("Request timed out. Try again.")
        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return .network("Couldn't reach OpenAI. Check your connection.")
        default:
            return .network(error.localizedDescription)
        }
    }
}
