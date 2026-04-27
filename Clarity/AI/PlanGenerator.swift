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
    /// If `existing` is non-empty, the AI is asked to MERGE the user's new
    /// thoughts with the existing plan rather than replan from scratch.
    func generate(from transcript: String, existing: [PlanTask] = []) async {
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

        // Run animation + API in parallel.
        async let apiResult = callOpenAI(userMessage: userMessage, apiKey: apiKey)

        for next in Stage.allCases {
            stage = next
            try? await Task.sleep(for: .milliseconds(700))
        }

        switch await apiResult {
        case .success(let generated):
            tasks = generated
        case .failure(let err):
            error = err.localizedDescription
        }
        isComplete = true
    }

    private func buildUserMessage(transcript: String, existing: [PlanTask]) -> String {
        guard !existing.isEmpty else { return transcript }

        let lines = existing.map { task -> String in
            let subs = task.subtasks.isEmpty ? "" : " — subtasks: \(task.subtasks.map(\.title).joined(separator: "; "))"
            return "- \(task.startTimeLabel) \(task.title) (\(task.durationMinutes)m, category=\(task.category.rawValue), priority=\(task.priority.rawValue), section=\(task.section.rawValue))\(subs)"
        }
        let summary = lines.joined(separator: "\n")

        return """
        My current day plan:
        \(summary)

        New thoughts from me:
        \(transcript)

        Update my plan to incorporate the new thoughts. Keep tasks that aren't affected. Adjust times if needed to fit the new tasks. Output the FULL updated day, not just deltas.
        """
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
    You are Clarity, a personal day planning assistant. The user speaks a stream-of-consciousness brain dump describing what they want to do today. Convert it into a structured, realistic day plan.

    MERGE BEHAVIOR:
    If the user message includes a "My current day plan" section, you are UPDATING that plan, not replacing it.
    - Keep tasks that aren't affected by the new thoughts.
    - Add new tasks the user mentions.
    - If the user explicitly asks to remove or rename a task, do so.
    - Adjust times only when needed to make new tasks fit; don't shuffle tasks unnecessarily.
    - Always output the FULL updated day, not just the new pieces.

    SCHEDULING RULES:
    - Schedule between 8:00 AM and 7:00 PM unless the user specifies times.
    - Respect explicit times the user mentions ("at 3pm", "this morning").
    - Don't pack the day. Leave breathing room. Include lunch and a short break or two when planning a fresh day.
    - Prefer 60–90 minute focus blocks.

    PER-TASK FIELDS:
    - title: short, action-oriented
    - category, priority, section: see allowed values
    - startHour, startMinute, durationMinutes: realistic numbers
    - notes: 1–2 sentences explaining how to approach the task
    - subtasks: 1–4 short actionable steps for tasks that benefit from breakdown (focus/create work especially). Empty array for simple tasks like "Lunch".

    ALLOWED VALUES:
    - category: "work" | "personal" | "health" | "admin" | "focus" | "create" | "energize" | "windDown"
    - priority: "low" | "medium" | "high"
    - section: "focusTime" | "create" | "getThingsDone" | "energize" | "windDown"

    SECTION GUIDANCE:
    - focusTime: deep, uninterrupted thinking work
    - create: making something new (writing, design, content)
    - getThingsDone: admin, errands, meetings, quick wins
    - energize: meals, breaks, exercise
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
                "startHour":       JSONSchema(type: .integer, minimum: 0, maximum: 23),
                "startMinute":     JSONSchema(type: .integer, minimum: 0, maximum: 59),
                "durationMinutes": JSONSchema(type: .integer, minimum: 5, maximum: 480),
                "notes":           JSONSchema(type: .string),
                "subtasks":        JSONSchema(type: .array, items: SchemaBox(JSONSchema(type: .string)))
            ],
            required: ["title", "category", "priority", "section", "startHour", "startMinute", "durationMinutes", "notes", "subtasks"],
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
            let startTime = cal.date(
                bySettingHour: max(0, min(23, t.startHour)),
                minute: max(0, min(59, t.startMinute)),
                second: 0,
                of: today
            ) ?? today
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
