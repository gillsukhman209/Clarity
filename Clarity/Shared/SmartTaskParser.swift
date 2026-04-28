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
}

enum SmartTaskParser {

    static func parse(_ rawInput: String, now: Date = Date()) -> ParsedQuickTask {
        let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ParsedQuickTask(
                startTime: nil, title: "New task",
                durationMinutes: 0, category: .personal
            )
        }

        // 1. Date + time
        // 1a. "in N minutes/hours/seconds" — a relative offset from now.
        // We check this BEFORE NSDataDetector because NSDataDetector is unreliable
        // on small relative offsets ("in 2 mins") and we don't want the duration
        // regex below to swallow the "30 minutes" as a task duration.
        var startTime: Date? = nil
        var dateMatchText: String? = nil
        var explicitTimeFromOffset = false
        if let (date, matched) = relativeOffsetMatch(in: trimmed, now: now) {
            startTime = date
            dateMatchText = matched
            explicitTimeFromOffset = true
        } else if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
            // 1b. Absolute / named dates: "tomorrow at 6am", "next Monday", "noon".
            let range = NSRange(trimmed.startIndex..., in: trimmed)
            if let match = detector.matches(in: trimmed, options: [], range: range).first {
                if let r = Range(match.range, in: trimmed) {
                    dateMatchText = String(trimmed[r])
                }
                startTime = match.date
            }
        }

        // hasTime decision: relative offsets are always explicit; for absolute
        // dates, only when the matched text contains time-of-day markers.
        let hasExplicitTime = explicitTimeFromOffset
            || (dateMatchText.map(containsTimeMarker(_:)) ?? false)

        // 2. Build a working title by stripping the date phrase.
        var working = trimmed
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

        return ParsedQuickTask(
            startTime: startTime,
            title: title,
            durationMinutes: durationMinutes,
            category: category
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

    // MARK: - Helpers

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
