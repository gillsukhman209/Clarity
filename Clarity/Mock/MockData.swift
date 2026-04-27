//
//  MockData.swift
//  Clarity
//
//  Used to be a seed for the day plan; tasks now come exclusively from the user.
//  Kept around for the few non-task constants the UI still reads (greeting name,
//  date helper). Phase 10 onboarding will replace these with real user values.
//

import Foundation

enum MockData {
    /// Placeholder display name. Replaced once onboarding (Phase 10) collects the real one.
    static let userFirstName = "there"

    static var today: Date {
        Calendar.current.startOfDay(for: Date())
    }
}
