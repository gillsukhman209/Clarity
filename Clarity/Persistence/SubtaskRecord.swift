//
//  SubtaskRecord.swift
//  Clarity
//
//  Phase 9 — every stored property has a default for CloudKit compatibility.
//

import Foundation
import SwiftData

@Model
final class SubtaskRecord {
    var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var sortIndex: Int = 0
    /// Back-reference to the owning task. Required by CloudKit, which needs
    /// every relationship to have an inverse.
    var task: TaskRecord? = nil

    init(
        id: UUID = UUID(),
        title: String = "",
        isCompleted: Bool = false,
        sortIndex: Int = 0
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.sortIndex = sortIndex
    }
}
