//
//  SmartTaskParser.swift
//  Clarity
//
//  Local, instant parsing for the Quick Add "Smart" mode — no API roundtrip.
//  Uses NSDataDetector for date/time recognition (handles "tomorrow at 6am",
//  "in 2 mins", "next Monday", "noon", etc.), a regex for explicit durations
//  ("for 30 min", "1 hour"), and keyword heuristics for category. Anything we
//  can't infer falls back to a sane default and the user can edit later.
//

import Foundation

struct ParsedQuickTask {
    /// `nil` when the input had no time reference. Caller should set
    /// `hasTime = false` and anchor the task to today (or today + dayOffset).
    var startTime: Date?
    var title: String
    /// `0` means the parser couldn't infer a duration — leave it open-ended.
    var durationMinutes: Int
    var category: TaskCategory
    var hasExplicitTime: Bool
    var recurrence: TaskRecurrence?
}

struct TaskRecurrence: Hashable {
    enum Frequency: Hashable {
        case daily
        case weekly
        case monthly
    }

    var frequency: Frequency
    var interval: Int = 1
    /// Calendar weekday values: Sunday = 1, Monday = 2, ... Saturday = 7.
    var weekdays: Set<Int> = []
    var dayOfMonth: Int? = nil

    var occurrenceLimit: Int {
        switch frequency {
        case .daily: return weekdays.isEmpty ? 180 : 130
        case .weekly: return 104
        case .monthly: return 36
        }
    }

    func firstDate(onOrAfter date: Date, preservingTimeFrom preferred: Date?, hasTime: Bool, calendar: Calendar = .current) -> Date {
        let reference = preferred ?? date
        let time = calendar.dateComponents([.hour, .minute, .second], from: hasTime ? reference : calendar.startOfDay(for: reference))
        let searchStart = hasTime ? date : calendar.startOfDay(for: date)

        switch frequency {
        case .daily:
            return nextDailyDate(onOrAfter: searchStart, time: time, calendar: calendar)
        case .weekly:
            return nextWeeklyDate(onOrAfter: searchStart, time: time, calendar: calendar)
        case .monthly:
            return nextMonthlyDate(onOrAfter: searchStart, time: time, calendar: calendar)
        }
    }

    func expandedTasks(from base: PlanTask, now: Date = Date(), calendar: Calendar = .current) -> [PlanTask] {
        let first = firstDate(onOrAfter: now, preservingTimeFrom: base.startTime, hasTime: base.hasTime, calendar: calendar)
        let dates = occurrenceDates(startingAt: first, hasTime: base.hasTime, calendar: calendar)
        return dates.map { date in
            PlanTask(
                title: base.title,
                category: base.category,
                priority: base.priority,
                startTime: date,
                hasTime: base.hasTime,
                durationMinutes: base.durationMinutes,
                notes: base.notes,
                subtasks: base.subtasks,
                isCompleted: false,
                projectID: base.projectID,
                boardStatus: base.boardStatus,
                manualOrder: base.manualOrder
            )
        }
    }

    private func occurrenceDates(startingAt start: Date, hasTime: Bool, calendar: Calendar) -> [Date] {
        var dates: [Date] = []
        var cursor = start
        var guardCount = 0

        while dates.count < occurrenceLimit && guardCount < occurrenceLimit * 8 {
            guardCount += 1
            if matches(cursor, calendar: calendar) {
                dates.append(cursor)
            }

            switch frequency {
            case .daily:
                cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor.addingTimeInterval(86_400)
            case .weekly:
                let step = weekdays.isEmpty ? 7 * interval : 1
                cursor = calendar.date(byAdding: .day, value: step, to: cursor) ?? cursor.addingTimeInterval(TimeInterval(step * 86_400))
            case .monthly:
                cursor = nextMonth(after: cursor, calendar: calendar)
            }
        }
        return dates
    }

    private func matches(_ date: Date, calendar: Calendar) -> Bool {
        switch frequency {
        case .daily:
            return weekdays.isEmpty || weekdays.contains(calendar.component(.weekday, from: date))
        case .weekly:
            return weekdays.isEmpty || weekdays.contains(calendar.component(.weekday, from: date))
        case .monthly:
            guard let dayOfMonth else { return true }
            return calendar.component(.day, from: date) == dayOfMonth
        }
    }

    private func nextDailyDate(onOrAfter date: Date, time: DateComponents, calendar: Calendar) -> Date {
        for offset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: date)),
                  let candidate = calendar.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: time.second ?? 0, of: day)
            else { continue }
            if candidate >= date && matches(candidate, calendar: calendar) {
                return candidate
            }
        }
        return date
    }

    private func nextWeeklyDate(onOrAfter date: Date, time: DateComponents, calendar: Calendar) -> Date {
        for offset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: date)),
                  let candidate = calendar.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: time.second ?? 0, of: day)
            else { continue }
            if candidate >= date && matches(candidate, calendar: calendar) {
                return candidate
            }
        }
        return date
    }

    private func nextMonthlyDate(onOrAfter date: Date, time: DateComponents, calendar: Calendar) -> Date {
        let requestedDay = dayOfMonth ?? calendar.component(.day, from: date)
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? calendar.startOfDay(for: date)
        for offset in 0..<48 {
            guard let month = calendar.date(byAdding: .month, value: offset, to: monthStart),
                  let range = calendar.range(of: .day, in: .month, for: month)
            else { continue }
            let clampedDay = min(max(1, requestedDay), range.count)
            var comps = calendar.dateComponents([.year, .month], from: month)
            comps.day = clampedDay
            comps.hour = time.hour ?? 0
            comps.minute = time.minute ?? 0
            comps.second = time.second ?? 0
            guard let candidate = calendar.date(from: comps), candidate >= date else { continue }
            return candidate
        }
        return date
    }

    private func nextMonth(after date: Date, calendar: Calendar) -> Date {
        let time = calendar.dateComponents([.hour, .minute, .second], from: date)
        let nextMonth = calendar.date(byAdding: .month, value: interval, to: date) ?? date
        let requestedDay = dayOfMonth ?? calendar.component(.day, from: date)
        let range = calendar.range(of: .day, in: .month, for: nextMonth)
        var comps = calendar.dateComponents([.year, .month], from: nextMonth)
        comps.day = min(max(1, requestedDay), range?.count ?? requestedDay)
        comps.hour = time.hour ?? 0
        comps.minute = time.minute ?? 0
        comps.second = time.second ?? 0
        return calendar.date(from: comps) ?? nextMonth
    }
}

enum SmartTaskParser {

    static func parse(_ rawInput: String, now: Date = Date()) -> ParsedQuickTask {
        let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ParsedQuickTask(
                startTime: nil, title: "New task",
                durationMinutes: 0, category: .personal,
                hasExplicitTime: false,
                recurrence: nil
            )
        }

        let recurrenceMatch = detectRecurrence(in: trimmed)
        let dateSource = removeRanges(recurrenceMatch?.ranges ?? [], from: trimmed)

        // 1. Date + time
        // 1a. "in N minutes/hours/seconds" — a relative offset from now.
        // We check this BEFORE NSDataDetector because NSDataDetector is unreliable
        // on small relative offsets ("in 2 mins") and we don't want the duration
        // regex below to swallow the "30 minutes" as a task duration.
        var startTime: Date? = nil
        var dateMatchText: String? = nil
        var explicitTimeFromOffset = false
        if let (date, matched) = relativeOffsetMatch(in: dateSource, now: now) {
            startTime = date
            dateMatchText = matched
            explicitTimeFromOffset = true
        } else if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
            // 1b. Absolute / named dates: "tomorrow at 6am", "next Monday", "noon".
            let range = NSRange(dateSource.startIndex..., in: dateSource)
            if let match = detector.matches(in: dateSource, options: [], range: range).first {
                if let r = Range(match.range, in: dateSource) {
                    dateMatchText = String(dateSource[r])
                }
                startTime = match.date
            }
        }

        // hasTime decision: relative offsets are always explicit; for absolute
        // dates, only when the matched text contains time-of-day markers.
        let hasExplicitTime = explicitTimeFromOffset
            || (dateMatchText.map { containsTimeMarker($0) } ?? false)

        // 2. Build a working title by stripping the date phrase.
        var working = dateSource
        if let match = dateMatchText, let r = working.range(of: match) {
            working.removeSubrange(r)
        }

        // 3. Detect explicit duration ("30 min", "1 hour", "for 90m").
        // Default `0` = no duration set — task is open-ended unless the user
        // says otherwise.
        var durationMinutes: Int = 0
        if let regex = try? NSRegularExpression(
            pattern: #"\b(\d{1,3})\s*(minutes?|mins?|m|hours?|hrs?|h)\b"#,
            options: .caseInsensitive
        ) {
            let nsWorking = working as NSString
            let r = NSRange(location: 0, length: nsWorking.length)
            if let m = regex.firstMatch(in: working, options: [], range: r) {
                let valueText = nsWorking.substring(with: m.range(at: 1))
                let unitText  = nsWorking.substring(with: m.range(at: 2)).lowercased()
                if let value = Int(valueText) {
                    durationMinutes = unitText.first == "h" ? value * 60 : value
                }
                // Strip the duration phrase from the title.
                if let r2 = Range(m.range, in: working) {
                    working.removeSubrange(r2)
                }
            }
        }

        // 4. Tidy up: collapse whitespace + drop trailing connectors.
        let title = cleanTitle(working).ifEmpty(rawInput)

        // 5. Infer category from keywords.
        let category = inferCategory(from: title)

        // 6. If we have a start time but no time was actually stated (e.g. "tomorrow"),
        // discard the time-of-day component and anchor the task to that day.
        if let s = startTime, !hasExplicitTime {
            startTime = Calendar.current.startOfDay(for: s)
        }

        if let recurrence = recurrenceMatch?.recurrence {
            startTime = recurrence.firstDate(
                onOrAfter: now,
                preservingTimeFrom: startTime,
                hasTime: hasExplicitTime
            )
        }

        return ParsedQuickTask(
            startTime: startTime,
            title: title,
            durationMinutes: durationMinutes,
            category: category,
            hasExplicitTime: hasExplicitTime,
            recurrence: recurrenceMatch?.recurrence
        )
    }

    /// Returns whether the parser concluded the input names an explicit time.
    /// Useful for setting `PlanTask.hasTime`.
    static func hasExplicitTime(in rawInput: String) -> Bool {
        let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if relativeOffsetMatch(in: trimmed, now: Date()) != nil { return true }
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue),
              let match = detector.matches(in: trimmed, options: [], range: NSRange(trimmed.startIndex..., in: trimmed)).first,
              let r = Range(match.range, in: trimmed)
        else { return false }
        return containsTimeMarker(String(trimmed[r]))
    }

    static func makeTasks(
        from input: String,
        priority: TaskPriority = .medium,
        projectID: UUID? = nil,
        boardStatus: TaskBoardStatus = .upcoming,
        now: Date = Date()
    ) -> [PlanTask] {
        let parsed = parse(input, now: now)
        let anchor = parsed.startTime ?? Calendar.current.startOfDay(for: now)
        let base = PlanTask(
            title: parsed.title,
            category: parsed.category,
            priority: priority,
            startTime: anchor,
            hasTime: parsed.hasExplicitTime,
            durationMinutes: parsed.durationMinutes,
            projectID: projectID,
            boardStatus: boardStatus
        )
        guard let recurrence = parsed.recurrence else { return [base] }
        return recurrence.expandedTasks(from: base, now: now)
    }

    // MARK: - Helpers

    private struct RecurrenceMatch {
        var recurrence: TaskRecurrence
        var ranges: [Range<String.Index>]
    }

    private static func detectRecurrence(in text: String) -> RecurrenceMatch? {
        if let monthly = detectMonthlyRecurrence(in: text) {
            return monthly
        }
        if let weekly = detectWeeklyRecurrence(in: text) {
            return weekly
        }
        if let daily = firstRegexMatch(#"\b(every\s*day|everyday|daily|each\s+day)\b"#, in: text) {
            return RecurrenceMatch(
                recurrence: TaskRecurrence(frequency: .daily),
                ranges: [daily]
            )
        }
        if let weekday = firstRegexMatch(#"\b(every\s+weekday|weekdays|every\s+workday|workdays)\b"#, in: text) {
            return RecurrenceMatch(
                recurrence: TaskRecurrence(frequency: .daily, weekdays: Set(2...6)),
                ranges: [weekday]
            )
        }
        if let weekend = firstRegexMatch(#"\b(every\s+weekend|weekends)\b"#, in: text) {
            return RecurrenceMatch(
                recurrence: TaskRecurrence(frequency: .daily, weekdays: Set([1, 7])),
                ranges: [weekend]
            )
        }
        return nil
    }

    private static func detectMonthlyRecurrence(in text: String) -> RecurrenceMatch? {
        let patterns = [
            #"\b(?:on\s+)?(?:the\s+)?(\d{1,2})(?:st|nd|rd|th)?\s+(?:of\s+)?every\s+month\b"#,
            #"\bevery\s+month\s+(?:on\s+)?(?:the\s+)?(\d{1,2})(?:st|nd|rd|th)?\b"#,
            #"\bmonthly\s+(?:on\s+)?(?:the\s+)?(\d{1,2})(?:st|nd|rd|th)?\b"#
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let nsRange = NSRange(text.startIndex..., in: text)
            guard let match = regex.firstMatch(in: text, options: [], range: nsRange),
                  let full = Range(match.range, in: text),
                  let dayRange = Range(match.range(at: 1), in: text),
                  let day = Int(text[dayRange]),
                  (1...31).contains(day)
            else { continue }
            return RecurrenceMatch(
                recurrence: TaskRecurrence(frequency: .monthly, dayOfMonth: day),
                ranges: [full]
            )
        }
        if let monthly = firstRegexMatch(#"\b(every\s+month|monthly)\b"#, in: text) {
            return RecurrenceMatch(
                recurrence: TaskRecurrence(frequency: .monthly),
                ranges: [monthly]
            )
        }
        return nil
    }

    private static func detectWeeklyRecurrence(in text: String) -> RecurrenceMatch? {
        let weekdayAlternation = weekdayNames.keys.sorted().joined(separator: "|")
        let patterns = [
            #"\b(?:every|each)\s+("# + weekdayAlternation + #")(?:s)?\b"#,
            #"\bweekly\s+on\s+("# + weekdayAlternation + #")(?:s)?\b"#
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let nsRange = NSRange(text.startIndex..., in: text)
            guard let match = regex.firstMatch(in: text, options: [], range: nsRange),
                  let full = Range(match.range, in: text),
                  let dayRange = Range(match.range(at: 1), in: text)
            else { continue }
            let key = String(text[dayRange]).lowercased()
            guard let weekday = weekdayNames[key] else { continue }
            return RecurrenceMatch(
                recurrence: TaskRecurrence(frequency: .weekly, weekdays: [weekday]),
                ranges: [full]
            )
        }
        if let weekly = firstRegexMatch(#"\b(every\s+week|weekly)\b"#, in: text) {
            return RecurrenceMatch(
                recurrence: TaskRecurrence(frequency: .weekly),
                ranges: [weekly]
            )
        }
        return nil
    }

    private static let weekdayNames: [String: Int] = [
        "sunday": 1, "sun": 1,
        "monday": 2, "mon": 2,
        "tuesday": 3, "tue": 3, "tues": 3,
        "wednesday": 4, "wed": 4,
        "thursday": 5, "thu": 5, "thurs": 5,
        "friday": 6, "fri": 6,
        "saturday": 7, "sat": 7
    ]

    private static func firstRegexMatch(_ pattern: String, in text: String) -> Range<String.Index>? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }
        return Range(match.range, in: text)
    }

    private static func removeRanges(_ ranges: [Range<String.Index>], from text: String) -> String {
        var output = text
        for range in ranges.sorted(by: { $0.lowerBound > $1.lowerBound }) {
            output.removeSubrange(range)
        }
        return output
    }

    /// Detects "in N seconds/minutes/hours" and returns the resulting absolute
    /// date plus the exact matched substring (so callers can strip it from the
    /// title). Returns `nil` if the input doesn't contain such a phrase.
    private static func relativeOffsetMatch(in text: String, now: Date) -> (Date, String)? {
        let pattern = #"\bin\s+(\d{1,3})\s*(seconds?|secs?|minutes?|mins?|hours?|hrs?|s|m|h)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let valueR = Range(match.range(at: 1), in: text),
              let unitR  = Range(match.range(at: 2), in: text),
              let fullR  = Range(match.range, in: text),
              let value  = Int(text[valueR])
        else { return nil }

        let unit = text[unitR].lowercased()
        let secondsPerUnit: TimeInterval
        if unit.hasPrefix("s") {
            secondsPerUnit = 1
        } else if unit.hasPrefix("h") {
            secondsPerUnit = 3600
        } else {
            secondsPerUnit = 60
        }
        let date = now.addingTimeInterval(TimeInterval(value) * secondsPerUnit)
        return (date, String(text[fullR]))
    }

    private static func containsTimeMarker(_ text: String) -> Bool {
        let lower = text.lowercased()
        let markers = [
            "am", "pm", "a.m", "p.m", ":",
            "noon", "midnight", "morning", "afternoon", "evening", "night",
            "sec", "min", "hour", "hr"
        ]
        return markers.contains(where: { lower.contains($0) })
    }

    private static func cleanTitle(_ raw: String) -> String {
        let connectors = [
            " at ", " on ", " in ", " for ", " by ",
            " around ", " from ", " to ",
            " starting ", " starts ", " until ",
        ]
        var out = " " + raw + " "
        for c in connectors {
            out = out.replacingOccurrences(of: c, with: " ", options: .caseInsensitive)
        }
        let collapsed = out
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = collapsed.first else { return collapsed }
        return first.uppercased() + collapsed.dropFirst()
    }

    private static func inferCategory(from title: String) -> TaskCategory {
        let t = title.lowercased()
        let any: (String, [String]) -> Bool = { _, words in words.contains(where: { t.contains($0) }) }

        if any("health", [
            "workout", "gym", "run", "jog", "walk", "yoga", "pilates", "training",
            "doctor", "dentist", "chiro", "appointment", "therapy", "medical",
            "stretch", "swim"
        ]) { return .health }

        if any("energize", [
            "lunch", "breakfast", "dinner", "snack", "coffee", "eat", "meal",
            "break", "nap"
        ]) { return .energize }

        if any("create", [
            "write", "draft", "design", "sketch", "prototype", "brainstorm",
            "compose", "record", "edit", "outline", "blog", "post", "video"
        ]) { return .create }

        if any("focus", [
            "focus", "deep work", "study", "research", "review proposal", "analysis"
        ]) { return .focus }

        if any("admin", [
            "pay", "bill", "tax", "file", "paperwork", "organize", "schedule",
            "plan tomorrow"
        ]) { return .admin }

        if any("windDown", [
            "read", "book", "sleep", "meditate", "journal", "relax",
            "wind down", "skincare"
        ]) { return .windDown }

        if any("personal", [
            "groceries", "grocery", "shopping", "errand", "pick up", "buy",
            "call mom", "call dad", "family", "kids", "home"
        ]) { return .personal }

        if any("work", [
            "call", "email", "slack", "message", "meeting", "standup", "sync",
            "review", "1:1", "client", "interview", "follow up"
        ]) { return .work }

        return .personal
    }

}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
