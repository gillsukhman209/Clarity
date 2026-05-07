//
//  IntentHandler.swift
//  ClarityIntents
//

import Foundation
import Intents
import UserNotifications

final class IntentHandler: INExtension, INAddTasksIntentHandling {
    override func handler(for intent: INIntent) -> Any {
        self
    }

    func resolveTaskTitles(
        for intent: INAddTasksIntent,
        with completion: @escaping ([INSpeakableStringResolutionResult]) -> Void
    ) {
        let titles = intent.taskTitles ?? []
        guard !titles.isEmpty else {
            completion([.needsValue()])
            return
        }
        completion(titles.map { .success(with: $0) })
    }

    func resolveTargetTaskList(
        for intent: INAddTasksIntent,
        with completion: @escaping (INAddTasksTargetTaskListResolutionResult) -> Void
    ) {
        completion(.notRequired())
    }

    func resolveTemporalEventTrigger(
        for intent: INAddTasksIntent,
        with completion: @escaping (INAddTasksTemporalEventTriggerResolutionResult) -> Void
    ) {
        guard let trigger = intent.temporalEventTrigger else {
            completion(.notRequired())
            return
        }
        completion(.success(with: trigger))
    }

    func resolvePriority(
        for intent: INAddTasksIntent,
        with completion: @escaping (INTaskPriorityResolutionResult) -> Void
    ) {
        completion(.success(with: intent.priority))
    }

    @MainActor
    func handle(intent: INAddTasksIntent) async -> INAddTasksIntentResponse {
        let rawTitles = (intent.taskTitles ?? [])
            .map(\.spokenPhrase)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !rawTitles.isEmpty else {
            return INAddTasksIntentResponse(code: .failure, userActivity: nil)
        }

        do {
            let drafts = rawTitles.flatMap { title in
                IntentTaskParser.makeDrafts(
                    from: title,
                    temporalEventTrigger: intent.temporalEventTrigger,
                    priority: intent.priority
                )
            }
            let now = Date()
            let records = drafts.map { draft in
                TaskRecord(
                    id: draft.id,
                    title: draft.title,
                    categoryRaw: draft.categoryRaw,
                    priorityRaw: draft.priorityRaw,
                    startTime: draft.startTime,
                    hasTime: draft.hasTime,
                    durationMinutes: draft.durationMinutes,
                    notes: nil,
                    isCompleted: false,
                    boardStatusRaw: "upcoming",
                    manualOrder: 0
                )
            }
            try IntentSiriTaskCaptureInbox.enqueue(records)
            await IntentNotificationScheduler.sync(with: records)

            let response = INAddTasksIntentResponse(code: .success, userActivity: nil)
            response.addedTasks = records.map { record in
                INTask(
                    title: INSpeakableString(spokenPhrase: record.title),
                    status: .notCompleted,
                    taskType: .completable,
                    spatialEventTrigger: intent.spatialEventTrigger,
                    temporalEventTrigger: intent.temporalEventTrigger,
                    createdDateComponents: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: now),
                    modifiedDateComponents: nil,
                    identifier: record.id.uuidString,
                    priority: intent.priority
                )
            }
            return response
        } catch {
            return INAddTasksIntentResponse(code: .failure, userActivity: nil)
        }
    }
}

private struct TaskRecord: Codable {
    var id: UUID
    var title: String
    var categoryRaw: String
    var priorityRaw: String
    var startTime: Date
    var hasTime: Bool
    var durationMinutes: Int
    var notes: String?
    var isCompleted: Bool
    var boardStatusRaw: String
    var manualOrder: Int
}

private enum IntentSiriTaskCaptureInbox {
    private static let suiteName = "group.com.gill.Clarity"
    private static let pendingKey = "pendingSiriTaskCaptures"

    static func enqueue(_ records: [TaskRecord]) throws {
        guard !records.isEmpty,
              let defaults = UserDefaults(suiteName: suiteName)
        else { return }

        var pending: [TaskRecord] = []
        if let data = defaults.data(forKey: pendingKey) {
            pending = (try? JSONDecoder().decode([TaskRecord].self, from: data)) ?? []
        }
        pending.append(contentsOf: records)
        let data = try JSONEncoder().encode(pending)
        defaults.set(data, forKey: pendingKey)
        defaults.synchronize()
    }
}

private struct IntentTaskDraft {
    var id = UUID()
    var title: String
    var categoryRaw: String
    var priorityRaw: String
    var startTime: Date
    var hasTime: Bool
    var durationMinutes: Int
}

private struct IntentRecurrence {
    enum Frequency {
        case daily
        case weekly
        case monthly
    }

    var frequency: Frequency
    var weekdays: Set<Int> = []
    var dayOfMonth: Int? = nil

    var occurrenceLimit: Int {
        switch frequency {
        case .daily: return weekdays.isEmpty ? 180 : 130
        case .weekly: return 104
        case .monthly: return 36
        }
    }
}

private enum IntentTaskParser {
    static func makeDrafts(
        from input: String,
        temporalEventTrigger: INTemporalEventTrigger?,
        priority: INTaskPriority
    ) -> [IntentTaskDraft] {
        let parsed = parse(input, temporalEventTrigger: temporalEventTrigger)
        let dates = occurrenceDates(
            firstDate: parsed.startTime,
            hasTime: parsed.hasTime,
            recurrence: parsed.recurrence
        )
        return dates.map { date in
            IntentTaskDraft(
                title: parsed.title,
                categoryRaw: inferCategory(from: parsed.title),
                priorityRaw: priority == .flagged ? "high" : "medium",
                startTime: date,
                hasTime: parsed.hasTime,
                durationMinutes: parsed.durationMinutes
            )
        }
    }

    private static func parse(
        _ rawInput: String,
        temporalEventTrigger: INTemporalEventTrigger?
    ) -> (title: String, startTime: Date, hasTime: Bool, durationMinutes: Int, recurrence: IntentRecurrence?) {
        let now = Date()
        let triggerParsed = parse(trigger: temporalEventTrigger)
        let recurrenceMatch = detectRecurrence(in: rawInput)
        let dateSource = removeRanges(recurrenceMatch.ranges, from: rawInput)

        var startTime = triggerParsed.startTime
        var hasTime = triggerParsed.hasTime
        var dateMatchText: String?

        if startTime == nil,
           let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
            let range = NSRange(dateSource.startIndex..., in: dateSource)
            if let match = detector.matches(in: dateSource, options: [], range: range).first {
                if let r = Range(match.range, in: dateSource) {
                    dateMatchText = String(dateSource[r])
                    hasTime = containsTimeMarker(String(dateSource[r]))
                }
                startTime = match.date
            }
        }

        var working = dateSource
        if let dateMatchText, let r = working.range(of: dateMatchText) {
            working.removeSubrange(r)
        }

        let duration = extractDuration(from: &working)
        let title = cleanTitle(working).ifEmpty(rawInput)
        let recurrence = triggerParsed.recurrence ?? recurrenceMatch.recurrence
        let anchoredStart = startTime ?? Calendar.current.startOfDay(for: now)
        return (title, anchoredStart, hasTime, duration, recurrence)
    }

    private static func parse(trigger: INTemporalEventTrigger?) -> (startTime: Date?, hasTime: Bool, recurrence: IntentRecurrence?) {
        guard let range = trigger?.dateComponentsRange else {
            return (nil, false, nil)
        }
        let comps = range.startDateComponents
        let date = comps.flatMap { Calendar.current.date(from: $0) }
        let hasTime = comps?.hour != nil || comps?.minute != nil
        let recurrence: IntentRecurrence?
        if let rule = range.recurrenceRule {
            recurrence = self.recurrence(from: rule, date: date)
        } else {
            recurrence = nil
        }
        return (date, hasTime, recurrence)
    }

    private static func recurrence(from rule: INRecurrenceRule, date: Date?) -> IntentRecurrence {
        switch rule.frequency {
        case .daily:
            return IntentRecurrence(frequency: .daily)
        case .weekly:
            return IntentRecurrence(frequency: .weekly, weekdays: weekdays(from: rule.weeklyRecurrenceDays))
        case .monthly:
            return IntentRecurrence(
                frequency: .monthly,
                dayOfMonth: date.map { Calendar.current.component(.day, from: $0) }
            )
        default:
            return IntentRecurrence(frequency: .daily)
        }
    }

    private static func weekdays(from options: INDayOfWeekOptions) -> Set<Int> {
        var days: Set<Int> = []
        if options.contains(.monday) { days.insert(2) }
        if options.contains(.tuesday) { days.insert(3) }
        if options.contains(.wednesday) { days.insert(4) }
        if options.contains(.thursday) { days.insert(5) }
        if options.contains(.friday) { days.insert(6) }
        if options.contains(.saturday) { days.insert(7) }
        if options.contains(.sunday) { days.insert(1) }
        return days
    }

    private static func occurrenceDates(
        firstDate: Date,
        hasTime: Bool,
        recurrence: IntentRecurrence?
    ) -> [Date] {
        guard let recurrence else { return [firstDate] }
        let calendar = Calendar.current
        var dates: [Date] = []
        var cursor = firstMatchingDate(firstDate, recurrence: recurrence)
        var guardCount = 0
        while dates.count < recurrence.occurrenceLimit && guardCount < recurrence.occurrenceLimit * 8 {
            guardCount += 1
            if matches(cursor, recurrence: recurrence) {
                dates.append(cursor)
            }
            switch recurrence.frequency {
            case .daily:
                cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor
            case .weekly:
                cursor = calendar.date(byAdding: .day, value: recurrence.weekdays.isEmpty ? 7 : 1, to: cursor) ?? cursor
            case .monthly:
                cursor = nextMonth(after: cursor, recurrence: recurrence)
            }
        }
        return dates
    }

    private static func firstMatchingDate(_ date: Date, recurrence: IntentRecurrence) -> Date {
        let calendar = Calendar.current
        for offset in 0..<32 {
            guard let candidate = calendar.date(byAdding: .day, value: offset, to: date) else { continue }
            if candidate >= Date(), matches(candidate, recurrence: recurrence) {
                return candidate
            }
        }
        return date
    }

    private static func matches(_ date: Date, recurrence: IntentRecurrence) -> Bool {
        let calendar = Calendar.current
        switch recurrence.frequency {
        case .daily:
            return recurrence.weekdays.isEmpty || recurrence.weekdays.contains(calendar.component(.weekday, from: date))
        case .weekly:
            return recurrence.weekdays.isEmpty || recurrence.weekdays.contains(calendar.component(.weekday, from: date))
        case .monthly:
            guard let day = recurrence.dayOfMonth else { return true }
            return calendar.component(.day, from: date) == day
        }
    }

    private static func nextMonth(after date: Date, recurrence: IntentRecurrence) -> Date {
        let calendar = Calendar.current
        let time = calendar.dateComponents([.hour, .minute, .second], from: date)
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: date) ?? date
        let requestedDay = recurrence.dayOfMonth ?? calendar.component(.day, from: date)
        let range = calendar.range(of: .day, in: .month, for: nextMonth)
        var comps = calendar.dateComponents([.year, .month], from: nextMonth)
        comps.day = min(max(1, requestedDay), range?.count ?? requestedDay)
        comps.hour = time.hour ?? 0
        comps.minute = time.minute ?? 0
        comps.second = time.second ?? 0
        return calendar.date(from: comps) ?? nextMonth
    }

    private static func detectRecurrence(in text: String) -> (recurrence: IntentRecurrence?, ranges: [Range<String.Index>]) {
        if let monthly = firstRegexMatch(#"\b(?:on\s+)?(?:the\s+)?(\d{1,2})(?:st|nd|rd|th)?\s+(?:of\s+)?every\s+month\b"#, in: text),
           let day = capturedInt(monthly, group: 1, in: text) {
            return (IntentRecurrence(frequency: .monthly, dayOfMonth: day), [monthly.range])
        }
        if let daily = firstRegexMatch(#"\b(every\s*day|everyday|daily|each\s+day)\b"#, in: text) {
            return (IntentRecurrence(frequency: .daily), [daily.range])
        }
        if let weekday = firstRegexMatch(#"\b(every\s+weekday|weekdays|every\s+workday|workdays)\b"#, in: text) {
            return (IntentRecurrence(frequency: .daily, weekdays: Set(2...6)), [weekday.range])
        }
        if let weekly = firstRegexMatch(#"\b(every\s+week|weekly)\b"#, in: text) {
            return (IntentRecurrence(frequency: .weekly), [weekly.range])
        }
        return (nil, [])
    }

    private static func firstRegexMatch(_ pattern: String, in text: String) -> (match: NSTextCheckingResult, range: Range<String.Index>)? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text)
        else { return nil }
        return (match, range)
    }

    private static func capturedInt(_ match: (match: NSTextCheckingResult, range: Range<String.Index>), group: Int, in text: String) -> Int? {
        guard match.match.numberOfRanges > group,
              let range = Range(match.match.range(at: group), in: text)
        else { return nil }
        return Int(text[range])
    }

    private static func extractDuration(from text: inout String) -> Int {
        guard let regex = try? NSRegularExpression(
            pattern: #"\b(\d{1,3})\s*(minutes?|mins?|m|hours?|hrs?|h)\b"#,
            options: .caseInsensitive
        ) else { return 0 }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let valueRange = Range(match.range(at: 1), in: text),
              let unitRange = Range(match.range(at: 2), in: text),
              let fullRange = Range(match.range, in: text),
              let value = Int(text[valueRange])
        else { return 0 }
        let unit = text[unitRange].lowercased()
        text.removeSubrange(fullRange)
        return unit.hasPrefix("h") ? value * 60 : value
    }

    private static func removeRanges(_ ranges: [Range<String.Index>], from text: String) -> String {
        var output = text
        for range in ranges.sorted(by: { $0.lowerBound > $1.lowerBound }) {
            output.removeSubrange(range)
        }
        return output
    }

    private static func cleanTitle(_ raw: String) -> String {
        let connectors = [" at ", " on ", " in ", " for ", " by ", " around "]
        var out = " " + raw + " "
        for connector in connectors {
            out = out.replacingOccurrences(of: connector, with: " ", options: .caseInsensitive)
        }
        let collapsed = out
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        guard let first = collapsed.first else { return collapsed }
        return first.uppercased() + collapsed.dropFirst()
    }

    private static func containsTimeMarker(_ text: String) -> Bool {
        let lower = text.lowercased()
        return ["am", "pm", ":", "noon", "midnight", "morning", "afternoon", "evening", "night"].contains {
            lower.contains($0)
        }
    }

    private static func inferCategory(from title: String) -> String {
        let t = title.lowercased()
        if ["workout", "gym", "run", "yoga", "doctor", "dentist"].contains(where: { t.contains($0) }) {
            return "health"
        }
        if ["pay", "bill", "tax", "paperwork"].contains(where: { t.contains($0) }) {
            return "admin"
        }
        if ["call", "email", "meeting", "review"].contains(where: { t.contains($0) }) {
            return "work"
        }
        return "personal"
    }
}

private enum IntentNotificationScheduler {
    static func sync(with records: [TaskRecord]) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus) else {
            return
        }
        let now = Date()
        for record in records where record.hasTime && !record.isCompleted {
            let lead = record.priorityRaw == "high" ? 30 : 15
            let fireDate = record.startTime.addingTimeInterval(-Double(lead) * 60)
            guard fireDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = record.title
            content.body = "Starts in \(lead) min"
            content.sound = .default

            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: "clarity.task.\(record.id.uuidString)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
